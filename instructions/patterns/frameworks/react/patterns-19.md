# React 19パターン

React 19の最新機能とuseフックを活用したモダンパターン（React 19専用）。

## React 19 新機能

### useフック - Promise/Context統合
Promise、Context、その他のリソースを直接的に「使用」する新しいフック。

```jsx
// Promise with useフック
const UserProfile = ({ userId }: { userId: string }) => {
  // Promise を直接 use できる
  const user = use(fetchUser(userId));
  
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
};

// Suspense境界内で自動的に処理
const App = () => (
  <Suspense fallback={<div>ユーザー読み込み中...</div>}>
    <UserProfile userId="123" />
  </Suspense>
);

// 条件付きPromise使用
const ConditionalData = ({ shouldLoad, dataId }: { shouldLoad: boolean; dataId: string }) => {
  let data = null;
  
  if (shouldLoad) {
    // 条件内でもuseフックが使用可能
    data = use(fetchData(dataId));
  }
  
  return (
    <div>
      {data ? <DataDisplay data={data} /> : <div>データなし</div>}
    </div>
  );
};
```

### use with Context - 動的コンテキスト
useContextの代替としてuseフックでコンテキストを使用。

```jsx
const ThemeContext = createContext<'light' | 'dark'>('light');
const UserContext = createContext<User | null>(null);

const DynamicConsumer = ({ useTheme, useUser }: { useTheme: boolean; useUser: boolean }) => {
  // 条件的にコンテキストを使用
  const theme = useTheme ? use(ThemeContext) : 'light';
  const user = useUser ? use(UserContext) : null;
  
  return (
    <div className={`theme-${theme}`}>
      {user ? `こんにちは、${user.name}さん` : 'ゲストユーザー'}
    </div>
  );
};

// 従来のuseContextでは不可能だった条件的使用が可能
const FlexibleComponent = ({ mode }: { mode: 'simple' | 'advanced' }) => {
  const baseTheme = use(ThemeContext);
  
  if (mode === 'simple') {
    return <div className={baseTheme}>シンプルモード</div>;
  }
  
  // advancedモードでのみUserContextを使用
  const user = use(UserContext);
  return (
    <div className={baseTheme}>
      アドバンスモード - {user?.name || 'Unknown'}
    </div>
  );
};
```

### useフック with データフェッチング統合
SWR/TanStack Queryライクなパターンをuseフックで実現。

```jsx
// カスタムPromiseファクトリー
const createDataFetcher = (url: string) => {
  let promise: Promise<any> | null = null;
  
  return () => {
    if (!promise) {
      promise = fetch(url).then(res => res.json());
    }
    return promise;
  };
};

const PostList = () => {
  const getPosts = createDataFetcher('/api/posts');
  const posts = use(getPosts());
  
  return (
    <div>
      {posts.map((post: any) => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  );
};

// エラーハンドリング付きuse
const SafeDataComponent = ({ dataUrl }: { dataUrl: string }) => {
  try {
    const data = use(fetch(dataUrl).then(r => r.json()));
    return <DataDisplay data={data} />;
  } catch (error) {
    if (error instanceof Promise) {
      // まだ pending - Suspense が処理
      throw error;
    }
    // 実際のエラー
    return <ErrorDisplay error={error} />;
  }
};
```

## React 19 強化された並行機能

### useTransition with React 19 improvements
React 19で強化されたuseTransition。

```jsx
const EnhancedSearch = () => {
  const [isPending, startTransition] = useTransition();
  const [query, setQuery] = useState('');
  
  const handleSearch = (newQuery: string) => {
    setQuery(newQuery);
    
    startTransition(() => {
      // React 19では自動的により効率的な並行処理
      const results = use(searchAPI(newQuery));
      updateSearchResults(results);
    });
  };
  
  return (
    <div>
      <input 
        value={query} 
        onChange={e => handleSearch(e.target.value)}
        disabled={isPending}
      />
      {isPending && <SearchSpinner />}
    </div>
  );
};
```

### Suspense with Resource Loading
React 19でより柔軟になったSuspenseパターン。

```jsx
const ResourcefulComponent = ({ resourceId }: { resourceId: string }) => {
  // 複数のリソースを並行取得
  const userData = use(fetchUser(resourceId));
  const userPosts = use(fetchUserPosts(resourceId));
  const userFollowers = use(fetchUserFollowers(resourceId));
  
  return (
    <div>
      <UserCard user={userData} />
      <PostGrid posts={userPosts} />
      <FollowersList followers={userFollowers} />
    </div>
  );
};

// 部分的Suspense境界
const ProfilePage = ({ userId }: { userId: string }) => (
  <div>
    <Suspense fallback={<UserSkeleton />}>
      <BasicUserInfo userId={userId} />
    </Suspense>
    
    <Suspense fallback={<PostsSkeleton />}>
      <UserPosts userId={userId} />
    </Suspense>
    
    <Suspense fallback={<SocialSkeleton />}>
      <SocialConnections userId={userId} />
    </Suspense>
  </div>
);
```

## フォーム処理 (React 19)

### Actions with useFormStatus
React 19の新しいフォーム処理機能。

```jsx
const ContactForm = () => {
  const submitAction = async (formData: FormData) => {
    'use server'; // サーバーアクション
    
    const name = formData.get('name');
    const email = formData.get('email');
    
    await submitContactForm({ name, email });
  };
  
  return (
    <form action={submitAction}>
      <input name="name" placeholder="名前" required />
      <input name="email" type="email" placeholder="メール" required />
      <SubmitButton />
    </form>
  );
};

const SubmitButton = () => {
  const { pending } = useFormStatus();
  
  return (
    <button type="submit" disabled={pending}>
      {pending ? '送信中...' : '送信'}
    </button>
  );
};
```

### useOptimistic - 楽観的更新
楽観的UI更新パターン。

```jsx
const TodoList = ({ todos }: { todos: Todo[] }) => {
  const [optimisticTodos, addOptimisticTodo] = useOptimistic(
    todos,
    (state, newTodo: Todo) => [...state, newTodo]
  );
  
  const handleAddTodo = async (text: string) => {
    const newTodo = { id: Date.now(), text, completed: false };
    
    // 楽観的更新
    addOptimisticTodo(newTodo);
    
    try {
      await addTodoAPI(newTodo);
    } catch (error) {
      // エラー時は自動的にロールバック
      console.error('Todo追加失敗:', error);
    }
  };
  
  return (
    <div>
      {optimisticTodos.map(todo => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
      <AddTodoForm onAdd={handleAddTodo} />
    </div>
  );
};
```

## Error Boundaries (React 19)

### 強化されたエラー処理
React 19でより柔軟になったエラーバウンダリ。

```jsx
const AsyncErrorBoundary = ({ children }: { children: React.ReactNode }) => {
  return (
    <ErrorBoundary
      fallback={({ error, retry }) => (
        <div>
          <h2>エラーが発生しました</h2>
          <details>
            <summary>詳細</summary>
            <pre>{error.message}</pre>
          </details>
          <button onClick={retry}>再試行</button>
        </div>
      )}
      onError={(error, errorInfo) => {
        // React 19では非同期エラーも捕捉
        console.error('Error caught:', error, errorInfo);
      }}
    >
      {children}
    </ErrorBoundary>
  );
};

// use と組み合わせたエラー処理
const RobustDataComponent = ({ dataId }: { dataId: string }) => {
  const fetchWithRetry = useCallback(async () => {
    const maxRetries = 3;
    let lastError;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await fetchData(dataId);
      } catch (error) {
        lastError = error;
        await new Promise(resolve => setTimeout(resolve, 1000 * i));
      }
    }
    throw lastError;
  }, [dataId]);
  
  const data = use(fetchWithRetry());
  
  return <DataDisplay data={data} />;
};
```

## モジュールベストプラクティス（React 19対応）

### Named Exports原則（React 19版）
React 19環境での現実的なエクスポート戦略。

```jsx
// ✅ 原則：名前付きエクスポート（ライブラリコンポーネント）
export const Button = ({ children, ...props }: ButtonProps) => (
  <button {...props}>{children}</button>
);

export const Input = ({ label, ...props }: InputProps) => (
  <div>
    <label>{label}</label>
    <input {...props} />
  </div>
);

// ✅ 例外1：Next.js App Router ページ
export default function HomePage() {
  return <div>Home Page</div>;
}

// ✅ 例外2：サーバーアクション
export default async function handleFormSubmit(formData: FormData) {
  'use server';
  // サーバーアクション処理
}

// ✅ 例外3：lazy loading対象
const HeavyChart = lazy(() => import('./HeavyChart')); // default exportを期待

// ✅ 例外4：useフック with dynamic imports
const DynamicResourceUser = ({ resourceType }: { resourceType: string }) => {
  const getResource = useCallback(async () => {
    const module = await import(`./resources/${resourceType}`);
    return module.default; // default exportが必要
  }, [resourceType]);
  
  const resource = use(getResource());
  return <ResourceDisplay resource={resource} />;
};
```

## テスト（React 19）

### useフックのテスト
React 19のuseフックを含む新機能のテスト。

```jsx
import { render, screen, waitFor } from '@testing-library/react';

describe('React 19 use hook', () => {
  test('Promiseからデータを正しく取得', async () => {
    const mockData = { id: 1, name: 'Test User' };
    const mockPromise = Promise.resolve(mockData);
    
    const TestComponent = () => {
      const data = use(mockPromise);
      return <div>{data.name}</div>;
    };
    
    render(
      <Suspense fallback={<div>Loading...</div>}>
        <TestComponent />
      </Suspense>
    );
    
    expect(screen.getByText('Loading...')).toBeInTheDocument();
    
    await waitFor(() => {
      expect(screen.getByText('Test User')).toBeInTheDocument();
    });
  });
  
  test('条件付きuseフックの動作確認', async () => {
    const TestComponent = ({ shouldLoad }: { shouldLoad: boolean }) => {
      if (shouldLoad) {
        const data = use(Promise.resolve('Loaded Data'));
        return <div>{data}</div>;
      }
      return <div>No Data</div>;
    };
    
    const { rerender } = render(
      <Suspense fallback={<div>Loading...</div>}>
        <TestComponent shouldLoad={false} />
      </Suspense>
    );
    
    expect(screen.getByText('No Data')).toBeInTheDocument();
    
    rerender(
      <Suspense fallback={<div>Loading...</div>}>
        <TestComponent shouldLoad={true} />
      </Suspense>
    );
    
    await waitFor(() => {
      expect(screen.getByText('Loaded Data')).toBeInTheDocument();
    });
  });
});

// フォーム機能のテスト
describe('React 19 Forms', () => {
  test('useFormStatusでフォーム状態を正しく表示', async () => {
    const mockSubmit = jest.fn();
    
    const TestForm = () => (
      <form action={mockSubmit}>
        <input name="test" />
        <SubmitButton />
      </form>
    );
    
    render(<TestForm />);
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    expect(button).toBeDisabled();
    expect(screen.getByText('送信中...')).toBeInTheDocument();
  });
});
```

## React 19ベストプラクティスチェックリスト

### 新機能活用
- [ ] Promise処理にuseフックを使用
- [ ] 条件付きフック使用でuseを活用
- [ ] Context読み取りにuseを検討
- [ ] フォーム処理にuseFormStatusを実装
- [ ] 楽観的更新にuseOptimisticを使用

### パフォーマンス
- [ ] リソース並行取得でuseを活用
- [ ] Suspense境界を適切に分割
- [ ] エラーバウンダリで非同期エラーを処理
- [ ] useTransitionで重い処理を並行実行

### コード品質
- [ ] TypeScriptでuseフックを型安全に使用
- [ ] エラー処理を包括的に実装
- [ ] 新機能の包括的テストを記述
- [ ] サーバーアクションを適切に活用
- [ ] 楽観的更新でUX向上を図る

### モジュール管理
- [ ] 原則named exports、必要時のみdefault exports
- [ ] サーバーアクションでdefault exportを使用
- [ ] 動的インポートでの適切なexport形式選択