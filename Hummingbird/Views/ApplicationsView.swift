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
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationLink(destination: SecurityDetailsView(securityId: security.id)
            .environmentObject(userViewModel)
            .environmentObject(viewModel)
        ) {
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
        .overlay {
            if !previewMode && securityViewModel.isLoadingDetails {
                LoadingOverlay(message: "Loading security details...")
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
            // Only load from API if not using preview data
            if !previewMode {
                Task {
                    await securityViewModel.loadSecurityDetails(token: userViewModel.token, securityId: securityId)
                }
            }
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