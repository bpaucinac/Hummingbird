import Foundation
import SwiftUI

class SecurityViewModel: ObservableObject {
    @Published var securities: [Security] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    private let securityService = SecurityService()
    
    func loadSecurities(token: String) async {
        if token.isEmpty {
            DispatchQueue.main.async {
                self.error = "Authentication token is missing"
                self.showError = true
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let securities = try await securityService.searchSecurities(token: token)
            DispatchQueue.main.async {
                self.securities = securities
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
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