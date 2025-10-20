# REST APIベストプラクティス

## URL構造

### リソース命名
```
# 良い - 複数形の名詞
GET /api/users
GET /api/orders
GET /api/products

# 悪い - 動詞または混在した規則
GET /api/getUser
GET /api/user  (一貫性のない単数形)
POST /api/createOrder
```

### ネストされたリソース
```
# 浅いネスト (推奨)
GET /api/users/{id}/orders
GET /api/orders/{id}

# 深いネスト (避ける)
GET /api/users/{id}/orders/{orderId}/items/{itemId}/reviews
# より良い:
GET /api/order-items/{id}/reviews
```

## HTTPメソッドとステータスコード

### GET - リソースの取得
```
GET /api/users              → 200 OK (リスト付き)
GET /api/users/{id}         → 200 OK または 404 Not Found
GET /api/users?page=2       → 200 OK (ページネーション済み)
```

### POST - リソースの作成
```
POST /api/users
  Body: {"name": "John", "email": "john@example.com"}
  → 201 Created
  Location: /api/users/123
  Body: {"id": "123", "name": "John", ...}

POST /api/users (バリデーションエラー)
  → 422 Unprocessable Entity
  Body: {"errors": [...]}
```

### PUT - リソースの置換
```
PUT /api/users/{id}
  Body: {完全なユーザーオブジェクト}
  → 200 OK (更新済み)
  → 404 Not Found (存在しない)

# すべてのフィールドを含める必要がある
```

### PATCH - 部分更新
```
PATCH /api/users/{id}
  Body: {"name": "Jane"}  (変更されたフィールドのみ)
  → 200 OK
  → 404 Not Found
```

### DELETE - リソースの削除
```
DELETE /api/users/{id}
  → 204 No Content (削除済み)
  → 404 Not Found
  → 409 Conflict (参照により削除できない)
```

## フィルタリング、ソート、検索

### クエリパラメータ
```
# フィルタリング
GET /api/users?status=active
GET /api/users?role=admin&status=active

# ソート
GET /api/users?sort=created_at
GET /api/users?sort=-created_at  (降順)
GET /api/users?sort=name,created_at

# 検索
GET /api/users?search=john
GET /api/users?q=john

# フィールド選択 (スパースフィールドセット)
GET /api/users?fields=id,name,email
```

## ページネーションパターン

### オフセットベースページネーション
```python
GET /api/users?page=2&page_size=20

Response:
{
  "items": [...],
  "page": 2,
  "page_size": 20,
  "total": 150,
  "pages": 8
}
```

### カーソルベースページネーション (大規模データセット用)
```python
GET /api/users?limit=20&cursor=eyJpZCI6MTIzfQ

Response:
{
  "items": [...],
  "next_cursor": "eyJpZCI6MTQzfQ",
  "has_more": true
}
```

### Linkヘッダーページネーション (RESTful)
```
GET /api/users?page=2

Response Headers:
Link: <https://api.example.com/users?page=3>; rel="next",
      <https://api.example.com/users?page=1>; rel="prev",
      <https://api.example.com/users?page=1>; rel="first",
      <https://api.example.com/users?page=8>; rel="last"
```

## バージョニング戦略

### URLバージョニング (推奨)
```
/api/v1/users
/api/v2/users

利点: 明確、ルーティングが簡単
欠点: 同じリソースに複数のURL
```

### ヘッダーバージョニング
```
GET /api/users
Accept: application/vnd.api+json; version=2

利点: クリーンなURL
欠点: 可視性が低い、テストが難しい
```

### クエリパラメータ
```
GET /api/users?version=2

利点: テストが簡単
欠点: オプションパラメータが忘れられる可能性
```

## レート制限

### ヘッダー
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 742
X-RateLimit-Reset: 1640000000

制限時のレスポンス:
429 Too Many Requests
Retry-After: 3600
```

### 実装パターン
```python
from fastapi import HTTPException, Request
from datetime import datetime, timedelta

class RateLimiter:
    def __init__(self, calls: int, period: int):
        self.calls = calls
        self.period = period
        self.cache = {}

    def check(self, key: str) -> bool:
        now = datetime.now()
        if key not in self.cache:
            self.cache[key] = []

        # Remove old requests
        self.cache[key] = [
            ts for ts in self.cache[key]
            if now - ts < timedelta(seconds=self.period)
        ]

        if len(self.cache[key]) >= self.calls:
            return False

        self.cache[key].append(now)
        return True

limiter = RateLimiter(calls=100, period=60)

@app.get("/api/users")
async def get_users(request: Request):
    if not limiter.check(request.client.host):
        raise HTTPException(
            status_code=429,
            headers={"Retry-After": "60"}
        )
    return {"users": [...]}
```

## 認証と認可

### Bearerトークン
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

401 Unauthorized - トークンが欠落/無効
403 Forbidden - 有効なトークン、権限不足
```

### APIキー
```
X-API-Key: your-api-key-here
```

## エラーレスポンス形式

### 一貫した構造
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format",
        "value": "not-an-email"
      }
    ],
    "timestamp": "2025-10-16T12:00:00Z",
    "path": "/api/users"
  }
}
```

### ステータスコードガイドライン
- `200 OK`: 成功したGET、PATCH、PUT
- `201 Created`: 成功したPOST
- `204 No Content`: 成功したDELETE
- `400 Bad Request`: 不正な形式のリクエスト
- `401 Unauthorized`: 認証が必要
- `403 Forbidden`: 認証済みだが認可されていない
- `404 Not Found`: リソースが存在しない
- `409 Conflict`: 状態の競合(重複メールなど)
- `422 Unprocessable Entity`: バリデーションエラー
- `429 Too Many Requests`: レート制限
- `500 Internal Server Error`: サーバーエラー
- `503 Service Unavailable`: 一時的なダウンタイム

## キャッシング

### キャッシュヘッダー
```
# クライアントキャッシング
Cache-Control: public, max-age=3600

# キャッシングなし
Cache-Control: no-cache, no-store, must-revalidate

# 条件付きリクエスト
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
If-None-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"
→ 304 Not Modified
```

## バルク操作

### バッチエンドポイント
```python
POST /api/users/batch
{
  "items": [
    {"name": "User1", "email": "user1@example.com"},
    {"name": "User2", "email": "user2@example.com"}
  ]
}

Response:
{
  "results": [
    {"id": "1", "status": "created"},
    {"id": null, "status": "failed", "error": "Email already exists"}
  ]
}
```

## 冪等性

### 冪等性キー
```
POST /api/orders
Idempotency-Key: unique-key-123

重複リクエストの場合:
→ 200 OK (キャッシュされたレスポンスを返す)
```

## CORS設定

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://example.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## OpenAPIによるドキュメント

```python
from fastapi import FastAPI

app = FastAPI(
    title="My API",
    description="API for managing users",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

@app.get(
    "/api/users/{user_id}",
    summary="Get user by ID",
    response_description="User details",
    tags=["Users"]
)
async def get_user(
    user_id: str = Path(..., description="The user ID")
):
    """
    Retrieve user by ID.

    Returns full user profile including:
    - Basic information
    - Contact details
    - Account status
    """
    pass
```

## ヘルスと監視エンドポイント

```python
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health/detailed")
async def detailed_health():
    return {
        "status": "healthy",
        "checks": {
            "database": await check_database(),
            "redis": await check_redis(),
            "external_api": await check_external_api()
        }
    }
```
