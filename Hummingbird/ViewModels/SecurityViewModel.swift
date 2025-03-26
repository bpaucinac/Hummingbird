import Foundation
import SwiftUI

@MainActor
class SecurityViewModel: ObservableObject {
    @Published var securities: [Security] = []
    @Published var securityDetails: SecurityDetails?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var isLoadingDetails = false
    @Published var error: String?
    @Published var showError = false
    @Published var hasMorePages = true
    @Published var primaryOnly = false
    @Published var searchCriteria = ""
    
    private let securityService = SecurityService()
    private var currentPage = 1
    private let pageSize = 20
    
    func loadSecurities(token: String, isRefreshing: Bool = false) async {
        if token.isEmpty {
            error = "Authentication token is missing"
            showError = true
            return
        }
        
        if isRefreshing {
            self.isRefreshing = true
            currentPage = 1
        } else {
            self.isLoading = true
        }
        error = nil
        
        do {
            let securities = try await securityService.searchSecurities(
                token: token,
                page: currentPage,
                pageSize: pageSize,
                criteria: searchCriteria,
                listedOnly: false,
                primaryOnly: primaryOnly
            )
            
            if isRefreshing {
                self.securities = securities
            } else {
                self.securities = securities
            }
            
            // Update pagination state
            hasMorePages = !securities.isEmpty && securities.count == pageSize
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        if isRefreshing {
            self.isRefreshing = false
        } else {
            self.isLoading = false
        }
    }
    
    func loadMoreSecurities(token: String) async {
        guard hasMorePages, !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let newSecurities = try await securityService.searchSecurities(
                token: token,
                page: currentPage,
                pageSize: pageSize,
                criteria: searchCriteria,
                listedOnly: false,
                primaryOnly: primaryOnly
            )
            
            self.securities.append(contentsOf: newSecurities)
            hasMorePages = !newSecurities.isEmpty && newSecurities.count == pageSize
        } catch {
            self.error = error.localizedDescription
            showError = true
            currentPage -= 1 // Revert page increment on error
        }
        
        isLoadingMore = false
    }
    
    func loadSecurityDetails(token: String, securityId: String) async {
        guard !token.isEmpty else {
            error = "Authentication token is missing"
            showError = true
            return
        }
        
        isLoadingDetails = true
        error = nil
        
        do {
            self.securityDetails = try await securityService.getSecurityDetails(token: token, securityId: securityId)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        isLoadingDetails = false
    }
    
    func togglePrimaryOnly() {
        primaryOnly.toggle()
    }
    
    func setSearchCriteria(_ criteria: String) {
        searchCriteria = criteria
    }
    
    func refreshWithCurrentFilters(token: String) async {
        await loadSecurities(token: token, isRefreshing: true)
    }
    
    func formatPrice(_ price: Double?) -> String {
        guard let price = price else { return "N/A" }
        return Formatters.priceFormatter.string(from: NSNumber(value: price)) ?? "N/A"
    }
    
    func formatReturn(_ returnValue: Double?) -> String {
        guard let returnValue = returnValue else { return "N/A" }
        return Formatters.returnFormatter.string(from: NSNumber(value: returnValue)) ?? "N/A"
    }
    
    func formatMarketCap(_ marketCap: Double?) -> String {
        return Formatters.formatMarketCap(marketCap)
    }
    
    func resetFilters() {
        primaryOnly = false
        searchCriteria = ""
    }
    
    func formatDate(_ dateString: String?) -> String {
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
}

// MARK: - Preview Helpers
extension SecurityViewModel {
    static var preview: SecurityViewModel {
        let viewModel = SecurityViewModel()
        
        // Create mock security details
        let mockDetails = SecurityDetails(
            id: "c240d763-c854-45f0-b551-650fae813339",
            shortName: "Apple Inc",
            longName: "Apple Inc.",
            description: "Apple Inc.",
            ticker: "AAPL",
            bbgTicker: "AAPL UW Equity",
            compositeBbgTicker: "AAPL US Equity",
            figi: "BBG000B9Y5X2",
            compositeFigi: "BBG000B9XRY4",
            shareClassFigi: "BBG001S5N8V8",
            isin: "US0378331005",
            cusip: "037833100",
            sedol: "2046251",
            assetType: "Ordinary Shares",
            assetClass: "Equity",
            currency: "USD",
            country: "US",
            exchange: Exchange(
                id: 416,
                name: "NASDAQ Global Select",
                mic: "XNGS",
                bbgExchangeCode: "UW",
                countryIso2Code: "US"
            ),
            issuer: Issuer(
                id: "5782b131-0029-45bc-a09a-334e36922582",
                name: "Apple Inc.",
                countryDomicile: "US",
                countryIncorporation: "US",
                ipoDate: "1980-12-12T00:00:00Z",
                isActive: true,
                isPublic: true
            ),
            instrument: Instrument(
                id: "3a1a85dc-e3a9-4f7b-adc0-af67f34acf3f",
                name: "Apple Inc."
            ),
            classifications: [
                Classification(
                    id: 8,
                    type: "Gics",
                    subType: "Sector",
                    name: "Information Technology",
                    code: "45",
                    effectiveFrom: "2014-03-14T00:00:00Z",
                    effectiveTo: nil
                ),
                Classification(
                    id: 32,
                    type: "Gics",
                    subType: "IndustryGroup",
                    name: "Technology Hardware & Equipment",
                    code: "4520",
                    effectiveFrom: "2014-03-14T00:00:00Z",
                    effectiveTo: nil
                ),
                Classification(
                    id: 96,
                    type: "Gics",
                    subType: "Industry",
                    name: "Technology Hardware, Storage & Peripherals",
                    code: "452020",
                    effectiveFrom: "2014-03-14T00:00:00Z",
                    effectiveTo: nil
                ),
                Classification(
                    id: 268,
                    type: "Gics",
                    subType: "SubIndustry",
                    name: "Technology Hardware, Storage & Peripherals",
                    code: "45202030",
                    effectiveFrom: "2014-03-14T00:00:00Z",
                    effectiveTo: nil
                )
            ],
            activeSymbols: [
                Symbol(
                    id: "3bff66ae-d636-4a91-83f5-32fb146547f3",
                    type: "Ticker",
                    effectiveFrom: "1980-12-12T00:00:00Z",
                    effectiveTo: nil,
                    value: "AAPL"
                ),
                Symbol(
                    id: "32dc341a-3466-426f-8266-3981239c3d2c",
                    type: "CompositeFigi",
                    effectiveFrom: "1980-12-12T00:00:00Z",
                    effectiveTo: nil,
                    value: "BBG000B9XRY4"
                )
            ],
            historicalSymbols: [],
            vendorIds: [
                VendorID(type: "QadInfoCode", value: "72990"),
                VendorID(type: "QadOvsSecCode", value: "1133")
            ],
            isComposite: true,
            isPrimary: true,
            isCustom: false,
            isGlobal: false,
            isActive: true,
            orgIsActive: true,
            dateOfFirstListing: "1980-12-12",
            dateOfDelisting: nil,
            createdAt: "2022-10-06T17:05:22.259126Z",
            updatedAt: "2025-03-25T17:22:02.50636Z"
        )
        
        // Set the mock details in the view model
        viewModel.securityDetails = mockDetails
        
        // Create some mock securities
        viewModel.securities = [Security.preview]
        
        return viewModel
    }
} 