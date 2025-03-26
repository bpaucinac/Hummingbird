import Foundation
import SwiftUI

@MainActor
class SecurityViewModel: ObservableObject {
    @Published var securities: [Security] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
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
} 