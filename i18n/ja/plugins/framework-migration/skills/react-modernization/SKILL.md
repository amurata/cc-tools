> **[English](../../../../../plugins/framework-migration/skills/react-modernization/SKILL.md)** | **日本語**

---
name: react-modernization
description: Reactアプリケーションを最新バージョンにアップグレードし、クラスコンポーネントからフックへ移行し、並行機能を採用します。Reactコードベースのモダナイゼーション、React Hooksへの移行、または最新Reactバージョンへのアップグレード時に使用します。
---

# Reactモダナイゼーション

Reactバージョンアップグレード、クラスからフックへの移行、並行機能の採用、自動変換のためのcodemodをマスターします。

## このスキルを使用するタイミング

- Reactアプリケーションを最新バージョンにアップグレード
- クラスコンポーネントをフックを使用した関数コンポーネントに移行
- 並行React機能（Suspense、トランジション）を採用
- 自動リファクタリングのためにcodemodを適用
- 状態管理パターンをモダナイズ
- TypeScriptに更新
- React 18+機能でパフォーマンスを改善

## バージョンアップグレードパス

### React 16 → 17 → 18

**バージョン別の破壊的変更:**

**React 17:**
- イベント委譲の変更
- イベントプーリングなし
- エフェクトクリーンアップのタイミング
- JSX変換（Reactインポート不要）

**React 18:**
- 自動バッチング
- 並行レンダリング
- Strict Modeの変更（二重呼び出し）
- 新しいルートAPI
- サーバー上のSuspense

## クラスからフックへの移行

### 状態管理
```javascript
// Before: クラスコンポーネント
class Counter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      count: 0,
      name: ''
    };
  }

  increment = () => {
    this.setState({ count: this.state.count + 1 });
  }

  render() {
    return (
      <div>
        <p>Count: {this.state.count}</p>
        <button onClick={this.increment}>Increment</button>
      </div>
    );
  }
}

// After: フックを使用した関数コンポーネント
function Counter() {
  const [count, setCount] = useState(0);
  const [name, setName] = useState('');

  const increment = () => {
    setCount(count + 1);
  };

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>Increment</button>
    </div>
  );
}
```

### ライフサイクルメソッドからフックへ
```javascript
// Before: ライフサイクルメソッド
class DataFetcher extends React.Component {
  state = { data: null, loading: true };

  componentDidMount() {
    this.fetchData();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.id !== this.props.id) {
      this.fetchData();
    }
  }

  componentWillUnmount() {
    this.cancelRequest();
  }

  fetchData = async () => {
    const data = await fetch(`/api/${this.props.id}`);
    this.setState({ data, loading: false });
  };

  cancelRequest = () => {
    // クリーンアップ
  };

  render() {
    if (this.state.loading) return <div>Loading...</div>;
    return <div>{this.state.data}</div>;
  }
}

// After: useEffectフック
function DataFetcher({ id }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    const fetchData = async () => {
      try {
        const response = await fetch(`/api/${id}`);
        const result = await response.json();

        if (!cancelled) {
          setData(result);
          setLoading(false);
        }
      } catch (error) {
        if (!cancelled) {
          console.error(error);
        }
      }
    };

    fetchData();

    // クリーンアップ関数
    return () => {
      cancelled = true;
    };
  }, [id]); // idが変更されたときに再実行

  if (loading) return <div>Loading...</div>;
  return <div>{data}</div>;
}
```

### ContextとHOCからフックへ
```javascript
// Before: Contextコンシューマーとホック
const ThemeContext = React.createContext();

class ThemedButton extends React.Component {
  static contextType = ThemeContext;

  render() {
    return (
      <button style={{ background: this.context.theme }}>
        {this.props.children}
      </button>
    );
  }
}

// After: useContextフック
function ThemedButton({ children }) {
  const { theme } = useContext(ThemeContext);

  return (
    <button style={{ background: theme }}>
      {children}
    </button>
  );
}

// Before: データフェッチのためのHOC
function withUser(Component) {
  return class extends React.Component {
    state = { user: null };

    componentDidMount() {
      fetchUser().then(user => this.setState({ user }));
    }

    render() {
      return <Component {...this.props} user={this.state.user} />;
    }
  };
}

// After: カスタムフック
function useUser() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    fetchUser().then(setUser);
  }, []);

  return user;
}

function UserProfile() {
  const user = useUser();
  if (!user) return <div>Loading...</div>;
  return <div>{user.name}</div>;
}
```

## React 18並行機能

### 新しいルートAPI
```javascript
// Before: React 17
import ReactDOM from 'react-dom';

ReactDOM.render(<App />, document.getElementById('root'));

// After: React 18
import { createRoot } from 'react-dom/client';

const root = createRoot(document.getElementById('root'));
root.render(<App />);
```

### 自動バッチング
```javascript
// React 18: すべての更新がバッチ処理される
function handleClick() {
  setCount(c => c + 1);
  setFlag(f => !f);
  // 1回だけ再レンダリング（バッチ処理）
}

// 非同期でも:
setTimeout(() => {
  setCount(c => c + 1);
  setFlag(f => !f);
  // React 18でもバッチ処理される！
}, 1000);

// 必要に応じてオプトアウト
import { flushSync } from 'react-dom';

flushSync(() => {
  setCount(c => c + 1);
});
// ここで再レンダリングが発生
setFlag(f => !f);
// 別の再レンダリング
```

### トランジション
```javascript
import { useState, useTransition } from 'react';

function SearchResults() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [isPending, startTransition] = useTransition();

  const handleChange = (e) => {
    // 緊急: 入力を即座に更新
    setQuery(e.target.value);

    // 緊急でない: 結果を更新（中断可能）
    startTransition(() => {
      setResults(searchResults(e.target.value));
    });
  };

  return (
    <>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <Results data={results} />
    </>
  );
}
```

### データフェッチのためのSuspense
```javascript
import { Suspense } from 'react';

// リソースベースのデータフェッチ（React 18で）
const resource = fetchProfileData();

function ProfilePage() {
  return (
    <Suspense fallback={<Loading />}>
      <ProfileDetails />
      <Suspense fallback={<Loading />}>
        <ProfileTimeline />
      </Suspense>
    </Suspense>
  );
}

function ProfileDetails() {
  // データの準備ができていない場合、サスペンドされる
  const user = resource.user.read();
  return <h1>{user.name}</h1>;
}

function ProfileTimeline() {
  const posts = resource.posts.read();
  return <Timeline posts={posts} />;
}
```

## 自動化のためのCodemod

### React Codemodを実行
```bash
# jscodeshiftをインストール
npm install -g jscodeshift

# React 16.9 codemod（unsafe lifecycleメソッドをリネーム）
npx react-codeshift <transform> <path>

# 例: UNSAFE_メソッドをリネーム
npx react-codeshift --parser=tsx \
  --transform=react-codeshift/transforms/rename-unsafe-lifecycles.js \
  src/

# 新しいJSX変換に更新（React 17+）
npx react-codeshift --parser=tsx \
  --transform=react-codeshift/transforms/new-jsx-transform.js \
  src/

# クラスからフックへ（サードパーティ）
npx codemod react/hooks/convert-class-to-function src/
```

### カスタムCodemodの例
```javascript
// custom-codemod.js
module.exports = function(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);

  // setState呼び出しを検索
  root.find(j.CallExpression, {
    callee: {
      type: 'MemberExpression',
      property: { name: 'setState' }
    }
  }).forEach(path => {
    // useStateに変換
    // ... 変換ロジック
  });

  return root.toSource();
};

// 実行: jscodeshift -t custom-codemod.js src/
```

## パフォーマンス最適化

### useMemoとuseCallback
```javascript
function ExpensiveComponent({ items, filter }) {
  // 高価な計算をメモ化
  const filteredItems = useMemo(() => {
    return items.filter(item => item.category === filter);
  }, [items, filter]);

  // 子の再レンダリングを防ぐためにコールバックをメモ化
  const handleClick = useCallback((id) => {
    console.log('Clicked:', id);
  }, []); // 依存関係なし、変更されない

  return (
    <List items={filteredItems} onClick={handleClick} />
  );
}

// memoを使用した子コンポーネント
const List = React.memo(({ items, onClick }) => {
  return items.map(item => (
    <Item key={item.id} item={item} onClick={onClick} />
  ));
});
```

### コード分割
```javascript
import { lazy, Suspense } from 'react';

// コンポーネントを遅延読み込み
const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

## TypeScript移行

```typescript
// Before: JavaScript
function Button({ onClick, children }) {
  return <button onClick={onClick}>{children}</button>;
}

// After: TypeScript
interface ButtonProps {
  onClick: () => void;
  children: React.ReactNode;
}

function Button({ onClick, children }: ButtonProps) {
  return <button onClick={onClick}>{children}</button>;
}

// ジェネリックコンポーネント
interface ListProps<T> {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
}

function List<T>({ items, renderItem }: ListProps<T>) {
  return <>{items.map(renderItem)}</>;
}
```

## 移行チェックリスト

```markdown
### 移行前
- [ ] 依存関係を段階的に更新（すべて一度にではなく）
- [ ] リリースノートの破壊的変更をレビュー
- [ ] テストスイートをセットアップ
- [ ] フィーチャーブランチを作成

### クラス → フック移行
- [ ] 移行するクラスコンポーネントを特定
- [ ] リーフコンポーネント（子なし）から開始
- [ ] 状態をuseStateに変換
- [ ] ライフサイクルをuseEffectに変換
- [ ] contextをuseContextに変換
- [ ] カスタムフックを抽出
- [ ] 徹底的にテスト

### React 18アップグレード
- [ ] まずReact 17に更新（必要に応じて）
- [ ] reactとreact-domを18に更新
- [ ] TypeScript使用時は@types/reactを更新
- [ ] createRoot APIに変更
- [ ] StrictModeでテスト（二重呼び出し）
- [ ] 並行レンダリングの問題に対処
- [ ] 有益な場合はSuspense/Transitionsを採用

### パフォーマンス
- [ ] パフォーマンスボトルネックを特定
- [ ] 適切な箇所にReact.memoを追加
- [ ] 高価な操作にuseMemo/useCallbackを使用
- [ ] コード分割を実装
- [ ] 再レンダリングを最適化

### テスト
- [ ] テストユーティリティを更新（React Testing Library）
- [ ] React 18機能でテスト
- [ ] コンソールの警告を確認
- [ ] パフォーマンステスト
```

## リソース

- **references/breaking-changes.md**: バージョン固有の破壊的変更
- **references/codemods.md**: Codemod使用ガイド
- **references/hooks-migration.md**: 包括的フックパターン
- **references/concurrent-features.md**: React 18並行機能
- **assets/codemod-config.json**: Codemod設定
- **assets/migration-checklist.md**: ステップバイステップチェックリスト
- **scripts/apply-codemods.sh**: 自動化codemodスクリプト

## ベストプラクティス

1. **段階的移行**: すべてを一度に移行しない
2. **徹底的にテスト**: 各ステップで包括的テスト
3. **Codemodを使用**: 繰り返し変換を自動化
4. **シンプルから開始**: リーフコンポーネントから始める
5. **StrictModeを活用**: 早期に問題を検出
6. **パフォーマンスを監視**: 変更前後を測定
7. **変更を文書化**: 移行ログを保持

## 一般的な落とし穴

- useEffect依存関係を忘れる
- useMemo/useCallbackを過度に使用
- useEffectでクリーンアップを処理しない
- クラスと関数パターンを混在させる
- StrictMode警告を無視
- 破壊的変更の仮定
