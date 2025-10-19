---
title: JavaScript失敗防止ガイド
description: AIがJavaScriptで陥りやすい落とし穴
priority: HIGH
---

# JavaScript Pitfalls

## ⚠️ 絶対規則（必須遵守）

1. **[厳密等価演算子(===)使用](#型強制の罠)**
2. **[var禁止](#var使用)**（const/let使用）
3. **[async/await使用](#コールバック地獄)**（callback/then禁止）
4. **[アロー関数優先](#this束縛)**
5. **[ES2024+機能使用](#古い書き方)**

## 🎯 Google JavaScript Style Guide準拠
[Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)

## 型強制の罠

### ❌ AIがやりがちな失敗
```javascript
if (value == null)  // undefined含む曖昧な比較
```

### ✅ 正しい実装
```javascript
if (value === null || value === undefined)
// またはnullish演算子
const result = value ?? defaultValue
```

## var使用

### ❌ 失敗例
```javascript
var count = 0  // スコープ問題
```

### ✅ 正しい実装
```javascript
const count = 0  // 不変
let mutable = 0  // 可変時のみ
```

## コールバック地獄

### ❌ 失敗例
```javascript
getData(id, (err, data) => {
  if (err) return handleError(err)
  processData(data, (err, result) => {
    // ネスト地獄
  })
})
```

### ✅ 正しい実装
```javascript
const processFlow = async () => {
  try {
    const data = await getData(id)
    const result = await processData(data)
    return result
  } catch (error) {
    handleError(error)
  }
}
```

## this束縛

### ❌ 失敗例
```javascript
obj.method = function() {
  return this.value  // this不安定
}
```

### ✅ 正しい実装
```javascript
obj.method = () => obj.value  // アロー関数
```

## 古い書き方

### ❌ 失敗例
```javascript
array.indexOf(item) !== -1  // ES5
```

### ✅ 正しい実装
```javascript
array.includes(item)  // ES2016+
Object.hasOwn(obj, 'key')  // ES2022+
```

## 📐 必須設定

```json
// .eslintrc
{
  "rules": {
    "eqeqeq": "error",
    "no-var": "error",
    "prefer-const": "error",
    "prefer-arrow-callback": "error"
  }
}
```