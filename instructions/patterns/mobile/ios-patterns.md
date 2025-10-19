# iOS Development Patterns

Native iOS development patterns using Swift and SwiftUI.

## SwiftUI Architecture

### MVVM Pattern
```swift
import SwiftUI
import Combine

// Model
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var avatarURL: URL?
}

// ViewModel
@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service: UserService
    private var cancellables = Set<AnyCancellable>()
    
    init(service: UserService = UserService()) {
        self.service = service
    }
    
    func fetchUsers() async {
        isLoading = true
        error = nil
        
        do {
            users = try await service.fetchUsers()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

// View
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.users) { user in
                    NavigationLink(destination: UserDetailView(user: user)) {
                        UserRow(user: user)
                    }
                }
            }
            .navigationTitle("Users")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
            .task {
                await viewModel.fetchUsers()
            }
        }
    }
}
```

## Networking Layer

### Modern Async/Await API
```swift
import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

class NetworkService {
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init(session: URLSession = .shared) {
        self.session = session
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func fetch<T: Decodable>(_ type: T.Type, from endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
```

## Data Persistence

### Core Data with SwiftUI
```swift
import CoreData

// Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
}

// SwiftUI Integration
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<Item>
    
    var body: some View {
        List {
            ForEach(items) { item in
                Text(item.name ?? "")
            }
            .onDelete(perform: deleteItems)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}
```

## State Management

### Combine Publishers
```swift
import Combine

class AppState: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var settings = Settings()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // React to authentication changes
        $user
            .map { $0 != nil }
            .assign(to: &$isAuthenticated)
        
        // Auto-save settings
        $settings
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] settings in
                self?.saveSettings(settings)
            }
            .store(in: &cancellables)
    }
    
    private func saveSettings(_ settings: Settings) {
        UserDefaults.standard.set(try? JSONEncoder().encode(settings), forKey: "settings")
    }
}
```

## Custom UI Components

### Reusable SwiftUI Components
```swift
struct CustomButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray
            case .destructive: return .red
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(style.backgroundColor)
                .cornerRadius(10)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}
```

## Dependency Injection

### Container Pattern
```swift
protocol DependencyContainer {
    var networkService: NetworkService { get }
    var authService: AuthService { get }
    var storageService: StorageService { get }
}

class AppDependencyContainer: DependencyContainer {
    lazy var networkService: NetworkService = NetworkService()
    lazy var authService: AuthService = AuthService(network: networkService)
    lazy var storageService: StorageService = StorageService()
}

// Environment injection
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = AppDependencyContainer()
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// Usage
struct MyView: View {
    @Environment(\.dependencies) private var dependencies
    
    var body: some View {
        Text("Hello")
            .task {
                await dependencies.authService.authenticate()
            }
    }
}
```

## Navigation

### Navigation Coordinator
```swift
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    enum Destination: Hashable {
        case home
        case profile(userId: String)
        case settings
        case detail(item: Item)
    }
    
    func navigate(to destination: Destination) {
        path.append(destination)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
}

struct CoordinatorView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    switch destination {
                    case .home:
                        HomeView()
                    case .profile(let userId):
                        ProfileView(userId: userId)
                    case .settings:
                        SettingsView()
                    case .detail(let item):
                        DetailView(item: item)
                    }
                }
        }
        .environmentObject(coordinator)
    }
}
```

## Error Handling

### Result Type Pattern
```swift
enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
}

class DataService {
    func fetchData() async -> Result<[Data], Error> {
        do {
            let data = try await networkCall()
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    func processResult() async {
        let result = await fetchData()
        
        switch result {
        case .success(let data):
            handleSuccess(data)
        case .failure(let error):
            handleError(error)
        }
    }
}
```

## Testing

### Unit Testing
```swift
import XCTest
@testable import MyApp

class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    var mockService: MockUserService!
    
    override func setUp() {
        super.setUp()
        mockService = MockUserService()
        viewModel = UserViewModel(service: mockService)
    }
    
    func testFetchUsersSuccess() async {
        // Given
        let expectedUsers = [User(id: UUID(), name: "Test", email: "test@example.com")]
        mockService.users = expectedUsers
        
        // When
        await viewModel.fetchUsers()
        
        // Then
        XCTAssertEqual(viewModel.users, expectedUsers)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testFetchUsersFailure() async {
        // Given
        mockService.shouldFail = true
        
        // When
        await viewModel.fetchUsers()
        
        // Then
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertNotNil(viewModel.error)
    }
}
```

## Checklist
- [ ] Set up MVVM architecture
- [ ] Implement networking layer
- [ ] Configure Core Data
- [ ] Add dependency injection
- [ ] Create navigation coordinator
- [ ] Implement error handling
- [ ] Write unit tests
- [ ] Add UI tests