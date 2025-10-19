# JavaScriptモダン構文

## 分割代入

### オブジェクト分割代入
オブジェクトから値を簡潔に抽出。

```javascript
// 良い例
const { name, age, city = '不明' } = user;

// ネストした分割代入
const { address: { street, zip } } = user;

// 変数名の変更
const { name: userName, age: userAge } = user;

// 悪い例
const name = user.name;
const age = user.age;
const city = user.city || '不明';
```

### 配列分割代入
配列から値を抽出。

```javascript
// 良い例
const [first, second, ...rest] = numbers;

// 要素をスキップ
const [, , third] = numbers;

// 変数の入れ替え
[a, b] = [b, a];

// デフォルト値
const [x = 0, y = 0] = coordinates || [];
```

## スプレッドとレスト

### スプレッド演算子
反復可能オブジェクトを個別の要素に展開。

```javascript
// 良い例 - 配列操作
const combined = [...arr1, ...arr2];
const copy = [...original];
const max = Math.max(...numbers);

// オブジェクト操作
const merged = { ...defaults, ...userConfig };
const clone = { ...original };
const updated = { ...user, name: '新しい名前' };

// 悪い例
const combined = arr1.concat(arr2);
const merged = Object.assign({}, defaults, userConfig);
```

### レストパラメータ
残りの要素を収集。

```javascript
// 良い例
function sum(...numbers) {
  return numbers.reduce((a, b) => a + b, 0);
}

function logInfo(message, ...details) {
  console.log(message);
  details.forEach(detail => console.log('  -', detail));
}

// 悪い例
function sum() {
  return Array.from(arguments).reduce((a, b) => a + b, 0);
}
```

## テンプレートリテラル

### 文字列補間
動的に文字列を構築。

```javascript
// 良い例
const message = `こんにちは、${name}さん！${count}件の新着メッセージがあります。`;

// 複数行文字列
const html = `
  <div class="card">
    <h2>${title}</h2>
    <p>${description}</p>
  </div>
`;

// タグ付きテンプレート
const sql = SQL`SELECT * FROM users WHERE id = ${userId}`;

// 悪い例
const message = 'こんにちは、' + name + 'さん！' + count + '件の新着メッセージがあります。';
```

## アロー関数

### 簡潔な構文
短い関数式。

```javascript
// 良い例
const double = x => x * 2;
const add = (a, b) => a + b;
const getUser = id => ({ id, name: 'ユーザー' });

// オブジェクトの暗黙的リターン
const createUser = (name, age) => ({ name, age });

// 配列メソッドと共に
const squared = numbers.map(n => n ** 2);
const adults = users.filter(user => user.age >= 18);

// 悪い例
const double = function(x) {
  return x * 2;
};
```

## オプショナルチェーンとNull合体演算子

### オプショナルチェーン
ネストしたプロパティに安全にアクセス。

```javascript
// 良い例
const street = user?.address?.street;
const result = obj?.method?.();
const item = arr?.[index];

// デフォルト値と共に
const name = user?.profile?.name ?? '匿名';

// 悪い例
const street = user && user.address && user.address.street;
```

### Null合体演算子
null/undefinedの場合のみデフォルト値を設定。

```javascript
// 良い例
const port = config.port ?? 3000;
const enabled = settings.enabled ?? true;
const count = value ?? 0;

// OR演算子との違い
const value1 = 0 || 5;        // 5 (0はfalsy)
const value2 = 0 ?? 5;        // 0 (0はnull/undefinedではない)
```

## Async/Await

### Promise処理
クリーンな非同期コード。

```javascript
// 良い例
async function fetchUserData(id) {
  try {
    const user = await fetchUser(id);
    const posts = await fetchPosts(user.id);
    return { user, posts };
  } catch (error) {
    console.error('データ取得失敗:', error);
    throw error;
  }
}

// 並列実行
async function fetchAll() {
  const [users, posts, comments] = await Promise.all([
    fetchUsers(),
    fetchPosts(),
    fetchComments()
  ]);
  return { users, posts, comments };
}

// 悪い例 - Promiseチェーン
function fetchUserData(id) {
  return fetchUser(id)
    .then(user => fetchPosts(user.id)
      .then(posts => ({ user, posts })))
    .catch(error => {
      console.error('失敗:', error);
      throw error;
    });
}
```

## ESモジュール

### Import/Export
モダンなモジュール構文 - 常に名前付きエクスポートを使用。

```javascript
// ✅ 良い例 - 名前付きエクスポートのみ
export const API_URL = 'https://api.example.com';
export function fetchData() { /* ... */ }
export class User { /* ... */ }
export class App { /* ... */ }

// ❌ 悪い例 - デフォルトエクスポート（禁止）
// export default class App { /* ... */ }

// 名前付きエクスポートをインポート
import { App } from './App';
import { API_URL, fetchData } from './api';
import * as utils from './utils';

// 動的インポート
const module = await import('./heavy-module');

// クリーンなインポートのためのbarrel exports
export { UserService } from './UserService';
export { AuthService } from './AuthService';
export { validateEmail, validatePhone } from './validators';
```

## Map、Set、WeakMap

### モダンなコレクション
組み込みデータ構造。

```javascript
// Map - 任意のキータイプでのキー値ペア
const map = new Map();
map.set(obj, '値');
map.set('key', 42);
map.has(obj);  // true
map.get(obj);  // '値'

// Set - ユニークな値
const unique = new Set([1, 2, 2, 3, 3]);
console.log([...unique]);  // [1, 2, 3]

// WeakMap - ガベージコレクション可能なキー
const cache = new WeakMap();
cache.set(element, computeExpensive(element));
```

## ProxyとReflect

### メタプログラミング
操作をインターセプトしてカスタマイズ。

```javascript
// リアクティブオブジェクト
const reactive = obj => new Proxy(obj, {
  set(target, key, value) {
    console.log(`${key}を${value}に設定`);
    return Reflect.set(target, key, value);
  },
  get(target, key) {
    console.log(`${key}を取得`);
    return Reflect.get(target, key);
  }
});

const state = reactive({ count: 0 });
state.count++;  // ログ: countを取得、countを1に設定
```

## ベストプラクティスチェックリスト

- [ ] デフォルトでconst、必要時にlet、varは避ける
- [ ] コールバックにはアロー関数を優先
- [ ] 文字列連結にはテンプレートリテラルを使用
- [ ] よりクリーンなコードのため分割代入を適用
- [ ] Object.assign/Array.concatの代わりにスプレッド演算子を使用
- [ ] 安全なプロパティアクセスにはオプショナルチェーンを適用
- [ ] デフォルト値にはNull合体演算子を使用
- [ ] Promiseチェーンよりasync/awaitを優先
- [ ] ESモジュール（import/export）を使用
- [ ] ループより配列メソッド（map、filter、reduce）を適用
- [ ] 反復にはfor...inではなくfor...ofを使用