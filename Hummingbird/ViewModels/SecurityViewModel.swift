import Foundation
import SwiftUI

@MainActor
class SecurityViewModel: ObservableObject {
    @Published var securities: [Security] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var showError = false
    
    private let securityService = SecurityService()
    
    func loadSecurities(token: String, isRefreshing: Bool = false) async {
        if token.isEmpty {
            error = "Authentication token is missing"
            showError = true
            return
        }
        
        if isRefreshing {
            self.isRefreshing = true
        } else {
            self.isLoading = true
        }
        error = nil
        
        do {
            let securities = try await securityService.searchSecurities(token: token)
            self.securities = securities
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
} 