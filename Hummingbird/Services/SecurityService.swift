import Foundation

class SecurityService {
    private let baseURL = "https://production.hds.kiskisoftware.com/secmaster-api/api/v2"
    
    func searchSecurities(token: String, page: Int = 1, pageSize: Int = 50, criteria: String = "", listedOnly: Bool = false, primaryOnly: Bool = false, assetClasses: [String] = ["Equity"]) async throws -> [Security] {
        guard let url = URL(string: "\(baseURL)/security-search?page=\(page)&pageSize=\(pageSize)") else {
            throw NSError(domain: "SecurityService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Always include isActive as true, only include isPrimary if explicitly set
        let searchRequest = SecuritySearchRequest(
            listedOnly: listedOnly,
            criteria: criteria,
            isPrimary: primaryOnly ? true : nil,
            isActive: true,
            assetClasses: assetClasses.isEmpty ? nil : assetClasses
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(searchRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "SecurityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to search securities"])
        }
        
        let searchResponse = try JSONDecoder().decode(SecuritySearchResponse.self, from: data)
        return searchResponse.value.items
    }
    
    func getSecurityDetails(token: String, securityId: String) async throws -> SecurityDetails {
        guard let url = URL(string: "https://production.hds.kiskisoftware.com/secmaster-api/api/equities/\(securityId)") else {
            throw NSError(domain: "SecurityService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "SecurityService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch security details"])
        }
        
        let detailsResponse = try JSONDecoder().decode(SecurityDetailsResponse.self, from: data)
        return detailsResponse.value
    }
} 