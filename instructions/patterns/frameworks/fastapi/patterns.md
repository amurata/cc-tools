# FastAPI パターン

高性能な非同期APIのためのFastAPIパターン。

## 基本構造

### アプリケーション構成
```python
from fastapi import FastAPI, Depends
from pydantic import BaseModel

app = FastAPI(
    title="API Service",
    version="1.0.0",
    docs_url="/api/docs"
)

# Pydanticモデル
class UserCreate(BaseModel):
    email: str
    name: str

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    
    class Config:
        from_attributes = True

# エンドポイント
@app.post("/users", response_model=UserResponse)
async def create_user(user: UserCreate):
    return await user_service.create(user)
```

## 依存性注入

### データベース接続
```python
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

# 使用
@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    return await user_repository.get(db, user_id)
```

### 認証
```python
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    token = credentials.credentials
    user = await verify_token(token)
    if not user:
        raise HTTPException(status_code=401)
    return user

# 保護されたエンドポイント
@app.get("/profile")
async def get_profile(user: User = Depends(get_current_user)):
    return user
```

## エラーハンドリング

### カスタム例外
```python
from fastapi import HTTPException

class UserNotFound(HTTPException):
    def __init__(self, user_id: int):
        super().__init__(
            status_code=404,
            detail=f"User {user_id} not found"
        )

# 例外ハンドラー
@app.exception_handler(ValueError)
async def value_error_handler(request, exc):
    return JSONResponse(
        status_code=400,
        content={"detail": str(exc)}
    )
```

## バリデーション

### Pydanticバリデーター
```python
from pydantic import validator, EmailStr
from typing import Optional

class UserModel(BaseModel):
    email: EmailStr
    age: int
    phone: Optional[str] = None
    
    @validator('age')
    def age_must_be_positive(cls, v):
        if v < 0:
            raise ValueError('Age must be positive')
        return v
    
    @validator('phone')
    def phone_validation(cls, v):
        if v and not v.startswith('+'):
            raise ValueError('Phone must start with +')
        return v
```

## 非同期処理

### バックグラウンドタスク
```python
from fastapi import BackgroundTasks

async def send_email(email: str, message: str):
    # メール送信処理
    await email_service.send(email, message)

@app.post("/notify")
async def notify_user(
    email: str,
    background_tasks: BackgroundTasks
):
    background_tasks.add_task(send_email, email, "Welcome!")
    return {"message": "Notification queued"}
```

### 並行処理
```python
import asyncio

@app.get("/aggregate")
async def get_aggregated_data():
    # 並行実行
    results = await asyncio.gather(
        fetch_users(),
        fetch_orders(),
        fetch_products()
    )
    return {
        "users": results[0],
        "orders": results[1],
        "products": results[2]
    }
```

## ミドルウェア

### CORS設定
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

### カスタムミドルウェア
```python
@app.middleware("http")
async def add_process_time(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response
```

## テスト

### 非同期テスト
```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_user():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/users",
            json={"email": "test@example.com", "name": "Test"}
        )
        assert response.status_code == 201
        assert response.json()["email"] == "test@example.com"
```

## チェックリスト
- [ ] Pydanticモデル定義
- [ ] 依存性注入活用
- [ ] 適切なエラーハンドリング
- [ ] バリデーション実装
- [ ] 非同期処理最適化
- [ ] ミドルウェア設定
- [ ] テスト作成