---
title: Python失敗防止ガイド
description: AIがPythonで陥りやすい落とし穴
priority: HIGH
---

# Python Pitfalls

## ⚠️ 絶対規則（必須遵守）

1. **[型ヒント100%必須](#型ヒント省略)**
2. **[f-strings使用](#文字列フォーマット)**（%/.format禁止）
3. **[pathlib使用](#ファイルパス)**（os.path禁止）
4. **[with文必須](#リソース管理)**（コンテキストマネージャ）
5. **[Python 3.10+機能使用](#古い書き方)**

## 🎯 Google Python Style Guide準拠
[Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)

## 型ヒント省略

### ❌ AIがやりがちな失敗
```python
def calculate_total(items, tax_rate):
    return sum(item.price for item in items) * (1 + tax_rate)
```

### ✅ 正しい実装
```python
def calculate_total(items: list[Item], tax_rate: float) -> float:
    return sum(item.price for item in items) * (1 + tax_rate)
```

## 文字列フォーマット

### ❌ 失敗例
```python
msg = "User %s has %d points" % (name, points)
msg = "User {} has {}".format(name, points)
```

### ✅ 正しい実装
```python
msg = f"User {name} has {points} points"
```

## ファイルパス

### ❌ 失敗例
```python
import os
path = os.path.join(dir, "file.txt")
```

### ✅ 正しい実装
```python
from pathlib import Path
path = Path(dir) / "file.txt"
```

## リソース管理

### ❌ 失敗例
```python
file = open("data.txt")
data = file.read()
file.close()
```

### ✅ 正しい実装
```python
with Path("data.txt").open() as file:
    data = file.read()
```

## 古い書き方

### ❌ 失敗例
```python
if isinstance(value, int) or isinstance(value, float):
    numeric = value
```

### ✅ 正しい実装（Python 3.10+）
```python
match value:
    case int() | float():
        numeric = value
    case _:
        raise TypeError(f"Expected numeric, got {type(value)}")
```

## 📐 必須設定

```toml
# pyproject.toml
[tool.mypy]
strict = true
python_version = "3.10"

[tool.ruff]
select = ["E", "F", "UP", "B", "SIM", "I"]
target-version = "py310"
```