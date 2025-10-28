---
name: async-python-patterns
description: Python asyncio、並行プログラミング、高性能アプリケーション向けの非同期/awaitパターンをマスター。非同期API、並行システム、ノンブロッキング操作が必要なI/OバウンドアプリケーションをPythonで構築する際に使用。
---

> **[English](../../../../../../plugins/python-development/skills/async-python-patterns/SKILL.md)** | **日本語**

# 非同期Pythonパターン

asyncio、並行プログラミングパターン、および非同期/awaitを使用した非同期Pythonアプリケーションの実装に関する包括的なガイド。高性能でノンブロッキングなシステムを構築します。

## このスキルを使用するタイミング

- 非同期WebAPI（FastAPI、aiohttp、Sanic）の構築
- 並行I/O操作（データベース、ファイル、ネットワーク）の実装
- 並行リクエストを使用したWebスクレイパーの作成
- リアルタイムアプリケーション（WebSocketサーバー、チャットシステム）の開発
- 複数の独立したタスクの同時処理
- 非同期通信を使用したマイクロサービスの構築
- I/Oバウンドワークロードの最適化
- 非同期バックグラウンドタスクとキューの実装

## コア概念

### 1. イベントループ
イベントループはasyncioの中心であり、非同期タスクを管理およびスケジュールします。

**主な特徴：**
- シングルスレッド協調マルチタスキング
- 実行のためのコルーチンをスケジュール
- ブロックせずにI/O操作を処理
- コールバックとfutureを管理

### 2. コルーチン
`async def`で定義され、一時停止および再開できる関数。

**構文：**
```python
async def my_coroutine():
    result = await some_async_operation()
    return result
```

### 3. タスク
イベントループで並行して実行されるようにスケジュールされたコルーチン。

### 4. Future
非同期操作の最終的な結果を表す低レベルオブジェクト。

### 5. 非同期コンテキストマネージャー
適切なクリーンアップのために`async with`をサポートするリソース。

### 6. 非同期イテレータ
非同期データソースを反復するための`async for`をサポートするオブジェクト。

## クイックスタート

```python
import asyncio

async def main():
    print("Hello")
    await asyncio.sleep(1)
    print("World")

# Python 3.7+
asyncio.run(main())
```

## 基本パターン

### パターン1: 基本的な非同期/Await

```python
import asyncio

async def fetch_data(url: str) -> dict:
    """URLから非同期にデータを取得。"""
    await asyncio.sleep(1)  # I/Oをシミュレート
    return {"url": url, "data": "result"}

async def main():
    result = await fetch_data("https://api.example.com")
    print(result)

asyncio.run(main())
```

### パターン2: gather()による並行実行

```python
import asyncio
from typing import List

async def fetch_user(user_id: int) -> dict:
    """ユーザーデータを取得。"""
    await asyncio.sleep(0.5)
    return {"id": user_id, "name": f"User {user_id}"}

async def fetch_all_users(user_ids: List[int]) -> List[dict]:
    """複数のユーザーを並行して取得。"""
    tasks = [fetch_user(uid) for uid in user_ids]
    results = await asyncio.gather(*tasks)
    return results

async def main():
    user_ids = [1, 2, 3, 4, 5]
    users = await fetch_all_users(user_ids)
    print(f"Fetched {len(users)} users")

asyncio.run(main())
```

### パターン3: タスク作成と管理

```python
import asyncio

async def background_task(name: str, delay: int):
    """長時間実行されるバックグラウンドタスク。"""
    print(f"{name} started")
    await asyncio.sleep(delay)
    print(f"{name} completed")
    return f"Result from {name}"

async def main():
    # タスクを作成
    task1 = asyncio.create_task(background_task("Task 1", 2))
    task2 = asyncio.create_task(background_task("Task 2", 1))

    # 他の作業を行う
    print("Main: doing other work")
    await asyncio.sleep(0.5)

    # タスクを待つ
    result1 = await task1
    result2 = await task2

    print(f"Results: {result1}, {result2}")

asyncio.run(main())
```

### パターン4: 非同期コードでのエラー処理

```python
import asyncio
from typing import List, Optional

async def risky_operation(item_id: int) -> dict:
    """失敗する可能性のある操作。"""
    await asyncio.sleep(0.1)
    if item_id % 3 == 0:
        raise ValueError(f"Item {item_id} failed")
    return {"id": item_id, "status": "success"}

async def safe_operation(item_id: int) -> Optional[dict]:
    """エラー処理付きのラッパー。"""
    try:
        return await risky_operation(item_id)
    except ValueError as e:
        print(f"Error: {e}")
        return None

async def process_items(item_ids: List[int]):
    """エラー処理を含む複数アイテムの処理。"""
    tasks = [safe_operation(iid) for iid in item_ids]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # 失敗をフィルタリング
    successful = [r for r in results if r is not None and not isinstance(r, Exception)]
    failed = [r for r in results if isinstance(r, Exception)]

    print(f"Success: {len(successful)}, Failed: {len(failed)}")
    return successful

asyncio.run(process_items([1, 2, 3, 4, 5, 6]))
```

### パターン5: タイムアウト処理

```python
import asyncio

async def slow_operation(delay: int) -> str:
    """時間がかかる操作。"""
    await asyncio.sleep(delay)
    return f"Completed after {delay}s"

async def with_timeout():
    """タイムアウト付きで操作を実行。"""
    try:
        result = await asyncio.wait_for(slow_operation(5), timeout=2.0)
        print(result)
    except asyncio.TimeoutError:
        print("Operation timed out")

asyncio.run(with_timeout())
```

## 高度なパターン

### パターン6: 非同期コンテキストマネージャー

```python
import asyncio
from typing import Optional

class AsyncDatabaseConnection:
    """非同期データベース接続コンテキストマネージャー。"""

    def __init__(self, dsn: str):
        self.dsn = dsn
        self.connection: Optional[object] = None

    async def __aenter__(self):
        print("Opening connection")
        await asyncio.sleep(0.1)  # 接続をシミュレート
        self.connection = {"dsn": self.dsn, "connected": True}
        return self.connection

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        print("Closing connection")
        await asyncio.sleep(0.1)  # クリーンアップをシミュレート
        self.connection = None

async def query_database():
    """非同期コンテキストマネージャーを使用。"""
    async with AsyncDatabaseConnection("postgresql://localhost") as conn:
        print(f"Using connection: {conn}")
        await asyncio.sleep(0.2)  # クエリをシミュレート
        return {"rows": 10}

asyncio.run(query_database())
```

### パターン7: 非同期イテレータとジェネレータ

```python
import asyncio
from typing import AsyncIterator

async def async_range(start: int, end: int, delay: float = 0.1) -> AsyncIterator[int]:
    """遅延を伴って数値を生成する非同期ジェネレータ。"""
    for i in range(start, end):
        await asyncio.sleep(delay)
        yield i

async def fetch_pages(url: str, max_pages: int) -> AsyncIterator[dict]:
    """ページネーションされたデータを非同期に取得。"""
    for page in range(1, max_pages + 1):
        await asyncio.sleep(0.2)  # API呼び出しをシミュレート
        yield {
            "page": page,
            "url": f"{url}?page={page}",
            "data": [f"item_{page}_{i}" for i in range(5)]
        }

async def consume_async_iterator():
    """非同期イテレータを消費。"""
    async for number in async_range(1, 5):
        print(f"Number: {number}")

    print("\nFetching pages:")
    async for page_data in fetch_pages("https://api.example.com/items", 3):
        print(f"Page {page_data['page']}: {len(page_data['data'])} items")

asyncio.run(consume_async_iterator())
```

### パターン8: プロデューサー・コンシューマーパターン

```python
import asyncio
from asyncio import Queue
from typing import Optional

async def producer(queue: Queue, producer_id: int, num_items: int):
    """アイテムを生成してキューに入れる。"""
    for i in range(num_items):
        item = f"Item-{producer_id}-{i}"
        await queue.put(item)
        print(f"Producer {producer_id} produced: {item}")
        await asyncio.sleep(0.1)
    await queue.put(None)  # 完了シグナル

async def consumer(queue: Queue, consumer_id: int):
    """キューからアイテムを消費。"""
    while True:
        item = await queue.get()
        if item is None:
            queue.task_done()
            break

        print(f"Consumer {consumer_id} processing: {item}")
        await asyncio.sleep(0.2)  # 作業をシミュレート
        queue.task_done()

async def producer_consumer_example():
    """プロデューサー・コンシューマーパターンを実行。"""
    queue = Queue(maxsize=10)

    # タスクを作成
    producers = [
        asyncio.create_task(producer(queue, i, 5))
        for i in range(2)
    ]

    consumers = [
        asyncio.create_task(consumer(queue, i))
        for i in range(3)
    ]

    # プロデューサーを待つ
    await asyncio.gather(*producers)

    # キューが空になるのを待つ
    await queue.join()

    # コンシューマーをキャンセル
    for c in consumers:
        c.cancel()

asyncio.run(producer_consumer_example())
```

### パターン9: レート制限用のセマフォ

```python
import asyncio
from typing import List

async def api_call(url: str, semaphore: asyncio.Semaphore) -> dict:
    """レート制限付きでAPI呼び出しを行う。"""
    async with semaphore:
        print(f"Calling {url}")
        await asyncio.sleep(0.5)  # API呼び出しをシミュレート
        return {"url": url, "status": 200}

async def rate_limited_requests(urls: List[str], max_concurrent: int = 5):
    """レート制限付きで複数のリクエストを行う。"""
    semaphore = asyncio.Semaphore(max_concurrent)
    tasks = [api_call(url, semaphore) for url in urls]
    results = await asyncio.gather(*tasks)
    return results

async def main():
    urls = [f"https://api.example.com/item/{i}" for i in range(20)]
    results = await rate_limited_requests(urls, max_concurrent=3)
    print(f"Completed {len(results)} requests")

asyncio.run(main())
```

### パターン10: 非同期ロックと同期

```python
import asyncio

class AsyncCounter:
    """スレッドセーフな非同期カウンター。"""

    def __init__(self):
        self.value = 0
        self.lock = asyncio.Lock()

    async def increment(self):
        """カウンターを安全にインクリメント。"""
        async with self.lock:
            current = self.value
            await asyncio.sleep(0.01)  # 作業をシミュレート
            self.value = current + 1

    async def get_value(self) -> int:
        """現在の値を取得。"""
        async with self.lock:
            return self.value

async def worker(counter: AsyncCounter, worker_id: int):
    """カウンターをインクリメントするワーカー。"""
    for _ in range(10):
        await counter.increment()
        print(f"Worker {worker_id} incremented")

async def test_counter():
    """並行カウンターをテスト。"""
    counter = AsyncCounter()

    workers = [asyncio.create_task(worker(counter, i)) for i in range(5)]
    await asyncio.gather(*workers)

    final_value = await counter.get_value()
    print(f"Final counter value: {final_value}")

asyncio.run(test_counter())
```

## 実世界のアプリケーション

### aiohttpによるWebスクレイピング

```python
import asyncio
import aiohttp
from typing import List, Dict

async def fetch_url(session: aiohttp.ClientSession, url: str) -> Dict:
    """単一のURLを取得。"""
    try:
        async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as response:
            text = await response.text()
            return {
                "url": url,
                "status": response.status,
                "length": len(text)
            }
    except Exception as e:
        return {"url": url, "error": str(e)}

async def scrape_urls(urls: List[str]) -> List[Dict]:
    """複数のURLを並行してスクレイピング。"""
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        results = await asyncio.gather(*tasks)
        return results

async def main():
    urls = [
        "https://httpbin.org/delay/1",
        "https://httpbin.org/delay/2",
        "https://httpbin.org/status/404",
    ]

    results = await scrape_urls(urls)
    for result in results:
        print(result)

asyncio.run(main())
```

### 非同期データベース操作

```python
import asyncio
from typing import List, Optional

# シミュレートされた非同期データベースクライアント
class AsyncDB:
    """シミュレートされた非同期データベース。"""

    async def execute(self, query: str) -> List[dict]:
        """クエリを実行。"""
        await asyncio.sleep(0.1)
        return [{"id": 1, "name": "Example"}]

    async def fetch_one(self, query: str) -> Optional[dict]:
        """単一の行を取得。"""
        await asyncio.sleep(0.1)
        return {"id": 1, "name": "Example"}

async def get_user_data(db: AsyncDB, user_id: int) -> dict:
    """ユーザーと関連データを並行して取得。"""
    user_task = db.fetch_one(f"SELECT * FROM users WHERE id = {user_id}")
    orders_task = db.execute(f"SELECT * FROM orders WHERE user_id = {user_id}")
    profile_task = db.fetch_one(f"SELECT * FROM profiles WHERE user_id = {user_id}")

    user, orders, profile = await asyncio.gather(user_task, orders_task, profile_task)

    return {
        "user": user,
        "orders": orders,
        "profile": profile
    }

async def main():
    db = AsyncDB()
    user_data = await get_user_data(db, 1)
    print(user_data)

asyncio.run(main())
```

### WebSocketサーバー

```python
import asyncio
from typing import Set

# シミュレートされたWebSocket接続
class WebSocket:
    """シミュレートされたWebSocket。"""

    def __init__(self, client_id: str):
        self.client_id = client_id

    async def send(self, message: str):
        """メッセージを送信。"""
        print(f"Sending to {self.client_id}: {message}")
        await asyncio.sleep(0.01)

    async def recv(self) -> str:
        """メッセージを受信。"""
        await asyncio.sleep(1)
        return f"Message from {self.client_id}"

class WebSocketServer:
    """シンプルなWebSocketサーバー。"""

    def __init__(self):
        self.clients: Set[WebSocket] = set()

    async def register(self, websocket: WebSocket):
        """新しいクライアントを登録。"""
        self.clients.add(websocket)
        print(f"Client {websocket.client_id} connected")

    async def unregister(self, websocket: WebSocket):
        """クライアントの登録を解除。"""
        self.clients.remove(websocket)
        print(f"Client {websocket.client_id} disconnected")

    async def broadcast(self, message: str):
        """すべてのクライアントにメッセージをブロードキャスト。"""
        if self.clients:
            tasks = [client.send(message) for client in self.clients]
            await asyncio.gather(*tasks)

    async def handle_client(self, websocket: WebSocket):
        """個別のクライアント接続を処理。"""
        await self.register(websocket)
        try:
            async for message in self.message_iterator(websocket):
                await self.broadcast(f"{websocket.client_id}: {message}")
        finally:
            await self.unregister(websocket)

    async def message_iterator(self, websocket: WebSocket):
        """クライアントからのメッセージを反復。"""
        for _ in range(3):  # 3つのメッセージをシミュレート
            yield await websocket.recv()
```

## パフォーマンスベストプラクティス

### 1. 接続プールを使用

```python
import asyncio
import aiohttp

async def with_connection_pool():
    """効率性のために接続プールを使用。"""
    connector = aiohttp.TCPConnector(limit=100, limit_per_host=10)

    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = [session.get(f"https://api.example.com/item/{i}") for i in range(50)]
        responses = await asyncio.gather(*tasks)
        return responses
```

### 2. バッチ操作

```python
async def batch_process(items: List[str], batch_size: int = 10):
    """アイテムをバッチで処理。"""
    for i in range(0, len(items), batch_size):
        batch = items[i:i + batch_size]
        tasks = [process_item(item) for item in batch]
        await asyncio.gather(*tasks)
        print(f"Processed batch {i // batch_size + 1}")

async def process_item(item: str):
    """単一アイテムを処理。"""
    await asyncio.sleep(0.1)
    return f"Processed: {item}"
```

### 3. ブロッキング操作を避ける

```python
import asyncio
import concurrent.futures
from typing import Any

def blocking_operation(data: Any) -> Any:
    """CPU集約的なブロッキング操作。"""
    import time
    time.sleep(1)
    return data * 2

async def run_in_executor(data: Any) -> Any:
    """スレッドプールでブロッキング操作を実行。"""
    loop = asyncio.get_event_loop()
    with concurrent.futures.ThreadPoolExecutor() as pool:
        result = await loop.run_in_executor(pool, blocking_operation, data)
        return result

async def main():
    results = await asyncio.gather(*[run_in_executor(i) for i in range(5)])
    print(results)

asyncio.run(main())
```

## よくある落とし穴

### 1. awaitを忘れる

```python
# 間違い - コルーチンオブジェクトを返し、実行されない
result = async_function()

# 正しい
result = await async_function()
```

### 2. イベントループをブロックする

```python
# 間違い - イベントループをブロック
import time
async def bad():
    time.sleep(1)  # ブロック！

# 正しい
async def good():
    await asyncio.sleep(1)  # ノンブロッキング
```

### 3. キャンセルを処理しない

```python
async def cancelable_task():
    """キャンセルを処理するタスク。"""
    try:
        while True:
            await asyncio.sleep(1)
            print("Working...")
    except asyncio.CancelledError:
        print("Task cancelled, cleaning up...")
        # クリーンアップを実行
        raise  # キャンセルを伝播するために再raise
```

### 4. 同期と非同期コードを混ぜる

```python
# 間違い - 同期から非同期を直接呼び出せない
def sync_function():
    result = await async_function()  # SyntaxError!

# 正しい
def sync_function():
    result = asyncio.run(async_function())
```

## 非同期コードのテスト

```python
import asyncio
import pytest

# pytest-asyncioを使用
@pytest.mark.asyncio
async def test_async_function():
    """非同期関数をテスト。"""
    result = await fetch_data("https://api.example.com")
    assert result is not None

@pytest.mark.asyncio
async def test_with_timeout():
    """タイムアウト付きでテスト。"""
    with pytest.raises(asyncio.TimeoutError):
        await asyncio.wait_for(slow_operation(5), timeout=1.0)
```

## リソース

- **Python asyncioドキュメント**: https://docs.python.org/3/library/asyncio.html
- **aiohttp**: 非同期HTTP クライアント/サーバー
- **FastAPI**: モダンな非同期Webフレームワーク
- **asyncpg**: 非同期PostgreSQLドライバー
- **motor**: 非同期MongoDBドライバー

## ベストプラクティス概要

1. **エントリポイントにはasyncio.run()を使用**（Python 3.7+）
2. **常にコルーチンをawait**して実行
3. **複数タスクの並行実行にgather()を使用**
4. **try/exceptで適切なエラー処理を実装**
5. **ハングする操作を防ぐためにタイムアウトを使用**
6. **より良いパフォーマンスのために接続をプール**
7. **非同期コードでブロッキング操作を避ける**
8. **レート制限にセマフォを使用**
9. **タスクキャンセルを適切に処理**
10. **pytest-asyncioで非同期コードをテスト**
