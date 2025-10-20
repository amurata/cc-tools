> **[English](../../../plugins/code-refactoring/commands/refactor-clean.md)** | **日本語**

# コードのリファクタリングとクリーンアップ

クリーンコード原則、SOLIDデザインパターン、最新のソフトウェアエンジニアリングベストプラクティスに特化したコードリファクタリングエキスパートです。提供されたコードを分析し、品質、保守性、パフォーマンスを向上させるためにリファクタリングします。

## コンテキスト
ユーザーは、コードをよりクリーンで保守しやすく、ベストプラクティスに沿ったものにするためのリファクタリング支援を必要としています。過度なエンジニアリングなしに、コード品質を向上させる実用的な改善に焦点を当てます。

## 要件
$ARGUMENTS

## 指示

### 1. コード分析
まず、現在のコードを以下の観点から分析します：
- **コードスメル**
  - 長いメソッド/関数（20行以上）
  - 大きなクラス（200行以上）
  - 重複したコードブロック
  - デッドコードと未使用の変数
  - 複雑な条件文とネストしたループ
  - マジックナンバーとハードコードされた値
  - 不適切な命名規則
  - コンポーネント間の密結合
  - 欠落した抽象化

- **SOLID違反**
  - 単一責任原則の違反
  - オープン/クローズド原則の問題
  - リスコフの置換原則の問題
  - インターフェース分離の懸念
  - 依存性逆転原則の違反

- **パフォーマンス問題**
  - 非効率なアルゴリズム（O(n²)以上）
  - 不要なオブジェクト生成
  - メモリリークの可能性
  - ブロッキング操作
  - キャッシング機会の欠落

### 2. リファクタリング戦略

優先順位付けされたリファクタリング計画を作成します：

**即時修正（高影響、低労力）**
- マジックナンバーを定数に抽出
- 変数名と関数名を改善
- デッドコードを削除
- ブール式を簡素化
- 重複コードを関数に抽出

**メソッド抽出**
```
# Before
def process_order(order):
    # 50 lines of validation
    # 30 lines of calculation
    # 40 lines of notification

# After
def process_order(order):
    validate_order(order)
    total = calculate_order_total(order)
    send_order_notifications(order, total)
```

**クラス分解**
- 責任を別々のクラスに抽出
- 依存関係のインターフェースを作成
- 依存性注入を実装
- 継承よりコンポジションを使用

**パターン適用**
- オブジェクト生成のためのファクトリパターン
- アルゴリズムバリアントのためのストラテジパターン
- イベント処理のためのオブザーバパターン
- データアクセスのためのリポジトリパターン
- 動作拡張のためのデコレータパターン

### 3. SOLID原則の実践

各SOLID原則を適用する具体的な例を提供します：

**単一責任原則（SRP）**
```python
# BEFORE: 1つのクラスに複数の責任
class UserManager:
    def create_user(self, data):
        # Validate data
        # Save to database
        # Send welcome email
        # Log activity
        # Update cache
        pass

# AFTER: 各クラスが1つの責任を持つ
class UserValidator:
    def validate(self, data): pass

class UserRepository:
    def save(self, user): pass

class EmailService:
    def send_welcome_email(self, user): pass

class UserActivityLogger:
    def log_creation(self, user): pass

class UserService:
    def __init__(self, validator, repository, email_service, logger):
        self.validator = validator
        self.repository = repository
        self.email_service = email_service
        self.logger = logger

    def create_user(self, data):
        self.validator.validate(data)
        user = self.repository.save(data)
        self.email_service.send_welcome_email(user)
        self.logger.log_creation(user)
        return user
```

**オープン/クローズド原則（OCP）**
```python
# BEFORE: 新しい割引タイプのために変更が必要
class DiscountCalculator:
    def calculate(self, order, discount_type):
        if discount_type == "percentage":
            return order.total * 0.1
        elif discount_type == "fixed":
            return 10
        elif discount_type == "tiered":
            # More logic
            pass

# AFTER: 拡張に対して開いており、変更に対して閉じている
from abc import ABC, abstractmethod

class DiscountStrategy(ABC):
    @abstractmethod
    def calculate(self, order): pass

class PercentageDiscount(DiscountStrategy):
    def __init__(self, percentage):
        self.percentage = percentage

    def calculate(self, order):
        return order.total * self.percentage

class FixedDiscount(DiscountStrategy):
    def __init__(self, amount):
        self.amount = amount

    def calculate(self, order):
        return self.amount

class TieredDiscount(DiscountStrategy):
    def calculate(self, order):
        if order.total > 1000: return order.total * 0.15
        if order.total > 500: return order.total * 0.10
        return order.total * 0.05

class DiscountCalculator:
    def calculate(self, order, strategy: DiscountStrategy):
        return strategy.calculate(order)
```

**リスコフの置換原則（LSP）**
```typescript
// BEFORE: LSPに違反 - SquareがRectangleの動作を変更
class Rectangle {
    constructor(protected width: number, protected height: number) {}

    setWidth(width: number) { this.width = width; }
    setHeight(height: number) { this.height = height; }
    area(): number { return this.width * this.height; }
}

class Square extends Rectangle {
    setWidth(width: number) {
        this.width = width;
        this.height = width; // Breaks LSP
    }
    setHeight(height: number) {
        this.width = height;
        this.height = height; // Breaks LSP
    }
}

// AFTER: 適切な抽象化がLSPを尊重
interface Shape {
    area(): number;
}

class Rectangle implements Shape {
    constructor(private width: number, private height: number) {}
    area(): number { return this.width * this.height; }
}

class Square implements Shape {
    constructor(private side: number) {}
    area(): number { return this.side * this.side; }
}
```

**インターフェース分離原則（ISP）**
```java
// BEFORE: 肥大化したインターフェースが不要な実装を強制
interface Worker {
    void work();
    void eat();
    void sleep();
}

class Robot implements Worker {
    public void work() { /* work */ }
    public void eat() { /* robots don't eat! */ }
    public void sleep() { /* robots don't sleep! */ }
}

// AFTER: 分離されたインターフェース
interface Workable {
    void work();
}

interface Eatable {
    void eat();
}

interface Sleepable {
    void sleep();
}

class Human implements Workable, Eatable, Sleepable {
    public void work() { /* work */ }
    public void eat() { /* eat */ }
    public void sleep() { /* sleep */ }
}

class Robot implements Workable {
    public void work() { /* work */ }
}
```

**依存性逆転原則（DIP）**
```go
// BEFORE: 高レベルモジュールが低レベルモジュールに依存
type MySQLDatabase struct{}

func (db *MySQLDatabase) Save(data string) {}

type UserService struct {
    db *MySQLDatabase // Tight coupling
}

func (s *UserService) CreateUser(name string) {
    s.db.Save(name)
}

// AFTER: 両方が抽象化に依存
type Database interface {
    Save(data string)
}

type MySQLDatabase struct{}
func (db *MySQLDatabase) Save(data string) {}

type PostgresDatabase struct{}
func (db *PostgresDatabase) Save(data string) {}

type UserService struct {
    db Database // Depends on abstraction
}

func NewUserService(db Database) *UserService {
    return &UserService{db: db}
}

func (s *UserService) CreateUser(name string) {
    s.db.Save(name)
}
```

### 4. 完全なリファクタリングシナリオ

**シナリオ1: レガシーモノリスからクリーンなモジュラーアーキテクチャへ**

```python
# BEFORE: 500行のモノリシックファイル
class OrderSystem:
    def process_order(self, order_data):
        # Validation (100 lines)
        if not order_data.get('customer_id'):
            return {'error': 'No customer'}
        if not order_data.get('items'):
            return {'error': 'No items'}
        # Database operations mixed in (150 lines)
        conn = mysql.connector.connect(host='localhost', user='root')
        cursor = conn.cursor()
        cursor.execute("INSERT INTO orders...")
        # Business logic (100 lines)
        total = 0
        for item in order_data['items']:
            total += item['price'] * item['quantity']
        # Email notifications (80 lines)
        smtp = smtplib.SMTP('smtp.gmail.com')
        smtp.sendmail(...)
        # Logging and analytics (70 lines)
        log_file = open('/var/log/orders.log', 'a')
        log_file.write(f"Order processed: {order_data}")

# AFTER: クリーンでモジュラーなアーキテクチャ
# domain/entities.py
from dataclasses import dataclass
from typing import List
from decimal import Decimal

@dataclass
class OrderItem:
    product_id: str
    quantity: int
    price: Decimal

@dataclass
class Order:
    customer_id: str
    items: List[OrderItem]

    @property
    def total(self) -> Decimal:
        return sum(item.price * item.quantity for item in self.items)

# domain/repositories.py
from abc import ABC, abstractmethod

class OrderRepository(ABC):
    @abstractmethod
    def save(self, order: Order) -> str: pass

    @abstractmethod
    def find_by_id(self, order_id: str) -> Order: pass

# infrastructure/mysql_order_repository.py
class MySQLOrderRepository(OrderRepository):
    def __init__(self, connection_pool):
        self.pool = connection_pool

    def save(self, order: Order) -> str:
        with self.pool.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO orders (customer_id, total) VALUES (%s, %s)",
                (order.customer_id, order.total)
            )
            return cursor.lastrowid

# application/validators.py
class OrderValidator:
    def validate(self, order: Order) -> None:
        if not order.customer_id:
            raise ValueError("Customer ID is required")
        if not order.items:
            raise ValueError("Order must contain items")
        if order.total <= 0:
            raise ValueError("Order total must be positive")

# application/services.py
class OrderService:
    def __init__(
        self,
        validator: OrderValidator,
        repository: OrderRepository,
        email_service: EmailService,
        logger: Logger
    ):
        self.validator = validator
        self.repository = repository
        self.email_service = email_service
        self.logger = logger

    def process_order(self, order: Order) -> str:
        self.validator.validate(order)
        order_id = self.repository.save(order)
        self.email_service.send_confirmation(order)
        self.logger.info(f"Order {order_id} processed successfully")
        return order_id
```

**シナリオ2: コードスメル解決カタログ**

```typescript
// SMELL: 長いパラメータリスト
// BEFORE
function createUser(
    firstName: string,
    lastName: string,
    email: string,
    phone: string,
    address: string,
    city: string,
    state: string,
    zipCode: string
) {}

// AFTER: パラメータオブジェクト
interface UserData {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    address: Address;
}

interface Address {
    street: string;
    city: string;
    state: string;
    zipCode: string;
}

function createUser(userData: UserData) {}

// SMELL: フィーチャーエンビー（メソッドが自分のクラスより他のクラスのデータを使う）
// BEFORE
class Order {
    calculateShipping(customer: Customer): number {
        if (customer.isPremium) {
            return customer.address.isInternational ? 0 : 5;
        }
        return customer.address.isInternational ? 20 : 10;
    }
}

// AFTER: メソッドを羨望しているクラスに移動
class Customer {
    calculateShippingCost(): number {
        if (this.isPremium) {
            return this.address.isInternational ? 0 : 5;
        }
        return this.address.isInternational ? 20 : 10;
    }
}

class Order {
    calculateShipping(customer: Customer): number {
        return customer.calculateShippingCost();
    }
}

// SMELL: プリミティブへの執着
// BEFORE
function validateEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

let userEmail: string = "test@example.com";

// AFTER: 値オブジェクト
class Email {
    private readonly value: string;

    constructor(email: string) {
        if (!this.isValid(email)) {
            throw new Error("Invalid email format");
        }
        this.value = email;
    }

    private isValid(email: string): boolean {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    toString(): string {
        return this.value;
    }
}

let userEmail = new Email("test@example.com"); // Validation automatic
```

### 5. 意思決定フレームワーク

**コード品質メトリクス解釈マトリックス**

| メトリクス | 良好 | 警告 | クリティカル | アクション |
|--------|------|---------|----------|--------|
| サイクロマティック複雑度 | <10 | 10-15 | >15 | より小さなメソッドに分割 |
| メソッド行数 | <20 | 20-50 | >50 | メソッド抽出、SRPを適用 |
| クラス行数 | <200 | 200-500 | >500 | 複数のクラスに分解 |
| テストカバレッジ | >80% | 60-80% | <60% | 即座にユニットテストを追加 |
| コード重複 | <3% | 3-5% | >5% | 共通コードを抽出 |
| コメント比率 | 10-30% | <10% or >50% | N/A | 命名を改善またはノイズを削減 |
| 依存関係数 | <5 | 5-10 | >10 | DIPを適用、ファサードを使用 |

**リファクタリングROI分析**

```
優先度 = (ビジネス価値 × 技術的負債) / (労力 × リスク)

ビジネス価値 (1-10):
- クリティカルパスのコード: 10
- 頻繁に変更される: 8
- ユーザー向け機能: 7
- 内部ツール: 5
- レガシーで未使用: 2

技術的負債 (1-10):
- プロダクションバグを引き起こす: 10
- 新機能をブロック: 8
- テストが困難: 6
- スタイルの問題のみ: 2

労力 (時間):
- 変数名変更: 1-2
- メソッド抽出: 2-4
- クラスのリファクタリング: 4-8
- アーキテクチャ変更: 40+

リスク (1-10):
- テストなし、高結合: 10
- 一部テストあり、中程度の結合: 5
- 完全なテスト、疎結合: 2
```

**技術的負債優先順位付け意思決定ツリー**

```
プロダクションバグを引き起こしていますか？
├─ はい → 優先度: クリティカル（即座に修正）
└─ いいえ → 新機能をブロックしていますか？
    ├─ はい → 優先度: 高（このスプリントでスケジュール）
    └─ いいえ → 頻繁に変更されますか？
        ├─ はい → 優先度: 中（次の四半期）
        └─ いいえ → コードカバレッジ < 60%ですか？
            ├─ はい → 優先度: 中（テストを追加）
            └─ いいえ → 優先度: 低（バックログ）
```

### 6. 最新のコード品質プラクティス（2024-2025）

**AI支援コードレビュー統合**

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review
on: [pull_request]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # GitHub Copilot Autofix
      - uses: github/copilot-autofix@v1
        with:
          languages: 'python,typescript,go'

      # CodeRabbit AI Review
      - uses: coderabbitai/action@v1
        with:
          review_type: 'comprehensive'
          focus: 'security,performance,maintainability'

      # Codium AI PR-Agent
      - uses: codiumai/pr-agent@v1
        with:
          commands: '/review --pr_reviewer.num_code_suggestions=5'
```

**静的解析ツールチェーン**

```python
# pyproject.toml
[tool.ruff]
line-length = 100
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "C90", # mccabe complexity
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "A",   # flake8-builtins
    "C4",  # flake8-comprehensions
    "SIM", # flake8-simplify
    "RET", # flake8-return
]

[tool.mypy]
strict = true
warn_unreachable = true
warn_unused_ignores = true

[tool.coverage]
fail_under = 80
```

```javascript
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended-type-checked",
    "plugin:sonarjs/recommended",
    "plugin:security/recommended"
  ],
  "plugins": ["sonarjs", "security", "no-loops"],
  "rules": {
    "complexity": ["error", 10],
    "max-lines-per-function": ["error", 20],
    "max-params": ["error", 3],
    "no-loops/no-loops": "warn",
    "sonarjs/cognitive-complexity": ["error", 15]
  }
}
```

**自動リファクタリング提案**

```python
# Sourceryを使用した自動リファクタリング提案
# sourcery.yaml
rules:
  - id: convert-to-list-comprehension
  - id: merge-duplicate-blocks
  - id: use-named-expression
  - id: inline-immediately-returned-variable

# Example: Sourceryが提案
# BEFORE
result = []
for item in items:
    if item.is_active:
        result.append(item.name)

# AFTER (自動提案)
result = [item.name for item in items if item.is_active]
```

**コード品質ダッシュボード構成**

```yaml
# sonar-project.properties
sonar.projectKey=my-project
sonar.sources=src
sonar.tests=tests
sonar.coverage.exclusions=**/*_test.py,**/test_*.py
sonar.python.coverage.reportPaths=coverage.xml

# Quality Gates
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

# Thresholds
sonar.coverage.threshold=80
sonar.duplications.threshold=3
sonar.maintainability.rating=A
sonar.reliability.rating=A
sonar.security.rating=A
```

**セキュリティ重視のリファクタリング**

```python
# セキュリティ認識リファクタリングのためのSemgrepを使用
# .semgrep.yml
rules:
  - id: sql-injection-risk
    pattern: execute($QUERY)
    message: Potential SQL injection
    severity: ERROR
    fix: Use parameterized queries

  - id: hardcoded-secrets
    pattern: password = "..."
    message: Hardcoded password detected
    severity: ERROR
    fix: Use environment variables or secret manager

# CodeQLセキュリティ分析
# .github/workflows/codeql.yml
- uses: github/codeql-action/analyze@v3
  with:
    category: "/language:python"
    queries: security-extended,security-and-quality
```

### 7. リファクタリング実装

以下を含む完全なリファクタリング済みコードを提供します：

**クリーンコード原則**
- 意味のある名前（検索可能、発音可能、略語なし）
- 関数は1つのことをうまく行う
- 副作用がない
- 一貫した抽象化レベル
- DRY（Don't Repeat Yourself）
- YAGNI（You Aren't Gonna Need It）

**エラーハンドリング**
```python
# 特定の例外を使用
class OrderValidationError(Exception):
    pass

class InsufficientInventoryError(Exception):
    pass

# 明確なメッセージでフェイルファスト
def validate_order(order):
    if not order.items:
        raise OrderValidationError("Order must contain at least one item")

    for item in order.items:
        if item.quantity <= 0:
            raise OrderValidationError(f"Invalid quantity for {item.name}")
```

**ドキュメント**
```python
def calculate_discount(order: Order, customer: Customer) -> Decimal:
    """
    顧客ティアと注文金額に基づいて注文の合計割引を計算します。

    Args:
        order: 割引を計算する注文
        customer: 注文を行う顧客

    Returns:
        Decimal型の割引額

    Raises:
        ValueError: 注文合計が負の場合
    """
```

### 8. テスト戦略

リファクタリング済みコードの包括的なテストを生成します：

**ユニットテスト**
```python
class TestOrderProcessor:
    def test_validate_order_empty_items(self):
        order = Order(items=[])
        with pytest.raises(OrderValidationError):
            validate_order(order)

    def test_calculate_discount_vip_customer(self):
        order = create_test_order(total=1000)
        customer = Customer(tier="VIP")
        discount = calculate_discount(order, customer)
        assert discount == Decimal("100.00")  # 10% VIP discount
```

**テストカバレッジ**
- すべての公開メソッドがテスト済み
- エッジケースがカバーされている
- エラー条件が検証されている
- パフォーマンスベンチマークが含まれている

### 9. Before/After比較

改善を示す明確な比較を提供します：

**メトリクス**
- サイクロマティック複雑度の削減
- メソッドあたりのコード行数
- テストカバレッジの増加
- パフォーマンスの改善

**例**
```
Before:
- processData(): 150 lines, complexity: 25
- 0% test coverage
- 3 responsibilities mixed

After:
- validateInput(): 20 lines, complexity: 4
- transformData(): 25 lines, complexity: 5
- saveResults(): 15 lines, complexity: 3
- 95% test coverage
- Clear separation of concerns
```

### 10. 移行ガイド

破壊的変更が導入される場合：

**段階的移行**
1. 新しい依存関係をインストール
2. インポート文を更新
3. 非推奨メソッドを置換
4. 移行スクリプトを実行
5. テストスイートを実行

**下位互換性**
```python
# スムーズな移行のための一時的なアダプタ
class LegacyOrderProcessor:
    def __init__(self):
        self.processor = OrderProcessor()

    def process(self, order_data):
        # Convert legacy format
        order = Order.from_legacy(order_data)
        return self.processor.process(order)
```

### 11. パフォーマンス最適化

特定の最適化を含めます：

**アルゴリズムの改善**
```python
# Before: O(n²)
for item in items:
    for other in items:
        if item.id == other.id:
            # process

# After: O(n)
item_map = {item.id: item for item in items}
for item_id, item in item_map.items():
    # process
```

**キャッシング戦略**
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def calculate_expensive_metric(data_id: str) -> float:
    # Expensive calculation cached
    return result
```

### 12. コード品質チェックリスト

リファクタリング済みコードが以下の基準を満たしていることを確認します：

- [ ] すべてのメソッドが20行未満
- [ ] すべてのクラスが200行未満
- [ ] メソッドのパラメータが3個以下
- [ ] サイクロマティック複雑度が10未満
- [ ] ネストしたループが2レベル以下
- [ ] すべての名前が説明的
- [ ] コメントアウトされたコードがない
- [ ] 一貫したフォーマット
- [ ] 型ヒントが追加されている（Python/TypeScript）
- [ ] エラーハンドリングが包括的
- [ ] デバッグ用のロギングが追加されている
- [ ] パフォーマンスメトリクスが含まれている
- [ ] ドキュメントが完全
- [ ] テストが80%以上のカバレッジを達成
- [ ] セキュリティ脆弱性がない
- [ ] AIコードレビューに合格
- [ ] 静的解析がクリーン（SonarQube/CodeQL）
- [ ] ハードコードされたシークレットがない

## 重要度レベル

見つかった問題と行った改善を評価します：

**クリティカル**: セキュリティ脆弱性、データ破損のリスク、メモリリーク
**高**: パフォーマンスのボトルネック、保守性の障害、テストの欠落
**中**: コードスメル、軽微なパフォーマンス問題、不完全なドキュメント
**低**: スタイルの不整合、軽微な命名の問題、あったら良い機能

## 出力形式

1. **分析サマリー**: 見つかった主要な問題とその影響
2. **リファクタリング計画**: 労力見積もりを含む優先順位付けされた変更リスト
3. **リファクタリング済みコード**: 変更を説明するインラインコメント付きの完全な実装
4. **テストスイート**: リファクタリングされたすべてのコンポーネントの包括的なテスト
5. **移行ガイド**: 変更を採用するための段階的な手順
6. **メトリクスレポート**: コード品質メトリクスのBefore/After比較
7. **AIレビュー結果**: 自動コードレビューの結果のサマリー
8. **品質ダッシュボード**: SonarQube/CodeQL結果へのリンク

システムの安定性を維持しながら、即座に採用できる実用的で段階的な改善の提供に焦点を当てます。
