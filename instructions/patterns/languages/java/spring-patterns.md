# Spring Framework Patterns

Enterprise Java patterns using Spring Boot and Spring Framework.

## Dependency Injection

### Constructor Injection (Recommended)
```java
@Service
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;
    
    // Constructor injection - immutable and testable
    public UserService(UserRepository userRepository, 
                      EmailService emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

### Configuration Classes
```java
@Configuration
@EnableTransactionManagement
public class AppConfig {
    
    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://localhost/db");
        config.setUsername("user");
        config.setPassword("password");
        config.setMaximumPoolSize(10);
        return new HikariDataSource(config);
    }
    
    @Bean
    @Profile("dev")
    public CommandLineRunner dataLoader(UserRepository repo) {
        return args -> {
            repo.save(new User("test@example.com"));
        };
    }
}
```

## REST API Patterns

### RESTful Controller
```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;
    
    @GetMapping
    public Page<UserDto> getUsers(Pageable pageable) {
        return userService.findAll(pageable);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserDto createUser(@Valid @RequestBody CreateUserRequest request) {
        return userService.create(request);
    }
    
    @PutMapping("/{id}")
    public UserDto updateUser(@PathVariable Long id, 
                             @Valid @RequestBody UpdateUserRequest request) {
        return userService.update(id, request);
    }
    
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Long id) {
        userService.delete(id);
    }
}
```

## Exception Handling

### Global Exception Handler
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(
            ResourceNotFoundException ex) {
        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.NOT_FOUND.value())
            .message(ex.getMessage())
            .timestamp(LocalDateTime.now())
            .build();
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            errors.put(error.getField(), error.getDefaultMessage())
        );
        
        ErrorResponse error = ErrorResponse.builder()
            .status(HttpStatus.BAD_REQUEST.value())
            .message("Validation failed")
            .details(errors)
            .timestamp(LocalDateTime.now())
            .build();
        return ResponseEntity.badRequest().body(error);
    }
}
```

## Data Access Patterns

### JPA Repository
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByEmail(String email);
    
    @Query("SELECT u FROM User u WHERE u.status = :status")
    List<User> findByStatus(@Param("status") UserStatus status);
    
    @Modifying
    @Query("UPDATE User u SET u.lastLogin = :date WHERE u.id = :id")
    void updateLastLogin(@Param("id") Long id, @Param("date") LocalDateTime date);
    
    // Specification for complex queries
    default Page<User> findWithFilters(UserFilter filter, Pageable pageable) {
        Specification<User> spec = Specification.where(null);
        
        if (filter.getName() != null) {
            spec = spec.and((root, query, cb) -> 
                cb.like(root.get("name"), "%" + filter.getName() + "%"));
        }
        
        if (filter.getStatus() != null) {
            spec = spec.and((root, query, cb) -> 
                cb.equal(root.get("status"), filter.getStatus()));
        }
        
        return findAll(spec, pageable);
    }
}
```

## Service Layer Patterns

### Transactional Service
```java
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final NotificationService notificationService;
    
    @Transactional
    public OrderDto createOrder(CreateOrderRequest request) {
        // Validate
        validateOrder(request);
        
        // Create order
        Order order = orderRepository.save(
            Order.builder()
                .userId(request.getUserId())
                .items(request.getItems())
                .status(OrderStatus.PENDING)
                .build()
        );
        
        // Process payment
        PaymentResult payment = paymentService.process(order);
        
        if (payment.isSuccessful()) {
            order.setStatus(OrderStatus.PAID);
            order.setPaymentId(payment.getTransactionId());
            
            // Send notification
            notificationService.sendOrderConfirmation(order);
        } else {
            throw new PaymentFailedException(payment.getError());
        }
        
        return OrderMapper.toDto(order);
    }
}
```

## Security Patterns

### Spring Security Configuration
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter(), UsernamePasswordAuthenticationFilter.class)
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(unauthorizedHandler())
            );
        
        return http.build();
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

## Caching Patterns

### Spring Cache
```java
@Service
@CacheConfig(cacheNames = "users")
public class UserService {
    
    @Cacheable(key = "#id")
    public UserDto findById(Long id) {
        return userRepository.findById(id)
            .map(UserMapper::toDto)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
    
    @CachePut(key = "#result.id")
    public UserDto update(Long id, UpdateUserRequest request) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        
        return UserMapper.toDto(userRepository.save(user));
    }
    
    @CacheEvict(key = "#id")
    public void delete(Long id) {
        userRepository.deleteById(id);
    }
    
    @CacheEvict(allEntries = true)
    @Scheduled(fixedDelay = 3600000) // 1 hour
    public void evictAllCaches() {
        // Scheduled cache eviction
    }
}
```

## Event-Driven Patterns

### Application Events
```java
// Event definition
@Getter
public class UserCreatedEvent extends ApplicationEvent {
    private final User user;
    
    public UserCreatedEvent(Object source, User user) {
        super(source);
        this.user = user;
    }
}

// Event publisher
@Service
public class UserService {
    @Autowired
    private ApplicationEventPublisher eventPublisher;
    
    public User createUser(CreateUserRequest request) {
        User user = userRepository.save(new User(request));
        eventPublisher.publishEvent(new UserCreatedEvent(this, user));
        return user;
    }
}

// Event listener
@Component
public class UserEventListener {
    
    @EventListener
    @Async
    public void handleUserCreated(UserCreatedEvent event) {
        // Send welcome email
        emailService.sendWelcomeEmail(event.getUser());
    }
    
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handleUserCreatedAfterCommit(UserCreatedEvent event) {
        // Actions after transaction commit
        analyticsService.trackUserCreation(event.getUser());
    }
}
```

## Testing Patterns

### Integration Testing
```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UserControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void shouldCreateUser() throws Exception {
        String userJson = """
            {
                "name": "John Doe",
                "email": "john@example.com"
            }
            """;
        
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(userJson))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("John Doe"))
            .andExpect(jsonPath("$.email").value("john@example.com"));
    }
}
```

## Checklist
- [ ] Use constructor injection
- [ ] Implement proper exception handling
- [ ] Add validation annotations
- [ ] Configure security properly
- [ ] Implement caching strategy
- [ ] Write integration tests
- [ ] Use profiles for environments