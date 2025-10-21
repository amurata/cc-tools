# GraphQLスキーマ設計パターン

## スキーマ組織化

### モジュラースキーマ構造
```graphql
# user.graphql
type User {
  id: ID!
  email: String!
  name: String!
  posts: [Post!]!
}

extend type Query {
  user(id: ID!): User
  users(first: Int, after: String): UserConnection!
}

extend type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
}

# post.graphql
type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
}

extend type Query {
  post(id: ID!): Post
}
```

## 型設計パターン

### 1. Non-Null型
```graphql
type User {
  id: ID!              # 常に必須
  email: String!       # 必須
  phone: String        # オプション (nullable)
  posts: [Post!]!      # Non-null投稿のnon-null配列
  tags: [String!]      # Non-null文字列のnullable配列
}
```

### 2. ポリモーフィズムのためのインターフェース
```graphql
interface Node {
  id: ID!
  createdAt: DateTime!
}

type User implements Node {
  id: ID!
  createdAt: DateTime!
  email: String!
}

type Post implements Node {
  id: ID!
  createdAt: DateTime!
  title: String!
}

type Query {
  node(id: ID!): Node
}
```

### 3. 異種結果のためのユニオン
```graphql
union SearchResult = User | Post | Comment

type Query {
  search(query: String!): [SearchResult!]!
}

# クエリ例
{
  search(query: "graphql") {
    ... on User {
      name
      email
    }
    ... on Post {
      title
      content
    }
    ... on Comment {
      text
      author { name }
    }
  }
}
```

### 4. 入力型
```graphql
input CreateUserInput {
  email: String!
  name: String!
  password: String!
  profileInput: ProfileInput
}

input ProfileInput {
  bio: String
  avatar: String
  website: String
}

input UpdateUserInput {
  id: ID!
  email: String
  name: String
  profileInput: ProfileInput
}
```

## ページネーションパターン

### Relayカーソルページネーション (推奨)
```graphql
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type Query {
  users(
    first: Int
    after: String
    last: Int
    before: String
  ): UserConnection!
}

# 使用例
{
  users(first: 10, after: "cursor123") {
    edges {
      cursor
      node {
        id
        name
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

### オフセットページネーション (シンプル)
```graphql
type UserList {
  items: [User!]!
  total: Int!
  page: Int!
  pageSize: Int!
}

type Query {
  users(page: Int = 1, pageSize: Int = 20): UserList!
}
```

## ミューテーション設計パターン

### 1. Input/Payloadパターン
```graphql
input CreatePostInput {
  title: String!
  content: String!
  tags: [String!]
}

type CreatePostPayload {
  post: Post
  errors: [Error!]
  success: Boolean!
}

type Error {
  field: String
  message: String!
  code: String!
}

type Mutation {
  createPost(input: CreatePostInput!): CreatePostPayload!
}
```

### 2. 楽観的レスポンスサポート
```graphql
type UpdateUserPayload {
  user: User
  clientMutationId: String
  errors: [Error!]
}

input UpdateUserInput {
  id: ID!
  name: String
  clientMutationId: String
}

type Mutation {
  updateUser(input: UpdateUserInput!): UpdateUserPayload!
}
```

### 3. バッチミューテーション
```graphql
input BatchCreateUserInput {
  users: [CreateUserInput!]!
}

type BatchCreateUserPayload {
  results: [CreateUserResult!]!
  successCount: Int!
  errorCount: Int!
}

type CreateUserResult {
  user: User
  errors: [Error!]
  index: Int!
}

type Mutation {
  batchCreateUsers(input: BatchCreateUserInput!): BatchCreateUserPayload!
}
```

## フィールド設計

### 引数とフィルタリング
```graphql
type Query {
  posts(
    # ページネーション
    first: Int = 20
    after: String

    # フィルタリング
    status: PostStatus
    authorId: ID
    tag: String

    # ソート
    orderBy: PostOrderBy = CREATED_AT
    orderDirection: OrderDirection = DESC

    # 検索
    search: String
  ): PostConnection!
}

enum PostStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}

enum PostOrderBy {
  CREATED_AT
  UPDATED_AT
  TITLE
}

enum OrderDirection {
  ASC
  DESC
}
```

### 計算フィールド
```graphql
type User {
  firstName: String!
  lastName: String!
  fullName: String!  # リゾルバーで計算

  posts: [Post!]!
  postCount: Int!    # 計算、すべての投稿をロードしない
}

type Post {
  likeCount: Int!
  commentCount: Int!
  isLikedByViewer: Boolean!  # コンテキスト依存
}
```

## サブスクリプション

```graphql
type Subscription {
  postAdded: Post!

  postUpdated(postId: ID!): Post!

  userStatusChanged(userId: ID!): UserStatus!
}

type UserStatus {
  userId: ID!
  online: Boolean!
  lastSeen: DateTime!
}

# クライアント使用例
subscription {
  postAdded {
    id
    title
    author {
      name
    }
  }
}
```

## カスタムスカラー

```graphql
scalar DateTime
scalar Email
scalar URL
scalar JSON
scalar Money

type User {
  email: Email!
  website: URL
  createdAt: DateTime!
  metadata: JSON
}

type Product {
  price: Money!
}
```

## ディレクティブ

### 組み込みディレクティブ
```graphql
type User {
  name: String!
  email: String! @deprecated(reason: "Use emails field instead")
  emails: [String!]!

  # 条件付き包含
  privateData: PrivateData @include(if: $isOwner)
}

# クエリ
query GetUser($isOwner: Boolean!) {
  user(id: "123") {
    name
    privateData @include(if: $isOwner) {
      ssn
    }
  }
}
```

### カスタムディレクティブ
```graphql
directive @auth(requires: Role = USER) on FIELD_DEFINITION

enum Role {
  USER
  ADMIN
  MODERATOR
}

type Mutation {
  deleteUser(id: ID!): Boolean! @auth(requires: ADMIN)
  updateProfile(input: ProfileInput!): User! @auth
}
```

## エラー処理

### ユニオンエラーパターン
```graphql
type User {
  id: ID!
  email: String!
}

type ValidationError {
  field: String!
  message: String!
}

type NotFoundError {
  message: String!
  resourceType: String!
  resourceId: ID!
}

type AuthorizationError {
  message: String!
}

union UserResult = User | ValidationError | NotFoundError | AuthorizationError

type Query {
  user(id: ID!): UserResult!
}

# 使用例
{
  user(id: "123") {
    ... on User {
      id
      email
    }
    ... on NotFoundError {
      message
      resourceType
    }
    ... on AuthorizationError {
      message
    }
  }
}
```

### ペイロードのエラー
```graphql
type CreateUserPayload {
  user: User
  errors: [Error!]
  success: Boolean!
}

type Error {
  field: String
  message: String!
  code: ErrorCode!
}

enum ErrorCode {
  VALIDATION_ERROR
  UNAUTHORIZED
  NOT_FOUND
  INTERNAL_ERROR
}
```

## N+1クエリ問題の解決

### DataLoaderパターン
```python
from aiodataloader import DataLoader

class PostLoader(DataLoader):
    async def batch_load_fn(self, post_ids):
        posts = await db.posts.find({"id": {"$in": post_ids}})
        post_map = {post["id"]: post for post in posts}
        return [post_map.get(pid) for pid in post_ids]

# リゾルバー
@user_type.field("posts")
async def resolve_posts(user, info):
    loader = info.context["loaders"]["post"]
    return await loader.load_many(user["post_ids"])
```

### クエリ深度制限
```python
from graphql import GraphQLError

def depth_limit_validator(max_depth: int):
    def validate(context, node, ancestors):
        depth = len(ancestors)
        if depth > max_depth:
            raise GraphQLError(
                f"Query depth {depth} exceeds maximum {max_depth}"
            )
    return validate
```

### クエリ複雑性分析
```python
def complexity_limit_validator(max_complexity: int):
    def calculate_complexity(node):
        # 各フィールド = 1、リストは乗算
        complexity = 1
        if is_list_field(node):
            complexity *= get_list_size_arg(node)
        return complexity

    return validate_complexity
```

## スキーマバージョニング

### フィールド非推奨
```graphql
type User {
  name: String! @deprecated(reason: "Use firstName and lastName")
  firstName: String!
  lastName: String!
}
```

### スキーマ進化
```graphql
# v1 - 初期
type User {
  name: String!
}

# v2 - オプションフィールド追加 (後方互換)
type User {
  name: String!
  email: String
}

# v3 - 非推奨と新フィールド追加
type User {
  name: String! @deprecated(reason: "Use firstName/lastName")
  firstName: String!
  lastName: String!
  email: String
}
```

## ベストプラクティスまとめ

1. **Nullable vs Non-Null**: nullableから始め、保証できる時にnon-nullにする
2. **入力型**: ミューテーションには常に入力型を使用
3. **Payloadパターン**: ミューテーションペイロードでエラーを返す
4. **ページネーション**: 無限スクロールにはカーソルベース、シンプルなケースにはオフセット
5. **命名**: フィールドにはcamelCase、型にはPascalCase
6. **非推奨**: フィールドを削除する代わりに`@deprecated`を使用
7. **DataLoader**: N+1を防ぐため常に関係に使用
8. **複雑性制限**: 高コストなクエリから保護
9. **カスタムスカラー**: ドメイン固有型に使用 (Email、DateTime)
10. **ドキュメント**: 説明ですべてのフィールドを文書化
