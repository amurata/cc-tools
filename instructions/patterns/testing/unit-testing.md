# Unit Testing Patterns

単体テストの設計パターンとベストプラクティス。

## テスト構造

### AAA パターン
```typescript
describe('Calculator', () => {
  test('adds two numbers correctly', () => {
    // Arrange: 準備
    const calculator = new Calculator();
    const a = 5;
    const b = 3;
    
    // Act: 実行
    const result = calculator.add(a, b);
    
    // Assert: 検証
    expect(result).toBe(8);
  });
});
```

### テストの独立性
```typescript
describe('UserService', () => {
  let userService: UserService;
  let mockRepository: jest.Mocked<UserRepository>;
  
  beforeEach(() => {
    // 各テストで新しいインスタンス
    mockRepository = createMockRepository();
    userService = new UserService(mockRepository);
  });
  
  afterEach(() => {
    // クリーンアップ
    jest.clearAllMocks();
  });
  
  test('creates user with unique ID', async () => {
    const userData = { name: 'John', email: 'john@example.com' };
    mockRepository.save.mockResolvedValue({ id: '123', ...userData });
    
    const user = await userService.createUser(userData);
    
    expect(user.id).toBeDefined();
    expect(mockRepository.save).toHaveBeenCalledWith(userData);
  });
});
```

## モックパターン

### テストダブルの種類
```typescript
// Dummy: 使われないが必要なパラメータ
const dummyLogger = {} as Logger;

// Stub: 固定値を返す
const fetchUserStub = jest.fn().mockReturnValue({
  id: '1',
  name: 'Test User'
});

// Spy: 呼び出しを記録
const consoleSpy = jest.spyOn(console, 'log');

// Mock: 期待される振る舞いを定義
const emailServiceMock = {
  send: jest.fn().mockResolvedValue({ success: true })
};

// Fake: 簡易実装
class FakeDatabase {
  private data = new Map();
  
  async save(key: string, value: any) {
    this.data.set(key, value);
    return value;
  }
  
  async find(key: string) {
    return this.data.get(key);
  }
}
```

### 依存性のモック
```typescript
// __mocks__/emailService.ts
export const sendEmail = jest.fn().mockResolvedValue({ sent: true });
export const verifyEmail = jest.fn().mockResolvedValue({ valid: true });

// userService.test.ts
jest.mock('../services/emailService');

import { sendEmail } from '../services/emailService';
import { UserService } from '../services/userService';

test('sends welcome email on registration', async () => {
  const userService = new UserService();
  await userService.register('user@example.com');
  
  expect(sendEmail).toHaveBeenCalledWith(
    expect.objectContaining({
      to: 'user@example.com',
      subject: expect.stringContaining('Welcome')
    })
  );
});
```

## パラメータ化テスト

### テストケースの配列
```typescript
describe('Password Validator', () => {
  const testCases = [
    { password: '12345', valid: false, reason: 'too short' },
    { password: 'password', valid: false, reason: 'no numbers' },
    { password: 'PASSWORD123', valid: false, reason: 'no lowercase' },
    { password: 'password123', valid: false, reason: 'no uppercase' },
    { password: 'Password123!', valid: true, reason: 'valid' }
  ];
  
  test.each(testCases)(
    'validates "$password" as $valid ($reason)',
    ({ password, valid }) => {
      const result = validatePassword(password);
      expect(result.valid).toBe(valid);
    }
  );
});
```

### プロパティベーステスト
```typescript
import fc from 'fast-check';

test('reverse twice returns original string', () => {
  fc.assert(
    fc.property(fc.string(), (str) => {
      const reversed = reverseString(reverseString(str));
      expect(reversed).toBe(str);
    })
  );
});

test('sorted array is always ascending', () => {
  fc.assert(
    fc.property(fc.array(fc.integer()), (arr) => {
      const sorted = sortArray(arr);
      for (let i = 1; i < sorted.length; i++) {
        expect(sorted[i]).toBeGreaterThanOrEqual(sorted[i - 1]);
      }
    })
  );
});
```

## エッジケーステスト

### 境界値テスト
```typescript
describe('Pagination', () => {
  test('handles empty dataset', () => {
    const result = paginate([], 1, 10);
    expect(result).toEqual({
      data: [],
      page: 1,
      totalPages: 0
    });
  });
  
  test('handles single item', () => {
    const result = paginate([1], 1, 10);
    expect(result.data).toHaveLength(1);
  });
  
  test('handles exact page boundary', () => {
    const items = Array.from({ length: 10 }, (_, i) => i);
    const result = paginate(items, 1, 10);
    expect(result.totalPages).toBe(1);
  });
  
  test('handles page overflow', () => {
    const items = Array.from({ length: 5 }, (_, i) => i);
    const result = paginate(items, 10, 10);
    expect(result.data).toEqual([]);
    expect(result.page).toBe(10);
  });
});
```

### Null/Undefined処理
```typescript
describe('SafeParser', () => {
  test('handles null input', () => {
    expect(() => parseJSON(null)).not.toThrow();
    expect(parseJSON(null)).toBeNull();
  });
  
  test('handles undefined input', () => {
    expect(() => parseJSON(undefined)).not.toThrow();
    expect(parseJSON(undefined)).toBeUndefined();
  });
  
  test('handles empty string', () => {
    expect(() => parseJSON('')).toThrow('Invalid JSON');
  });
  
  test('handles malformed JSON', () => {
    expect(() => parseJSON('{invalid}')).toThrow('Invalid JSON');
  });
});
```

## 非同期テスト

### Promise テスト
```typescript
// async/await使用
test('fetches user data', async () => {
  const userData = await fetchUser('123');
  expect(userData.name).toBe('John Doe');
});

// rejects matcher
test('rejects with error for invalid ID', async () => {
  await expect(fetchUser('invalid')).rejects.toThrow('User not found');
});

// resolves matcher
test('resolves with user data', async () => {
  await expect(fetchUser('123')).resolves.toMatchObject({
    id: '123',
    name: expect.any(String)
  });
});
```

### タイマーのモック
```typescript
describe('Debounce', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });
  
  afterEach(() => {
    jest.useRealTimers();
  });
  
  test('delays function execution', () => {
    const callback = jest.fn();
    const debounced = debounce(callback, 1000);
    
    debounced();
    debounced();
    debounced();
    
    expect(callback).not.toHaveBeenCalled();
    
    jest.advanceTimersByTime(1000);
    
    expect(callback).toHaveBeenCalledTimes(1);
  });
});
```

## テストカバレッジ

### カバレッジ目標
```javascript
// jest.config.js
module.exports = {
  collectCoverage: true,
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    './src/core/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  },
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/test/',
    '\\.mock\\.(ts|js)$'
  ]
};
```

### カバレッジレポート
```bash
# カバレッジ実行
npm test -- --coverage

# HTMLレポート生成
npm test -- --coverage --coverageReporters=html

# 特定ファイルのカバレッジ
npm test -- --coverage --collectCoverageFrom=src/services/**/*.ts
```

## スナップショットテスト

### コンポーネントスナップショット
```typescript
test('renders correctly', () => {
  const component = render(<Button label="Click me" />);
  expect(component).toMatchSnapshot();
});

// インラインスナップショット
test('generates correct SQL', () => {
  const query = buildQuery({ table: 'users', where: { age: 25 } });
  expect(query).toMatchInlineSnapshot(`"SELECT * FROM users WHERE age = 25"`);
});

// スナップショット更新
// npm test -- -u
```

## テスト命名規則

### 明確なテスト名
```typescript
// ✅ 良い例: 何をテストしているか明確
test('returns empty array when filtering with no matches', () => {});
test('throws ValidationError when email format is invalid', () => {});
test('retries 3 times before failing on network error', () => {});

// ❌ 悪い例: 曖昧
test('test filter', () => {});
test('error case', () => {});
test('works correctly', () => {});
```

## チェックリスト
- [ ] AAA パターン使用
- [ ] テストの独立性確保
- [ ] 適切なモック使用
- [ ] エッジケーステスト
- [ ] 非同期処理テスト
- [ ] エラーケーステスト
- [ ] カバレッジ目標達成
- [ ] 明確なテスト名
- [ ] テスト速度最適化