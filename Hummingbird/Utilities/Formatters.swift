import Foundation

struct Formatters {
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let returnFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let marketCapFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static func formatMarketCap(_ marketCap: Double?) -> String {
        guard let marketCap = marketCap else { return "N/A" }
        
        if marketCap >= 1_000_000_000_000 {
            return "\(marketCapFormatter.string(from: NSNumber(value: marketCap / 1_000_000_000_000)) ?? "N/A")T"
        } else if marketCap >= 1_000_000_000 {
            return "\(marketCapFormatter.string(from: NSNumber(value: marketCap / 1_000_000_000)) ?? "N/A")B"
        } else if marketCap >= 1_000_000 {
            return "\(marketCapFormatter.string(from: NSNumber(value: marketCap / 1_000_000)) ?? "N/A")M"
        } else {
            return "\(marketCapFormatter.string(from: NSNumber(value: marketCap)) ?? "N/A")"
        }
    }
} 