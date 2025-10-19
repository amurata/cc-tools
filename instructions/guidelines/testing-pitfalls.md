---
title: テスト失敗防止ガイド
description: AIがテストで陥りやすい落とし穴
priority: HIGH
---

# Testing Pitfalls

## ⚠️ 絶対規則（必須遵守）

1. **[ユーザー視点でテスト](#実装詳細テスト)**（実装詳細禁止）
2. **[テスト独立性確保](#テスト独立性)**（共有状態禁止）
3. **[AAA原則遵守](#テスト構造)**（Arrange-Act-Assert）
4. **[E2E最小限](#e2e誤用)**（10%以下）
5. **[モック最小限](#過度なモック)**（外部依存のみ）

## 🎯 Testing Trophy原則
[Testing Library Philosophy](https://testing-library.com/docs/guiding-principles/)

## 実装詳細テスト

### ❌ AIがやりがちな失敗
```javascript
test('should set state', () => {
  wrapper.instance().setState({ count: 1 })
  expect(wrapper.state('count')).toBe(1)
})
```

### ✅ 正しい実装
```javascript
test('should increment when clicked', async () => {
  const { getByRole } = render(<Counter />)
  await userEvent.click(getByRole('button'))
  expect(getByText('Count: 1')).toBeInTheDocument()
})
```

## 過度なモック

### ❌ 失敗例
```javascript
jest.mock('../api')
jest.mock('../utils')
jest.mock('../hooks/useAuth')  // 全モック＝無意味
```

### ✅ 正しい実装
```javascript
jest.mock('../api/external')  // 外部APIのみ
// 内部ロジックは実際に実行
```

## テスト独立性

### ❌ 失敗例
```javascript
let user
beforeAll(() => { user = createUser() })  // 共有状態
```

### ✅ 正しい実装
```javascript
beforeEach(() => {
  const user = createUser()  // 各テスト独立
})
```

## テスト構造

### ✅ AAA原則
```javascript
test('should handle login', () => {
  // Arrange
  const user = { email: 'test@example.com' }
  
  // Act
  const result = login(user)
  
  // Assert
  expect(result.success).toBe(true)
})
```

## E2E誤用

### ❌ 失敗例
```javascript
// 単体テストで十分な内容をE2E化
test('validates email', async () => {
  await page.goto('/signup')
  await page.fill('#email', 'invalid')
})
```

### ✅ 正しい比率
```yaml
Unit Tests: 70%     # 高速・多数
Integration: 20%    # API・DB連携  
E2E: 10%           # クリティカルパスのみ
```

## 📐 必須設定

```json
{
  "testMatch": ["**/*.test.{js,ts,jsx,tsx}"],
  "coverageThreshold": {
    "global": { "branches": 80 }
  }
}
```