---
name: modern-javascript-patterns
description: async/await、分割代入、スプレッド演算子、アロー関数、Promise、モジュール、イテレータ、ジェネレータ、関数型プログラミングパターンなどのES6+機能を習得し、クリーンで効率的なJavaScriptコードを書きます。レガシーコードのリファクタリング、モダンパターンの実装、JavaScriptアプリケーションの最適化時に使用してください。
---

> **[English](../../../../../plugins/javascript-typescript/skills/modern-javascript-patterns/SKILL.md)** | **日本語**

# モダンJavaScriptパターン

モダンJavaScript（ES6+）の機能、関数型プログラミングパターン、クリーンで保守可能で高性能なコードを書くためのベストプラクティスを習得するための包括的なガイド。

## このスキルを使用する場面

- レガシーJavaScriptをモダンな構文にリファクタリング
- 関数型プログラミングパターンの実装
- JavaScriptパフォーマンスの最適化
- 保守可能で読みやすいコードの作成
- 非同期操作の処理
- モダンWebアプリケーションの構築
- コールバックからPromise/async-awaitへの移行
- データ変換パイプラインの実装

## ES6+コア機能

### 1. アロー関数

**構文と使用例:**
```javascript
// 従来の関数
function add(a, b) {
  return a + b;
}

// アロー関数
const add = (a, b) => a + b;

// 単一パラメータ（括弧は省略可能）
const double = x => x * 2;

// パラメータなし
const getRandom = () => Math.random();

// 複数のステートメント（中括弧が必要）
const processUser = user => {
  const normalized = user.name.toLowerCase();
  return { ...user, name: normalized };
};

// オブジェクトを返す（括弧で囲む）
const createUser = (name, age) => ({ name, age });
```

**レキシカルな'this'バインディング:**
```javascript
class Counter {
  constructor() {
    this.count = 0;
  }

  // アロー関数は'this'コンテキストを保持
  increment = () => {
    this.count++;
  };

  // 従来の関数はコールバックで'this'を失う
  incrementTraditional() {
    setTimeout(function() {
      this.count++;  // 'this'はundefined
    }, 1000);
  }

  // アロー関数は'this'を維持
  incrementArrow() {
    setTimeout(() => {
      this.count++;  // 'this'はCounterインスタンスを参照
    }, 1000);
  }
}
```

### 2. 分割代入

**オブジェクトの分割代入:**
```javascript
const user = {
  id: 1,
  name: 'John Doe',
  email: 'john@example.com',
  address: {
    city: 'New York',
    country: 'USA'
  }
};

// 基本的な分割代入
const { name, email } = user;

// 変数名を変更
const { name: userName, email: userEmail } = user;

// デフォルト値
const { age = 25 } = user;

// ネストされた分割代入
const { address: { city, country } } = user;

// rest演算子
const { id, ...userWithoutId } = user;

// 関数パラメータ
function greet({ name, age = 18 }) {
  console.log(`Hello ${name}, you are ${age}`);
}
greet(user);
```

**配列の分割代入:**
```javascript
const numbers = [1, 2, 3, 4, 5];

// 基本的な分割代入
const [first, second] = numbers;

// 要素をスキップ
const [, , third] = numbers;

// rest演算子
const [head, ...tail] = numbers;

// 変数の交換
let a = 1, b = 2;
[a, b] = [b, a];

// 関数の戻り値
function getCoordinates() {
  return [10, 20];
}
const [x, y] = getCoordinates();

// デフォルト値
const [one, two, three = 0] = [1, 2];
```

### 3. スプレッドとrest演算子

**スプレッド演算子:**
```javascript
// 配列のスプレッド
const arr1 = [1, 2, 3];
const arr2 = [4, 5, 6];
const combined = [...arr1, ...arr2];

// オブジェクトのスプレッド
const defaults = { theme: 'dark', lang: 'en' };
const userPrefs = { theme: 'light' };
const settings = { ...defaults, ...userPrefs };

// 関数の引数
const numbers = [1, 2, 3];
Math.max(...numbers);

// 配列/オブジェクトのコピー（シャローコピー）
const copy = [...arr1];
const objCopy = { ...user };

// イミュータブルに項目を追加
const newArr = [...arr1, 4, 5];
const newObj = { ...user, age: 30 };
```

**restパラメータ:**
```javascript
// 関数の引数を収集
function sum(...numbers) {
  return numbers.reduce((total, num) => total + num, 0);
}
sum(1, 2, 3, 4, 5);

// 通常のパラメータと組み合わせ
function greet(greeting, ...names) {
  return `${greeting} ${names.join(', ')}`;
}
greet('Hello', 'John', 'Jane', 'Bob');

// オブジェクトのrest
const { id, ...userData } = user;

// 配列のrest
const [first, ...rest] = [1, 2, 3, 4, 5];
```

### 4. テンプレートリテラル

```javascript
// 基本的な使用
const name = 'John';
const greeting = `Hello, ${name}!`;

// 複数行の文字列
const html = `
  <div>
    <h1>${title}</h1>
    <p>${content}</p>
  </div>
`;

// 式の評価
const price = 19.99;
const total = `Total: $${(price * 1.2).toFixed(2)}`;

// タグ付きテンプレートリテラル
function highlight(strings, ...values) {
  return strings.reduce((result, str, i) => {
    const value = values[i] || '';
    return result + str + `<mark>${value}</mark>`;
  }, '');
}

const name = 'John';
const age = 30;
const html = highlight`Name: ${name}, Age: ${age}`;
// 出力: "Name: <mark>John</mark>, Age: <mark>30</mark>"
```

### 5. 拡張オブジェクトリテラル

```javascript
const name = 'John';
const age = 30;

// プロパティ名の省略記法
const user = { name, age };

// メソッド名の省略記法
const calculator = {
  add(a, b) {
    return a + b;
  },
  subtract(a, b) {
    return a - b;
  }
};

// 計算されたプロパティ名
const field = 'email';
const user = {
  name: 'John',
  [field]: 'john@example.com',
  [`get${field.charAt(0).toUpperCase()}${field.slice(1)}`]() {
    return this[field];
  }
};

// 動的プロパティ作成
const createUser = (name, ...props) => {
  return props.reduce((user, [key, value]) => ({
    ...user,
    [key]: value
  }), { name });
};

const user = createUser('John', ['age', 30], ['email', 'john@example.com']);
```

## 非同期パターン

### 1. Promise

**Promiseの作成と使用:**
```javascript
// Promiseの作成
const fetchUser = (id) => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (id > 0) {
        resolve({ id, name: 'John' });
      } else {
        reject(new Error('Invalid ID'));
      }
    }, 1000);
  });
};

// Promiseの使用
fetchUser(1)
  .then(user => console.log(user))
  .catch(error => console.error(error))
  .finally(() => console.log('Done'));

// Promiseのチェーン
fetchUser(1)
  .then(user => fetchUserPosts(user.id))
  .then(posts => processPosts(posts))
  .then(result => console.log(result))
  .catch(error => console.error(error));
```

**Promise組み合わせ演算子:**
```javascript
// Promise.all - 全てのPromiseを待つ
const promises = [
  fetchUser(1),
  fetchUser(2),
  fetchUser(3)
];

Promise.all(promises)
  .then(users => console.log(users))
  .catch(error => console.error('At least one failed:', error));

// Promise.allSettled - 結果に関係なく全てを待つ
Promise.allSettled(promises)
  .then(results => {
    results.forEach(result => {
      if (result.status === 'fulfilled') {
        console.log('Success:', result.value);
      } else {
        console.log('Error:', result.reason);
      }
    });
  });

// Promise.race - 最初に完了したもの
Promise.race(promises)
  .then(winner => console.log('First:', winner))
  .catch(error => console.error(error));

// Promise.any - 最初に成功したもの
Promise.any(promises)
  .then(first => console.log('First success:', first))
  .catch(error => console.error('All failed:', error));
```

### 2. Async/Await

**基本的な使用:**
```javascript
// async関数は常にPromiseを返す
async function fetchUser(id) {
  const response = await fetch(`/api/users/${id}`);
  const user = await response.json();
  return user;
}

// try/catchによるエラーハンドリング
async function getUserData(id) {
  try {
    const user = await fetchUser(id);
    const posts = await fetchUserPosts(user.id);
    return { user, posts };
  } catch (error) {
    console.error('Error fetching data:', error);
    throw error;
  }
}

// 逐次実行 vs 並列実行
async function sequential() {
  const user1 = await fetchUser(1);  // 待機
  const user2 = await fetchUser(2);  // 次に待機
  return [user1, user2];
}

async function parallel() {
  const [user1, user2] = await Promise.all([
    fetchUser(1),
    fetchUser(2)
  ]);
  return [user1, user2];
}
```

**高度なパターン:**
```javascript
// Async IIFE
(async () => {
  const result = await someAsyncOperation();
  console.log(result);
})();

// 非同期イテレーション
async function processUsers(userIds) {
  for (const id of userIds) {
    const user = await fetchUser(id);
    await processUser(user);
  }
}

// トップレベルawait（ES2022）
const config = await fetch('/config.json').then(r => r.json());

// リトライロジック
async function fetchWithRetry(url, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await fetch(url);
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}

// タイムアウトラッパー
async function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Timeout')), ms)
  );
  return Promise.race([promise, timeout]);
}
```

## 関数型プログラミングパターン

### 1. 配列メソッド

**Map、Filter、Reduce:**
```javascript
const users = [
  { id: 1, name: 'John', age: 30, active: true },
  { id: 2, name: 'Jane', age: 25, active: false },
  { id: 3, name: 'Bob', age: 35, active: true }
];

// Map - 配列を変換
const names = users.map(user => user.name);
const upperNames = users.map(user => user.name.toUpperCase());

// Filter - 要素を選択
const activeUsers = users.filter(user => user.active);
const adults = users.filter(user => user.age >= 18);

// Reduce - データを集計
const totalAge = users.reduce((sum, user) => sum + user.age, 0);
const avgAge = totalAge / users.length;

// プロパティでグループ化
const byActive = users.reduce((groups, user) => {
  const key = user.active ? 'active' : 'inactive';
  return {
    ...groups,
    [key]: [...(groups[key] || []), user]
  };
}, {});

// メソッドのチェーン
const result = users
  .filter(user => user.active)
  .map(user => user.name)
  .sort()
  .join(', ');
```

**高度な配列メソッド:**
```javascript
// Find - 最初にマッチする要素
const user = users.find(u => u.id === 2);

// FindIndex - 最初にマッチするインデックス
const index = users.findIndex(u => u.name === 'Jane');

// Some - 少なくとも1つマッチ
const hasActive = users.some(u => u.active);

// Every - 全てマッチ
const allAdults = users.every(u => u.age >= 18);

// FlatMap - マップとフラット化
const userTags = [
  { name: 'John', tags: ['admin', 'user'] },
  { name: 'Jane', tags: ['user'] }
];
const allTags = userTags.flatMap(u => u.tags);

// From - イテラブルから配列を作成
const str = 'hello';
const chars = Array.from(str);
const numbers = Array.from({ length: 5 }, (_, i) => i + 1);

// Of - 引数から配列を作成
const arr = Array.of(1, 2, 3);
```

### 2. 高階関数

**引数としての関数:**
```javascript
// カスタムforEach
function forEach(array, callback) {
  for (let i = 0; i < array.length; i++) {
    callback(array[i], i, array);
  }
}

// カスタムmap
function map(array, transform) {
  const result = [];
  for (const item of array) {
    result.push(transform(item));
  }
  return result;
}

// カスタムfilter
function filter(array, predicate) {
  const result = [];
  for (const item of array) {
    if (predicate(item)) {
      result.push(item);
    }
  }
  return result;
}
```

**関数を返す関数:**
```javascript
// カリー化
const multiply = a => b => a * b;
const double = multiply(2);
const triple = multiply(3);

console.log(double(5));  // 10
console.log(triple(5));  // 15

// 部分適用
function partial(fn, ...args) {
  return (...moreArgs) => fn(...args, ...moreArgs);
}

const add = (a, b, c) => a + b + c;
const add5 = partial(add, 5);
console.log(add5(3, 2));  // 10

// メモ化
function memoize(fn) {
  const cache = new Map();
  return (...args) => {
    const key = JSON.stringify(args);
    if (cache.has(key)) {
      return cache.get(key);
    }
    const result = fn(...args);
    cache.set(key, result);
    return result;
  };
}

const fibonacci = memoize((n) => {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
});
```

### 3. 合成とパイプ

```javascript
// 関数合成
const compose = (...fns) => x =>
  fns.reduceRight((acc, fn) => fn(acc), x);

const pipe = (...fns) => x =>
  fns.reduce((acc, fn) => fn(acc), x);

// 使用例
const addOne = x => x + 1;
const double = x => x * 2;
const square = x => x * x;

const composed = compose(square, double, addOne);
console.log(composed(3));  // ((3 + 1) * 2)^2 = 64

const piped = pipe(addOne, double, square);
console.log(piped(3));  // ((3 + 1) * 2)^2 = 64

// 実践例
const processUser = pipe(
  user => ({ ...user, name: user.name.trim() }),
  user => ({ ...user, email: user.email.toLowerCase() }),
  user => ({ ...user, age: parseInt(user.age) })
);

const user = processUser({
  name: '  John  ',
  email: 'JOHN@EXAMPLE.COM',
  age: '30'
});
```

### 4. 純粋関数とイミュータビリティ

```javascript
// 不純な関数（入力を変更）
function addItemImpure(cart, item) {
  cart.items.push(item);
  cart.total += item.price;
  return cart;
}

// 純粋関数（副作用なし）
function addItemPure(cart, item) {
  return {
    ...cart,
    items: [...cart.items, item],
    total: cart.total + item.price
  };
}

// イミュータブルな配列操作
const numbers = [1, 2, 3, 4, 5];

// 配列に追加
const withSix = [...numbers, 6];

// 配列から削除
const withoutThree = numbers.filter(n => n !== 3);

// 配列要素を更新
const doubled = numbers.map(n => n === 3 ? n * 2 : n);

// イミュータブルなオブジェクト操作
const user = { name: 'John', age: 30 };

// プロパティを更新
const olderUser = { ...user, age: 31 };

// プロパティを追加
const withEmail = { ...user, email: 'john@example.com' };

// プロパティを削除
const { age, ...withoutAge } = user;

// ディープクローン（シンプルなアプローチ）
const deepClone = obj => JSON.parse(JSON.stringify(obj));

// より良いディープクローン
const structuredClone = obj => globalThis.structuredClone(obj);
```

## モダンクラス機能

```javascript
// クラス構文
class User {
  // プライベートフィールド
  #password;

  // パブリックフィールド
  id;
  name;

  // 静的フィールド
  static count = 0;

  constructor(id, name, password) {
    this.id = id;
    this.name = name;
    this.#password = password;
    User.count++;
  }

  // パブリックメソッド
  greet() {
    return `Hello, ${this.name}`;
  }

  // プライベートメソッド
  #hashPassword(password) {
    return `hashed_${password}`;
  }

  // ゲッター
  get displayName() {
    return this.name.toUpperCase();
  }

  // セッター
  set password(newPassword) {
    this.#password = this.#hashPassword(newPassword);
  }

  // 静的メソッド
  static create(id, name, password) {
    return new User(id, name, password);
  }
}

// 継承
class Admin extends User {
  constructor(id, name, password, role) {
    super(id, name, password);
    this.role = role;
  }

  greet() {
    return `${super.greet()}, I'm an admin`;
  }
}
```

## モジュール（ES6）

```javascript
// エクスポート
// math.js
export const PI = 3.14159;
export function add(a, b) {
  return a + b;
}
export class Calculator {
  // ...
}

// デフォルトエクスポート
export default function multiply(a, b) {
  return a * b;
}

// インポート
// app.js
import multiply, { PI, add, Calculator } from './math.js';

// インポート名を変更
import { add as sum } from './math.js';

// 全てインポート
import * as Math from './math.js';

// 動的インポート
const module = await import('./math.js');
const { add } = await import('./math.js');

// 条件付きロード
if (condition) {
  const module = await import('./feature.js');
  module.init();
}
```

## イテレータとジェネレータ

```javascript
// カスタムイテレータ
const range = {
  from: 1,
  to: 5,

  [Symbol.iterator]() {
    return {
      current: this.from,
      last: this.to,

      next() {
        if (this.current <= this.last) {
          return { done: false, value: this.current++ };
        } else {
          return { done: true };
        }
      }
    };
  }
};

for (const num of range) {
  console.log(num);  // 1, 2, 3, 4, 5
}

// ジェネレータ関数
function* rangeGenerator(from, to) {
  for (let i = from; i <= to; i++) {
    yield i;
  }
}

for (const num of rangeGenerator(1, 5)) {
  console.log(num);
}

// 無限ジェネレータ
function* fibonacci() {
  let [prev, curr] = [0, 1];
  while (true) {
    yield curr;
    [prev, curr] = [curr, prev + curr];
  }
}

// 非同期ジェネレータ
async function* fetchPages(url) {
  let page = 1;
  while (true) {
    const response = await fetch(`${url}?page=${page}`);
    const data = await response.json();
    if (data.length === 0) break;
    yield data;
    page++;
  }
}

for await (const page of fetchPages('/api/users')) {
  console.log(page);
}
```

## モダン演算子

```javascript
// オプショナルチェイニング
const user = { name: 'John', address: { city: 'NYC' } };
const city = user?.address?.city;
const zipCode = user?.address?.zipCode;  // undefined

// 関数呼び出し
const result = obj.method?.();

// 配列アクセス
const first = arr?.[0];

// Null合体演算子
const value = null ?? 'default';      // 'default'
const value = undefined ?? 'default'; // 'default'
const value = 0 ?? 'default';         // 0 ('default'ではない)
const value = '' ?? 'default';        // '' ('default'ではない)

// 論理代入
let a = null;
a ??= 'default';  // a = 'default'

let b = 5;
b ??= 10;  // b = 5（変更なし）

let obj = { count: 0 };
obj.count ||= 1;  // obj.count = 1
obj.count &&= 2;  // obj.count = 2
```

## パフォーマンス最適化

```javascript
// デバウンス
function debounce(fn, delay) {
  let timeoutId;
  return (...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

const searchDebounced = debounce(search, 300);

// スロットル
function throttle(fn, limit) {
  let inThrottle;
  return (...args) => {
    if (!inThrottle) {
      fn(...args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}

const scrollThrottled = throttle(handleScroll, 100);

// 遅延評価
function* lazyMap(iterable, transform) {
  for (const item of iterable) {
    yield transform(item);
  }
}

// 必要なものだけ使用
const numbers = [1, 2, 3, 4, 5];
const doubled = lazyMap(numbers, x => x * 2);
const first = doubled.next().value;  // 最初の値だけ計算
```

## ベストプラクティス

1. **デフォルトでconstを使用**: 再代入が必要な場合のみletを使用
2. **アロー関数を優先**: 特にコールバックで
3. **テンプレートリテラルを使用**: 文字列連結の代わりに
4. **オブジェクトと配列を分割代入**: よりクリーンなコードのため
5. **async/awaitを使用**: Promiseチェーンの代わりに
6. **データの変更を避ける**: スプレッド演算子と配列メソッドを使用
7. **オプショナルチェイニングを使用**: "Cannot read property of undefined"を防ぐ
8. **Null合体演算子を使用**: デフォルト値のため
9. **配列メソッドを優先**: 従来のループよりも
10. **モジュールを使用**: より良いコード構成のため
11. **純粋関数を書く**: テストと推論が容易
12. **意味のある変数名を使用**: 自己文書化コード
13. **関数を小さく保つ**: 単一責任の原則
14. **エラーを適切に処理**: async/awaitでtry/catchを使用
15. **strictモードを使用**: `'use strict'`でより良いエラーキャッチ

## よくある落とし穴

1. **thisバインディングの混乱**: アロー関数またはbind()を使用
2. **エラーハンドリングなしのasync/await**: 常にtry/catchを使用
3. **不要なPromise作成**: すでに非同期の関数をラップしない
4. **オブジェクトの変更**: スプレッド演算子またはObject.assign()を使用
5. **awaitを忘れる**: async関数はPromiseを返す
6. **イベントループのブロック**: 同期操作を避ける
7. **メモリリーク**: イベントリスナーとタイマーをクリーンアップ
8. **Promiseのリジェクションを処理しない**: catch()またはtry/catchを使用

## リソース

- **MDN Web Docs**: https://developer.mozilla.org/en-US/docs/Web/JavaScript
- **JavaScript.info**: https://javascript.info/
- **You Don't Know JS**: https://github.com/getify/You-Dont-Know-JS
- **Eloquent JavaScript**: https://eloquentjavascript.net/
- **ES6 Features**: http://es6-features.org/
