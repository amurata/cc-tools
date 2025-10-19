# Go Concurrency Patterns

Idiomatic concurrency patterns in Go using goroutines and channels.

## Goroutine Patterns

### Basic Goroutine
```go
func main() {
    // Launch goroutine
    go processData()
    
    // Wait for completion
    time.Sleep(time.Second)
}

// WaitGroup for synchronization
func processInParallel(items []string) {
    var wg sync.WaitGroup
    
    for _, item := range items {
        wg.Add(1)
        go func(item string) {
            defer wg.Done()
            process(item)
        }(item)
    }
    
    wg.Wait()
}
```

## Channel Patterns

### Basic Channel Operations
```go
// Unbuffered channel
ch := make(chan int)

// Buffered channel
ch := make(chan int, 100)

// Send
ch <- 42

// Receive
value := <-ch

// Close
close(ch)

// Range over channel
for value := range ch {
    process(value)
}
```

### Producer-Consumer
```go
func producer(ch chan<- int) {
    for i := 0; i < 10; i++ {
        ch <- i
    }
    close(ch)
}

func consumer(ch <-chan int) {
    for value := range ch {
        fmt.Println("Consumed:", value)
    }
}

func main() {
    ch := make(chan int)
    go producer(ch)
    consumer(ch)
}
```

## Select Statement

### Multiplexing
```go
func multiplex(ch1, ch2 <-chan int) <-chan int {
    out := make(chan int)
    
    go func() {
        defer close(out)
        for {
            select {
            case val, ok := <-ch1:
                if !ok {
                    ch1 = nil
                    continue
                }
                out <- val
            case val, ok := <-ch2:
                if !ok {
                    ch2 = nil
                    continue
                }
                out <- val
            }
            
            if ch1 == nil && ch2 == nil {
                return
            }
        }
    }()
    
    return out
}
```

### Timeout Pattern
```go
func doWithTimeout(timeout time.Duration) error {
    ch := make(chan result)
    
    go func() {
        ch <- longRunningOperation()
    }()
    
    select {
    case res := <-ch:
        return res.err
    case <-time.After(timeout):
        return fmt.Errorf("operation timed out")
    }
}
```

## Worker Pool Pattern

### Fixed Worker Pool
```go
type Job struct {
    ID   int
    Data string
}

type Result struct {
    Job    Job
    Output string
}

func workerPool(jobs <-chan Job, results chan<- Result, workers int) {
    var wg sync.WaitGroup
    
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            
            for job := range jobs {
                output := process(job.Data)
                results <- Result{Job: job, Output: output}
            }
        }(i)
    }
    
    wg.Wait()
    close(results)
}
```

## Fan-In/Fan-Out

### Fan-Out
```go
func fanOut(in <-chan int, workers int) []<-chan int {
    channels := make([]<-chan int, workers)
    
    for i := 0; i < workers; i++ {
        ch := make(chan int)
        channels[i] = ch
        
        go func(out chan<- int) {
            for val := range in {
                out <- process(val)
            }
            close(out)
        }(ch)
    }
    
    return channels
}
```

### Fan-In
```go
func fanIn(channels ...<-chan int) <-chan int {
    out := make(chan int)
    var wg sync.WaitGroup
    
    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for val := range c {
                out <- val
            }
        }(ch)
    }
    
    go func() {
        wg.Wait()
        close(out)
    }()
    
    return out
}
```

## Pipeline Pattern

### Data Pipeline
```go
func pipeline() {
    // Stage 1: Generate numbers
    numbers := generate()
    
    // Stage 2: Square numbers
    squared := square(numbers)
    
    // Stage 3: Filter even
    even := filter(squared)
    
    // Consume results
    for result := range even {
        fmt.Println(result)
    }
}

func generate() <-chan int {
    out := make(chan int)
    go func() {
        for i := 1; i <= 10; i++ {
            out <- i
        }
        close(out)
    }()
    return out
}

func square(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        for n := range in {
            out <- n * n
        }
        close(out)
    }()
    return out
}
```

## Context Pattern

### Cancellation
```go
func operationWithContext(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            // Do work
            if isDone() {
                return nil
            }
        }
    }
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := operationWithContext(ctx); err != nil {
        log.Fatal(err)
    }
}
```

## Semaphore Pattern

### Rate Limiting
```go
type Semaphore struct {
    permits chan struct{}
}

func NewSemaphore(n int) *Semaphore {
    permits := make(chan struct{}, n)
    for i := 0; i < n; i++ {
        permits <- struct{}{}
    }
    return &Semaphore{permits: permits}
}

func (s *Semaphore) Acquire() {
    <-s.permits
}

func (s *Semaphore) Release() {
    s.permits <- struct{}{}
}

// Usage
sem := NewSemaphore(3) // Max 3 concurrent operations

for i := 0; i < 10; i++ {
    go func(id int) {
        sem.Acquire()
        defer sem.Release()
        
        // Do work
        process(id)
    }(i)
}
```

## Error Handling in Goroutines

### Error Channel
```go
type Result struct {
    Value string
    Err   error
}

func concurrent() ([]string, error) {
    urls := []string{"url1", "url2", "url3"}
    results := make(chan Result, len(urls))
    
    for _, url := range urls {
        go func(u string) {
            data, err := fetch(u)
            results <- Result{Value: data, Err: err}
        }(url)
    }
    
    var values []string
    for i := 0; i < len(urls); i++ {
        result := <-results
        if result.Err != nil {
            return nil, result.Err
        }
        values = append(values, result.Value)
    }
    
    return values, nil
}
```

## Checklist
- [ ] Use channels for communication
- [ ] Close channels when done
- [ ] Handle goroutine leaks
- [ ] Use context for cancellation
- [ ] Implement proper error handling
- [ ] Apply worker pool for CPU-bound tasks
- [ ] Use select for multiplexing