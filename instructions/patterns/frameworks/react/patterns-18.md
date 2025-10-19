# React 18パターン

React 18の並行機能とサーバーコンポーネントを活用したモダンパターン（React 18専用）。

## React 18 並行機能

### useTransition - 緊急でない更新
状態更新を緊急でないものとしてマークしてUIの応答性を保つ。

```jsx
const SearchComponent = () => {
  const [isPending, startTransition] = useTransition();
  const [searchResults, setSearchResults] = useState<User[]>([]);
  const [query, setQuery] = useState('');
  
  const handleSearch = (newQuery: string) => {
    setQuery(newQuery); // 緊急更新
    startTransition(() => {
      // 緊急でない更新 - UIをブロックしない
      setSearchResults(performHeavySearch(newQuery));
    });
  };
  
  return (
    <div>
      <input value={query} onChange={e => handleSearch(e.target.value)} />
      {isPending ? <Spinner /> : <Results data={searchResults} />}
    </div>
  );
};
```

### useDeferredValue - 遅延更新
より緊急な更新が完了するまで重要でない更新を遅延。

```jsx
const SearchResults = () => {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query);
  const results = useMemo(() => 
    searchDatabase(deferredQuery), [deferredQuery]
  );
  
  return (
    <div>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <div className={query !== deferredQuery ? 'dimmed' : ''}>
        {results.map(item => <Item key={item.id} {...item} />)}
      </div>
    </div>
  );
};
```

### 拡張Suspense - データフェッチング
より良いUXのため並行機能と組み合わせてSuspenseを使用。

```jsx
const UserProfile = ({ userId }: { userId: string }) => {
  return (
    <Suspense fallback={<ProfileSkeleton />}>
      <UserData userId={userId} />
      <Suspense fallback={<PostsSkeleton />}>
        <UserPosts userId={userId} />
      </Suspense>
    </Suspense>
  );
};

// ストリーミングSSRコンポーネント
const StreamingApp = () => {
  return (
    <html>
      <body>
        <Header />
        <Suspense fallback={<MainSkeleton />}>
          <MainContent />
        </Suspense>
        <Footer />
      </body>
    </html>
  );
};
```

## サーバーコンポーネント（Next.js 13+）

### サーバー vs クライアントコンポーネント
サーバーとクライアントレンダリングの明確な分離。

```jsx
// サーバーコンポーネント（'use client'なし）
const HomePage = async () => {
  const posts = await fetchPosts(); // 直接DB/API呼び出し
  
  return (
    <div>
      <h1>投稿</h1>
      {posts.map(post => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
};

// インタラクティブ機能のクライアントコンポーネント
'use client';
const InteractiveButton = ({ children }: { children: React.ReactNode }) => {
  const [count, setCount] = useState(0);
  
  return (
    <button onClick={() => setCount(c => c + 1)}>
      {children} ({count})
    </button>
  );
};
```

## モダン状態管理（React 18）

### useId - 安定ID
アクセシビリティのための安定したユニークIDを生成。

```jsx
const ContactForm = () => {
  const nameId = useId();
  const emailId = useId();
  
  return (
    <form>
      <label htmlFor={nameId}>名前</label>
      <input id={nameId} name="name" />
      
      <label htmlFor={emailId}>メール</label>
      <input id={emailId} name="email" type="email" />
    </form>
  );
};
```

### useSyncExternalStore - 外部状態
外部ストアと安全に同期。

```jsx
const useOnlineStatus = () => {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('online', callback);
      window.addEventListener('offline', callback);
      return () => {
        window.removeEventListener('online', callback);
        window.removeEventListener('offline', callback);
      };
    },
    () => navigator.onLine,
    () => true // サーバーサイドフォールバック
  );
};

const NetworkStatus = () => {
  const isOnline = useOnlineStatus();
  return <div>状態: {isOnline ? 'オンライン' : 'オフライン'}</div>;
};
```

## 複合コンポーネントパターン

### TypeScript複合コンポーネント
型安全な複合コンポーネントパターン。

```jsx
interface ToggleContextType {
  on: boolean;
  toggle: () => void;
}

const ToggleContext = createContext<ToggleContextType | null>(null);

const useToggle = () => {
  const context = useContext(ToggleContext);
  if (!context) {
    throw new Error('Toggleコンポーネントは Toggle 内で使用してください');
  }
  return context;
};

interface ToggleProps {
  children: React.ReactNode;
  defaultOn?: boolean;
}

export const Toggle = ({ children, defaultOn = false }: ToggleProps) => {
  const [on, setOn] = useState(defaultOn);
  const toggle = useCallback(() => setOn(prev => !prev), []);
  
  return (
    <ToggleContext.Provider value={{ on, toggle }}>
      {children}
    </ToggleContext.Provider>
  );
};

Toggle.Button = () => {
  const { on, toggle } = useToggle();
  return (
    <button onClick={toggle} aria-pressed={on}>
      {on ? 'オン' : 'オフ'}
    </button>
  );
};

Toggle.Display = () => {
  const { on } = useToggle();
  return <div>状態: {on ? 'アクティブ' : '非アクティブ'}</div>;
};
```

## パフォーマンス最適化

### React.memo with カスタム比較
カスタム比較で再レンダリングを最適化。

```jsx
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

export const UserCard = memo<UserCardProps>(({ user, onEdit }) => {
  return (
    <div>
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      <button onClick={() => onEdit(user.id)}>編集</button>
    </div>
  );
}, (prevProps, nextProps) => {
  return (
    prevProps.user.id === nextProps.user.id &&
    prevProps.user.name === nextProps.user.name &&
    prevProps.onEdit === nextProps.onEdit
  );
});

const UserList = ({ users }: { users: User[] }) => {
  const handleEdit = useCallback((id: string) => {
    // 編集ロジック
  }, []);
  
  return (
    <div>
      {users.map(user => (
        <UserCard key={user.id} user={user} onEdit={handleEdit} />
      ))}
    </div>
  );
};
```

### 並行機能付きコード分割
より良いUXでの遅延読み込み。

```jsx
const HeavyComponent = lazy(() => 
  import('./HeavyComponent').then(module => ({
    default: module.HeavyComponent
  }))
);

const App = () => {
  const [showHeavy, setShowHeavy] = useState(false);
  const [isPending, startTransition] = useTransition();
  
  const loadHeavyComponent = () => {
    startTransition(() => {
      setShowHeavy(true);
    });
  };
  
  return (
    <div>
      <button onClick={loadHeavyComponent} disabled={isPending}>
        {isPending ? '読み込み中...' : '重いコンポーネントを読み込み'}
      </button>
      
      {showHeavy && (
        <Suspense fallback={<ComponentSkeleton />}>
          <HeavyComponent />
        </Suspense>
      )}
    </div>
  );
};
```

## モジュールベストプラクティス

### Named Exports原則（例外あり）
原則として名前付きエクスポートを使用、特定用途でデフォルトエクスポート許可。

```jsx
// ✅ 原則：名前付きエクスポート
export const UserService = () => { /* ... */ };
export const AuthService = () => { /* ... */ };

// ✅ 例外：Appコンポーネント（メインエントリーポイント）
export default function App() {
  return <div>Main App</div>;
}

// ✅ 例外：Next.jsページコンポーネント
export default function HomePage() {
  return <div>Home Page</div>;
}

// ✅ 例外：動的インポート用コンポーネント
const LazyComponent = lazy(() => import('./ComponentRequiringDefault'));
```

## テスト（React 18）

### 並行機能テスト
React 18の並行機能とSuspenseのテスト。

```jsx
import { render, screen, waitFor, act } from '@testing-library/react';

describe('SearchComponent with React 18', () => {
  test('並行更新を正しく処理', async () => {
    render(<SearchComponent />);
    
    const input = screen.getByRole('textbox');
    
    await act(async () => {
      fireEvent.change(input, { target: { value: 'テストクエリ' } });
    });
    
    await waitFor(() => {
      expect(screen.getByText(/「テストクエリ」の結果/i)).toBeInTheDocument();
    });
  });
  
  test('トランジション中のローディング状態表示', async () => {
    render(<SearchComponent />);
    
    const input = screen.getByRole('textbox');
    fireEvent.change(input, { target: { value: '重いクエリ' } });
    
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });
});

test('Suspense境界でフォールバック表示', async () => {
  render(
    <Suspense fallback={<div>読み込み中...</div>}>
      <AsyncComponent />
    </Suspense>
  );
  
  expect(screen.getByText('読み込み中...')).toBeInTheDocument();
  
  await waitFor(() => {
    expect(screen.getByText('読み込み済みコンテンツ')).toBeInTheDocument();
  });
});
```

## React 18ベストプラクティスチェックリスト

### 並行機能
- [ ] 緊急でない更新にuseTransitionを使用
- [ ] 重い計算にuseDeferredValueを実装  
- [ ] データフェッチにSuspenseを活用
- [ ] 安定したコンポーネントIDにuseIdを使用
- [ ] 外部状態にuseSyncExternalStoreを実装

### サーバーコンポーネント
- [ ] 静的コンテンツにサーバーコンポーネントを検討
- [ ] 必要な場合のみ'use client'ディレクティブを使用
- [ ] サーバー・クライアント境界を明確に分離

### パフォーマンス
- [ ] useMemoで高コスト計算をメモ化
- [ ] useCallbackでコールバックを安定化
- [ ] コンポーネント最適化にReact.memoを使用
- [ ] lazy()でコード分割を実装

### コード品質  
- [ ] 型安全性のため常にTypeScriptを使用
- [ ] 適切なエラーバウンダリを実装
- [ ] 並行機能の包括的テストを記述
- [ ] 命名規則に従う（コンポーネントはPascalCase）
- [ ] ReactフックのESLintルールを使用
- [ ] 原則named exports、例外的にdefault exportsを使用