import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var securityViewModel: SecurityViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Market Overview Section
                Section {
                    Text("Market Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        MarketOverviewCard(
                            title: "S&P 500",
                            value: "5,254.67",
                            change: "+0.54%",
                            isPositive: true
                        )
                        
                        MarketOverviewCard(
                            title: "Nasdaq",
                            value: "16,384.45",
                            change: "+0.34%",
                            isPositive: true
                        )
                        
                        MarketOverviewCard(
                            title: "Dow Jones",
                            value: "39,170.35",
                            change: "-0.12%",
                            isPositive: false
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Securities Section
                Section {
                    HStack {
                        Text("Securities")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: SecuritiesView()
                            .environmentObject(securityViewModel)
                            .environmentObject(userViewModel)
                            .navigationTitle("Securities")
                        ) {
                            Text("See All")
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<5) { _ in
                                SecurityPreviewCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // News Section
                Section {
                    HStack {
                        Text("Latest News")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            // Handle see all action
                        } label: {
                            Text("See All")
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(1...3, id: \.self) { index in
                            NewsCard(
                                title: "Market update #\(index)",
                                source: "Financial Times",
                                timeAgo: "\(index * 2)h ago"
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct MarketOverviewCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    Text(change)
                }
                .foregroundColor(isPositive ? .success : .error)
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct SecurityPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text("A")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AAPL")
                        .font(.headline)
                    
                    Text("Apple Inc.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("$198.45")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text("+1.2%")
                }
                .foregroundColor(.success)
                .font(.subheadline)
            }
        }
        .padding()
        .frame(width: 220, height: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct NewsCard: View {
    let title: String
    let source: String
    let timeAgo: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "newspaper.fill")
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Text(source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
                    
                    // Filters Section
                    VStack(spacing: 12) {
                        // Primary toggle
                        HStack {
                            Toggle("Primary Only", isOn: $securityViewModel.primaryOnly)
                                .onChange(of: securityViewModel.primaryOnly) { _, _ in
                                    Task {
                                        await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
                                    }
                                }
                            
                            Spacer()
                        }
                        
                        // Asset Class Picker
                        HStack {
                            Text("Asset Class")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Menu {
                                ForEach(securityViewModel.availableAssetClasses, id: \.self) { assetClass in
                                    Button(action: {
                                        securityViewModel.selectedAssetClass = assetClass
                                        Task {
                                            await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
                                        }
                                    }) {
                                        HStack {
                                            Text(assetClass)
                                            if assetClass == securityViewModel.selectedAssetClass {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(securityViewModel.selectedAssetClass)
                                        .foregroundStyle(.primary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        // Active Filters Indicator
                        if securityViewModel.primaryOnly || !searchText.isEmpty {
                            HStack {
                                Text("Active Filters:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if securityViewModel.primaryOnly {
                                    FilterChip(text: "Primary Only")
                                }
                                
                                if !searchText.isEmpty {
                                    FilterChip(text: "Search: \(searchText)")
                                }
                                
                                FilterChip(text: "Asset Class: \(securityViewModel.selectedAssetClass)")
                                
                                Spacer()
                                
                                Button("Clear All") {
                                    securityViewModel.resetFilters()
                                    searchText = ""
                                    Task {
                                        await securityViewModel.refreshWithCurrentFilters(token: userViewModel.token)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.accent)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
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
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var isNavigating = false
    
    var body: some View {
        Button {
            // Pre-fetch details before navigation
            Task {
                await viewModel.loadSecurityDetails(token: userViewModel.token, securityId: security.id)
                isNavigating = true
            }
        } label: {
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
        }
        .buttonStyle(.plain)
        .background(
            NavigationLink(
                destination: SecurityDetailsView(securityId: security.id)
                    .environmentObject(userViewModel)
                    .environmentObject(viewModel),
                isActive: $isNavigating
            ) { EmptyView() }
        )
    }
}

// MARK: - Security Details View
struct SecurityDetailsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var securityViewModel: SecurityViewModel
    let securityId: String
    
    // For preview support
    private var previewDetails: SecurityDetails?
    private var previewMode: Bool = false
    
    init(securityId: String, previewDetails: SecurityDetails? = nil) {
        self.securityId = securityId
        self.previewDetails = previewDetails
        self.previewMode = previewDetails != nil
    }
    
    // Preview helper to format dates
    private func previewFormatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "N/A" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // Preview helper to get formatter for the view
    private func getFormatter() -> ((_ date: String?) -> String) {
        return previewMode ? previewFormatDate : securityViewModel.formatDate
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                if let details = previewDetails ?? securityViewModel.securityDetails {
                    VStack(spacing: 24) {
                        // Company Logo and Name Card
                        HStack(alignment: .center, spacing: 16) {
                            AsyncImage(url: details.logoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } placeholder: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.accentColor.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Text(details.shortName.prefix(1))
                                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(details.longName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(details.ticker)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // General Information Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("General")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 20) {
                                // Security ID
                                InfoRow(title: "Security ID", value: details.id)
                                
                                // Issuer ID
                                InfoRow(title: "Issuer ID", value: details.issuer.id)
                                
                                // Instrument ID
                                InfoRow(title: "Instrument ID", value: details.instrument.id)
                                
                                // Name
                                InfoRow(title: "Name", value: details.longName)
                            }
                            
                            Divider()
                            
                            HStack {
                                // Status Flags
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Status Flags")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        ForEach(details.status, id: \.self) { status in
                                            StatusBadge(label: status)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            // Exchange
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Exchange")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(details.exchange.name)
                                        .font(.body)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            // MIC and BBG Code
                            HStack {
                                // MIC
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MIC")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack {
                                        Text(details.exchange.mic)
                                            .font(.body)
                                    }
                                }
                                
                                Spacer()
                                
                                // BBG Code
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("BBG Code")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(details.exchange.bbgExchangeCode)
                                        .font(.body)
                                }
                            }
                            
                            Divider()
                            
                            // Country Information
                            VStack(spacing: 20) {
                                // Country Domicile
                                InfoRow(title: "Country Domicile", value: details.issuer.countryDomicile)
                                
                                // Country Incorporation
                                InfoRow(title: "Country Incorporation", value: details.issuer.countryIncorporation)
                            }
                            
                            Divider()
                            
                            // Currency and IPO Date
                            HStack {
                                // Currency
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Currency")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(details.currency)
                                        .font(.body)
                                }
                                
                                Spacer()
                                
                                // IPO Date
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("IPO Date")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(getFormatter()(details.issuer.ipoDate))
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // GICS Classifications Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("GICS Classifications")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            // Table Headers
                            HStack {
                                Text("Effective Dates")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Sub Industry")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Sector / Industry Group / Industry")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 8)
                            
                            Divider()
                            
                            // Classification rows
                            let sectorClassifications = details.classifications.filter { $0.type == "Gics" && $0.subType == "Sector" }
                            let industryGroupClassifications = details.classifications.filter { $0.type == "Gics" && $0.subType == "IndustryGroup" }
                            let industryClassifications = details.classifications.filter { $0.type == "Gics" && $0.subType == "Industry" }
                            let subIndustryClassifications = details.classifications.filter { $0.type == "Gics" && $0.subType == "SubIndustry" }
                            
                            ForEach(subIndustryClassifications, id: \.id) { subIndustry in
                                VStack(spacing: 8) {
                                    HStack(alignment: .top) {
                                        // Effective dates
                                        Text(getEffectiveDates(classification: subIndustry, formatter: getFormatter()))
                                            .font(.callout)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Sub Industry
                                        Text("\(subIndustry.code) - \(subIndustry.name)")
                                            .font(.callout)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Sector/Industry/Industry Group chain
                                        let sector = sectorClassifications.first { isInDateRange(subIndustry, classification: $0) }
                                        let industryGroup = industryGroupClassifications.first { isInDateRange(subIndustry, classification: $0) }
                                        let industry = industryClassifications.first { isInDateRange(subIndustry, classification: $0) }
                                        
                                        Text(getClassificationChain(sector: sector, industryGroup: industryGroup, industry: industry))
                                            .font(.callout)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    Divider()
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Vendor Identifiers Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Vendor Identifiers")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            // Table Headers
                            HStack {
                                Text("Type")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Value")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.horizontal, 8)
                            
                            Divider()
                            
                            // Vendor ID rows
                            ForEach(details.vendorIds, id: \.type) { vendorId in
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(vendorId.type)
                                            .font(.callout)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(vendorId.value)
                                            .font(.callout)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    
                                    Divider()
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Active Symbols Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Active Symbols")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            // Symbols
                            ForEach(details.activeSymbols, id: \.id) { symbol in
                                VStack(spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(symbol.type)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            
                                            Text(symbol.value)
                                                .font(.body)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Effective From")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            
                                            Text(getFormatter()(symbol.effectiveFrom))
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Divider()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(previewDetails?.ticker ?? securityViewModel.securityDetails?.ticker ?? "Security Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $securityViewModel.showError) {
            Button("OK") {
                securityViewModel.error = nil
            }
        } message: {
            Text(securityViewModel.error ?? "")
        }
    }
    
    // Helper for formatting effective dates
    private func getEffectiveDates(classification: Classification, formatter: (_ date: String?) -> String) -> String {
        let from = formatter(classification.effectiveFrom)
        let to = classification.effectiveTo != nil ? formatter(classification.effectiveTo) : "Present"
        return "\(from) - \(to)"
    }
    
    // Helper to check if a classification is in the same date range as another
    private func isInDateRange(_ referenceClassification: Classification, classification: Classification?) -> Bool {
        guard let classification = classification else { return false }
        
        // Check if the effectiveFrom dates are close to each other (within a few days)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let refDate = formatter.date(from: referenceClassification.effectiveFrom),
           let compDate = formatter.date(from: classification.effectiveFrom) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: refDate, to: compDate)
            let dayDifference = abs(components.day ?? 0)
            
            // If dates are within a reasonable range (e.g., 7 days)
            return dayDifference <= 7
        }
        
        return false
    }
    
    // Helper to build classification chain
    private func getClassificationChain(sector: Classification?, industryGroup: Classification?, industry: Classification?) -> String {
        var chain = [String]()
        
        if let sector = sector {
            chain.append("\(sector.name)")
        }
        
        if let industryGroup = industryGroup {
            chain.append("\(industryGroup.name)")
        }
        
        if let industry = industry {
            chain.append("\(industry.name)")
        }
        
        return chain.joined(separator: " / ")
    }
}

// Helper Views
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct StatusBadge: View {
    let label: String
    
    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(.accent)
            .clipShape(Capsule())
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
        .environmentObject(SecurityViewModel.preview)
}

#Preview("Securities") {
    NavigationStack {
        SecuritiesView()
            .environmentObject(UserViewModel())
            .environmentObject(SecurityViewModel.preview)
    }
}

#Preview("Security Card") {
    SecurityCard(
        security: .preview,
        viewModel: SecurityViewModel.preview
    )
    .padding()
}

#Preview("Security Details") {
    let viewModel = SecurityViewModel.preview
    return NavigationStack {
        SecurityDetailsView(
            securityId: "c240d763-c854-45f0-b551-650fae813339",
            previewDetails: viewModel.securityDetails
        )
    }
}

#Preview("Security Details (Standalone)") {
    NavigationStack {
        SecurityDetailsView(
            securityId: "c240d763-c854-45f0-b551-650fae813339", 
            previewDetails: SecurityViewModel.preview.securityDetails
        )
    }
} 