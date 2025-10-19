# GraphQL Design Patterns

GraphQL API設計のベストプラクティスとパターン。

## スキーマ設計

### 型定義のベストプラクティス
```graphql
# スカラー型
scalar DateTime
scalar Email
scalar URL
scalar JSON

# Enum定義
enum UserRole {
  ADMIN
  EDITOR
  VIEWER
}

enum OrderStatus {
  PENDING
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}

# Interface定義
interface Node {
  id: ID!
}

interface Timestamped {
  createdAt: DateTime!
  updatedAt: DateTime!
}

# Type定義
type User implements Node & Timestamped {
  id: ID!
  email: Email!
  name: String!
  role: UserRole!
  posts: [Post!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Post implements Node & Timestamped {
  id: ID!
  title: String!
  content: String!
  author: User!
  comments(first: Int, after: String): CommentConnection!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

### Relay仕様準拠
```graphql
# Connection型（ページネーション）
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type PostEdge {
  cursor: String!
  node: Post!
}

type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

# Query定義
type Query {
  # 単一ノード取得
  node(id: ID!): Node
  
  # リスト取得（Connection）
  posts(
    first: Int
    after: String
    last: Int
    before: String
    filter: PostFilter
    orderBy: PostOrderBy
  ): PostConnection!
}
```

## リゾルバー実装

### 基本的なリゾルバー
```typescript
import { GraphQLResolveInfo } from 'graphql';

interface Context {
  user?: User;
  dataSources: DataSources;
  loaders: DataLoaders;
}

const resolvers = {
  Query: {
    user: async (
      parent: any,
      args: { id: string },
      context: Context,
      info: GraphQLResolveInfo
    ) => {
      // DataLoaderでN+1問題回避
      return context.loaders.userLoader.load(args.id);
    },
    
    posts: async (parent, args, context) => {
      const { first = 20, after, filter, orderBy } = args;
      
      // Cursor-basedページネーション
      const posts = await context.dataSources.postAPI.getPosts({
        first: first + 1, // hasNextPage判定用
        after,
        filter,
        orderBy
      });
      
      const hasNextPage = posts.length > first;
      const edges = posts.slice(0, first).map(post => ({
        cursor: Buffer.from(post.id).toString('base64'),
        node: post
      }));
      
      return {
        edges,
        pageInfo: {
          hasNextPage,
          hasPreviousPage: !!after,
          startCursor: edges[0]?.cursor,
          endCursor: edges[edges.length - 1]?.cursor
        }
      };
    }
  },
  
  User: {
    posts: async (parent: User, args, context) => {
      return context.loaders.postsByUserLoader.load(parent.id);
    }
  },
  
  Post: {
    author: async (parent: Post, args, context) => {
      return context.loaders.userLoader.load(parent.authorId);
    }
  }
};
```

### DataLoader実装
```typescript
import DataLoader from 'dataloader';

class UserLoader {
  private loader: DataLoader<string, User>;
  
  constructor(private db: Database) {
    this.loader = new DataLoader(
      async (userIds: readonly string[]) => {
        const users = await db.user.findMany({
          where: { id: { in: userIds as string[] } }
        });
        
        const userMap = new Map(users.map(u => [u.id, u]));
        return userIds.map(id => userMap.get(id) || null);
      },
      {
        cacheKeyFn: (key) => key,
        maxBatchSize: 100
      }
    );
  }
  
  async load(userId: string): Promise<User | null> {
    return this.loader.load(userId);
  }
  
  clearAll(): void {
    this.loader.clearAll();
  }
}

// Context作成
const createContext = (req: Request): Context => {
  const db = new Database();
  
  return {
    user: req.user,
    dataSources: {
      userAPI: new UserAPI(db),
      postAPI: new PostAPI(db)
    },
    loaders: {
      userLoader: new UserLoader(db),
      postsByUserLoader: new PostsByUserLoader(db)
    }
  };
};
```

## ミューテーション設計

### Input型とPayload型
```graphql
# Input型
input CreateUserInput {
  email: Email!
  name: String!
  password: String!
  role: UserRole
}

input UpdateUserInput {
  email: Email
  name: String
  role: UserRole
}

# Payload型（成功/エラー両方を扱う）
interface MutationResponse {
  success: Boolean!
  message: String
}

type CreateUserPayload implements MutationResponse {
  success: Boolean!
  message: String
  user: User
  errors: [FieldError!]
}

type FieldError {
  field: String!
  message: String!
}

# Mutation定義
type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!
}
```

### ミューテーションリゾルバー
```typescript
const mutations = {
  createUser: async (parent, args, context) => {
    try {
      // バリデーション
      const validation = await validateCreateUser(args.input);
      if (!validation.valid) {
        return {
          success: false,
          message: 'Validation failed',
          user: null,
          errors: validation.errors
        };
      }
      
      // ビジネスロジック
      const user = await context.dataSources.userAPI.createUser(args.input);
      
      // キャッシュクリア
      context.loaders.userLoader.clearAll();
      
      return {
        success: true,
        message: 'User created successfully',
        user,
        errors: []
      };
    } catch (error) {
      console.error('Create user error:', error);
      return {
        success: false,
        message: error.message,
        user: null,
        errors: []
      };
    }
  }
};
```

## サブスクリプション

### リアルタイム更新
```graphql
type Subscription {
  postAdded(authorId: ID): Post!
  commentAdded(postId: ID!): Comment!
  userStatusChanged(userId: ID!): UserStatus!
}

type UserStatus {
  userId: ID!
  status: String!
  lastSeen: DateTime!
}
```

### サブスクリプション実装
```typescript
import { PubSub } from 'graphql-subscriptions';
import { withFilter } from 'graphql-subscriptions';

const pubsub = new PubSub();

// トリガー定数
const TRIGGERS = {
  POST_ADDED: 'POST_ADDED',
  COMMENT_ADDED: 'COMMENT_ADDED',
  USER_STATUS_CHANGED: 'USER_STATUS_CHANGED'
};

const subscriptions = {
  postAdded: {
    subscribe: withFilter(
      () => pubsub.asyncIterator(TRIGGERS.POST_ADDED),
      (payload, variables) => {
        // フィルタリング
        return !variables.authorId || payload.postAdded.authorId === variables.authorId;
      }
    )
  },
  
  commentAdded: {
    subscribe: withFilter(
      () => pubsub.asyncIterator(TRIGGERS.COMMENT_ADDED),
      (payload, variables) => {
        return payload.commentAdded.postId === variables.postId;
      }
    )
  }
};

// ミューテーションでパブリッシュ
const createPost = async (parent, args, context) => {
  const post = await context.dataSources.postAPI.createPost(args.input);
  
  // サブスクリプションに通知
  await pubsub.publish(TRIGGERS.POST_ADDED, { postAdded: post });
  
  return post;
};
```

## エラーハンドリング

### カスタムエラー
```typescript
import { GraphQLError } from 'graphql';

class AuthenticationError extends GraphQLError {
  constructor(message: string = 'Not authenticated') {
    super(message, {
      extensions: {
        code: 'UNAUTHENTICATED',
        http: { status: 401 }
      }
    });
  }
}

class ForbiddenError extends GraphQLError {
  constructor(message: string = 'Not authorized') {
    super(message, {
      extensions: {
        code: 'FORBIDDEN',
        http: { status: 403 }
      }
    });
  }
}

class UserInputError extends GraphQLError {
  constructor(message: string, invalidArgs?: any) {
    super(message, {
      extensions: {
        code: 'BAD_USER_INPUT',
        invalidArgs,
        http: { status: 400 }
      }
    });
  }
}

// 使用例
const resolvers = {
  Query: {
    user: async (parent, args, context) => {
      if (!context.user) {
        throw new AuthenticationError();
      }
      
      const user = await context.loaders.userLoader.load(args.id);
      
      if (!user) {
        throw new UserInputError('User not found', { id: args.id });
      }
      
      if (!canViewUser(context.user, user)) {
        throw new ForbiddenError('Cannot view this user');
      }
      
      return user;
    }
  }
};
```

## パフォーマンス最適化

### クエリ深度制限
```typescript
import depthLimit from 'graphql-depth-limit';

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    depthLimit(5) // 最大深度5
  ]
});
```

### クエリコスト分析
```typescript
import costAnalysis from 'graphql-cost-analysis';

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    costAnalysis({
      maximumCost: 1000,
      defaultCost: 1,
      scalarCost: 1,
      objectCost: 2,
      listFactor: 10,
      introspectionCost: 1000,
      enforceIntrospectionCost: false
    })
  ]
});
```

### フィールドレベルキャッシング
```typescript
import { cacheControl } from '@apollo/cache-control';

const resolvers = {
  Query: {
    // 静的データは長めにキャッシュ
    categories: (parent, args, context, info) => {
      info.cacheControl.setCacheHint({ maxAge: 3600 });
      return context.dataSources.categoryAPI.getAll();
    },
    
    // 動的データは短めに
    trending: (parent, args, context, info) => {
      info.cacheControl.setCacheHint({ maxAge: 60 });
      return context.dataSources.postAPI.getTrending();
    }
  }
};
```

## セキュリティ

### 認証・認可
```typescript
import { rule, shield, and, or, not } from 'graphql-shield';

// ルール定義
const isAuthenticated = rule({ cache: 'contextual' })(
  async (parent, args, context) => {
    return context.user !== null;
  }
);

const isOwner = rule({ cache: 'strict' })(
  async (parent, args, context) => {
    const user = await context.loaders.userLoader.load(args.id);
    return user?.id === context.user?.id;
  }
);

const isAdmin = rule({ cache: 'contextual' })(
  async (parent, args, context) => {
    return context.user?.role === 'ADMIN';
  }
);

// パーミッション定義
const permissions = shield({
  Query: {
    users: isAuthenticated,
    user: isAuthenticated,
    adminStats: isAdmin
  },
  Mutation: {
    updateUser: or(isOwner, isAdmin),
    deleteUser: isAdmin
  }
});
```

### レート制限
```typescript
import { RateLimiterMemory } from 'rate-limiter-flexible';

const rateLimiter = new RateLimiterMemory({
  points: 100, // リクエスト数
  duration: 60  // 秒
});

const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: async ({ req }) => {
    // レート制限チェック
    const key = req.ip || 'anonymous';
    try {
      await rateLimiter.consume(key);
    } catch (error) {
      throw new Error('Too many requests');
    }
    
    return createContext(req);
  }
});
```

## チェックリスト
- [ ] 適切なスキーマ設計
- [ ] Relay仕様準拠
- [ ] DataLoader実装
- [ ] エラーハンドリング
- [ ] サブスクリプション対応
- [ ] クエリ深度制限
- [ ] コスト分析
- [ ] キャッシング戦略
- [ ] 認証・認可実装
- [ ] レート制限設定