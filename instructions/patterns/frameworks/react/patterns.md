# Reactパターン

React 18+の並行機能とパフォーマンス最適化パターン。

## 並行機能

### useTransition
```tsx
const [isPending, startTransition] = useTransition();

const handleSearch = (query: string) => {
  setQuery(query); // 緊急更新
  startTransition(() => {
    setSearchResults(performHeavySearch(query)); // 非緊急更新
  });
};
```

### useDeferredValue
```tsx
const deferredQuery = useDeferredValue(query);
const results = useMemo(() => searchDatabase(deferredQuery), [deferredQuery]);
```

### Suspense
```tsx
<Suspense fallback={<ProfileSkeleton />}>
  <UserData userId={userId} />
  <Suspense fallback={<PostsSkeleton />}>
    <UserPosts userId={userId} />
  </Suspense>
</Suspense>
```

## サーバーコンポーネント（Next.js 13+）

```tsx
// サーバーコンポーネント（デフォルト）
const HomePage = async () => {
  const posts = await fetchPosts(); // DB/API直接呼び出し
  return <PostList posts={posts} />;
};

// クライアントコンポーネント（インタラクティブ）
'use client';
const InteractiveButton = () => {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
};
```

## 状態管理

### useId
```tsx
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

### useSyncExternalStore
```tsx
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
    () => true // SSRフォールバック
  );
};
```

## コンポーネントパターン

### 複合コンポーネント
```tsx
const ToggleContext = createContext<ToggleContextType | null>(null);

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
  return <button onClick={toggle} aria-pressed={on}>{on ? 'ON' : 'OFF'}</button>;
};

Toggle.Display = () => {
  const { on } = useToggle();
  return <div>{on ? 'Active' : 'Inactive'}</div>;
};
```

### エラーバウンダリ（react-error-boundary）
```tsx
<ErrorBoundary
  FallbackComponent={ErrorFallback}
  onError={(error, errorInfo) => {
    console.error('Error:', error, errorInfo);
  }}
>
  <App />
</ErrorBoundary>
```

## パフォーマンス最適化

### React.memo with カスタム比較
```tsx
export const UserCard = memo<UserCardProps>(
  ({ user, onEdit }) => (
    <div>
      <h3>{user.name}</h3>
      <button onClick={() => onEdit(user.id)}>編集</button>
    </div>
  ),
  (prevProps, nextProps) => 
    prevProps.user.id === nextProps.user.id &&
    prevProps.user.name === nextProps.user.name
);
```

### コード分割 + 並行機能
```tsx
const HeavyComponent = lazy(() => import('./HeavyComponent'));

const App = () => {
  const [showHeavy, setShowHeavy] = useState(false);
  const [isPending, startTransition] = useTransition();
  
  const loadComponent = () => {
    startTransition(() => setShowHeavy(true));
  };
  
  return (
    <>
      <button onClick={loadComponent} disabled={isPending}>
        {isPending ? 'Loading...' : 'Load'}
      </button>
      {showHeavy && (
        <Suspense fallback={<Skeleton />}>
          <HeavyComponent />
        </Suspense>
      )}
    </>
  );
};
```

## テストパターン

### 並行機能テスト
```tsx
test('並行更新の処理', async () => {
  render(<SearchComponent />);
  
  const input = screen.getByRole('textbox');
  await act(async () => {
    fireEvent.change(input, { target: { value: 'test' } });
  });
  
  await waitFor(() => {
    expect(screen.getByText(/test結果/i)).toBeInTheDocument();
  });
});
```

### Suspenseテスト
```tsx
test('Suspenseフォールバック', async () => {
  render(
    <Suspense fallback={<div>Loading...</div>}>
      <AsyncComponent />
    </Suspense>
  );
  
  expect(screen.getByText('Loading...')).toBeInTheDocument();
  await waitFor(() => {
    expect(screen.getByText('Loaded Content')).toBeInTheDocument();
  });
});
```

## チェックリスト

### React 18+
- [ ] useTransition for non-urgent updates
- [ ] useDeferredValue for heavy computations
- [ ] Suspense for data fetching
- [ ] useId for stable IDs
- [ ] useSyncExternalStore for external state

### パフォーマンス
- [ ] useMemo for expensive calculations
- [ ] useCallback for stable callbacks
- [ ] React.memo for component optimization
- [ ] lazy() for code splitting
- [ ] Bundle size optimization

### 品質
- [ ] TypeScript for type safety
- [ ] Error boundaries
- [ ] Comprehensive testing
- [ ] ESLint React hooks rules