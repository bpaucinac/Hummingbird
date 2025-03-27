import Foundation
import Combine
import Network

@MainActor
class OwnershipViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var filers: [Filer] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var hasError = false
    @Published var searchQuery = ""
    @Published var sortBy = SortOption.aum
    @Published var sortOrder = OwnershipService.SortOrder.descending
    @Published var isOfflineMode = false
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var authStatus: AuthStatus = .authenticated
    
    // MARK: - Pagination
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var hasMorePages = false
    
    // MARK: - Private Properties
    private let ownershipService = OwnershipService()
    private var searchTask: Task<Void, Never>? = nil
    private let networkMonitor = NWPathMonitor()
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Sort Options
    enum SortOption: String, CaseIterable, Identifiable {
        case aum = "aum"
        case name = "name"
        case dateOfLatestReport = "dateOfLatestReport"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .aum: return "Assets Under Management"
            case .name: return "Filer Name"
            case .dateOfLatestReport: return "Latest Report Date"
            }
        }
    }
    
    // MARK: - Network Status
    enum NetworkStatus {
        case connected
        case disconnected
        case unknown
    }
    
    // MARK: - Auth Status
    enum AuthStatus {
        case authenticated
        case unauthenticated
        case unknown
        
        var isAuthenticated: Bool {
            self == .authenticated
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied {
                    self?.networkStatus = .connected
                    print("OwnershipViewModel: Network connection available")
                } else {
                    self?.networkStatus = .disconnected
                    self?.isOfflineMode = true
                    print("OwnershipViewModel: No network connection")
                }
            }
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Public Methods
    
    /// Load first page of filers with current search and sort settings
    func loadFilers() async {
        await searchFilers(resetResults: true)
    }
    
    /// Load the next page of results if available
    func loadMoreResultsIfNeeded() async {
        guard hasMorePages && !isLoading else { return }
        
        currentPage += 1
        await searchFilers(resetResults: false)
    }
    
    /// Change sort option and reload results
    func setSortOption(_ option: SortOption) async {
        guard sortBy != option else { return }
        
        sortBy = option
        await searchFilers(resetResults: true)
    }
    
    /// Toggle sort order between ascending and descending
    func toggleSortOrder() async {
        sortOrder = sortOrder == .ascending ? .descending : .ascending
        await searchFilers(resetResults: true)
    }
    
    /// Toggle between online and offline mode
    func toggleOfflineMode() {
        isOfflineMode.toggle()
        Task {
            await loadFilers()
        }
    }
    
    /// Search with debounce to avoid excessive API calls
    func performSearch() {
        // Cancel any in-flight search
        searchTask?.cancel()
        
        // Create a new search task with a slight delay
        searchTask = Task {
            // Debounce for 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            await searchFilers(resetResults: true)
        }
    }
    
    // MARK: - Private Methods
    
    /// Make API call to search for filers or use mock data in offline mode
    private func searchFilers(resetResults: Bool) async {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        if resetResults {
            currentPage = 1
            if !filers.isEmpty {
                filers = []
            }
        }
        
        // If in offline mode or network is not available, use mock data
        if isOfflineMode || networkStatus == .disconnected {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Use mock data
            filers = ownershipService.getMockFilers()
            
            // Filter by search query if needed
            if !searchQuery.isEmpty {
                filers = filers.filter { 
                    $0.name.lowercased().contains(searchQuery.lowercased())
                }
            }
            
            // Sort the data
            sortMockData()
            
            totalPages = 1
            hasMorePages = false
            isLoading = false
            
            if filers.isEmpty {
                errorMessage = "No results found"
                hasError = true
            }
            
            return
        }
        
        do {
            let response = try await ownershipService.searchFilers(
                page: currentPage,
                pageSize: 20,
                query: searchQuery.isEmpty ? nil : searchQuery,
                sortBy: sortBy.rawValue,
                sortOrder: sortOrder
            )
            
            if resetResults {
                filers = response.items
            } else {
                filers.append(contentsOf: response.items)
            }
            
            totalPages = response.totalPages
            hasMorePages = currentPage < response.totalPages
            
            // Update auth status on successful API call
            authStatus = .authenticated
        } catch {
            let errorDescription: String
            
            switch error {
            case let ownershipError as OwnershipService.OwnershipError:
                switch ownershipError {
                case .invalidURL:
                    errorDescription = "Invalid URL configuration"
                case .networkError:
                    errorDescription = "Network error - check your connection"
                    // Switch to offline mode with mock data
                    isOfflineMode = true
                    filers = ownershipService.getMockFilers()
                    sortMockData()
                case .decodingError:
                    errorDescription = "Error processing server response"
                case .serverError(let code):
                    errorDescription = "Server error (code: \(code))"
                case .unauthorized:
                    errorDescription = "Unauthorized - API token may have expired"
                    // Even if unauthorized, we still stay in authenticated status since we have a hardcoded token
                    isOfflineMode = true
                    filers = ownershipService.getMockFilers()
                    sortMockData()
                case .unknown:
                    errorDescription = "Unknown error occurred"
                }
            default:
                errorDescription = error.localizedDescription
                // Also use mock data for other errors
                isOfflineMode = true
                filers = ownershipService.getMockFilers()
                sortMockData()
            }
            
            errorMessage = errorDescription
            hasError = true
        }
        
        isLoading = false
    }
    
    /// Sort the mock data according to current sort settings
    private func sortMockData() {
        switch sortBy {
        case .aum:
            filers.sort { a, b in
                let aumA = a.aum ?? 0
                let aumB = b.aum ?? 0
                return sortOrder == .ascending ? aumA < aumB : aumA > aumB
            }
        case .name:
            filers.sort { a, b in
                let nameA = a.name.lowercased()
                let nameB = b.name.lowercased()
                return sortOrder == .ascending ? nameA < nameB : nameA > nameB
            }
        case .dateOfLatestReport:
            filers.sort { a, b in
                let dateA = a.dateOfLatestReport ?? ""
                let dateB = b.dateOfLatestReport ?? ""
                return sortOrder == .ascending ? dateA < dateB : dateA > dateB
            }
        }
    }
} 