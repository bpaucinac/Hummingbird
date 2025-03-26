import Foundation

struct SecuritySearchRequest: Codable {
    let listedOnly: Bool
    let criteria: String
}

struct SecuritySearchResponse: Codable {
    let successful: Bool
    let value: SecuritySearchValue
}

struct SecuritySearchValue: Codable {
    let pageSize: Int
    let currentPage: Int
    let totalItems: Int
    let totalPages: Int
    let items: [Security]
}

struct Security: Codable, Identifiable {
    let id: String
    let shortName: String
    let longName: String
    let ticker: String
    let assetClass: String
    let currency: String
    let classifications: [Classification]
    let latestPrice: LatestPrice?
    let latestMktCap: LatestMarketCap?
    
    var logoURL: URL? {
        return URL(string: "https://storage.googleapis.com/iex/api/logos/\(ticker).png")
    }
    
    var sectorName: String {
        return classifications.first(where: { $0.subType == "Sector" })?.name ?? "Unknown"
    }
}

struct Classification: Codable {
    let id: Int
    let type: String
    let subType: String
    let name: String
    let code: String
    let effectiveFrom: String
    let effectiveTo: String?
}

struct LatestPrice: Codable {
    let tradeDate: String
    let closeFullAdj: Double
    let totalReturn: Double
}

struct LatestMarketCap: Codable {
    let localCurrencyConsolidatedMarketValue: Double
} 