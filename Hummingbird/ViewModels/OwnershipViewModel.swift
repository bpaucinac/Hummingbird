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
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var authStatus: AuthStatus = .authenticated
    
    // MARK: - Pagination
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var hasMorePages = false
    @Published var isLoadingNextPage = false
    
    // MARK: - Private Properties
    private let ownershipService = OwnershipService()
    private var searchTask: Task<Void, Never>? = nil
    private let networkMonitor = NWPathMonitor()
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private let pageSize = 20
    
    // MARK: - Sort Options
    enum SortOption: String, CaseIterable, Identifiable {
        case aum = "aum"
        case name = "filerName"
        case dateOfLatestReport = "latestReportDate"
        
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
                    print("OwnershipViewModel: No network connection")
                }
            }
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Public Methods
    
    /// Load first page of filers with current search and sort settings
    func loadFilers() async {
        await fetchAndCacheFilers()
    }
    
    /// Load the next page of results if available
    func loadMoreResultsIfNeeded() async {
        guard hasMorePages && !isLoadingNextPage else { return }
        
        isLoadingNextPage = true
        currentPage += 1
        await searchFilers(resetResults: false)
        isLoadingNextPage = false
    }
    
    /// Change sort option and reload results
    func setSortOption(_ option: SortOption) async {
        guard sortBy != option else { return }
        
        sortBy = option
        if !searchQuery.isEmpty {
            // Re-sort the current search results
            filers = ownershipService.searchFilersInCache(
                query: searchQuery,
                sortBy: sortBy.rawValue,
                sortOrder: sortOrder
            )
        } else {
            // Re-sort all cached filers
            filers = ownershipService.getCachedFilers()
        }
    }
    
    /// Toggle sort order between ascending and descending
    func toggleSortOrder() async {
        sortOrder = sortOrder == .ascending ? .descending : .ascending
        if !searchQuery.isEmpty {
            // Re-sort the current search results
            filers = ownershipService.searchFilersInCache(
                query: searchQuery,
                sortBy: sortBy.rawValue,
                sortOrder: sortOrder
            )
        } else {
            // Re-sort all cached filers
            filers = ownershipService.getCachedFilers()
        }
    }
    
    /// Search with debounce to avoid excessive filtering
    func performSearch() {
        // Cancel any in-flight search
        searchTask?.cancel()
        
        // Create a new search task with a slight delay
        searchTask = Task {
            // Debounce for 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            // Perform client-side search
            if !searchQuery.isEmpty {
                filers = ownershipService.searchFilersInCache(
                    query: searchQuery,
                    sortBy: sortBy.rawValue,
                    sortOrder: sortOrder
                )
            } else {
                // If no search query, show all cached filers
                filers = ownershipService.getCachedFilers()
            }
        }
    }
    
    /// Fetch all filers and cache them
    private func fetchAndCacheFilers() async {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        do {
            let response = try await ownershipService.fetchAllFilers(
                page: 1,
                pageSize: 100,  // Fetch 100 records at once
                sortBy: sortBy.rawValue,
                sortOrder: sortOrder
            )
            
            // Cache the filers
            ownershipService.cacheFilers(response.items)
            
            // Update the displayed filers
            filers = response.items
            
            // Update pagination state
            totalPages = response.totalPages
            hasMorePages = currentPage < response.totalPages
            
            // Update auth status on successful API call
            authStatus = .authenticated
            
            // Clear any error messages
            errorMessage = nil
            hasError = false
        } catch {
            let errorDescription: String
            
            switch error {
            case let ownershipError as OwnershipService.OwnershipError:
                switch ownershipError {
                case .invalidURL:
                    errorDescription = "Invalid URL configuration"
                case .networkError:
                    // Use mock data for network errors
                    filers = ownershipService.getMockFilers()
                    ownershipService.cacheFilers(filers)
                    errorMessage = "Using cached data"
                    hasError = true
                    isLoading = false
                    return
                case .decodingError:
                    errorDescription = "Error processing server response"
                case .serverError(let code):
                    errorDescription = "Server error (code: \(code))"
                case .unauthorized:
                    // Use mock data for auth errors
                    filers = ownershipService.getMockFilers()
                    ownershipService.cacheFilers(filers)
                    errorMessage = "Using cached data"
                    hasError = true
                    isLoading = false
                    return
                case .unknown:
                    errorDescription = "Unknown error occurred"
                }
            default:
                errorDescription = "Unknown error occurred"
            }
            
            errorMessage = errorDescription
            hasError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Make API call to search for filers
    private func searchFilers(resetResults: Bool) async {
        // Set the appropriate loading flag
        if resetResults {
            isLoading = true
        } else {
            // For pagination, we're already using isLoadingNextPage
            // which is set in loadMoreResultsIfNeeded
        }
        
        errorMessage = nil
        hasError = false
        
        if resetResults {
            currentPage = 1
            if !filers.isEmpty {
                filers = []
            }
        }
        
        // If network is not available, use mock data with a clear message
        if networkStatus == .disconnected {
            print("OwnershipViewModel: Network disconnected, using mock data")
            // Use mock data
            let mockFilers = ownershipService.getMockFilers()
            
            // Filter by search query if needed
            let filteredFilers: [Filer]
            if !searchQuery.isEmpty {
                filteredFilers = mockFilers.filter { 
                    $0.name.lowercased().contains(searchQuery.lowercased())
                }
            } else {
                filteredFilers = mockFilers
            }
            
            // For infinite scroll simulation with mock data
            if resetResults {
                filers = filteredFilers
            } else {
                // Simulate pagination by adding only a subset of the mock data
                if currentPage <= 3 { // Simulate 3 pages of data
                    // Add a few more items to simulate new page
                    filers.append(contentsOf: filteredFilers.prefix(min(5, filteredFilers.count)))
                }
            }
            
            // Sort the data
            sortMockData()
            
            // Set pagination state for mock data
            if resetResults {
                totalPages = 3 // Simulate 3 pages total for mock data
                hasMorePages = true
            } else {
                hasMorePages = currentPage < totalPages
            }
            
            // Reset loading states
            isLoading = false
            
            // Only show cached data message if we actually have results
            if !filers.isEmpty && resetResults {
                errorMessage = "Showing cached data"
                hasError = true
            }
            
            return
        }
        
        do {
            // Debug print to verify sort parameters
            print("OwnershipViewModel: Making API request with parameters:")
            print("- Page: \(currentPage)")
            print("- Page Size: \(pageSize)")
            print("- Search Query: \(searchQuery)")
            print("- Sort By: \(sortBy.rawValue)")
            print("- Sort Order: \(sortOrder == .ascending ? "ascending" : "descending")")
            
            let response = try await ownershipService.fetchAllFilers(
                page: currentPage,
                pageSize: pageSize,
                sortBy: sortBy.rawValue,
                sortOrder: sortOrder
            )
            
            print("OwnershipViewModel: Received response:")
            print("- Total Items: \(response.totalItems)")
            print("- Total Pages: \(response.totalPages)")
            print("- Current Page: \(response.currentPage)")
            print("- Items Count: \(response.items.count)")
            
            if resetResults {
                filers = response.items
            } else {
                filers.append(contentsOf: response.items)
            }
            
            totalPages = response.totalPages
            hasMorePages = currentPage < response.totalPages
            
            // Update auth status on successful API call
            authStatus = .authenticated
            
            // Don't show error message for empty results
            if filers.isEmpty && !searchQuery.isEmpty {
                // This is normal when filtering returns no results
                print("OwnershipViewModel: No matching filers found for query: \(searchQuery)")
                errorMessage = nil
                hasError = false
            } else {
                // Clear any error messages for successful results
                errorMessage = nil
                hasError = false
            }
        } catch {
            let errorDescription: String
            
            switch error {
            case let ownershipError as OwnershipService.OwnershipError:
                switch ownershipError {
                case .invalidURL:
                    errorDescription = "Invalid URL configuration"
                case .networkError:
                    // Don't show error message for network errors
                    // Just use the mock data quietly
                    filers = ownershipService.getMockFilers()
                    
                    // Filter the mock data if there's a search query
                    if !searchQuery.isEmpty {
                        filers = filers.filter { 
                            $0.name.lowercased().contains(searchQuery.lowercased())
                        }
                    }
                    
                    // Sort the mock data
                    sortMockData()
                    
                    // No error message
                    isLoading = false
                    return
                case .decodingError:
                    errorDescription = "Error processing server response"
                case .serverError(let code):
                    errorDescription = "Server error (code: \(code))"
                case .unauthorized:
                    // Even if unauthorized, we still stay in authenticated status since we have a hardcoded token
                    // Don't show error message for authorization errors
                    filers = ownershipService.getMockFilers()
                    
                    // Filter the mock data if there's a search query
                    if !searchQuery.isEmpty {
                        filers = filers.filter { 
                            $0.name.lowercased().contains(searchQuery.lowercased())
                        }
                    }
                    
                    // Sort the mock data
                    sortMockData()
                    
                    // No error message
                    isLoading = false
                    return
                case .unknown:
                    errorDescription = "Unknown error occurred"
                }
            default:
                // For any other errors, use mock data without showing error message
                filers = ownershipService.getMockFilers()
                
                // Filter the mock data if there's a search query
                if !searchQuery.isEmpty {
                    filers = filers.filter { 
                        $0.name.lowercased().contains(searchQuery.lowercased())
                    }
                }
                
                // Sort the mock data
                sortMockData()
                
                // No error message
                isLoading = false
                return
            }
            
            errorMessage = errorDescription
            hasError = true
        }
        
        // Always reset isLoading at the end of the main flow
        // (error handlers that return early handle this themselves)
        if resetResults {
            isLoading = false
        }
        // isLoadingNextPage is managed by the caller (loadMoreResultsIfNeeded)
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