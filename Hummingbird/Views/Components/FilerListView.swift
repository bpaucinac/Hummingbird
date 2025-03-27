import SwiftUI

struct FilerListView: View {
    @ObservedObject var viewModel: OwnershipViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
            
            // Network status indicator
            networkStatusBar
            
            // Sort controls
            sortControls
            
            // Divider
            Divider()
                .padding(.top, 8)
            
            // Filer list
            filerList
        }
        .task {
            if viewModel.filers.isEmpty {
                await viewModel.loadFilers()
            }
        }
        .alert(isPresented: $viewModel.hasError, content: {
            Alert(
                title: Text(viewModel.errorMessage == "Showing cached data" ? "Info" : "Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search filers...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                    viewModel.performSearch()
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    Task {
                        await viewModel.loadFilers()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Network Status Bar
    private var networkStatusBar: some View {
        HStack {
            // Network status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(.systemGroupedBackground).opacity(0.5))
    }
    
    // Network status color
    private var statusColor: Color {
        switch viewModel.networkStatus {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .unknown:
            return .yellow
        }
    }
    
    // Network status text
    private var statusText: String {
        switch viewModel.networkStatus {
        case .connected:
            return "Connected to API"
        case .disconnected:
            return "Using Cached Data"
        case .unknown:
            return "Checking Connection..."
        }
    }
    
    // MARK: - Sort Controls
    private var sortControls: some View {
        HStack {
            Text("Sort by:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(OwnershipViewModel.SortOption.allCases) { option in
                    Button {
                        Task {
                            await viewModel.setSortOption(option)
                        }
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if viewModel.sortBy == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.sortBy.displayName)
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.toggleSortOrder()
                }
            } label: {
                Image(systemName: viewModel.sortOrder == .ascending ? "arrow.up" : "arrow.down")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filer List
    private var filerList: some View {
        List {
            // Empty state when no results
            if viewModel.filers.isEmpty && !viewModel.isLoading {
                Text(viewModel.searchQuery.isEmpty ? "No filers found" : "No matching filers found")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .padding()
            }
            
            ForEach(viewModel.filers) { filer in
                FilerRowView(filer: filer)
                    .onAppear {
                        // Load more results when approaching the end of the list
                        // We check if we're within 5 items of the end
                        if shouldLoadMore(for: filer) {
                            Task {
                                await viewModel.loadMoreResultsIfNeeded()
                            }
                        }
                    }
            }
            
            // Loading indicator at bottom of list
            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading more filers...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
            
            // End of list indicator when we've reached the last page
            if !viewModel.hasMorePages && !viewModel.filers.isEmpty && !viewModel.isLoading {
                HStack {
                    Spacer()
                    Text("End of results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadFilers()
        }
    }
    
    // Function to determine if we should load more data
    private func shouldLoadMore(for filer: Filer) -> Bool {
        guard viewModel.hasMorePages && !viewModel.isLoadingNextPage else { return false }
        
        // Get the index of the current filer
        if let index = viewModel.filers.firstIndex(where: { $0.id == filer.id }) {
            // Load more when we're 5 items from the end or less
            let thresholdIndex = viewModel.filers.count - 5
            return index >= thresholdIndex
        }
        
        return false
    }
}

// MARK: - Filer Row View
struct FilerRowView: View {
    let filer: Filer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Filer name
            Text(filer.name)
                .font(.headline)
                .lineLimit(1)
            
            // Filer details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // ID
                    HStack {
                        Text("ID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(filer.externalId1 ?? "N/A")
                            .font(.caption)
                    }
                    
                    // Location
                    if let city = filer.city, let country = filer.country {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(city.capitalized), \(country)")
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // AUM
                    Text(filer.formattedAUM)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Latest report date
                    Text("Last report: \(filer.formattedDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
} 