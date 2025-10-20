---
name: api-design-principles
description: 開発者を喜ばせる直感的でスケーラブルで保守可能なAPIを構築するために、RESTとGraphQL APIの設計原則をマスターします。新しいAPIの設計、API仕様のレビュー、またはAPI設計標準の確立時に使用してください。
---

> **[English](../../../../plugins/backend-development/skills/api-design-principles/SKILL.md)** | **日本語**

# API設計原則

開発者を喜ばせ、時間の試練に耐えるRESTとGraphQL APIの設計原則をマスターします。

## このスキルを使用するタイミング

- 新しいRESTまたはGraphQL APIの設計
- より良い使いやすさのための既存APIのリファクタリング
- チームのAPI設計標準の確立
- 実装前のAPI仕様のレビュー
- APIパラダイム間の移行(RESTからGraphQLなど)
- 開発者フレンドリーなAPIドキュメントの作成
- 特定のユースケース(モバイル、サードパーティ統合)のAPIの最適化

## コアコンセプト

### 1. RESTful設計原則

**リソース指向アーキテクチャ**
- リソースは動詞ではなく名詞(users、orders、products)
- アクションにはHTTPメソッドを使用(GET、POST、PUT、PATCH、DELETE)
- URLはリソース階層を表す
- 一貫した命名規則

**HTTPメソッドのセマンティクス:**
- `GET`: リソースの取得(冪等、安全)
- `POST`: 新しいリソースの作成
- `PUT`: リソース全体の置換(冪等)
- `PATCH`: リソースの部分更新
- `DELETE`: リソースの削除(冪等)

### 2. GraphQL設計原則

**スキーマファースト開発**
- 型がドメインモデルを定義
- データ読み取り用のクエリ
- データ変更用のミューテーション
- リアルタイム更新用のサブスクリプション

**クエリ構造:**
- クライアントは必要なものだけを正確にリクエスト
- 単一エンドポイント、複数操作
- 強く型付けされたスキーマ
- 組み込みイントロスペクション

### 3. APIバージョニング戦略

**URLバージョニング:**
```
/api/v1/users
/api/v2/users
```

**ヘッダーバージョニング:**
```
Accept: application/vnd.api+json; version=1
```

**クエリパラメータバージョニング:**
```
/api/users?version=1
```

## REST API設計パターン

### パターン1: リソースコレクション設計

```python
# 良い: リソース指向エンドポイント
GET    /api/users              # ユーザーリスト(ページネーション付き)
POST   /api/users              # ユーザー作成
GET    /api/users/{id}         # 特定のユーザーを取得
PUT    /api/users/{id}         # ユーザーを置換
PATCH  /api/users/{id}         # ユーザーフィールドを更新
DELETE /api/users/{id}         # ユーザーを削除

# ネストされたリソース
GET    /api/users/{id}/orders  # ユーザーの注文を取得
POST   /api/users/{id}/orders  # ユーザーの注文を作成

# 悪い: アクション指向エンドポイント(避ける)
POST   /api/createUser
POST   /api/getUserById
POST   /api/deleteUser
```

### パターン2: ページネーションとフィルタリング

```python
from typing import List, Optional
from pydantic import BaseModel, Field

class PaginationParams(BaseModel):
    page: int = Field(1, ge=1, description="Page number")
    page_size: int = Field(20, ge=1, le=100, description="Items per page")

class FilterParams(BaseModel):
    status: Optional[str] = None
    created_after: Optional[str] = None
    search: Optional[str] = None

class PaginatedResponse(BaseModel):
    items: List[dict]
    total: int
    page: int
    page_size: int
    pages: int

    @property
    def has_next(self) -> bool:
        return self.page < self.pages

    @property
    def has_prev(self) -> bool:
        return self.page > 1

# FastAPIエンドポイント例
from fastapi import FastAPI, Query, Depends

app = FastAPI()

@app.get("/api/users", response_model=PaginatedResponse)
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None)
):
    # フィルターを適用
    query = build_query(status=status, search=search)

    # 合計をカウント
    total = await count_users(query)

    # ページを取得
    offset = (page - 1) * page_size
    users = await fetch_users(query, limit=page_size, offset=offset)

    return PaginatedResponse(
        items=users,
        total=total,
        page=page,
        page_size=page_size,
        pages=(total + page_size - 1) // page_size
    )
```

### パターン3: エラー処理とステータスコード

```python
from fastapi import HTTPException, status
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    error: str
    message: str
    details: Optional[dict] = None
    timestamp: str
    path: str

class ValidationErrorDetail(BaseModel):
    field: str
    message: str
    value: Any

# 一貫したエラーレスポンス
STATUS_CODES = {
    "success": 200,
    "created": 201,
    "no_content": 204,
    "bad_request": 400,
    "unauthorized": 401,
    "forbidden": 403,
    "not_found": 404,
    "conflict": 409,
    "unprocessable": 422,
    "internal_error": 500
}

def raise_not_found(resource: str, id: str):
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail={
            "error": "NotFound",
            "message": f"{resource} not found",
            "details": {"id": id}
        }
    )

def raise_validation_error(errors: List[ValidationErrorDetail]):
    raise HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail={
            "error": "ValidationError",
            "message": "Request validation failed",
            "details": {"errors": [e.dict() for e in errors]}
        }
    )

# 使用例
@app.get("/api/users/{user_id}")
async def get_user(user_id: str):
    user = await fetch_user(user_id)
    if not user:
        raise_not_found("User", user_id)
    return user
```

### パターン4: HATEOAS (Hypermedia as the Engine of Application State)

```python
class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    _links: dict

    @classmethod
    def from_user(cls, user: User, base_url: str):
        return cls(
            id=user.id,
            name=user.name,
            email=user.email,
            _links={
                "self": {"href": f"{base_url}/api/users/{user.id}"},
                "orders": {"href": f"{base_url}/api/users/{user.id}/orders"},
                "update": {
                    "href": f"{base_url}/api/users/{user.id}",
                    "method": "PATCH"
                },
                "delete": {
                    "href": f"{base_url}/api/users/{user.id}",
                    "method": "DELETE"
                }
            }
        )
```

## GraphQL設計パターン

### パターン1: スキーマ設計

```graphql
# schema.graphql

# 明確な型定義
type User {
  id: ID!
  email: String!
  name: String!
  createdAt: DateTime!

  # リレーションシップ
  orders(
    first: Int = 20
    after: String
    status: OrderStatus
  ): OrderConnection!

  profile: UserProfile
}

type Order {
  id: ID!
  status: OrderStatus!
  total: Money!
  items: [OrderItem!]!
  createdAt: DateTime!

  # 逆参照
  user: User!
}

# ページネーションパターン (Relayスタイル)
type OrderConnection {
  edges: [OrderEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type OrderEdge {
  node: Order!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

# 型安全のための列挙型
enum OrderStatus {
  PENDING
  CONFIRMED
  SHIPPED
  DELIVERED
  CANCELLED
}

# カスタムスカラー
scalar DateTime
scalar Money

# クエリルート
type Query {
  user(id: ID!): User
  users(
    first: Int = 20
    after: String
    search: String
  ): UserConnection!

  order(id: ID!): Order
}

# ミューテーションルート
type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!

  createOrder(input: CreateOrderInput!): CreateOrderPayload!
}

# ミューテーション用の入力型
input CreateUserInput {
  email: String!
  name: String!
  password: String!
}

# ミューテーション用のペイロード型
type CreateUserPayload {
  user: User
  errors: [Error!]
}

type Error {
  field: String
  message: String!
}
```

### パターン2: リゾルバー設計

```python
from typing import Optional, List
from ariadne import QueryType, MutationType, ObjectType
from dataclasses import dataclass

query = QueryType()
mutation = MutationType()
user_type = ObjectType("User")

@query.field("user")
async def resolve_user(obj, info, id: str) -> Optional[dict]:
    """IDで単一ユーザーを解決。"""
    return await fetch_user_by_id(id)

@query.field("users")
async def resolve_users(
    obj,
    info,
    first: int = 20,
    after: Optional[str] = None,
    search: Optional[str] = None
) -> dict:
    """ページネーションされたユーザーリストを解決。"""
    # カーソルをデコード
    offset = decode_cursor(after) if after else 0

    # ユーザーを取得
    users = await fetch_users(
        limit=first + 1,  # hasNextPageをチェックするために1つ余分に取得
        offset=offset,
        search=search
    )

    # ページネーション
    has_next = len(users) > first
    if has_next:
        users = users[:first]

    edges = [
        {
            "node": user,
            "cursor": encode_cursor(offset + i)
        }
        for i, user in enumerate(users)
    ]

    return {
        "edges": edges,
        "pageInfo": {
            "hasNextPage": has_next,
            "hasPreviousPage": offset > 0,
            "startCursor": edges[0]["cursor"] if edges else None,
            "endCursor": edges[-1]["cursor"] if edges else None
        },
        "totalCount": await count_users(search=search)
    }

@user_type.field("orders")
async def resolve_user_orders(user: dict, info, first: int = 20) -> dict:
    """ユーザーの注文を解決 (DataLoaderでN+1防止)。"""
    # DataLoaderを使用してリクエストをバッチ処理
    loader = info.context["loaders"]["orders_by_user"]
    orders = await loader.load(user["id"])

    return paginate_orders(orders, first)

@mutation.field("createUser")
async def resolve_create_user(obj, info, input: dict) -> dict:
    """新しいユーザーを作成。"""
    try:
        # 入力を検証
        validate_user_input(input)

        # ユーザーを作成
        user = await create_user(
            email=input["email"],
            name=input["name"],
            password=hash_password(input["password"])
        )

        return {
            "user": user,
            "errors": []
        }
    except ValidationError as e:
        return {
            "user": None,
            "errors": [{"field": e.field, "message": e.message}]
        }
```

### パターン3: DataLoader (N+1問題防止)

```python
from aiodataloader import DataLoader
from typing import List, Optional

class UserLoader(DataLoader):
    """IDでユーザーをバッチロード。"""

    async def batch_load_fn(self, user_ids: List[str]) -> List[Optional[dict]]:
        """単一クエリで複数のユーザーをロード。"""
        users = await fetch_users_by_ids(user_ids)

        # 結果を入力順序にマップ
        user_map = {user["id"]: user for user in users}
        return [user_map.get(user_id) for user_id in user_ids]

class OrdersByUserLoader(DataLoader):
    """ユーザーIDで注文をバッチロード。"""

    async def batch_load_fn(self, user_ids: List[str]) -> List[List[dict]]:
        """単一クエリで複数ユーザーの注文をロード。"""
        orders = await fetch_orders_by_user_ids(user_ids)

        # user_idで注文をグループ化
        orders_by_user = {}
        for order in orders:
            user_id = order["user_id"]
            if user_id not in orders_by_user:
                orders_by_user[user_id] = []
            orders_by_user[user_id].append(order)

        # 入力順序で返す
        return [orders_by_user.get(user_id, []) for user_id in user_ids]

# コンテキストセットアップ
def create_context():
    return {
        "loaders": {
            "user": UserLoader(),
            "orders_by_user": OrdersByUserLoader()
        }
    }
```

## ベストプラクティス

### REST API
1. **一貫した命名**: コレクションには複数形の名詞を使用(`/users`、`/user`ではなく)
2. **ステートレス**: 各リクエストに必要なすべての情報を含める
3. **HTTPステータスコードを正しく使用**: 2xx成功、4xxクライアントエラー、5xxサーバーエラー
4. **APIをバージョン管理**: 最初から破壊的変更を計画
5. **ページネーション**: 大規模コレクションは常にページネーション
6. **レート制限**: レート制限でAPIを保護
7. **ドキュメント**: インタラクティブドキュメントにはOpenAPI/Swaggerを使用

### GraphQL API
1. **スキーマファースト**: リゾルバーを書く前にスキーマを設計
2. **N+1を避ける**: 効率的なデータ取得にはDataLoaderを使用
3. **入力検証**: スキーマとリゾルバーレベルで検証
4. **エラー処理**: ミューテーションペイロードで構造化されたエラーを返す
5. **ページネーション**: カーソルベースページネーションを使用(Relay仕様)
6. **非推奨**: 段階的移行には`@deprecated`ディレクティブを使用
7. **監視**: クエリ複雑性と実行時間を追跡

## 一般的な落とし穴

- **過剰取得/不足取得 (REST)**: GraphQLで修正されるがDataLoaderが必要
- **破壊的変更**: APIをバージョン管理するか、非推奨戦略を使用
- **一貫性のないエラー形式**: エラーレスポンスを標準化
- **レート制限の欠如**: 制限のないAPIは濫用に脆弱
- **貧弱なドキュメント**: 文書化されていないAPIは開発者を苛立たせる
- **HTTPセマンティクスの無視**: 冪等操作にPOSTを使用すると期待に反する
- **密結合**: API構造はデータベーススキーマを反映すべきでない

## リソース

- **references/rest-best-practices.md**: 包括的なREST API設計ガイド
- **references/graphql-schema-design.md**: GraphQLスキーマパターンとアンチパターン
- **references/api-versioning-strategies.md**: バージョニングアプローチと移行パス
- **assets/rest-api-template.py**: FastAPI REST APIテンプレート
- **assets/graphql-schema-template.graphql**: 完全なGraphQLスキーマ例
- **assets/api-design-checklist.md**: 実装前レビューチェックリスト
- **scripts/openapi-generator.py**: コードからOpenAPI仕様を生成
