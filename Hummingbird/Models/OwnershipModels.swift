import Foundation

// MARK: - Filer Search Response
struct FilerSearchResponse: Codable {
    let pageSize: Int
    let currentPage: Int
    let totalItems: Int
    let totalPages: Int
    let items: [Filer]
}

// MARK: - Filer
struct Filer: Codable, Identifiable {
    let id: String
    let parentId: String?
    let name: String
    let type: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let country: String?
    let phone: String?
    let style: String?
    let orientation: String?
    let website: String?
    let dateOfLatestReport: String?
    let dateOfPriorReport: String?
    let isActive: Bool
    let externalId1: String?
    let externalId2: String?
    let aum: Double?
    let createdAt: String
    let updatedAt: String
    
    // Computed property to format AUM (Assets Under Management) in a human-readable format
    var formattedAUM: String {
        guard let aum = aum else { return "N/A" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        if aum >= 1_000_000_000 {
            formatter.positiveSuffix = "B"
            return formatter.string(from: NSNumber(value: aum / 1_000_000_000)) ?? "N/A"
        } else if aum >= 1_000_000 {
            formatter.positiveSuffix = "M"
            return formatter.string(from: NSNumber(value: aum / 1_000_000)) ?? "N/A"
        } else if aum >= 1_000 {
            formatter.positiveSuffix = "K"
            return formatter.string(from: NSNumber(value: aum / 1_000)) ?? "N/A"
        } else {
            return formatter.string(from: NSNumber(value: aum)) ?? "N/A"
        }
    }
    
    // Format date for display
    var formattedDate: String {
        guard let dateString = dateOfLatestReport else { return "N/A" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
} 