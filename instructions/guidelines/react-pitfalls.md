---
title: React失敗防止ガイド
description: AIがReactで陥りやすい落とし穴
priority: HIGH
---

# React Pitfalls

## ⚠️ 絶対規則（必須遵守）

1. **[アロー関数でコンポーネント定義](#コンポーネント定義)**
2. **[default export禁止](#コンポーネント定義)**（フレームワーク要求時除く）
3. **[useEffect最小限](#useeffectは最終手段)**（副作用のみ）
4. **[クリーンアップ関数必須](#useeffectは最終手段)**
5. **[依存配列完全記述](#useeffectは最終手段)**
6. **[状態管理ライブラリ使用](#状態管理)**（中規模以上）

## 🎯 React公式準拠
[React.dev](https://react.dev) | [Thinking in React](https://react.dev/learn/thinking-in-react)

## コンポーネント定義

### ❌ AIがやりがちな失敗
```jsx
function Component() { ... }
export default Component
```

### ✅ 正しい実装
```jsx
export const Component = () => { ... }  // アロー関数 + named export
```
**例外**: Next.js App Router等のフレームワーク要求時のみdefault export許可

## useEffectは最終手段

### ❌ 失敗：計算にuseEffect
```jsx
useEffect(() => {
  setCalculated(prop1 + prop2)
}, [prop1, prop2])  // setCalculated漏れ
```

### ✅ 正しい実装
```jsx
const calculated = useMemo(() => prop1 + prop2, [prop1, prop2])
```

### ✅ useEffect正しい使用法
```jsx
const handleUpdate = useCallback((data: Data) => {
  setProcessedData(process(data))
}, [])

useEffect(() => {
  const sub = api.subscribe(handleUpdate)
  return () => sub.unsubscribe()  // クリーンアップ必須
}, [handleUpdate])  // 依存配列完全

// 最終手段の除外
useEffect(() => {
  // 処理
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [])  // 除外理由を明記
```

## 状態管理

### ❌ 中規模以上でuseReducer
```jsx
const [state, dispatch] = useReducer(reducer, initial)
```

### ✅ 正しい実装
```jsx
// ローカル状態
const [count, setCount] = useState(0)

// グローバル状態（中規模以上）
import { atom, useAtom } from 'jotai'
import { useRecoilState } from 'recoil'
import { useSelector } from 'react-redux'
```

## 📐 必須設定

```json
{
  "rules": {
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "error"
  }
}
```