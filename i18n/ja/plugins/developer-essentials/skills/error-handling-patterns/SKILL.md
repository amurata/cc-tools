---
name: error-handling-patterns
description: 例外、Result型、エラー伝播、グレースフルデグラデーションを含む、言語横断的なエラーハンドリングパターンをマスターし、回復力のあるアプリケーションを構築。エラーハンドリングの実装、APIの設計、アプリケーションの信頼性向上時に使用。
---

> **[English](../../../../../../plugins/developer-essentials/skills/error-handling-patterns/SKILL.md)** | **日本語**

# エラーハンドリングパターン

堅牢なエラーハンドリング戦略で、障害を適切に処理し、優れたデバッグ体験を提供する回復力のあるアプリケーションを構築します。

## このスキルを使用するタイミング

- 新機能でのエラーハンドリング実装
- エラー耐性のあるAPI設計
- 本番環境の問題デバッグ
- アプリケーション信頼性の向上
- ユーザーと開発者向けの優れたエラーメッセージ作成
- リトライとサーキットブレーカーパターンの実装
- 非同期/並行エラーの処理
- フォールトトレラントな分散システムの構築

## コア概念

### 1. エラーハンドリングの哲学

**例外 vs Result型：**
- **例外**：従来のtry-catch、制御フローを中断
- **Result型**：明示的な成功/失敗、関数型アプローチ
- **エラーコード**：C言語スタイル、規律が必要
- **Option/Maybe型**：null許容値用

**それぞれの使用タイミング：**
- 例外：予期しないエラー、例外的な状況
- Result型：予想されるエラー、検証失敗
- パニック/クラッシュ：回復不可能なエラー、プログラミングバグ

### 2. エラーカテゴリ

**回復可能なエラー：**
- ネットワークタイムアウト
- ファイルの欠落
- 無効なユーザー入力
- APIレート制限

**回復不可能なエラー：**
- メモリ不足
- スタックオーバーフロー
- プログラミングバグ（nullポインタなど）

## 言語固有のパターン

### Pythonエラーハンドリング

**カスタム例外階層：**
```python
class ApplicationError(Exception):
    """すべてのアプリケーションエラーの基底例外。"""
    def __init__(self, message: str, code: str = None, details: dict = None):
        super().__init__(message)
        self.code = code
        self.details = details or {}
        self.timestamp = datetime.utcnow()

class ValidationError(ApplicationError):
    """検証が失敗した時に発生。"""
    pass

class NotFoundError(ApplicationError):
    """リソースが見つからない時に発生。"""
    pass

class ExternalServiceError(ApplicationError):
    """外部サービスが失敗した時に発生。"""
    def __init__(self, message: str, service: str, **kwargs):
        super().__init__(message, **kwargs)
        self.service = service

# 使用例
def get_user(user_id: str) -> User:
    user = db.query(User).filter_by(id=user_id).first()
    if not user:
        raise NotFoundError(
            f\"ユーザーが見つかりません\",
            code=\"USER_NOT_FOUND\",
            details={\"user_id\": user_id}
        )
    return user
```

**クリーンアップ用のコンテキストマネージャー：**
```python
from contextlib import contextmanager

@contextmanager
def database_transaction(session):
    """トランザクションがコミットまたはロールバックされることを保証。"""
    try:
        yield session
        session.commit()
    except Exception as e:
        session.rollback()
        raise
    finally:
        session.close()

# 使用例
with database_transaction(db.session) as session:
    user = User(name=\"Alice\")
    session.add(user)
    # 自動コミットまたはロールバック
```

**指数バックオフ付きリトライ：**
```python
import time
from functools import wraps
from typing import TypeVar, Callable

T = TypeVar('T')

def retry(
    max_attempts: int = 3,
    backoff_factor: float = 2.0,
    exceptions: tuple = (Exception,)
):
    """指数バックオフ付きリトライデコレーター。"""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        def wrapper(*args, **kwargs) -> T:
            last_exception = None
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt < max_attempts - 1:
                        sleep_time = backoff_factor ** attempt
                        time.sleep(sleep_time)
                        continue
                    raise
            raise last_exception
        return wrapper
    return decorator

# 使用例
@retry(max_attempts=3, exceptions=(NetworkError,))
def fetch_data(url: str) -> dict:
    response = requests.get(url, timeout=5)
    response.raise_for_status()
    return response.json()
```

### TypeScript/JavaScriptエラーハンドリング

**カスタムエラークラス：**
```typescript
// カスタムエラークラス
class ApplicationError extends Error {
    constructor(
        message: string,
        public code: string,
        public statusCode: number = 500,
        public details?: Record<string, any>
    ) {
        super(message);
        this.name = this.constructor.name;
        Error.captureStackTrace(this, this.constructor);
    }
}

class ValidationError extends ApplicationError {
    constructor(message: string, details?: Record<string, any>) {
        super(message, 'VALIDATION_ERROR', 400, details);
    }
}

class NotFoundError extends ApplicationError {
    constructor(resource: string, id: string) {
        super(
            `${resource}が見つかりません`,
            'NOT_FOUND',
            404,
            { resource, id }
        );
    }
}

// 使用例
function getUser(id: string): User {
    const user = users.find(u => u.id === id);
    if (!user) {
        throw new NotFoundError('User', id);
    }
    return user;
}
```

**Result型パターン：**
```typescript
// 明示的なエラーハンドリング用のResult型
type Result<T, E = Error> =
    | { ok: true; value: T }
    | { ok: false; error: E };

// ヘルパー関数
function Ok<T>(value: T): Result<T, never> {
    return { ok: true, value };
}

function Err<E>(error: E): Result<never, E> {
    return { ok: false, error };
}

// 使用例
function parseJSON<T>(json: string): Result<T, SyntaxError> {
    try {
        const value = JSON.parse(json) as T;
        return Ok(value);
    } catch (error) {
        return Err(error as SyntaxError);
    }
}

// Resultの消費
const result = parseJSON<User>(userJson);
if (result.ok) {
    console.log(result.value.name);
} else {
    console.error('パース失敗:', result.error.message);
}

// Resultのチェイン
function chain<T, U, E>(
    result: Result<T, E>,
    fn: (value: T) => Result<U, E>
): Result<U, E> {
    return result.ok ? fn(result.value) : result;
}
```

**非同期エラーハンドリング：**
```typescript
// 適切なエラーハンドリング付きasync/await
async function fetchUserOrders(userId: string): Promise<Order[]> {
    try {
        const user = await getUser(userId);
        const orders = await getOrders(user.id);
        return orders;
    } catch (error) {
        if (error instanceof NotFoundError) {
            return [];  // 見つからない場合は空配列を返す
        }
        if (error instanceof NetworkError) {
            // リトライロジック
            return retryFetchOrders(userId);
        }
        // 予期しないエラーを再スロー
        throw error;
    }
}

// Promiseエラーハンドリング
function fetchData(url: string): Promise<Data> {
    return fetch(url)
        .then(response => {
            if (!response.ok) {
                throw new NetworkError(`HTTP ${response.status}`);
            }
            return response.json();
        })
        .catch(error => {
            console.error('フェッチ失敗:', error);
            throw error;
        });
}
```

### Rustエラーハンドリング

**ResultとOption型：**
```rust
use std::fs::File;
use std::io::{self, Read};

// 失敗する可能性のある操作用のResult型
fn read_file(path: &str) -> Result<String, io::Error> {
    let mut file = File::open(path)?;  // ?演算子でエラーを伝播
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}

// カスタムエラー型
#[derive(Debug)]
enum AppError {
    Io(io::Error),
    Parse(std::num::ParseIntError),
    NotFound(String),
    Validation(String),
}

impl From<io::Error> for AppError {
    fn from(error: io::Error) -> Self {
        AppError::Io(error)
    }
}

// カスタムエラー型の使用
fn read_number_from_file(path: &str) -> Result<i32, AppError> {
    let contents = read_file(path)?;  // io::Errorを自動変換
    let number = contents.trim().parse()
        .map_err(AppError::Parse)?;   // ParseIntErrorを明示的に変換
    Ok(number)
}

// null許容値用のOption
fn find_user(id: &str) -> Option<User> {
    users.iter().find(|u| u.id == id).cloned()
}

// OptionとResultの組み合わせ
fn get_user_age(id: &str) -> Result<u32, AppError> {
    find_user(id)
        .ok_or_else(|| AppError::NotFound(id.to_string()))
        .map(|user| user.age)
}
```

### Goエラーハンドリング

**明示的なエラー戻り値：**
```go
// 基本的なエラーハンドリング
func getUser(id string) (*User, error) {
    user, err := db.QueryUser(id)
    if err != nil {
        return nil, fmt.Errorf(\"ユーザークエリ失敗: %w\", err)
    }
    if user == nil {
        return nil, errors.New(\"ユーザーが見つかりません\")
    }
    return user, nil
}

// カスタムエラー型
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf(\"%sの検証失敗: %s\", e.Field, e.Message)
}

// 比較用のセンチネルエラー
var (
    ErrNotFound     = errors.New(\"見つかりません\")
    ErrUnauthorized = errors.New(\"権限がありません\")
    ErrInvalidInput = errors.New(\"無効な入力\")
)

// エラーチェック
user, err := getUser(\"123\")
if err != nil {
    if errors.Is(err, ErrNotFound) {
        // 見つからない場合の処理
    } else {
        // その他のエラー処理
    }
}

// エラーのラップとアンラップ
func processUser(id string) error {
    user, err := getUser(id)
    if err != nil {
        return fmt.Errorf(\"ユーザー処理失敗: %w\", err)
    }
    // ユーザーを処理
    return nil
}

// エラーのアンラップ
err := processUser(\"123\")
if err != nil {
    var valErr *ValidationError
    if errors.As(err, &valErr) {
        fmt.Printf(\"検証エラー: %s\\n\", valErr.Field)
    }
}
```

## 汎用パターン

### パターン1：サーキットブレーカー

分散システムでのカスケード障害を防止。

```python
from enum import Enum
from datetime import datetime, timedelta
from typing import Callable, TypeVar

T = TypeVar('T')

class CircuitState(Enum):
    CLOSED = \"closed\"       # 正常動作
    OPEN = \"open\"          # 失敗中、リクエストを拒否
    HALF_OPEN = \"half_open\"  # 回復したかテスト中

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        timeout: timedelta = timedelta(seconds=60),
        success_threshold: int = 2
    ):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.success_threshold = success_threshold
        self.failure_count = 0
        self.success_count = 0
        self.state = CircuitState.CLOSED
        self.last_failure_time = None

    def call(self, func: Callable[[], T]) -> T:
        if self.state == CircuitState.OPEN:
            if datetime.now() - self.last_failure_time > self.timeout:
                self.state = CircuitState.HALF_OPEN
                self.success_count = 0
            else:
                raise Exception(\"サーキットブレーカーがOPEN状態です\")

        try:
            result = func()
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise

    def on_success(self):
        self.failure_count = 0
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                self.state = CircuitState.CLOSED
                self.success_count = 0

    def on_failure(self):
        self.failure_count += 1
        self.last_failure_time = datetime.now()
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

# 使用例
circuit_breaker = CircuitBreaker()

def fetch_data():
    return circuit_breaker.call(lambda: external_api.get_data())
```

### パターン2：エラー集約

最初のエラーで失敗するのではなく、複数のエラーを収集。

```typescript
class ErrorCollector {
    private errors: Error[] = [];

    add(error: Error): void {
        this.errors.push(error);
    }

    hasErrors(): boolean {
        return this.errors.length > 0;
    }

    getErrors(): Error[] {
        return [...this.errors];
    }

    throw(): never {
        if (this.errors.length === 1) {
            throw this.errors[0];
        }
        throw new AggregateError(
            this.errors,
            `${this.errors.length}個のエラーが発生しました`
        );
    }
}

// 使用例：複数フィールドの検証
function validateUser(data: any): User {
    const errors = new ErrorCollector();

    if (!data.email) {
        errors.add(new ValidationError('メールアドレスは必須です'));
    } else if (!isValidEmail(data.email)) {
        errors.add(new ValidationError('メールアドレスが無効です'));
    }

    if (!data.name || data.name.length < 2) {
        errors.add(new ValidationError('名前は2文字以上である必要があります'));
    }

    if (!data.age || data.age < 18) {
        errors.add(new ValidationError('年齢は18歳以上である必要があります'));
    }

    if (errors.hasErrors()) {
        errors.throw();
    }

    return data as User;
}
```

### パターン3：グレースフルデグラデーション

エラー発生時にフォールバック機能を提供。

```python
from typing import Optional, Callable, TypeVar

T = TypeVar('T')

def with_fallback(
    primary: Callable[[], T],
    fallback: Callable[[], T],
    log_error: bool = True
) -> T:
    """プライマリ関数を試行し、エラー時はフォールバックに切り替え。"""
    try:
        return primary()
    except Exception as e:
        if log_error:
            logger.error(f\"プライマリ関数が失敗: {e}\")
        return fallback()

# 使用例
def get_user_profile(user_id: str) -> UserProfile:
    return with_fallback(
        primary=lambda: fetch_from_cache(user_id),
        fallback=lambda: fetch_from_database(user_id)
    )

# 複数のフォールバック
def get_exchange_rate(currency: str) -> float:
    return (
        try_function(lambda: api_provider_1.get_rate(currency))
        or try_function(lambda: api_provider_2.get_rate(currency))
        or try_function(lambda: cache.get_rate(currency))
        or DEFAULT_RATE
    )

def try_function(func: Callable[[], Optional[T]]) -> Optional[T]:
    try:
        return func()
    except Exception:
        return None
```

## ベストプラクティス

1. **フェイルファスト**：早期に入力を検証し、素早く失敗
2. **コンテキストを保持**：スタックトレース、メタデータ、タイムスタンプを含める
3. **意味のあるメッセージ**：何が起きたか、どう修正するかを説明
4. **適切にログ記録**：エラー = ログ、予想される失敗 = ログをスパムしない
5. **適切なレベルで処理**：意味のある処理ができる場所でキャッチ
6. **リソースをクリーンアップ**：try-finally、コンテキストマネージャー、deferを使用
7. **エラーを飲み込まない**：ログまたは再スロー、静かに無視しない
8. **型安全なエラー**：可能な限り型付きエラーを使用

```python
# 良いエラーハンドリングの例
def process_order(order_id: str) -> Order:
    """包括的なエラーハンドリング付きで注文を処理。"""
    try:
        # 入力を検証
        if not order_id:
            raise ValidationError(\"注文IDが必要です\")

        # 注文を取得
        order = db.get_order(order_id)
        if not order:
            raise NotFoundError(\"Order\", order_id)

        # 決済を処理
        try:
            payment_result = payment_service.charge(order.total)
        except PaymentServiceError as e:
            # 外部サービスエラーをログに記録してラップ
            logger.error(f\"注文{order_id}の決済失敗: {e}\")
            raise ExternalServiceError(
                f\"決済処理に失敗しました\",
                service=\"payment_service\",
                details={\"order_id\": order_id, \"amount\": order.total}
            ) from e

        # 注文を更新
        order.status = \"completed\"
        order.payment_id = payment_result.id
        db.save(order)

        return order

    except ApplicationError:
        # 既知のアプリケーションエラーを再スロー
        raise
    except Exception as e:
        # 予期しないエラーをログ
        logger.exception(f\"注文{order_id}の処理で予期しないエラー\")
        raise ApplicationError(
            \"注文処理に失敗しました\",
            code=\"INTERNAL_ERROR\"
        ) from e
```

## よくある落とし穴

- **広すぎるキャッチ**：`except Exception`はバグを隠す
- **空のキャッチブロック**：エラーを静かに飲み込む
- **ログと再スロー**：重複したログエントリを作成
- **クリーンアップしない**：ファイル、接続を閉じるのを忘れる
- **貧弱なエラーメッセージ**：「エラーが発生しました」は役に立たない
- **エラーコードを返す**：例外またはResult型を使用
- **非同期エラーを無視**：未処理のPromise拒否

## リソース

- **references/exception-hierarchy-design.md**：エラークラス階層の設計
- **references/error-recovery-strategies.md**：さまざまなシナリオの回復パターン
- **references/async-error-handling.md**：並行コードでのエラー処理
- **assets/error-handling-checklist.md**：エラーハンドリングのレビューチェックリスト
- **assets/error-message-guide.md**：役立つエラーメッセージの書き方
- **scripts/error-analyzer.py**：ログ内のエラーパターンを分析
