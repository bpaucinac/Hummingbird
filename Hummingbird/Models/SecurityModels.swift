import Foundation

struct SecuritySearchRequest: Codable {
    let listedOnly: Bool
    let criteria: String
    let isPrimary: Bool?
    let isActive: Bool?
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
    let isActive: Bool
    
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

// MARK: - Security Details Models
struct SecurityDetailsResponse: Codable {
    let successful: Bool
    let value: SecurityDetails
}

struct SecurityDetails: Codable {
    let id: String
    let shortName: String
    let longName: String
    let description: String
    let ticker: String
    let bbgTicker: String
    let compositeBbgTicker: String
    let figi: String?
    let compositeFigi: String?
    let shareClassFigi: String?
    let isin: String?
    let cusip: String?
    let sedol: String?
    let assetType: String
    let assetClass: String
    let currency: String
    let country: String
    let exchange: Exchange
    let issuer: Issuer
    let instrument: Instrument
    let classifications: [Classification]
    let activeSymbols: [Symbol]
    let historicalSymbols: [Symbol]
    let vendorIds: [VendorID]
    let isComposite: Bool
    let isPrimary: Bool
    let isCustom: Bool
    let isGlobal: Bool
    let isActive: Bool
    let orgIsActive: Bool
    let dateOfFirstListing: String?
    let dateOfDelisting: String?
    let createdAt: String?
    let updatedAt: String?
    
    var logoURL: URL? {
        return URL(string: "https://storage.googleapis.com/iex/api/logos/\(ticker).png")
    }
    
    var sectorName: String {
        return classifications.first(where: { $0.subType == "Sector" })?.name ?? "Unknown"
    }
    
    var industryName: String {
        return classifications.first(where: { $0.subType == "Industry" })?.name ?? "Unknown"
    }
    
    var status: [String] {
        var statuses: [String] = []
        if isPrimary { statuses.append("Primary") }
        if isComposite { statuses.append("Composite") }
        if isCustom { statuses.append("Custom") }
        if isGlobal { statuses.append("Global") }
        if isActive { statuses.append("Active") }
        return statuses
    }
}

struct Exchange: Codable {
    let id: Int
    let name: String
    let mic: String
    let bbgExchangeCode: String
    let countryIso2Code: String
}

struct Issuer: Codable {
    let id: String
    let name: String
    let countryDomicile: String
    let countryIncorporation: String
    let ipoDate: String?
    let isActive: Bool
    let isPublic: Bool
}

struct Instrument: Codable {
    let id: String
    let name: String
}

struct Symbol: Codable {
    let id: String
    let type: String
    let effectiveFrom: String
    let effectiveTo: String?
    let value: String
}

struct VendorID: Codable {
    let type: String
    let value: String
} 