# React Hooks Patterns

React Hooksの実装パターンとベストプラクティス。

## カスタムフック設計

### 基本的なカスタムフック
```typescript
// useLocalStorage フック
function useLocalStorage<T>(
  key: string,
  initialValue: T
): [T, (value: T | ((val: T) => T)) => void] {
  // 初期値の取得
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(`Error loading localStorage key "${key}":`, error);
      return initialValue;
    }
  });
  
  // 値の更新
  const setValue = useCallback((value: T | ((val: T) => T)) => {
    try {
      setStoredValue(prevValue => {
        const valueToStore = value instanceof Function ? value(prevValue) : value;
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
        return valueToStore;
      });
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  }, [key]);
  
  return [storedValue, setValue];
}

// 使用例
function Settings() {
  const [theme, setTheme] = useLocalStorage('theme', 'light');
  const [language, setLanguage] = useLocalStorage('language', 'en');
  
  return (
    <div>
      <select value={theme} onChange={e => setTheme(e.target.value)}>
        <option value="light">Light</option>
        <option value="dark">Dark</option>
      </select>
    </div>
  );
}
```

### データフェッチフック
```typescript
interface UseApiState<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
}

function useApi<T>(
  url: string,
  options?: RequestInit
): UseApiState<T> & { refetch: () => Promise<void> } {
  const [state, setState] = useState<UseApiState<T>>({
    data: null,
    loading: true,
    error: null
  });
  
  const fetchData = useCallback(async () => {
    setState(prev => ({ ...prev, loading: true, error: null }));
    
    try {
      const response = await fetch(url, options);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setState({ data, loading: false, error: null });
    } catch (error) {
      setState({ data: null, loading: false, error: error as Error });
    }
  }, [url, options]);
  
  useEffect(() => {
    fetchData();
  }, [fetchData]);
  
  return { ...state, refetch: fetchData };
}

// 使用例
function UserProfile({ userId }: { userId: string }) {
  const { data, loading, error, refetch } = useApi<User>(
    `/api/users/${userId}`
  );
  
  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} onRetry={refetch} />;
  if (!data) return <EmptyState />;
  
  return <UserCard user={data} />;
}
```

## 状態管理パターン

### useReducer での複雑な状態管理
```typescript
type State = {
  items: Item[];
  selectedIds: Set<string>;
  filter: string;
  sortBy: 'name' | 'date' | 'price';
  loading: boolean;
  error: string | null;
};

type Action =
  | { type: 'SET_ITEMS'; payload: Item[] }
  | { type: 'TOGGLE_SELECTION'; payload: string }
  | { type: 'SELECT_ALL' }
  | { type: 'CLEAR_SELECTION' }
  | { type: 'SET_FILTER'; payload: string }
  | { type: 'SET_SORT'; payload: State['sortBy'] }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null };

function itemsReducer(state: State, action: Action): State {
  switch (action.type) {
    case 'SET_ITEMS':
      return { ...state, items: action.payload, loading: false };
      
    case 'TOGGLE_SELECTION': {
      const newSelection = new Set(state.selectedIds);
      if (newSelection.has(action.payload)) {
        newSelection.delete(action.payload);
      } else {
        newSelection.add(action.payload);
      }
      return { ...state, selectedIds: newSelection };
    }
    
    case 'SELECT_ALL':
      return {
        ...state,
        selectedIds: new Set(state.items.map(item => item.id))
      };
      
    case 'CLEAR_SELECTION':
      return { ...state, selectedIds: new Set() };
      
    case 'SET_FILTER':
      return { ...state, filter: action.payload };
      
    case 'SET_SORT':
      return { ...state, sortBy: action.payload };
      
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
      
    case 'SET_ERROR':
      return { ...state, error: action.payload, loading: false };
      
    default:
      return state;
  }
}

function useItems() {
  const [state, dispatch] = useReducer(itemsReducer, {
    items: [],
    selectedIds: new Set(),
    filter: '',
    sortBy: 'name',
    loading: false,
    error: null
  });
  
  // 派生状態
  const filteredItems = useMemo(() => {
    return state.items
      .filter(item => 
        item.name.toLowerCase().includes(state.filter.toLowerCase())
      )
      .sort((a, b) => {
        switch (state.sortBy) {
          case 'name':
            return a.name.localeCompare(b.name);
          case 'date':
            return new Date(b.date).getTime() - new Date(a.date).getTime();
          case 'price':
            return b.price - a.price;
        }
      });
  }, [state.items, state.filter, state.sortBy]);
  
  // アクション
  const actions = useMemo(() => ({
    setItems: (items: Item[]) => dispatch({ type: 'SET_ITEMS', payload: items }),
    toggleSelection: (id: string) => dispatch({ type: 'TOGGLE_SELECTION', payload: id }),
    selectAll: () => dispatch({ type: 'SELECT_ALL' }),
    clearSelection: () => dispatch({ type: 'CLEAR_SELECTION' }),
    setFilter: (filter: string) => dispatch({ type: 'SET_FILTER', payload: filter }),
    setSort: (sortBy: State['sortBy']) => dispatch({ type: 'SET_SORT', payload: sortBy })
  }), []);
  
  return {
    ...state,
    filteredItems,
    ...actions
  };
}
```

## パフォーマンス最適化

### useMemo と useCallback
```typescript
function ExpensiveComponent({ data, onUpdate }: Props) {
  // 高コストな計算をメモ化
  const processedData = useMemo(() => {
    console.log('Processing data...');
    return data.map(item => ({
      ...item,
      computed: expensiveComputation(item)
    }));
  }, [data]);
  
  // コールバックをメモ化（子コンポーネントの再レンダリング防止）
  const handleClick = useCallback((id: string) => {
    onUpdate(id);
  }, [onUpdate]);
  
  // 複数の依存関係を持つメモ化
  const summary = useMemo(() => {
    const total = processedData.reduce((sum, item) => sum + item.value, 0);
    const average = total / processedData.length;
    return { total, average, count: processedData.length };
  }, [processedData]);
  
  return (
    <div>
      <Summary {...summary} />
      {processedData.map(item => (
        <Item key={item.id} {...item} onClick={handleClick} />
      ))}
    </div>
  );
}
```

### 遅延初期化
```typescript
function useExpensiveInit(computeInitialValue: () => any) {
  // useState の遅延初期化
  const [value, setValue] = useState(() => {
    console.log('Computing initial value...');
    return computeInitialValue();
  });
  
  // useRef での一度だけの初期化
  const initialized = useRef(false);
  const expensiveObject = useRef<ExpensiveObject | null>(null);
  
  if (!initialized.current) {
    expensiveObject.current = new ExpensiveObject();
    initialized.current = true;
  }
  
  return { value, setValue, expensiveObject: expensiveObject.current };
}
```

## 副作用管理

### useEffect パターン
```typescript
function useEventListener<K extends keyof WindowEventMap>(
  eventName: K,
  handler: (event: WindowEventMap[K]) => void,
  element: HTMLElement | Window = window
) {
  // ハンドラーを ref に保存
  const savedHandler = useRef(handler);
  
  useLayoutEffect(() => {
    savedHandler.current = handler;
  }, [handler]);
  
  useEffect(() => {
    // イベントリスナー
    const eventListener = (event: Event) => {
      savedHandler.current(event as WindowEventMap[K]);
    };
    
    element.addEventListener(eventName, eventListener);
    
    // クリーンアップ
    return () => {
      element.removeEventListener(eventName, eventListener);
    };
  }, [eventName, element]);
}

// デバウンス効果
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);
  
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    
    return () => {
      clearTimeout(timer);
    };
  }, [value, delay]);
  
  return debouncedValue;
}

// 使用例
function SearchInput() {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearchTerm = useDebounce(searchTerm, 500);
  
  useEffect(() => {
    if (debouncedSearchTerm) {
      // API呼び出し
      searchAPI(debouncedSearchTerm);
    }
  }, [debouncedSearchTerm]);
  
  return (
    <input
      value={searchTerm}
      onChange={e => setSearchTerm(e.target.value)}
      placeholder="Search..."
    />
  );
}
```

## フォーム管理

### カスタムフォームフック
```typescript
interface FormValues {
  [key: string]: any;
}

interface FormErrors {
  [key: string]: string;
}

interface UseFormReturn<T extends FormValues> {
  values: T;
  errors: FormErrors;
  touched: Set<keyof T>;
  handleChange: (name: keyof T) => (e: React.ChangeEvent<HTMLInputElement>) => void;
  handleBlur: (name: keyof T) => () => void;
  handleSubmit: (e: React.FormEvent) => Promise<void>;
  setFieldValue: (name: keyof T, value: any) => void;
  setFieldError: (name: keyof T, error: string) => void;
  reset: () => void;
  isSubmitting: boolean;
  isValid: boolean;
}

function useForm<T extends FormValues>({
  initialValues,
  validate,
  onSubmit
}: {
  initialValues: T;
  validate?: (values: T) => FormErrors;
  onSubmit: (values: T) => Promise<void>;
}): UseFormReturn<T> {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState<Set<keyof T>>(new Set());
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // バリデーション実行
  useEffect(() => {
    if (validate) {
      const newErrors = validate(values);
      setErrors(newErrors);
    }
  }, [values, validate]);
  
  const handleChange = useCallback((name: keyof T) => {
    return (e: React.ChangeEvent<HTMLInputElement>) => {
      const { value, type, checked } = e.target;
      setValues(prev => ({
        ...prev,
        [name]: type === 'checkbox' ? checked : value
      }));
    };
  }, []);
  
  const handleBlur = useCallback((name: keyof T) => {
    return () => {
      setTouched(prev => new Set(prev).add(name));
    };
  }, []);
  
  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    // 全フィールドをタッチ済みに
    setTouched(new Set(Object.keys(values) as (keyof T)[]));
    
    // バリデーション
    if (validate) {
      const newErrors = validate(values);
      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        setIsSubmitting(false);
        return;
      }
    }
    
    try {
      await onSubmit(values);
      // 成功時にリセット
      reset();
    } catch (error) {
      console.error('Form submission error:', error);
    } finally {
      setIsSubmitting(false);
    }
  }, [values, validate, onSubmit]);
  
  const setFieldValue = useCallback((name: keyof T, value: any) => {
    setValues(prev => ({ ...prev, [name]: value }));
  }, []);
  
  const setFieldError = useCallback((name: keyof T, error: string) => {
    setErrors(prev => ({ ...prev, [name]: error }));
  }, []);
  
  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setTouched(new Set());
    setIsSubmitting(false);
  }, [initialValues]);
  
  const isValid = Object.keys(errors).length === 0;
  
  return {
    values,
    errors,
    touched,
    handleChange,
    handleBlur,
    handleSubmit,
    setFieldValue,
    setFieldError,
    reset,
    isSubmitting,
    isValid
  };
}
```

## 非同期処理

### 非同期状態管理
```typescript
function useAsync<T>(
  asyncFunction: () => Promise<T>,
  immediate = true
) {
  const [state, setState] = useState<{
    data: T | null;
    loading: boolean;
    error: Error | null;
  }>({
    data: null,
    loading: false,
    error: null
  });
  
  const execute = useCallback(async () => {
    setState({ data: null, loading: true, error: null });
    
    try {
      const data = await asyncFunction();
      setState({ data, loading: false, error: null });
      return data;
    } catch (error) {
      setState({ data: null, loading: false, error: error as Error });
      throw error;
    }
  }, [asyncFunction]);
  
  useEffect(() => {
    if (immediate) {
      execute();
    }
  }, [execute, immediate]);
  
  return { ...state, execute };
}
```

## チェックリスト
- [ ] カスタムフック抽出
- [ ] 適切な依存配列設定
- [ ] useMemo/useCallback活用
- [ ] useEffectクリーンアップ
- [ ] 遅延初期化使用
- [ ] エラーハンドリング実装
- [ ] テスト容易な設計
- [ ] 型安全性確保
- [ ] パフォーマンス最適化