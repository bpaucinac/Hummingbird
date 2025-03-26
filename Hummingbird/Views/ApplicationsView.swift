import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var securityViewModel: SecurityViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: SecuritiesView()
                        .environmentObject(securityViewModel)
                        .environmentObject(userViewModel)
                        .navigationTitle("Securities")
                    ) {
                        ApplicationCard(
                            title: "Securities",
                            description: "Market data and securities",
                            iconName: "chart.bar",
                            color: .accentColor
                        )
                    }
                    
                    // Placeholder for future apps
                    ApplicationCard(
                        title: "Portfolio",
                        description: "Track your holdings",
                        iconName: "briefcase",
                        color: .green
                    )
                    .opacity(0.6)
                    
                    ApplicationCard(
                        title: "News",
                        description: "Financial news",
                        iconName: "newspaper",
                        color: .orange
                    )
                    .opacity(0.6)
                    
                    ApplicationCard(
                        title: "Research",
                        description: "Analyst reports",
                        iconName: "doc.text.magnifyingglass",
                        color: .purple
                    )
                    .opacity(0.6)
                }
                .padding()
            }
            .padding(.top)
        }
    }
}

struct ApplicationCard: View {
    var title: String
    var description: String
    var iconName: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: iconName)
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                Spacer()
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(height: 160)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle()) // Ensures the entire card is tappable
        .frame(minWidth: 44, minHeight: 44) // Minimum touch target size
    }
}

struct SecuritiesView: View {
    @EnvironmentObject var securityViewModel: SecurityViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshable = false
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)
                
                VStack(spacing: 16) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search securities...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onChange(of: searchText) { _, newValue in
                                securityViewModel.setSearchCriteria(newValue)
                                Task {
                                    await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
                                }
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    
                    // Primary toggle
                    HStack {
                        Toggle("Primary Only", isOn: $securityViewModel.primaryOnly)
                            .padding(.horizontal)
                            .onChange(of: securityViewModel.primaryOnly) { _, _ in
                                Task {
                                    await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
                                }
                            }
                    }
                    
                    if securityViewModel.securities.isEmpty && !securityViewModel.isLoading {
                        ContentUnavailableView {
                            Label("No Securities", systemImage: "chart.bar")
                        } description: {
                            Text("Pull to refresh or try again later")
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(securityViewModel.securities) { security in
                                SecurityCard(security: security, viewModel: securityViewModel)
                                    .padding(.horizontal)
                            }
                            
                            if securityViewModel.hasMorePages {
                                ProgressView()
                                    .padding()
                                    .onAppear {
                                        Task {
                                            await securityViewModel.loadMoreSecurities(token: userViewModel.token)
                                        }
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            scrollOffset = offset
            // Only enable refresh when pulled down more than 50 points
            isRefreshable = offset > 50
        }
        .refreshable(action: {
            if isRefreshable {
                await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
            }
        })
        .overlay {
            if securityViewModel.isLoading {
                LoadingOverlay(message: "Loading securities...")
            }
        }
        .alert("Error", isPresented: $securityViewModel.showError) {
            Button("OK") {
                securityViewModel.error = nil
            }
        } message: {
            Text(securityViewModel.error ?? "")
        }
        .onAppear {
            // Reset state to defaults
            searchText = ""
            securityViewModel.resetFilters()
            
            // Refresh with default filters
            Task {
                await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SecurityCard: View {
    let security: Security
    let viewModel: SecurityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                AsyncImage(url: security.logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Text(security.shortName.prefix(1))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(security.shortName)
                        .font(.headline)
                    
                    Text(security.ticker)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formatPrice(security.latestPrice?.closeFullAdj))
                        .font(.headline)
                    
                    HStack(spacing: 2) {
                        Text(viewModel.formatReturn(security.latestPrice?.totalReturn))
                            .font(.subheadline)
                            .foregroundStyle(security.latestPrice?.totalReturn ?? 0 >= 0 ? .green : .red)
                    }
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sector")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(security.sectorName)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Market Cap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.formatMarketCap(security.latestMktCap?.localCurrencyConsolidatedMarketValue))
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview Helpers
extension Security {
    static let preview = Security(
        id: "AAPL",
        shortName: "Apple Inc",
        longName: "Apple Inc.",
        ticker: "AAPL",
        assetClass: "Equity",
        currency: "USD",
        classifications: [
            Classification(
                id: 1,
                type: "Industry",
                subType: "Sector",
                name: "Technology",
                code: "TECH",
                effectiveFrom: "2020-01-01",
                effectiveTo: nil
            )
        ],
        latestPrice: LatestPrice(
            tradeDate: "2024-03-26",
            closeFullAdj: 172.45,
            totalReturn: 12.5
        ),
        latestMktCap: LatestMarketCap(
            localCurrencyConsolidatedMarketValue: 2750000000000.0
        ),
        isActive: true
    )
}

#Preview("Applications") {
    ApplicationsView()
        .environmentObject(UserViewModel())
        .environmentObject(SecurityViewModel())
}

#Preview("Securities") {
    NavigationStack {
        SecuritiesView()
            .environmentObject(UserViewModel())
            .environmentObject(SecurityViewModel())
    }
}

#Preview("Security Card") {
    SecurityCard(
        security: .preview,
        viewModel: SecurityViewModel()
    )
    .padding()
} 