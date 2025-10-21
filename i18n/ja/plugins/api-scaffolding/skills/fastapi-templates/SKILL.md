---
name: fastapi-templates
description: 非同期パターン、依存性注入、包括的なエラー処理を備えた本番環境対応のFastAPIプロジェクトを作成。新しいFastAPIアプリケーションの構築またはバックエンドAPIプロジェクトのセットアップ時に使用。
---

> **[English](../../../../../plugins/api-scaffolding/skills/fastapi-templates/SKILL.md)** | **日本語**

# FastAPIプロジェクトテンプレート

非同期パターン、依存性注入、ミドルウェア、高性能APIを構築するためのベストプラクティスを備えた本番環境対応のFastAPIプロジェクト構造。

## このスキルを使用する場面

- ゼロから新しいFastAPIプロジェクトを開始
- Pythonで非同期REST APIを実装
- 高性能Webサービスとマイクロサービスの構築
- PostgreSQL、MongoDBを使用した非同期アプリケーションの作成
- 適切な構造とテストを備えたAPIプロジェクトのセットアップ

## コアコンセプト

### 1. プロジェクト構造

**推奨レイアウト:**
```
app/
├── api/                    # APIルート
│   ├── v1/
│   │   ├── endpoints/
│   │   │   ├── users.py
│   │   │   ├── auth.py
│   │   │   └── items.py
│   │   └── router.py
│   └── dependencies.py     # 共有依存関係
├── core/                   # コア設定
│   ├── config.py
│   ├── security.py
│   └── database.py
├── models/                 # データベースモデル
│   ├── user.py
│   └── item.py
├── schemas/                # Pydanticスキーマ
│   ├── user.py
│   └── item.py
├── services/               # ビジネスロジック
│   ├── user_service.py
│   └── auth_service.py
├── repositories/           # データアクセス
│   ├── user_repository.py
│   └── item_repository.py
└── main.py                 # アプリケーションエントリー
```

### 2. 依存性注入

`Depends`を使用したFastAPIの組み込みDIシステム:
- データベースセッション管理
- 認証/認可
- 共有ビジネスロジック
- 設定注入

### 3. 非同期パターン

適切なasync/await使用:
- 非同期ルートハンドラー
- 非同期データベース操作
- 非同期バックグラウンドタスク
- 非同期ミドルウェア

## 実装パターン

### パターン 1: 完全なFastAPIアプリケーション

```python
# main.py
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    """アプリケーションライフスパンイベント。"""
    # スタートアップ
    await database.connect()
    yield
    # シャットダウン
    await database.disconnect()

app = FastAPI(
    title="API Template",
    version="1.0.0",
    lifespan=lifespan
)

# CORSミドルウェア
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ルーターを含める
from app.api.v1.router import api_router
app.include_router(api_router, prefix="/api/v1")

# core/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    """アプリケーション設定。"""
    DATABASE_URL: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    API_V1_STR: str = "/api/v1"

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    return Settings()

# core/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=True,
    future=True
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

Base = declarative_base()

async def get_db() -> AsyncSession:
    """データベースセッションの依存関係。"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

### パターン 2: CRUDリポジトリパターン

```python
# repositories/base_repository.py
from typing import Generic, TypeVar, Type, Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel

ModelType = TypeVar("ModelType")
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)

class BaseRepository(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    """CRUD操作の基本リポジトリ。"""

    def __init__(self, model: Type[ModelType]):
        self.model = model

    async def get(self, db: AsyncSession, id: int) -> Optional[ModelType]:
        """IDで取得。"""
        result = await db.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalars().first()

    async def get_multi(
        self,
        db: AsyncSession,
        skip: int = 0,
        limit: int = 100
    ) -> List[ModelType]:
        """複数レコードを取得。"""
        result = await db.execute(
            select(self.model).offset(skip).limit(limit)
        )
        return result.scalars().all()

    async def create(
        self,
        db: AsyncSession,
        obj_in: CreateSchemaType
    ) -> ModelType:
        """新しいレコードを作成。"""
        db_obj = self.model(**obj_in.dict())
        db.add(db_obj)
        await db.flush()
        await db.refresh(db_obj)
        return db_obj

    async def update(
        self,
        db: AsyncSession,
        db_obj: ModelType,
        obj_in: UpdateSchemaType
    ) -> ModelType:
        """レコードを更新。"""
        update_data = obj_in.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_obj, field, value)
        await db.flush()
        await db.refresh(db_obj)
        return db_obj

    async def delete(self, db: AsyncSession, id: int) -> bool:
        """レコードを削除。"""
        obj = await self.get(db, id)
        if obj:
            await db.delete(obj)
            return True
        return False

# repositories/user_repository.py
from app.repositories.base_repository import BaseRepository
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate

class UserRepository(BaseRepository[User, UserCreate, UserUpdate]):
    """ユーザー固有のリポジトリ。"""

    async def get_by_email(self, db: AsyncSession, email: str) -> Optional[User]:
        """メールアドレスでユーザーを取得。"""
        result = await db.execute(
            select(User).where(User.email == email)
        )
        return result.scalars().first()

    async def is_active(self, db: AsyncSession, user_id: int) -> bool:
        """ユーザーがアクティブかチェック。"""
        user = await self.get(db, user_id)
        return user.is_active if user else False

user_repository = UserRepository(User)
```

### パターン 3: サービス層

```python
# services/user_service.py
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.user_repository import user_repository
from app.schemas.user import UserCreate, UserUpdate, User
from app.core.security import get_password_hash, verify_password

class UserService:
    """ユーザーのビジネスロジック。"""

    def __init__(self):
        self.repository = user_repository

    async def create_user(
        self,
        db: AsyncSession,
        user_in: UserCreate
    ) -> User:
        """ハッシュ化されたパスワードで新しいユーザーを作成。"""
        # メールアドレスが存在するかチェック
        existing = await self.repository.get_by_email(db, user_in.email)
        if existing:
            raise ValueError("Email already registered")

        # パスワードをハッシュ化
        user_in_dict = user_in.dict()
        user_in_dict["hashed_password"] = get_password_hash(user_in_dict.pop("password"))

        # ユーザーを作成
        user = await self.repository.create(db, UserCreate(**user_in_dict))
        return user

    async def authenticate(
        self,
        db: AsyncSession,
        email: str,
        password: str
    ) -> Optional[User]:
        """ユーザーを認証。"""
        user = await self.repository.get_by_email(db, email)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    async def update_user(
        self,
        db: AsyncSession,
        user_id: int,
        user_in: UserUpdate
    ) -> Optional[User]:
        """ユーザーを更新。"""
        user = await self.repository.get(db, user_id)
        if not user:
            return None

        if user_in.password:
            user_in_dict = user_in.dict(exclude_unset=True)
            user_in_dict["hashed_password"] = get_password_hash(
                user_in_dict.pop("password")
            )
            user_in = UserUpdate(**user_in_dict)

        return await self.repository.update(db, user, user_in)

user_service = UserService()
```

### パターン 4: 依存関係を持つAPIエンドポイント

```python
# api/v1/endpoints/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.schemas.user import User, UserCreate, UserUpdate
from app.services.user_service import user_service
from app.api.dependencies import get_current_user

router = APIRouter()

@router.post("/", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """新しいユーザーを作成。"""
    try:
        user = await user_service.create_user(db, user_in)
        return user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/me", response_model=User)
async def read_current_user(
    current_user: User = Depends(get_current_user)
):
    """現在のユーザーを取得。"""
    return current_user

@router.get("/{user_id}", response_model=User)
async def read_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """IDでユーザーを取得。"""
    user = await user_service.repository.get(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.patch("/{user_id}", response_model=User)
async def update_user(
    user_id: int,
    user_in: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """ユーザーを更新。"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    user = await user_service.update_user(db, user_id, user_in)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """ユーザーを削除。"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    deleted = await user_service.repository.delete(db, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="User not found")
```

### パターン 5: 認証と認可

```python
# core/security.py
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import get_settings

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """JWTアクセストークンを作成。"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """パスワードをハッシュと照合。"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """パスワードをハッシュ化。"""
    return pwd_context.hash(password)

# api/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import ALGORITHM
from app.core.config import get_settings
from app.repositories.user_repository import user_repository

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

async def get_current_user(
    db: AsyncSession = Depends(get_db),
    token: str = Depends(oauth2_scheme)
):
    """現在の認証済みユーザーを取得。"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = await user_repository.get(db, user_id)
    if user is None:
        raise credentials_exception

    return user
```

## テスト

```python
# tests/conftest.py
import pytest
import asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import get_db, Base

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
async def db_session():
    engine = create_async_engine(TEST_DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    AsyncSessionLocal = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async with AsyncSessionLocal() as session:
        yield session

@pytest.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

# tests/test_users.py
import pytest

@pytest.mark.asyncio
async def test_create_user(client):
    response = await client.post(
        "/api/v1/users/",
        json={
            "email": "test@example.com",
            "password": "testpass123",
            "name": "Test User"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data
```

## リソース

- **references/fastapi-architecture.md**: 詳細なアーキテクチャガイド
- **references/async-best-practices.md**: Async/awaitパターン
- **references/testing-strategies.md**: 包括的テストガイド
- **assets/project-template/**: 完全なFastAPIプロジェクト
- **assets/docker-compose.yml**: 開発環境セットアップ

## ベストプラクティス

1. **完全非同期**: データベース、外部APIに非同期を使用
2. **依存性注入**: FastAPIのDIシステムを活用
3. **リポジトリパターン**: データアクセスをビジネスロジックから分離
4. **サービス層**: ビジネスロジックをルートの外に保つ
5. **Pydanticスキーマ**: リクエスト/レスポンスの強力な型付け
6. **エラー処理**: 一貫性のあるエラーレスポンス
7. **テスト**: すべての層を独立してテスト

## よくある落とし穴

- **非同期内でのブロッキングコード**: 同期データベースドライバーの使用
- **サービス層なし**: ルートハンドラー内のビジネスロジック
- **Type hintsの欠落**: FastAPIの利点を失う
- **セッション無視**: データベースセッションの適切な管理なし
- **テストなし**: 統合テストのスキップ
- **密結合**: ルート内での直接データベースアクセス
