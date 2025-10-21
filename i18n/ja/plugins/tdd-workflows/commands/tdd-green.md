---
description: TDDグリーンフェーズで失敗するテストを成功させるための最小限のコードを実装します。
---

> **[English](../../../plugins/tdd-workflows/commands/tdd-green.md)** | **日本語**

TDDグリーンフェーズで失敗するテストを成功させるための最小限のコードを実装します。

[拡張思考: このツールは、test-automatorエージェントを使用して、テストを成功させるために必要な最小限のコードを実装します。過度な設計を避けながら、シンプルさに焦点を当て、すべてのテストがグリーンになることを保証します。]

## 実装プロセス

Taskツールを使用し、subagent_type="unit-testing::test-automator"で最小限の成功するコードを実装します。

プロンプト: "これらの失敗するテストを成功させるための最小限のコードを実装してください: $ARGUMENTS。TDDグリーンフェーズの原則に従ってください:

1. **実装前の分析**
   - すべての失敗するテストとそのエラーメッセージをレビュー
   - テストを成功させる最もシンプルなパスを特定
   - テスト要件を最小限の実装ニーズにマッピング
   - 早期の最適化や過度な設計を避ける
   - テストをグリーンにすることにフォーカス、完璧なコードではない

2. **実装戦略**
   - **偽装実装(Fake It)**: 適切な場合はハードコードされた値を返す
   - **明白な実装(Obvious Implementation)**: 解決策が些細で明確な場合
   - **三角測量(Triangulation)**: 複数のテストが必要とする場合にのみ一般化
   - 最もシンプルなテストから始めて段階的に進める
   - 一度に1つのテスト - すべてを一度に成功させようとしない

3. **コード構造ガイドライン**
   - 動作する可能性のある最小限のコードを記述
   - テストで要求されていない機能の追加を避ける
   - 最初はシンプルなデータ構造を使用
   - アーキテクチャの決定はリファクタフェーズまで延期
   - メソッド/関数を小さく集中させる
   - テストで要求されない限りエラーハンドリングを追加しない

4. **言語別パターン**
   - **JavaScript/TypeScript**: シンプルな関数、最初はクラスを避ける
   - **Python**: クラスより関数、シンプルな戻り値
   - **Java**: 最小限のクラス構造、まだパターンなし
   - **C#**: 基本的な実装、まだインターフェースなし
   - **Go**: シンプルな関数、goroutine/channelは延期
   - **Ruby**: 可能な場合は手続き型からオブジェクト指向へ

5. **段階的実装**
   - 最もシンプルなコードで最初のテストを成功させる
   - 各変更後にテストを実行して進捗を検証
   - 次の失敗するテストのために十分なコードだけを追加
   - テスト要件を超えた実装への誘惑に抵抗
   - リファクタフェーズのために技術的負債を記録
   - 取ったショートカットと仮定を文書化

6. **一般的なグリーンフェーズテクニック**
   - 初期テストのためのハードコードされた戻り値
   - 限定されたテストケースのためのシンプルなif/else
   - イテレーションテストが必要な場合のみ基本的なループ
   - 最小限のデータ構造(複雑なオブジェクトの前に配列)
   - データベース統合の前にインメモリストレージ
   - 非同期実装の前に同期

7. **成功基準**
   ✓ すべてのテストが成功(グリーン)
   ✓ テスト要件を超える追加機能なし
   ✓ コードが読みやすい(最適でなくても)
   ✓ 既存の機能が壊れていない
   ✓ 実装時間が最小化されている
   ✓ リファクタリングへの明確なパスが特定されている

8. **避けるべきアンチパターン**
   - ゴールドプレーティングや要求されていない機能の追加
   - 時期尚早なデザインパターンの実装
   - テストの正当性なしの複雑な抽象化
   - メトリクスなしのパフォーマンス最適化
   - グリーンフェーズ中のテスト追加
   - 実装中のリファクタリング
   - 前進するためにテスト失敗を無視

9. **実装メトリクス**
   - グリーンまでの時間: 実装期間を追跡
   - コード行数: 実装サイズを測定
   - 循環的複雑度: 最初は低く保つ
   - テスト合格率: 100%に到達しなければならない
   - コードカバレッジ: すべてのパスがテストされていることを検証

10. **検証ステップ**
    - すべてのテストを実行して成功を確認
    - 既存のテストに退行がないことを検証
    - 実装が本当に最小限であることをチェック
    - 作成した技術的負債を文書化
    - リファクタリングフェーズのためのノートを準備

出力には以下を含めるべき:
- 完全な実装コード
- すべてグリーンを示すテスト実行結果
- 後のリファクタリングのために取ったショートカットのリスト
- 実装時間メトリクス
- 技術的負債の文書
- リファクタフェーズへの準備状況評価"

## 実装後のチェック

実装後:
1. すべてのテストが成功することを確認するためにフルテストスイートを実行
2. 既存のテストが壊れていないことを検証
3. リファクタリングが必要な領域を文書化
4. 実装が本当に最小限であることをチェック
5. メトリクスのために実装時間を記録

## リカバリプロセス

テストがまだ失敗する場合:
- テスト要件を慎重にレビュー
- 誤解されたアサーションをチェック
- 特定の失敗に対処するための最小限のコードを追加
- ゼロから書き直す誘惑を避ける
- テスト自体が調整を必要とするかどうか検討

## 統合ポイント

- tdd-red.mdのテスト作成から続く
- tdd-refactor.mdの改善に備える
- テストカバレッジメトリクスを更新
- CI/CDパイプライン検証をトリガー
- 追跡のために技術的負債を文書化

## ベストプラクティス

- このフェーズでは「十分良い」を受け入れる
- 完璧さより速度(完璧さはリファクタで)
- 動かしてから、正しくしてから、速くする
- リファクタリングフェーズがコードを改善すると信頼する
- 変更を小さく段階的に保つ
- グリーン状態に到達したら祝福！

## 完全な実装例

### 例1: 最小限 → プロダクション対応(ユーザーサービス)

**テスト要件:**
```typescript
describe('UserService', () => {
  it('should create a new user', async () => {
    const user = await userService.create({ email: 'test@example.com', name: 'Test' });
    expect(user.id).toBeDefined();
    expect(user.email).toBe('test@example.com');
  });

  it('should find user by email', async () => {
    await userService.create({ email: 'test@example.com', name: 'Test' });
    const user = await userService.findByEmail('test@example.com');
    expect(user).toBeDefined();
  });
});
```

**ステージ1: 偽装実装(最小限)**
```typescript
class UserService {
  create(data: { email: string; name: string }) {
    return { id: '123', email: data.email, name: data.name };
  }

  findByEmail(email: string) {
    return { id: '123', email: email, name: 'Test' };
  }
}
```
*テストが成功。実装は明らかに偽物だが、テスト構造を検証。*

**ステージ2: シンプルな実際の実装**
```typescript
class UserService {
  private users: Map<string, User> = new Map();
  private nextId = 1;

  create(data: { email: string; name: string }) {
    const user = { id: String(this.nextId++), ...data };
    this.users.set(user.email, user);
    return user;
  }

  findByEmail(email: string) {
    return this.users.get(email) || null;
  }
}
```
*インメモリストレージ。テストが成功。グリーンフェーズには十分。*

**ステージ3: プロダクション対応(リファクタフェーズ)**
```typescript
class UserService {
  constructor(private db: Database) {}

  async create(data: { email: string; name: string }) {
    const existing = await this.db.query('SELECT * FROM users WHERE email = ?', [data.email]);
    if (existing) throw new Error('User exists');

    const id = await this.db.insert('users', data);
    return { id, ...data };
  }

  async findByEmail(email: string) {
    return this.db.queryOne('SELECT * FROM users WHERE email = ?', [email]);
  }
}
```
*データベース統合、エラーハンドリング、検証 - リファクタフェーズに保存。*

### 例2: API優先実装(Express)

**テスト要件:**
```javascript
describe('POST /api/tasks', () => {
  it('should create task and return 201', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .send({ title: 'Test Task' });

    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.title).toBe('Test Task');
  });
});
```

**ステージ1: ハードコードされたレスポンス**
```javascript
app.post('/api/tasks', (req, res) => {
  res.status(201).json({ id: '1', title: req.body.title });
});
```
*テストが即座に成功。まだロジックは不要。*

**ステージ2: シンプルなロジック**
```javascript
let tasks = [];
let nextId = 1;

app.post('/api/tasks', (req, res) => {
  const task = { id: String(nextId++), title: req.body.title };
  tasks.push(task);
  res.status(201).json(task);
});
```
*最小限の状態管理。さらなるテストの準備完了。*

**ステージ3: レイヤードアーキテクチャ(リファクタ)**
```javascript
// コントローラー
app.post('/api/tasks', async (req, res) => {
  try {
    const task = await taskService.create(req.body);
    res.status(201).json(task);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// サービスレイヤー
class TaskService {
  constructor(private repository: TaskRepository) {}

  async create(data: CreateTaskDto): Promise<Task> {
    this.validate(data);
    return this.repository.save(data);
  }
}
```
*適切な関心の分離がリファクタフェーズで追加。*

### 例3: データベース統合(Django)

**テスト要件:**
```python
def test_product_creation():
    product = Product.objects.create(name="Widget", price=9.99)
    assert product.id is not None
    assert product.name == "Widget"

def test_product_price_validation():
    with pytest.raises(ValidationError):
        Product.objects.create(name="Widget", price=-1)
```

**ステージ1: モデルのみ**
```python
class Product(models.Model):
    name = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)
```
*最初のテストが成功。2番目のテストは失敗 - 検証が実装されていない。*

**ステージ2: 検証を追加**
```python
class Product(models.Model):
    name = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    def clean(self):
        if self.price < 0:
            raise ValidationError("Price cannot be negative")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)
```
*すべてのテストが成功。最小限の検証ロジックを追加。*

**ステージ3: リッチドメインモデル(リファクタ)**
```python
class Product(models.Model):
    name = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=['category', '-created_at'])]

    def clean(self):
        if self.price < 0:
            raise ValidationError("Price cannot be negative")
        if self.price > 10000:
            raise ValidationError("Price exceeds maximum")

    def apply_discount(self, percentage: float) -> Decimal:
        return self.price * (1 - percentage / 100)
```
*必要に応じて追加機能、インデックス、ビジネスロジックを追加。*

### 例4: Reactコンポーネント実装

**テスト要件:**
```typescript
describe('UserProfile', () => {
  it('should display user name', () => {
    render(<UserProfile user={{ name: 'John', email: 'john@test.com' }} />);
    expect(screen.getByText('John')).toBeInTheDocument();
  });

  it('should display email', () => {
    render(<UserProfile user={{ name: 'John', email: 'john@test.com' }} />);
    expect(screen.getByText('john@test.com')).toBeInTheDocument();
  });
});
```

**ステージ1: 最小限のJSX**
```typescript
interface UserProfileProps {
  user: { name: string; email: string };
}

const UserProfile: React.FC<UserProfileProps> = ({ user }) => (
  <div>
    <div>{user.name}</div>
    <div>{user.email}</div>
  </div>
);
```
*テストが成功。スタイリングなし、構造なし。*

**ステージ2: 基本的な構造**
```typescript
const UserProfile: React.FC<UserProfileProps> = ({ user }) => (
  <div className="user-profile">
    <h2>{user.name}</h2>
    <p>{user.email}</p>
  </div>
);
```
*セマンティックHTML、スタイリングフックのためのclassNameを追加。*

**ステージ3: プロダクションコンポーネント(リファクタ)**
```typescript
const UserProfile: React.FC<UserProfileProps> = ({ user }) => {
  const [isEditing, setIsEditing] = useState(false);

  return (
    <div className="user-profile" role="article" aria-label="User profile">
      <header>
        <h2>{user.name}</h2>
        <button onClick={() => setIsEditing(true)} aria-label="Edit profile">
          Edit
        </button>
      </header>
      <section>
        <p>{user.email}</p>
        {user.bio && <p>{user.bio}</p>}
      </section>
    </div>
  );
};
```
*アクセシビリティ、インタラクション、追加機能を段階的に追加。*

## 意思決定フレームワーク

### フレームワーク1: 偽装 vs 実際の実装

**偽装実装すべき時:**
- 新機能の最初のテスト
- 複雑な外部依存関係(決済ゲートウェイ、API)
- 実装アプローチがまだ不確実
- まずテスト構造を検証する必要がある
- すべてのテストをグリーンにする時間的プレッシャー

**実際の実装にすべき時:**
- 2番目または3番目のテストがパターンを明らかにする
- 実装が明白でシンプル
- 偽装が実際のコードより複雑になる
- 統合ポイントをテストする必要がある
- テストが明示的に実際の動作を要求

**意思決定マトリックス:**
```
複雑度  低      | 高
         ↓      | ↓
シンプル → 実装  | まず偽装、後で実装
複雑    → 実装  | 偽装、代替案を評価
```

### フレームワーク2: 複雑性トレードオフ分析

**シンプルさスコア計算:**
```
スコア = (コード行数) + (循環的複雑度 × 2) + (依存関係 × 3)

< 20  → 十分シンプル、直接実装
20-50 → よりシンプルな代替案を検討
> 50  → リファクタフェーズに複雑性を延期
```

**評価例:**
```typescript
// オプションA: 直接実装(スコア: 45)
function calculateShipping(weight: number, distance: number, express: boolean): number {
  let base = weight * 0.5 + distance * 0.1;
  if (express) base *= 2;
  if (weight > 50) base += 10;
  if (distance > 1000) base += 20;
  return base;
}

// オプションB: グリーンフェーズで最もシンプル(スコア: 15)
function calculateShipping(weight: number, distance: number, express: boolean): number {
  return express ? 50 : 25; // より多くのテストが実際のロジックを駆動するまで偽装
}
```
*グリーンフェーズではオプションBを選択、テストが要求するにつれてオプションAに進化。*

### フレームワーク3: パフォーマンス考慮のタイミング

**グリーンフェーズ: 正確性にフォーカス**
```
❌ 避ける:
- キャッシング戦略
- データベースクエリ最適化
- アルゴリズム複雑性の改善
- 時期尚早なメモリ最適化

✓ 受け入れる:
- コードがシンプルになるならO(n²)
- 複数のデータベースクエリ
- 同期操作
- 非効率だが明確なアルゴリズム
```

**グリーンフェーズでパフォーマンスが重要な時:**
1. パフォーマンスが明示的なテスト要件
2. 実装がテストスイートでタイムアウトを引き起こす
3. メモリリークがテストをクラッシュさせる
4. リソース枯渇がテストを妨げる

**パフォーマンステスト統合:**
```typescript
// 機能テストが成功した後にパフォーマンステストを追加
describe('Performance', () => {
  it('should handle 1000 users within 100ms', () => {
    const start = Date.now();
    for (let i = 0; i < 1000; i++) {
      userService.create({ email: `user${i}@test.com`, name: `User ${i}` });
    }
    expect(Date.now() - start).toBeLessThan(100);
  });
});
```

## フレームワーク別パターン

### Reactパターン

**シンプルなコンポーネント → フック → コンテキスト:**
```typescript
// グリーンフェーズ: プロップスのみ
const Counter = ({ count, onIncrement }) => (
  <button onClick={onIncrement}>{count}</button>
);

// リファクタ: フックを追加
const Counter = () => {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
};

// リファクタ: コンテキストに抽出
const Counter = () => {
  const { count, increment } = useCounter();
  return <button onClick={increment}>{count}</button>;
};
```

### Djangoパターン

**関数ビュー → クラスビュー → ジェネリックビュー:**
```python
# グリーンフェーズ: シンプルな関数
def product_list(request):
    products = Product.objects.all()
    return JsonResponse({'products': list(products.values())})

# リファクタ: クラスベースビュー
class ProductListView(View):
    def get(self, request):
        products = Product.objects.all()
        return JsonResponse({'products': list(products.values())})

# リファクタ: ジェネリックビュー
class ProductListView(ListView):
    model = Product
    context_object_name = 'products'
```

### Expressパターン

**インライン → ミドルウェア → サービスレイヤー:**
```javascript
// グリーンフェーズ: インラインロジック
app.post('/api/users', (req, res) => {
  const user = { id: Date.now(), ...req.body };
  users.push(user);
  res.json(user);
});

// リファクタ: ミドルウェアを抽出
app.post('/api/users', validateUser, (req, res) => {
  const user = userService.create(req.body);
  res.json(user);
});

// リファクタ: 完全なレイヤリング
app.post('/api/users',
  validateUser,
  asyncHandler(userController.create)
);
```

## リファクタリング抵抗パターン

### パターン1: テストアンカーポイント

インターフェース契約を維持することでリファクタリング中もテストをグリーンに保つ:

```typescript
// 元の実装(テストはグリーン)
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// リファクタリング: 税計算を追加(インターフェースは維持)
function calculateTotal(items: Item[]): number {
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  const tax = subtotal * 0.1;
  return subtotal + tax;
}

// 戻り値の型/動作が変わっていないためテストはまだグリーン
```

### パターン2: 並列実装

古い実装と新しい実装を並行して実行:

```python
def process_order(order):
    # 古い実装(テストはこれに依存)
    result_old = legacy_process(order)

    # 新しい実装(並列でテスト)
    result_new = new_process(order)

    # 一致を検証
    assert result_old == result_new, "Implementation mismatch"

    return result_old  # テストをグリーンに保つ
```

### パターン3: リファクタリングのためのフィーチャーフラグ

```javascript
class PaymentService {
  processPayment(amount) {
    if (config.USE_NEW_PAYMENT_PROCESSOR) {
      return this.newPaymentProcessor(amount);
    }
    return this.legacyPaymentProcessor(amount);
  }
}
```

## パフォーマンス優先グリーンフェーズ戦略

### 戦略1: 型駆動開発

型を使用して最小限の実装をガイド:

```typescript
// 型が契約を定義
interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

// グリーンフェーズ: インメモリ実装
class InMemoryUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async findById(id: string) {
    return this.users.get(id) || null;
  }

  async save(user: User) {
    this.users.set(user.id, user);
  }
}

// リファクタ: データベース実装(同じインターフェース)
class DatabaseUserRepository implements UserRepository {
  constructor(private db: Database) {}

  async findById(id: string) {
    return this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }

  async save(user: User) {
    await this.db.insert('users', user);
  }
}
```

### 戦略2: 契約テスト統合

```typescript
// 契約を定義
const userServiceContract = {
  create: {
    input: { email: 'string', name: 'string' },
    output: { id: 'string', email: 'string', name: 'string' }
  }
};

// グリーンフェーズ: 実装が契約に一致
class UserService {
  create(data: { email: string; name: string }) {
    return { id: '123', ...data }; // 最小限だが契約に準拠
  }
}

// 契約テストがコンプライアンスを保証
describe('UserService Contract', () => {
  it('should match create contract', () => {
    const result = userService.create({ email: 'test@test.com', name: 'Test' });
    expect(typeof result.id).toBe('string');
    expect(typeof result.email).toBe('string');
    expect(typeof result.name).toBe('string');
  });
});
```

### 戦略3: 継続的リファクタリングワークフロー

**グリーンフェーズ中のマイクロリファクタリング:**

```python
# これでテストが成功
def calculate_discount(price, customer_type):
    if customer_type == 'premium':
        return price * 0.8
    return price

# 即座のマイクロリファクタ(テストはまだグリーン)
DISCOUNT_RATES = {
    'premium': 0.8,
    'standard': 1.0
}

def calculate_discount(price, customer_type):
    rate = DISCOUNT_RATES.get(customer_type, 1.0)
    return price * rate
```

**安全なリファクタリングチェックリスト:**
- ✓ リファクタリング前にテストがグリーン
- ✓ 一度に1つのことを変更
- ✓ 各変更後にテストを実行
- ✓ 各成功したリファクタ後にコミット
- ✓ 動作変更なし、構造のみ

## モダン開発プラクティス(2024/2025)

### 型駆動開発

**Python型ヒント:**
```python
from typing import Optional, List
from dataclasses import dataclass

@dataclass
class User:
    id: str
    email: str
    name: str

class UserService:
    def create(self, email: str, name: str) -> User:
        return User(id="123", email=email, name=name)

    def find_by_email(self, email: str) -> Optional[User]:
        return None  # 最小限の実装
```

**TypeScript厳格モード:**
```typescript
// tsconfig.jsonで厳格モードを有効化
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}

// 型によってガイドされる実装
interface CreateUserDto {
  email: string;
  name: string;
}

class UserService {
  create(data: CreateUserDto): User {
    // 型システムが契約を強制
    return { id: '123', email: data.email, name: data.name };
  }
}
```

### AI支援グリーンフェーズ

**Copilot/AIツールの使用:**
1. まずテストを書く(人間主導)
2. AIに最小限の実装を提案させる
3. 提案がテストを通過することを検証
4. 本当に最小限なら受け入れ、過度に設計されていれば拒否
5. リファクタリングフェーズのためにAIと反復

**AIプロンプトパターン:**
```
これらの失敗するテストが与えられた場合:
[テストを貼り付け]

テストを成功させる最小限の実装を提供してください。
エラーハンドリング、検証、またはテスト要件を超える機能を追加しないでください。
完全性よりシンプルさにフォーカスしてください。
```

### クラウドネイティブパターン

**ローカル → コンテナ → クラウド:**
```javascript
// グリーンフェーズ: ローカル実装
class CacheService {
  private cache = new Map();

  get(key) { return this.cache.get(key); }
  set(key, value) { this.cache.set(key, value); }
}

// リファクタ: Redis互換インターフェース
class CacheService {
  constructor(private redis) {}

  async get(key) { return this.redis.get(key); }
  async set(key, value) { return this.redis.set(key, value); }
}

// プロダクション: フォールバック付き分散キャッシュ
class CacheService {
  constructor(private redis, private fallback) {}

  async get(key) {
    try {
      return await this.redis.get(key);
    } catch {
      return this.fallback.get(key);
    }
  }
}
```

### オブザーバビリティ駆動開発

**グリーンフェーズ中にオブザーバビリティフックを追加:**
```typescript
class OrderService {
  async createOrder(data: CreateOrderDto): Promise<Order> {
    console.log('[OrderService] Creating order', { data }); // シンプルなロギング

    const order = { id: '123', ...data };

    console.log('[OrderService] Order created', { orderId: order.id }); // 成功ログ

    return order;
  }
}

// リファクタ: 構造化ロギング
class OrderService {
  constructor(private logger: Logger) {}

  async createOrder(data: CreateOrderDto): Promise<Order> {
    this.logger.info('order.create.start', { data });

    const order = await this.repository.save(data);

    this.logger.info('order.create.success', {
      orderId: order.id,
      duration: Date.now() - start
    });

    return order;
  }
}
```

成功させるテスト: $ARGUMENTS
