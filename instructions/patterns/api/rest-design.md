# REST API Design Patterns

RESTful API設計のベストプラクティスとパターン。

## RESTful原則

### リソース指向設計
```
# リソースはURL、操作はHTTPメソッド
GET    /users          # ユーザー一覧
GET    /users/{id}     # 特定ユーザー取得
POST   /users          # ユーザー作成  
PUT    /users/{id}     # ユーザー更新（全体）
PATCH  /users/{id}     # ユーザー更新（部分）
DELETE /users/{id}     # ユーザー削除

# リレーション
GET    /users/{id}/posts       # ユーザーの投稿一覧
POST   /users/{id}/posts       # ユーザーの投稿作成
GET    /posts/{id}/comments    # 投稿のコメント一覧
```

### HTTPステータスコード
```typescript
// 成功レスポンス
200 OK              // 成功
201 Created         // リソース作成成功
202 Accepted        // 受付（非同期処理）
204 No Content      // 成功（レスポンスボディなし）

// リダイレクト
301 Moved Permanently
304 Not Modified    // キャッシュ有効

// クライアントエラー
400 Bad Request     // リクエスト不正
401 Unauthorized    // 認証必要
403 Forbidden       // 権限なし
404 Not Found       // リソースなし
409 Conflict        // 競合
422 Unprocessable Entity // バリデーションエラー
429 Too Many Requests    // レート制限

// サーバーエラー
500 Internal Server Error
502 Bad Gateway
503 Service Unavailable
504 Gateway Timeout
```

## APIバージョニング

### URLパスバージョニング
```typescript
// Express実装
app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);

// バージョン別ルーティング
const v1Routes = Router();
v1Routes.get('/users', UsersControllerV1.list);

const v2Routes = Router();
v2Routes.get('/users', UsersControllerV2.list); // 改良版
```

### ヘッダーバージョニング
```typescript
app.use((req, res, next) => {
  const version = req.headers['api-version'] || 'v1';
  req.apiVersion = version;
  next();
});

app.get('/api/users', (req, res) => {
  switch (req.apiVersion) {
    case 'v2':
      return UsersControllerV2.list(req, res);
    default:
      return UsersControllerV1.list(req, res);
  }
});
```

## レスポンス設計

### 一貫性のあるレスポンス構造
```typescript
// 成功レスポンス
interface SuccessResponse<T> {
  success: true;
  data: T;
  meta?: {
    timestamp: string;
    version: string;
  };
}

// エラーレスポンス
interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: any;
  };
  meta?: {
    timestamp: string;
    request_id: string;
  };
}

// 実装例
class APIResponse {
  static success<T>(data: T, meta?: any): SuccessResponse<T> {
    return {
      success: true,
      data,
      meta: {
        timestamp: new Date().toISOString(),
        version: 'v1',
        ...meta
      }
    };
  }
  
  static error(
    code: string,
    message: string,
    statusCode: number,
    details?: any
  ): ErrorResponse {
    return {
      success: false,
      error: {
        code,
        message,
        details
      },
      meta: {
        timestamp: new Date().toISOString(),
        request_id: generateRequestId()
      }
    };
  }
}
```

### ページネーション
```typescript
// Offset-based
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  links: {
    first: string;
    prev: string | null;
    next: string | null;
    last: string;
  };
}

// Cursor-based
interface CursorPaginatedResponse<T> {
  data: T[];
  pagination: {
    hasMore: boolean;
    cursor: string | null;
  };
  links: {
    next: string | null;
  };
}

// 実装
app.get('/api/users', async (req, res) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = parseInt(req.query.limit as string) || 20;
  const offset = (page - 1) * limit;
  
  const [users, total] = await Promise.all([
    db.user.findMany({ skip: offset, take: limit }),
    db.user.count()
  ]);
  
  const totalPages = Math.ceil(total / limit);
  
  res.json({
    data: users,
    pagination: {
      page,
      limit,
      total,
      totalPages
    },
    links: {
      first: `/api/users?page=1&limit=${limit}`,
      prev: page > 1 ? `/api/users?page=${page - 1}&limit=${limit}` : null,
      next: page < totalPages ? `/api/users?page=${page + 1}&limit=${limit}` : null,
      last: `/api/users?page=${totalPages}&limit=${limit}`
    }
  });
});
```

## フィルタリングとソート

### クエリパラメータ設計
```typescript
// フィルタリング
GET /api/products?category=electronics&minPrice=100&maxPrice=500

// ソート
GET /api/products?sort=price,-rating  // 価格昇順、評価降順

// フィールド選択
GET /api/users?fields=id,name,email

// 検索
GET /api/products?q=laptop&category=electronics

// 実装
interface QueryParams {
  filters?: Record<string, any>;
  sort?: string;
  fields?: string;
  q?: string;
  page?: number;
  limit?: number;
}

class QueryBuilder {
  private query: any = {};
  private options: any = {};
  
  filter(filters: Record<string, any>): this {
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined) {
        // 範囲検索
        if (key.startsWith('min')) {
          const field = key.replace('min', '').toLowerCase();
          this.query[field] = { ...this.query[field], gte: value };
        } else if (key.startsWith('max')) {
          const field = key.replace('max', '').toLowerCase();
          this.query[field] = { ...this.query[field], lte: value };
        } else {
          this.query[key] = value;
        }
      }
    });
    return this;
  }
  
  sort(sortString: string): this {
    const sortFields = sortString.split(',');
    const orderBy = sortFields.map(field => {
      const isDesc = field.startsWith('-');
      const fieldName = isDesc ? field.slice(1) : field;
      return { [fieldName]: isDesc ? 'desc' : 'asc' };
    });
    this.options.orderBy = orderBy;
    return this;
  }
  
  select(fields: string): this {
    const select = fields.split(',').reduce((acc, field) => {
      acc[field] = true;
      return acc;
    }, {});
    this.options.select = select;
    return this;
  }
  
  paginate(page: number, limit: number): this {
    this.options.skip = (page - 1) * limit;
    this.options.take = limit;
    return this;
  }
  
  build() {
    return { where: this.query, ...this.options };
  }
}
```

## エラーハンドリング

### 構造化エラーレスポンス
```typescript
enum ErrorCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  INTERNAL_ERROR = 'INTERNAL_ERROR'
}

class APIError extends Error {
  constructor(
    public code: ErrorCode,
    public message: string,
    public statusCode: number,
    public details?: any
  ) {
    super(message);
  }
  
  toJSON() {
    return {
      error: {
        code: this.code,
        message: this.message,
        details: this.details
      }
    };
  }
}

// バリデーションエラー
app.post('/api/users', async (req, res, next) => {
  try {
    const validation = await validateUser(req.body);
    if (!validation.valid) {
      throw new APIError(
        ErrorCode.VALIDATION_ERROR,
        'Validation failed',
        422,
        validation.errors
      );
    }
    // ...
  } catch (error) {
    next(error);
  }
});

// グローバルエラーハンドラー
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof APIError) {
    return res.status(err.statusCode).json(err.toJSON());
  }
  
  // 予期しないエラー
  console.error(err);
  res.status(500).json({
    error: {
      code: ErrorCode.INTERNAL_ERROR,
      message: 'An unexpected error occurred'
    }
  });
});
```

## HATEOAS（Hypermedia）

### リンク付きレスポンス
```typescript
interface ResourceWithLinks<T> {
  data: T;
  _links: {
    self: string;
    [key: string]: string;
  };
}

// ユーザーリソース with HATEOAS
app.get('/api/users/:id', async (req, res) => {
  const user = await db.user.findUnique({
    where: { id: req.params.id }
  });
  
  res.json({
    data: user,
    _links: {
      self: `/api/users/${user.id}`,
      posts: `/api/users/${user.id}/posts`,
      followers: `/api/users/${user.id}/followers`,
      following: `/api/users/${user.id}/following`,
      update: {
        href: `/api/users/${user.id}`,
        method: 'PUT'
      },
      delete: {
        href: `/api/users/${user.id}`,
        method: 'DELETE'
      }
    }
  });
});
```

## 非同期処理

### Long-running Operations
```typescript
// 非同期ジョブの開始
app.post('/api/reports/generate', async (req, res) => {
  const jobId = generateJobId();
  
  // ジョブをキューに追加
  await queue.add('generate-report', {
    jobId,
    params: req.body
  });
  
  // 202 Accepted with Location header
  res.status(202)
    .location(`/api/jobs/${jobId}`)
    .json({
      jobId,
      status: 'pending',
      _links: {
        self: `/api/jobs/${jobId}`,
        cancel: `/api/jobs/${jobId}/cancel`
      }
    });
});

// ジョブステータス確認
app.get('/api/jobs/:id', async (req, res) => {
  const job = await getJob(req.params.id);
  
  if (job.status === 'completed') {
    res.json({
      jobId: job.id,
      status: 'completed',
      result: job.result,
      _links: {
        result: `/api/reports/${job.resultId}`
      }
    });
  } else if (job.status === 'failed') {
    res.status(500).json({
      jobId: job.id,
      status: 'failed',
      error: job.error
    });
  } else {
    res.json({
      jobId: job.id,
      status: job.status,
      progress: job.progress
    });
  }
});
```

## API Documentation

### OpenAPI/Swagger
```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - in: query
          name: page
          schema:
            type: integer
            default: 1
        - in: query
          name: limit
          schema:
            type: integer
            default: 20
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
```

## チェックリスト
- [ ] RESTful原則準拠
- [ ] 適切なHTTPステータスコード
- [ ] バージョニング戦略
- [ ] 一貫性のあるレスポンス構造
- [ ] ページネーション実装
- [ ] フィルタリング・ソート機能
- [ ] 構造化エラーハンドリング
- [ ] HATEOAS考慮
- [ ] 非同期処理パターン
- [ ] API文書化