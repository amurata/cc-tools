---
name: python-performance-optimization
description: cProfile、メモリプロファイラー、パフォーマンスベストプラクティスを使用してPythonコードをプロファイルおよび最適化。低速なPythonコードのデバッグ、ボトルネックの最適化、アプリケーションパフォーマンスの改善時に使用。
---

> **[English](../../../../../../plugins/python-development/skills/python-performance-optimization/SKILL.md)** | **日本語**

# Pythonパフォーマンス最適化

CPUプロファイリング、メモリ最適化、実装のベストプラクティスを含む、より良いパフォーマンスのためにPythonコードをプロファイル、分析、最適化するための包括的なガイド。

## このスキルを使用するタイミング

- Pythonアプリケーションのパフォーマンスボトルネックの特定
- アプリケーションレイテンシとレスポンスタイムの削減
- CPU集約的な操作の最適化
- メモリ消費とメモリリークの削減
- データベースクエリパフォーマンスの改善
- I/O操作の最適化
- データ処理パイプラインの高速化
- 高性能アルゴリズムの実装
- 本番アプリケーションのプロファイリング

## コア概念

### 1. プロファイリングタイプ
- **CPUプロファイリング**: 時間のかかる関数の特定
- **メモリプロファイリング**: メモリ割り当てとリークの追跡
- **行プロファイリング**: 行単位の粒度でプロファイル
- **呼び出しグラフ**: 関数呼び出しの関係を可視化

### 2. パフォーマンスメトリクス
- **実行時間**: 操作にかかる時間
- **メモリ使用量**: ピークおよび平均メモリ消費
- **CPU利用率**: プロセッサ使用パターン
- **I/O待機**: I/O操作に費やされる時間

### 3. 最適化戦略
- **アルゴリズム的**: より良いアルゴリズムとデータ構造
- **実装**: より効率的なコードパターン
- **並列化**: マルチスレッド/プロセシング
- **キャッシング**: 冗長な計算を回避
- **ネイティブ拡張**: クリティカルパス用のC/Rust

## クイックスタート

### 基本的なタイミング

```python
import time

def measure_time():
    """簡単なタイミング測定。"""
    start = time.time()

    # あなたのコードをここに
    result = sum(range(1000000))

    elapsed = time.time() - start
    print(f"Execution time: {elapsed:.4f} seconds")
    return result

# より良い方法: 正確な測定にはtimeitを使用
import timeit

execution_time = timeit.timeit(
    "sum(range(1000000))",
    number=100
)
print(f"Average time: {execution_time/100:.6f} seconds")
```

## プロファイリングツール

### パターン1: cProfile - CPUプロファイリング

```python
import cProfile
import pstats
from pstats import SortKey

def slow_function():
    """プロファイルする関数。"""
    total = 0
    for i in range(1000000):
        total += i
    return total

def another_function():
    """別の関数。"""
    return [i**2 for i in range(100000)]

def main():
    """プロファイルするメイン関数。"""
    result1 = slow_function()
    result2 = another_function()
    return result1, result2

# コードをプロファイル
if __name__ == "__main__":
    profiler = cProfile.Profile()
    profiler.enable()

    main()

    profiler.disable()

    # 統計を表示
    stats = pstats.Stats(profiler)
    stats.sort_stats(SortKey.CUMULATIVE)
    stats.print_stats(10)  # 上位10関数

    # 後で分析するためにファイルに保存
    stats.dump_stats("profile_output.prof")
```

**コマンドラインプロファイリング：**
```bash
# スクリプトをプロファイル
python -m cProfile -o output.prof script.py

# 結果を表示
python -m pstats output.prof
# pstatsで:
# sort cumtime
# stats 10
```

### パターン2: line_profiler - 行単位プロファイリング

```python
# インストール: pip install line-profiler

# @profileデコレータを追加（line_profilerがこれを提供）
@profile
def process_data(data):
    """行プロファイリング付きでデータを処理。"""
    result = []
    for item in data:
        processed = item * 2
        result.append(processed)
    return result

# 実行:
# kernprof -l -v script.py
```

**手動行プロファイリング：**
```python
from line_profiler import LineProfiler

def process_data(data):
    """プロファイルする関数。"""
    result = []
    for item in data:
        processed = item * 2
        result.append(processed)
    return result

if __name__ == "__main__":
    lp = LineProfiler()
    lp.add_function(process_data)

    data = list(range(100000))

    lp_wrapper = lp(process_data)
    lp_wrapper(data)

    lp.print_stats()
```

### パターン3: memory_profiler - メモリ使用量

```python
# インストール: pip install memory-profiler

from memory_profiler import profile

@profile
def memory_intensive():
    """大量のメモリを使用する関数。"""
    # 大きなリストを作成
    big_list = [i for i in range(1000000)]

    # 大きな辞書を作成
    big_dict = {i: i**2 for i in range(100000)}

    # データを処理
    result = sum(big_list)

    return result

if __name__ == "__main__":
    memory_intensive()

# 実行:
# python -m memory_profiler script.py
```

### パターン4: py-spy - 本番プロファイリング

```bash
# インストール: pip install py-spy

# 実行中のPythonプロセスをプロファイル
py-spy top --pid 12345

# flamegraphを生成
py-spy record -o profile.svg --pid 12345

# スクリプトをプロファイル
py-spy record -o profile.svg -- python script.py

# 現在の呼び出しスタックをダンプ
py-spy dump --pid 12345
```

## 最適化パターン

### パターン5: リスト内包表記 vs ループ

```python
import timeit

# 遅い: 従来のループ
def slow_squares(n):
    """ループを使用して平方のリストを作成。"""
    result = []
    for i in range(n):
        result.append(i**2)
    return result

# 速い: リスト内包表記
def fast_squares(n):
    """内包表記を使用して平方のリストを作成。"""
    return [i**2 for i in range(n)]

# ベンチマーク
n = 100000

slow_time = timeit.timeit(lambda: slow_squares(n), number=100)
fast_time = timeit.timeit(lambda: fast_squares(n), number=100)

print(f"Loop: {slow_time:.4f}s")
print(f"Comprehension: {fast_time:.4f}s")
print(f"Speedup: {slow_time/fast_time:.2f}x")

# 単純な操作にはさらに高速: map
def faster_squares(n):
    """さらに良いパフォーマンスのためにmapを使用。"""
    return list(map(lambda x: x**2, range(n)))
```

### パターン6: メモリ用のジェネレータ式

```python
import sys

def list_approach():
    """メモリ集約的なリスト。"""
    data = [i**2 for i in range(1000000)]
    return sum(data)

def generator_approach():
    """メモリ効率的なジェネレータ。"""
    data = (i**2 for i in range(1000000))
    return sum(data)

# メモリ比較
list_data = [i for i in range(1000000)]
gen_data = (i for i in range(1000000))

print(f"List size: {sys.getsizeof(list_data)} bytes")
print(f"Generator size: {sys.getsizeof(gen_data)} bytes")

# ジェネレータはサイズに関係なく一定メモリを使用
```

### パターン7: 文字列連結

```python
import timeit

def slow_concat(items):
    """遅い文字列連結。"""
    result = ""
    for item in items:
        result += str(item)
    return result

def fast_concat(items):
    """joinによる高速文字列連結。"""
    return "".join(str(item) for item in items)

def faster_concat(items):
    """リストでさらに高速。"""
    parts = [str(item) for item in items]
    return "".join(parts)

items = list(range(10000))

# ベンチマーク
slow = timeit.timeit(lambda: slow_concat(items), number=100)
fast = timeit.timeit(lambda: fast_concat(items), number=100)
faster = timeit.timeit(lambda: faster_concat(items), number=100)

print(f"Concatenation (+): {slow:.4f}s")
print(f"Join (generator): {fast:.4f}s")
print(f"Join (list): {faster:.4f}s")
```

### パターン8: 辞書ルックアップ vs リスト検索

```python
import timeit

# テストデータを作成
size = 10000
items = list(range(size))
lookup_dict = {i: i for i in range(size)}

def list_search(items, target):
    """リストでのO(n)検索。"""
    return target in items

def dict_search(lookup_dict, target):
    """辞書でのO(1)検索。"""
    return target in lookup_dict

target = size - 1  # リストの最悪ケース

# ベンチマーク
list_time = timeit.timeit(
    lambda: list_search(items, target),
    number=1000
)
dict_time = timeit.timeit(
    lambda: dict_search(lookup_dict, target),
    number=1000
)

print(f"List search: {list_time:.6f}s")
print(f"Dict search: {dict_time:.6f}s")
print(f"Speedup: {list_time/dict_time:.0f}x")
```

### パターン9: ローカル変数アクセス

```python
import timeit

# グローバル変数（遅い）
GLOBAL_VALUE = 100

def use_global():
    """グローバル変数にアクセス。"""
    total = 0
    for i in range(10000):
        total += GLOBAL_VALUE
    return total

def use_local():
    """ローカル変数を使用。"""
    local_value = 100
    total = 0
    for i in range(10000):
        total += local_value
    return total

# ローカルの方が速い
global_time = timeit.timeit(use_global, number=1000)
local_time = timeit.timeit(use_local, number=1000)

print(f"Global access: {global_time:.4f}s")
print(f"Local access: {local_time:.4f}s")
print(f"Speedup: {global_time/local_time:.2f}x")
```

### パターン10: 関数呼び出しオーバーヘッド

```python
import timeit

def calculate_inline():
    """インライン計算。"""
    total = 0
    for i in range(10000):
        total += i * 2 + 1
    return total

def helper_function(x):
    """ヘルパー関数。"""
    return x * 2 + 1

def calculate_with_function():
    """関数呼び出し付きの計算。"""
    total = 0
    for i in range(10000):
        total += helper_function(i)
    return total

# インラインは呼び出しオーバーヘッドがないため高速
inline_time = timeit.timeit(calculate_inline, number=1000)
function_time = timeit.timeit(calculate_with_function, number=1000)

print(f"Inline: {inline_time:.4f}s")
print(f"Function calls: {function_time:.4f}s")
```

## 高度な最適化

### パターン11: 数値演算のためのNumPy

```python
import timeit
import numpy as np

def python_sum(n):
    """純粋Pythonを使用した合計。"""
    return sum(range(n))

def numpy_sum(n):
    """NumPyを使用した合計。"""
    return np.arange(n).sum()

n = 1000000

python_time = timeit.timeit(lambda: python_sum(n), number=100)
numpy_time = timeit.timeit(lambda: numpy_sum(n), number=100)

print(f"Python: {python_time:.4f}s")
print(f"NumPy: {numpy_time:.4f}s")
print(f"Speedup: {python_time/numpy_time:.2f}x")

# ベクトル化操作
def python_multiply():
    """Pythonでの要素ごとの乗算。"""
    a = list(range(100000))
    b = list(range(100000))
    return [x * y for x, y in zip(a, b)]

def numpy_multiply():
    """NumPyでのベクトル化乗算。"""
    a = np.arange(100000)
    b = np.arange(100000)
    return a * b

py_time = timeit.timeit(python_multiply, number=100)
np_time = timeit.timeit(numpy_multiply, number=100)

print(f"\nPython multiply: {py_time:.4f}s")
print(f"NumPy multiply: {np_time:.4f}s")
print(f"Speedup: {py_time/np_time:.2f}x")
```

### パターン12: functools.lru_cacheによるキャッシング

```python
from functools import lru_cache
import timeit

def fibonacci_slow(n):
    """キャッシングなしの再帰フィボナッチ。"""
    if n < 2:
        return n
    return fibonacci_slow(n-1) + fibonacci_slow(n-2)

@lru_cache(maxsize=None)
def fibonacci_fast(n):
    """キャッシング付きの再帰フィボナッチ。"""
    if n < 2:
        return n
    return fibonacci_fast(n-1) + fibonacci_fast(n-2)

# 再帰アルゴリズムで大幅な高速化
n = 30

slow_time = timeit.timeit(lambda: fibonacci_slow(n), number=1)
fast_time = timeit.timeit(lambda: fibonacci_fast(n), number=1000)

print(f"Without cache (1 run): {slow_time:.4f}s")
print(f"With cache (1000 runs): {fast_time:.4f}s")

# キャッシュ情報
print(f"Cache info: {fibonacci_fast.cache_info()}")
```

### パターン13: メモリ用の__slots__使用

```python
import sys

class RegularClass:
    """__dict__付きの通常のクラス。"""
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

class SlottedClass:
    """メモリ効率のための__slots__付きクラス。"""
    __slots__ = ['x', 'y', 'z']

    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

# メモリ比較
regular = RegularClass(1, 2, 3)
slotted = SlottedClass(1, 2, 3)

print(f"Regular class size: {sys.getsizeof(regular)} bytes")
print(f"Slotted class size: {sys.getsizeof(slotted)} bytes")

# 多数のインスタンスで大幅な節約
regular_objects = [RegularClass(i, i+1, i+2) for i in range(10000)]
slotted_objects = [SlottedClass(i, i+1, i+2) for i in range(10000)]

print(f"\nMemory for 10000 regular objects: ~{sys.getsizeof(regular) * 10000} bytes")
print(f"Memory for 10000 slotted objects: ~{sys.getsizeof(slotted) * 10000} bytes")
```

### パターン14: CPUバウンドタスク用のマルチプロセシング

```python
import multiprocessing as mp
import time

def cpu_intensive_task(n):
    """CPU集約的な計算。"""
    return sum(i**2 for i in range(n))

def sequential_processing():
    """タスクを順次処理。"""
    start = time.time()
    results = [cpu_intensive_task(1000000) for _ in range(4)]
    elapsed = time.time() - start
    return elapsed, results

def parallel_processing():
    """タスクを並列処理。"""
    start = time.time()
    with mp.Pool(processes=4) as pool:
        results = pool.map(cpu_intensive_task, [1000000] * 4)
    elapsed = time.time() - start
    return elapsed, results

if __name__ == "__main__":
    seq_time, seq_results = sequential_processing()
    par_time, par_results = parallel_processing()

    print(f"Sequential: {seq_time:.2f}s")
    print(f"Parallel: {par_time:.2f}s")
    print(f"Speedup: {seq_time/par_time:.2f}x")
```

### パターン15: I/OバウンドタスクのAsyncio

```python
import asyncio
import aiohttp
import time
import requests

urls = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
]

def synchronous_requests():
    """同期HTTPリクエスト。"""
    start = time.time()
    results = []
    for url in urls:
        response = requests.get(url)
        results.append(response.status_code)
    elapsed = time.time() - start
    return elapsed, results

async def async_fetch(session, url):
    """非同期HTTPリクエスト。"""
    async with session.get(url) as response:
        return response.status

async def asynchronous_requests():
    """非同期HTTPリクエスト。"""
    start = time.time()
    async with aiohttp.ClientSession() as session:
        tasks = [async_fetch(session, url) for url in urls]
        results = await asyncio.gather(*tasks)
    elapsed = time.time() - start
    return elapsed, results

# 非同期はI/Oバウンド作業でははるかに高速
sync_time, sync_results = synchronous_requests()
async_time, async_results = asyncio.run(asynchronous_requests())

print(f"Synchronous: {sync_time:.2f}s")
print(f"Asynchronous: {async_time:.2f}s")
print(f"Speedup: {sync_time/async_time:.2f}x")
```

## データベース最適化

### パターン16: バッチデータベース操作

```python
import sqlite3
import time

def create_db():
    """テストデータベースを作成。"""
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
    return conn

def slow_inserts(conn, count):
    """レコードを1つずつ挿入。"""
    start = time.time()
    cursor = conn.cursor()
    for i in range(count):
        cursor.execute("INSERT INTO users (name) VALUES (?)", (f"User {i}",))
        conn.commit()  # 各挿入をコミット
    elapsed = time.time() - start
    return elapsed

def fast_inserts(conn, count):
    """単一コミットでバッチ挿入。"""
    start = time.time()
    cursor = conn.cursor()
    data = [(f"User {i}",) for i in range(count)]
    cursor.executemany("INSERT INTO users (name) VALUES (?)", data)
    conn.commit()  # 単一コミット
    elapsed = time.time() - start
    return elapsed

# ベンチマーク
conn1 = create_db()
slow_time = slow_inserts(conn1, 1000)

conn2 = create_db()
fast_time = fast_inserts(conn2, 1000)

print(f"Individual inserts: {slow_time:.4f}s")
print(f"Batch insert: {fast_time:.4f}s")
print(f"Speedup: {slow_time/fast_time:.2f}x")
```

### パターン17: クエリ最適化

```python
# 頻繁にクエリされる列にインデックスを使用
"""
-- 遅い: インデックスなし
SELECT * FROM users WHERE email = 'user@example.com';

-- 速い: インデックス付き
CREATE INDEX idx_users_email ON users(email);
SELECT * FROM users WHERE email = 'user@example.com';
"""

# クエリ計画を使用
import sqlite3

conn = sqlite3.connect("example.db")
cursor = conn.cursor()

# クエリパフォーマンスを分析
cursor.execute("EXPLAIN QUERY PLAN SELECT * FROM users WHERE email = ?", ("test@example.com",))
print(cursor.fetchall())

# 必要な列のみをSELECT
# 遅い: SELECT *
# 速い: SELECT id, name
```

## メモリ最適化

### パターン18: メモリリークの検出

```python
import tracemalloc
import gc

def memory_leak_example():
    """メモリをリークする例。"""
    leaked_objects = []

    for i in range(100000):
        # 追加されるが削除されないオブジェクト
        leaked_objects.append([i] * 100)

    # 実際のコードでは、これは意図しない参照になる

def track_memory_usage():
    """メモリ割り当てを追跡。"""
    tracemalloc.start()

    # 前のスナップショットを取得
    snapshot1 = tracemalloc.take_snapshot()

    # コードを実行
    memory_leak_example()

    # 後のスナップショットを取得
    snapshot2 = tracemalloc.take_snapshot()

    # 比較
    top_stats = snapshot2.compare_to(snapshot1, 'lineno')

    print("Top 10 memory allocations:")
    for stat in top_stats[:10]:
        print(stat)

    tracemalloc.stop()

# メモリを監視
track_memory_usage()

# ガベージコレクションを強制
gc.collect()
```

### パターン19: イテレータ vs リスト

```python
import sys

def process_file_list(filename):
    """ファイル全体をメモリにロード。"""
    with open(filename) as f:
        lines = f.readlines()  # すべての行をロード
        return sum(1 for line in lines if line.strip())

def process_file_iterator(filename):
    """ファイルを行ごとに処理。"""
    with open(filename) as f:
        return sum(1 for line in f if line.strip())

# イテレータは一定メモリを使用
# リストはファイル全体をメモリにロード
```

### パターン20: キャッシュのためのWeakref

```python
import weakref

class CachedResource:
    """ガベージコレクション可能なリソース。"""
    def __init__(self, data):
        self.data = data

# 通常のキャッシュはガベージコレクションを防ぐ
regular_cache = {}

def get_resource_regular(key):
    """通常のキャッシュからリソースを取得。"""
    if key not in regular_cache:
        regular_cache[key] = CachedResource(f"Data for {key}")
    return regular_cache[key]

# 弱参照キャッシュはガベージコレクションを許可
weak_cache = weakref.WeakValueDictionary()

def get_resource_weak(key):
    """弱参照キャッシュからリソースを取得。"""
    resource = weak_cache.get(key)
    if resource is None:
        resource = CachedResource(f"Data for {key}")
        weak_cache[key] = resource
    return resource

# 強参照が存在しない場合、オブジェクトはGCされる
```

## ベンチマークツール

### カスタムベンチマークデコレータ

```python
import time
from functools import wraps

def benchmark(func):
    """関数実行をベンチマークするデコレータ。"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.6f} seconds")
        return result
    return wrapper

@benchmark
def slow_function():
    """ベンチマークする関数。"""
    time.sleep(0.5)
    return sum(range(1000000))

result = slow_function()
```

### pytest-benchmarkによるパフォーマンステスト

```python
# インストール: pip install pytest-benchmark

def test_list_comprehension(benchmark):
    """リスト内包表記をベンチマーク。"""
    result = benchmark(lambda: [i**2 for i in range(10000)])
    assert len(result) == 10000

def test_map_function(benchmark):
    """map関数をベンチマーク。"""
    result = benchmark(lambda: list(map(lambda x: x**2, range(10000))))
    assert len(result) == 10000

# 実行: pytest test_performance.py --benchmark-compare
```

## ベストプラクティス

1. **最適化前にプロファイル** - 実際のボトルネックを見つけるために測定
2. **ホットパスに焦点** - 最も頻繁に実行されるコードを最適化
3. **適切なデータ構造を使用** - ルックアップには辞書、メンバーシップにはセット
4. **時期尚早な最適化を避ける** - まず明確さ、次に最適化
5. **組み込み関数を使用** - Cで実装されている
6. **高価な計算をキャッシュ** - lru_cacheを使用
7. **I/O操作をバッチ化** - システムコールを削減
8. **大規模データセットにジェネレータを使用**
9. **数値演算にNumPyを検討**
10. **本番コードをプロファイル** - ライブシステムにpy-spyを使用

## よくある落とし穴

- プロファイルせずに最適化
- グローバル変数を不必要に使用
- 適切なデータ構造を使用しない
- データの不要なコピーを作成
- データベースの接続プーリングを使用しない
- アルゴリズムの複雑性を無視
- まれなコードパスを過度に最適化
- メモリ使用量を考慮しない

## リソース

- **cProfile**: 組み込みCPUプロファイラー
- **memory_profiler**: メモリ使用量プロファイリング
- **line_profiler**: 行単位プロファイリング
- **py-spy**: 本番用サンプリングプロファイラー
- **NumPy**: 高性能数値計算
- **Cython**: PythonをCにコンパイル
- **PyPy**: JIT付き代替Pythonインタープリタ

## パフォーマンスチェックリスト

- [ ] ボトルネックを特定するためにコードをプロファイル
- [ ] 適切なデータ構造を使用
- [ ] 有益な場所でキャッシングを実装
- [ ] データベースクエリを最適化
- [ ] 大規模データセットにジェネレータを使用
- [ ] CPUバウンドタスクにマルチプロセシングを検討
- [ ] I/OバウンドタスクにAsyncioを使用
- [ ] ホットループでの関数呼び出しオーバーヘッドを最小化
- [ ] メモリリークをチェック
- [ ] 最適化前後でベンチマーク
