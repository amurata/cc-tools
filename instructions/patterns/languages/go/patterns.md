# Go パターン

シンプルで効率的なGoプログラミングパターン。

## 基本構造

### パッケージ構成
```go
// プロジェクト構造
myapp/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── handlers/
│   ├── models/
│   └── services/
├── pkg/
│   └── utils/
├── go.mod
└── go.sum
```

### エラーハンドリング
```go
// カスタムエラー
type AppError struct {
    Code    int
    Message string
    Err     error
}

func (e *AppError) Error() string {
    return e.Message
}

// エラーラップ
func processData(data []byte) error {
    if err := validate(data); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }
    return nil
}

// エラーチェック
if err != nil {
    return nil, err
}
```

## 並行処理

### Goroutines とChannels
```go
// Worker Pool
func workerPool(jobs <-chan Job, results chan<- Result) {
    var wg sync.WaitGroup
    workerCount := runtime.NumCPU()
    
    for i := 0; i < workerCount; i++ {
        wg.Add(1)
        go worker(jobs, results, &wg)
    }
    
    wg.Wait()
    close(results)
}

func worker(jobs <-chan Job, results chan<- Result, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs {
        results <- process(job)
    }
}
```

### Context使用
```go
func fetchData(ctx context.Context, id string) (*Data, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    select {
    case <-ctx.Done():
        return nil, ctx.Err()
    case data := <-fetchFromDB(ctx, id):
        return data, nil
    }
}
```

## インターフェース

### インターフェース定義
```go
// 小さなインターフェース
type Reader interface {
    Read([]byte) (int, error)
}

type Writer interface {
    Write([]byte) (int, error)
}

// 組み合わせ
type ReadWriter interface {
    Reader
    Writer
}

// インターフェース実装
type FileStore struct {
    path string
}

func (fs *FileStore) Read(p []byte) (int, error) {
    // 実装
    return len(p), nil
}
```

## 構造体パターン

### Functional Options
```go
type Server struct {
    host    string
    port    int
    timeout time.Duration
}

type Option func(*Server)

func WithHost(host string) Option {
    return func(s *Server) {
        s.host = host
    }
}

func WithTimeout(timeout time.Duration) Option {
    return func(s *Server) {
        s.timeout = timeout
    }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        host:    "localhost",
        port:    8080,
        timeout: 30 * time.Second,
    }
    
    for _, opt := range opts {
        opt(s)
    }
    
    return s
}

// 使用
server := NewServer(
    WithHost("0.0.0.0"),
    WithTimeout(60*time.Second),
)
```

### Builder パターン
```go
type RequestBuilder struct {
    method  string
    url     string
    headers map[string]string
    body    []byte
}

func (b *RequestBuilder) Method(method string) *RequestBuilder {
    b.method = method
    return b
}

func (b *RequestBuilder) URL(url string) *RequestBuilder {
    b.url = url
    return b
}

func (b *RequestBuilder) Build() (*http.Request, error) {
    req, err := http.NewRequest(b.method, b.url, bytes.NewReader(b.body))
    if err != nil {
        return nil, err
    }
    
    for k, v := range b.headers {
        req.Header.Set(k, v)
    }
    
    return req, nil
}
```

## テスト

### Table Driven Tests
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d; want %d", 
                    tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

### モック
```go
type MockDB struct {
    mock.Mock
}

func (m *MockDB) Get(id string) (*User, error) {
    args := m.Called(id)
    return args.Get(0).(*User), args.Error(1)
}

func TestService(t *testing.T) {
    mockDB := new(MockDB)
    mockDB.On("Get", "123").Return(&User{ID: "123"}, nil)
    
    service := NewService(mockDB)
    user, err := service.GetUser("123")
    
    assert.NoError(t, err)
    assert.Equal(t, "123", user.ID)
    mockDB.AssertExpectations(t)
}
```

## HTTPサーバー

### ハンドラー
```go
type Handler struct {
    service Service
}

func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    
    user, err := h.service.GetUser(r.Context(), id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

### ミドルウェア
```go
func LoggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        wrapped := &responseWriter{ResponseWriter: w}
        next.ServeHTTP(wrapped, r)
        
        log.Printf("%s %s %d %v",
            r.Method,
            r.URL.Path,
            wrapped.status,
            time.Since(start),
        )
    })
}
```

## ベストプラクティス

### defer使用
```go
func readFile(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer f.Close() // 必ずクローズ
    
    return io.ReadAll(f)
}
```

### embed使用
```go
//go:embed templates/*
var templates embed.FS

//go:embed config.yaml
var configData []byte
```

## チェックリスト
- [ ] エラーハンドリング適切
- [ ] goroutine リーク防止
- [ ] context 適切使用
- [ ] インターフェース小さく
- [ ] テーブル駆動テスト
- [ ] defer でリソース管理
- [ ] 並行処理パターン適用