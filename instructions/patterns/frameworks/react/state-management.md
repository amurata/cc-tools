# React State Management Patterns (2024)

最新のReact状態管理パターンとベストプラクティス。State of React 2024準拠。

## 最新の状態管理ソリューション

### TanStack Query v5 (サーバー状態管理のデファクトスタンダード)
```typescript
// v5の新しいAPI（gcTimeに変更）
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// データ取得
function useProducts() {
  return useQuery({
    queryKey: ['products'],
    queryFn: fetchProducts,
    staleTime: 5 * 60 * 1000, // 5分間はfreshとして扱う
    gcTime: 10 * 60 * 1000, // 10分後にガベージコレクション（旧cacheTime）
    refetchOnWindowFocus: false,
  });
}

// ミューテーション
function useCreateProduct() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: createProduct,
    onSuccess: (data) => {
      // キャッシュを無効化
      queryClient.invalidateQueries({ queryKey: ['products'] });
      // または楽観的更新
      queryClient.setQueryData(['products'], (old) => [...old, data]);
    },
    onError: (error, variables, context) => {
      // エラーハンドリング
      console.error('Failed to create product:', error);
    },
  });
}
```

### Zustand (軽量でシンプルなクライアント状態管理)
```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface AppState {
  user: User | null;
  theme: 'light' | 'dark';
  notifications: Notification[];
  
  // アクション
  setUser: (user: User | null) => void;
  toggleTheme: () => void;
  addNotification: (notification: Notification) => void;
  clearNotifications: () => void;
}

const useAppStore = create<AppState>()(
  devtools(
    persist(
      immer((set) => ({
        user: null,
        theme: 'light',
        notifications: [],
        
        setUser: (user) => set((state) => {
          state.user = user;
        }),
        
        toggleTheme: () => set((state) => {
          state.theme = state.theme === 'light' ? 'dark' : 'light';
        }),
        
        addNotification: (notification) => set((state) => {
          state.notifications.push(notification);
        }),
        
        clearNotifications: () => set((state) => {
          state.notifications = [];
        }),
      })),
      {
        name: 'app-storage',
        partialize: (state) => ({ theme: state.theme }), // 一部のみ永続化
      }
    )
  )
);

// 使用方法
function Component() {
  const { user, theme, toggleTheme } = useAppStore();
  return <div>{user?.name}</div>;
}
```

### Jotai (原子的な状態管理)
```typescript
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai';
import { atomWithStorage } from 'jotai/utils';

// アトムの定義
const countAtom = atom(0);
const userAtom = atom<User | null>(null);
const themeAtom = atomWithStorage('theme', 'light'); // localStorage連携

// 派生アトム
const doubleCountAtom = atom((get) => get(countAtom) * 2);

// 非同期アトム
const productsAtom = atom(async () => {
  const response = await fetch('/api/products');
  return response.json();
});

// 使用方法
function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const doubleCount = useAtomValue(doubleCountAtom);
  
  return (
    <div>
      <p>Count: {count}, Double: {doubleCount}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

## Redux Toolkit (現代的なRedux実装)

### Redux Toolkitの設定
```typescript
// store.ts
import { configureStore } from '@reduxjs/toolkit';
import { setupListeners } from '@reduxjs/toolkit/query';
import userReducer from './features/userSlice';
import cartReducer from './features/cartSlice';
import { api } from './services/api';

export const store = configureStore({
  reducer: {
    user: userReducer,
    cart: cartReducer,
    [api.reducerPath]: api.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST'],
      },
    }).concat(api.middleware),
});

setupListeners(store.dispatch);

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

### Sliceの作成 (Redux Toolkit)
```typescript
// features/userSlice.ts
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { userApi } from '../services/api';

interface UserState {
  currentUser: User | null;
  status: 'idle' | 'loading' | 'succeeded' | 'failed';
  error: string | null;
}

const initialState: UserState = {
  currentUser: null,
  status: 'idle',
  error: null,
};

// 非同期アクション
export const fetchUserById = createAsyncThunk(
  'user/fetchById',
  async (userId: string) => {
    const response = await userApi.getUser(userId);
    return response.data;
  }
);

const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    setUser: (state, action: PayloadAction<User>) => {
      state.currentUser = action.payload;
    },
    clearUser: (state) => {
      state.currentUser = null;
      state.status = 'idle';
      state.error = null;
    },
    updateUserProfile: (state, action: PayloadAction<Partial<User>>) => {
      if (state.currentUser) {
        state.currentUser = { ...state.currentUser, ...action.payload };
      }
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUserById.pending, (state) => {
        state.status = 'loading';
      })
      .addCase(fetchUserById.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.currentUser = action.payload;
      })
      .addCase(fetchUserById.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message || 'Failed to fetch user';
      });
  },
});

export const { setUser, clearUser, updateUserProfile } = userSlice.actions;
export default userSlice.reducer;
```

### RTK Query (データフェッチング)
```typescript
// services/api.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const api = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({
    baseUrl: '/api',
    prepareHeaders: (headers, { getState }) => {
      const token = (getState() as RootState).auth.token;
      if (token) {
        headers.set('authorization', `Bearer ${token}`);
      }
      return headers;
    },
  }),
  tagTypes: ['User', 'Product', 'Order'],
  endpoints: (builder) => ({
    getProducts: builder.query<Product[], void>({
      query: () => 'products',
      providesTags: ['Product'],
    }),
    getProductById: builder.query<Product, string>({
      query: (id) => `products/${id}`,
      providesTags: (result, error, id) => [{ type: 'Product', id }],
    }),
    createProduct: builder.mutation<Product, Partial<Product>>({
      query: (product) => ({
        url: 'products',
        method: 'POST',
        body: product,
      }),
      invalidatesTags: ['Product'],
    }),
    updateProduct: builder.mutation<Product, Partial<Product> & { id: string }>({
      query: ({ id, ...patch }) => ({
        url: `products/${id}`,
        method: 'PATCH',
        body: patch,
      }),
      invalidatesTags: (result, error, { id }) => [{ type: 'Product', id }],
    }),
  }),
});

export const {
  useGetProductsQuery,
  useGetProductByIdQuery,
  useCreateProductMutation,
  useUpdateProductMutation,
} = api;
```

### カスタムフック (TypeScript対応)
```typescript
// hooks/redux.ts
import { useDispatch, useSelector, TypedUseSelectorHook } from 'react-redux';
import type { RootState, AppDispatch } from '../store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;

// カスタムセレクター
export const useCurrentUser = () => 
  useAppSelector((state) => state.user.currentUser);

export const useCartItems = () => 
  useAppSelector((state) => state.cart.items);

export const useCartTotal = () => 
  useAppSelector((state) => 
    state.cart.items.reduce((total, item) => total + item.price * item.quantity, 0)
  );
```

### Redux Persist (永続化)
```typescript
// store/persist.ts
import { persistStore, persistReducer } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import { combineReducers } from '@reduxjs/toolkit';

const persistConfig = {
  key: 'root',
  storage,
  whitelist: ['user', 'cart'], // 永続化するreducer
  blacklist: ['api'], // 永続化しないreducer
};

const rootReducer = combineReducers({
  user: userReducer,
  cart: cartReducer,
  [api.reducerPath]: api.reducer,
});

export const persistedReducer = persistReducer(persistConfig, rootReducer);
```

### 使用例
```typescript
// components/ProductList.tsx
import { useGetProductsQuery } from '../services/api';
import { useAppDispatch, useAppSelector } from '../hooks/redux';
import { addToCart } from '../features/cartSlice';

export function ProductList() {
  const dispatch = useAppDispatch();
  const { data: products, isLoading, error } = useGetProductsQuery();
  const cartItems = useAppSelector((state) => state.cart.items);
  
  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading products</div>;
  
  return (
    <div>
      {products?.map((product) => (
        <div key={product.id}>
          <h3>{product.name}</h3>
          <p>{product.price}</p>
          <button onClick={() => dispatch(addToCart(product))}>
            Add to Cart
          </button>
        </div>
      ))}
    </div>
  );
}
```

## Classic Redux (レガシーパターン - 参考用)

### アクションとリデューサー
```typescript
// Classic Redux (Redux Toolkit推奨のため参考程度)
// actions/types.ts
const ADD_TODO = 'ADD_TODO';
const TOGGLE_TODO = 'TOGGLE_TODO';

// actions/creators.ts
export const addTodo = (text: string) => ({
  type: ADD_TODO,
  payload: { id: Date.now(), text, completed: false }
});

// reducers/todos.ts
const todosReducer = (state = [], action) => {
  switch (action.type) {
    case ADD_TODO:
      return [...state, action.payload];
    case TOGGLE_TODO:
      return state.map(todo =>
        todo.id === action.payload
          ? { ...todo, completed: !todo.completed }
          : todo
      );
    default:
      return state;
  }
};
```

## Context API パターン

### 基本的なContext実装
```typescript
// AuthContext
interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    // 初期認証チェック
    checkAuth()
      .then(setUser)
      .finally(() => setLoading(false));
  }, []);
  
  const login = useCallback(async (email: string, password: string) => {
    const user = await authService.login(email, password);
    setUser(user);
  }, []);
  
  const logout = useCallback(() => {
    authService.logout();
    setUser(null);
  }, []);
  
  const value = useMemo(
    () => ({ user, login, logout, loading }),
    [user, login, logout, loading]
  );
  
  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// カスタムフック
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

### Context分離パターン
```typescript
// 状態とディスパッチを分離
interface AppState {
  theme: 'light' | 'dark';
  language: string;
  notifications: Notification[];
}

type AppAction =
  | { type: 'SET_THEME'; payload: 'light' | 'dark' }
  | { type: 'SET_LANGUAGE'; payload: string }
  | { type: 'ADD_NOTIFICATION'; payload: Notification }
  | { type: 'REMOVE_NOTIFICATION'; payload: string };

const StateContext = createContext<AppState | undefined>(undefined);
const DispatchContext = createContext<Dispatch<AppAction> | undefined>(undefined);

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_THEME':
      return { ...state, theme: action.payload };
    case 'SET_LANGUAGE':
      return { ...state, language: action.payload };
    case 'ADD_NOTIFICATION':
      return {
        ...state,
        notifications: [...state.notifications, action.payload]
      };
    case 'REMOVE_NOTIFICATION':
      return {
        ...state,
        notifications: state.notifications.filter(n => n.id !== action.payload)
      };
    default:
      return state;
  }
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(appReducer, {
    theme: 'light',
    language: 'en',
    notifications: []
  });
  
  return (
    <StateContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>
        {children}
      </DispatchContext.Provider>
    </StateContext.Provider>
  );
}

// 個別フック
export function useAppState() {
  const context = useContext(StateContext);
  if (!context) throw new Error('useAppState must be used within AppProvider');
  return context;
}

export function useAppDispatch() {
  const context = useContext(DispatchContext);
  if (!context) throw new Error('useAppDispatch must be used within AppProvider');
  return context;
}

// 便利なアクションフック
export function useTheme() {
  const { theme } = useAppState();
  const dispatch = useAppDispatch();
  
  const setTheme = useCallback((newTheme: 'light' | 'dark') => {
    dispatch({ type: 'SET_THEME', payload: newTheme });
  }, [dispatch]);
  
  return { theme, setTheme };
}
```

## Zustand 状態管理

### 基本的なStore
```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface TodoState {
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';
  addTodo: (title: string) => void;
  toggleTodo: (id: string) => void;
  deleteTodo: (id: string) => void;
  setFilter: (filter: TodoState['filter']) => void;
  clearCompleted: () => void;
}

const useTodoStore = create<TodoState>()(
  devtools(
    persist(
      immer((set) => ({
        todos: [],
        filter: 'all',
        
        addTodo: (title) =>
          set((state) => {
            state.todos.push({
              id: crypto.randomUUID(),
              title,
              completed: false,
              createdAt: new Date()
            });
          }),
        
        toggleTodo: (id) =>
          set((state) => {
            const todo = state.todos.find(t => t.id === id);
            if (todo) {
              todo.completed = !todo.completed;
            }
          }),
        
        deleteTodo: (id) =>
          set((state) => {
            state.todos = state.todos.filter(t => t.id !== id);
          }),
        
        setFilter: (filter) =>
          set((state) => {
            state.filter = filter;
          }),
        
        clearCompleted: () =>
          set((state) => {
            state.todos = state.todos.filter(t => !t.completed);
          })
      })),
      {
        name: 'todo-storage'
      }
    )
  )
);

// セレクター
const selectFilteredTodos = (state: TodoState) => {
  switch (state.filter) {
    case 'active':
      return state.todos.filter(t => !t.completed);
    case 'completed':
      return state.todos.filter(t => t.completed);
    default:
      return state.todos;
  }
};

// 使用例
function TodoList() {
  const todos = useTodoStore(selectFilteredTodos);
  const toggleTodo = useTodoStore(state => state.toggleTodo);
  const deleteTodo = useTodoStore(state => state.deleteTodo);
  
  return (
    <ul>
      {todos.map(todo => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onToggle={toggleTodo}
          onDelete={deleteTodo}
        />
      ))}
    </ul>
  );
}
```

### Sliceパターン
```typescript
// Storeを機能ごとに分割
interface AuthSlice {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

interface UISlice {
  sidebarOpen: boolean;
  modalOpen: boolean;
  toggleSidebar: () => void;
  toggleModal: () => void;
}

interface CartSlice {
  items: CartItem[];
  addItem: (product: Product) => void;
  removeItem: (productId: string) => void;
  clearCart: () => void;
  total: number;
}

const createAuthSlice: StateCreator<
  AuthSlice & UISlice & CartSlice,
  [],
  [],
  AuthSlice
> = (set) => ({
  user: null,
  login: async (email, password) => {
    const user = await authService.login(email, password);
    set({ user });
  },
  logout: () => {
    authService.logout();
    set({ user: null });
  }
});

const createUISlice: StateCreator<
  AuthSlice & UISlice & CartSlice,
  [],
  [],
  UISlice
> = (set) => ({
  sidebarOpen: false,
  modalOpen: false,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  toggleModal: () => set((state) => ({ modalOpen: !state.modalOpen }))
});

const createCartSlice: StateCreator<
  AuthSlice & UISlice & CartSlice,
  [],
  [],
  CartSlice
> = (set, get) => ({
  items: [],
  addItem: (product) =>
    set((state) => {
      const existingItem = state.items.find(i => i.productId === product.id);
      if (existingItem) {
        existingItem.quantity++;
      } else {
        state.items.push({
          productId: product.id,
          product,
          quantity: 1
        });
      }
    }),
  removeItem: (productId) =>
    set((state) => ({
      items: state.items.filter(i => i.productId !== productId)
    })),
  clearCart: () => set({ items: [] }),
  get total() {
    return get().items.reduce(
      (sum, item) => sum + item.product.price * item.quantity,
      0
    );
  }
});

// Store統合
const useStore = create<AuthSlice & UISlice & CartSlice>()((...a) => ({
  ...createAuthSlice(...a),
  ...createUISlice(...a),
  ...createCartSlice(...a)
}));
```

## Redux Toolkit パターン

### Sliceの作成
```typescript
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';

// 非同期アクション
export const fetchPosts = createAsyncThunk(
  'posts/fetchPosts',
  async (userId?: string) => {
    const response = await api.getPosts(userId);
    return response.data;
  }
);

interface PostsState {
  items: Post[];
  status: 'idle' | 'loading' | 'succeeded' | 'failed';
  error: string | null;
  filter: string;
}

const initialState: PostsState = {
  items: [],
  status: 'idle',
  error: null,
  filter: ''
};

const postsSlice = createSlice({
  name: 'posts',
  initialState,
  reducers: {
    postAdded: (state, action: PayloadAction<Post>) => {
      state.items.push(action.payload);
    },
    postUpdated: (state, action: PayloadAction<{ id: string; changes: Partial<Post> }>) => {
      const post = state.items.find(p => p.id === action.payload.id);
      if (post) {
        Object.assign(post, action.payload.changes);
      }
    },
    postDeleted: (state, action: PayloadAction<string>) => {
      state.items = state.items.filter(p => p.id !== action.payload);
    },
    filterSet: (state, action: PayloadAction<string>) => {
      state.filter = action.payload;
    }
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchPosts.pending, (state) => {
        state.status = 'loading';
      })
      .addCase(fetchPosts.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.items = action.payload;
      })
      .addCase(fetchPosts.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message || 'Failed to fetch posts';
      });
  }
});

export const { postAdded, postUpdated, postDeleted, filterSet } = postsSlice.actions;
export default postsSlice.reducer;

// Selectors
export const selectAllPosts = (state: RootState) => state.posts.items;
export const selectFilteredPosts = (state: RootState) => {
  const { items, filter } = state.posts;
  if (!filter) return items;
  return items.filter(post =>
    post.title.toLowerCase().includes(filter.toLowerCase())
  );
};
```

### RTK Query
```typescript
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({
    baseUrl: '/api',
    prepareHeaders: (headers, { getState }) => {
      const token = (getState() as RootState).auth.token;
      if (token) {
        headers.set('authorization', `Bearer ${token}`);
      }
      return headers;
    }
  }),
  tagTypes: ['Post', 'User'],
  endpoints: (builder) => ({
    getPosts: builder.query<Post[], void>({
      query: () => '/posts',
      providesTags: (result) =>
        result
          ? [...result.map(({ id }) => ({ type: 'Post' as const, id })), 'Post']
          : ['Post']
    }),
    
    getPost: builder.query<Post, string>({
      query: (id) => `/posts/${id}`,
      providesTags: (result, error, id) => [{ type: 'Post', id }]
    }),
    
    createPost: builder.mutation<Post, Partial<Post>>({
      query: (post) => ({
        url: '/posts',
        method: 'POST',
        body: post
      }),
      invalidatesTags: ['Post']
    }),
    
    updatePost: builder.mutation<Post, Partial<Post> & { id: string }>({
      query: ({ id, ...patch }) => ({
        url: `/posts/${id}`,
        method: 'PATCH',
        body: patch
      }),
      invalidatesTags: (result, error, { id }) => [{ type: 'Post', id }]
    }),
    
    deletePost: builder.mutation<void, string>({
      query: (id) => ({
        url: `/posts/${id}`,
        method: 'DELETE'
      }),
      invalidatesTags: (result, error, id) => [{ type: 'Post', id }]
    })
  })
});

export const {
  useGetPostsQuery,
  useGetPostQuery,
  useCreatePostMutation,
  useUpdatePostMutation,
  useDeletePostMutation
} = apiSlice;
```

## Jotai アトミック状態管理

### 基本的なAtom
```typescript
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai';
import { atomWithStorage } from 'jotai/utils';

// 基本的なatom
const countAtom = atom(0);
const textAtom = atom('');

// localStorage連携
const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light');

// 派生atom（読み取り専用）
const doubleCountAtom = atom((get) => get(countAtom) * 2);

// 派生atom（読み書き）
const uppercaseAtom = atom(
  (get) => get(textAtom).toUpperCase(),
  (get, set, newValue: string) => set(textAtom, newValue)
);

// 非同期atom
const userAtom = atom(async () => {
  const response = await fetch('/api/user');
  return response.json();
});

// atom family
const todoAtomFamily = atomFamily((id: string) =>
  atom({ id, title: '', completed: false })
);

// 使用例
function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const doubleCount = useAtomValue(doubleCountAtom);
  
  return (
    <div>
      <p>Count: {count}</p>
      <p>Double: {doubleCount}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

## チェックリスト
- [ ] 適切な状態管理ライブラリ選択
- [ ] Context分離とメモ化
- [ ] Selector最適化
- [ ] 非同期処理パターン
- [ ] DevTools統合
- [ ] 永続化戦略
- [ ] テスト容易性確保
- [ ] 型安全性維持
- [ ] パフォーマンス最適化