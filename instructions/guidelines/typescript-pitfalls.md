---
title: TypeScript失敗防止ガイド
description: AIがTypeScriptで陥りやすい落とし穴
priority: HIGH
---

# TypeScript Pitfalls

## ⚠️ 絶対規則（必須遵守）

1. **[型アサーション(as)禁止](#型アサーション)**：最終手段時は必ず報告
2. **[any禁止](#any使用は論外)**：unknown使用
3. **[非null assertion最小限](#非null-assertion)**
4. **TypeScript未対応ライブラリ禁止**
5. **アロー関数で定義**

## 🎯 Google TypeScript Style Guide準拠
[Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)

## 型アサーション

### ❌ AIがやりがちな失敗
```typescript
const data = response.data as UserData
```

### ✅ 正しい実装
```typescript
// 型ガード（アロー関数）
const isUserData = (data: unknown): data is UserData => {
  return typeof data === 'object' && data !== null && 'id' in data
}

if (isUserData(response.data)) {
  const data = response.data  // 安全にUserData型
}
```

### ⚠️ 最終手段（必ず報告）
```typescript
// TODO: [AI報告] as使用：外部ライブラリ型定義不備
const legacy = lib.getData() as unknown as OurType
```

## any使用は論外

### ❌ 失敗例
```typescript
const process = (input: any): any => { ... }
```

### ✅ 正しい実装
```typescript
const process = <T>(input: T): ProcessedType<T> => { ... }
```

## 非null assertion

### ❌ 失敗例
```typescript
user!.profile!.name
```

### ✅ 正しい実装
```typescript
user?.profile?.name ?? 'Unknown'
```

## 📐 必須設定

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true
  }
}
```