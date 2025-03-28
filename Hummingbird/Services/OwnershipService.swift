import Foundation

class OwnershipService {
    private let baseURL = "https://production.hds.kiskisoftware.com"
    private let ownershipPath = "/ownership-api"
    
    // Auth token storage - using a hardcoded token
    private var authToken = "eyJraWQiOiI1cEJwR3RyeXdhMHh5QmFcL0lXUUhrYnJBaUpBZHZNTGx6eW1pWnF5eHlcL3c9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiI5ZWZiZWNmMS04NmMyLTQ1ZjYtOWRlZS1hMDBhNTM2MTA2NzYiLCJjb2duaXRvOmdyb3VwcyI6WyJVU0VSIiwiQURNSU4iXSwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX1VMQ0JUUHp3YSIsImNvZ25pdG86dXNlcm5hbWUiOiI5ZWZiZWNmMS04NmMyLTQ1ZjYtOWRlZS1hMDBhNTM2MTA2NzYiLCJjdXN0b206b3JnYW5pemF0aW9ucyI6IntcImRjZGVkNjZiLTg3MjQtNGViZS04OTM4LWYwMGY2ZGNiNzk1M1wiOlwiU1RBTkRBUkRcIn0iLCJvcmlnaW5fanRpIjoiZTdlZjE3MzQtNGVjMy00Njc2LWI5ZDMtM2M5OTQ5YjgwZjU0IiwiY3VzdG9tOmhiX3VzZXJfaWQiOiI4MTk1MjEyNi1iOWM4LTQzN2QtYTE3Yy01OGMzZTM0MTFhNWYiLCJhdWQiOiI3aWg5OHQ0Nzl1ZG8yazRuYWplZzZpa2hqYiIsImV2ZW50X2lkIjoiMTIwNzgzY2EtYTU2Yy00NjE4LWE0NzYtYjQwYjRmZTE0YzU4IiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3NDMwOTUwNDQsIm5hbWUiOiJEam9yZGplIFJhZGl2b2pldmljIiwiZXhwIjoxNzQzMTgxNDQ0LCJpYXQiOjE3NDMwOTUwNDQsImp0aSI6IjM0ZjViNjVkLThhOGYtNDI2Yi1iYzY1LWRiYmVkM2JlNDcwMCIsImVtYWlsIjoiZGpvcmRqZUBxdWFudGxhYnMucnMifQ.oTtWLB35SqzyQKNh79PvcXnqft0nrthV37xyNfg17PFEmRGsI2i26fLk9YP7eZVAkOE8fnT4GmYVsSclv4_GYEvHtwL-KXzVyqbdR70pclVWZUzC6zsSS7IJmSBctQQ6lt2sC7Ft0cHJMKzHFB_dC4wxHqYQEwznZVG7E9Fa0DUBlFf1XtLcg_t9FwgVoYCyWmiDGQk14RTtKhCuVuHy5QDRR8au3IvE7YiTwDNJNkjdCbYPTSmsn-dX0kbhl0Cd0hatMraHlhEcIf0coxoI0T1Ye4ONam9MDcM6_tYY4-gH3T5DLiMquL-UReuJNKfhj0TlRAge1kpSSBI8rPuQSw"
    
    enum OwnershipError: Error {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case serverError(Int)
        case unauthorized
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Data processing error: \(error.localizedDescription)"
            case .serverError(let code):
                return "Server error (code: \(code))"
            case .unauthorized:
                return "Unauthorized - please log in"
            case .unknown:
                return "Unknown error occurred"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // No need to load token from keychain since we're using a hardcoded one
    }
    
    // MARK: - Auth Token
    
    /// Set the auth token for API requests (not used with hardcoded token)
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    // MARK: - Filer Search
    
    /// Search for institutional filers with pagination and sorting
    /// - Parameters:
    ///   - page: Page number (starting from 1)
    ///   - pageSize: Number of items per page
    ///   - query: Optional search query for filer name
    ///   - sortBy: Optional sort field (e.g. "aum", "name")
    ///   - sortOrder: Sort direction (ascending or descending)
    /// - Returns: FilerSearchResponse containing matching filers
    func searchFilers(
        page: Int = 1,
        pageSize: Int = 20,
        query: String? = nil,
        sortBy: String = "aum",
        sortOrder: SortOrder = .descending
    ) async throws -> FilerSearchResponse {
        var urlComponents = URLComponents(string: "\(baseURL)\(ownershipPath)/api/filers")
        
        // Add query parameters
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        let sortPrefix = sortOrder == .ascending ? "" : "-"
        queryItems.append(URLQueryItem(name: "sorts", value: "\(sortPrefix)\(sortBy)"))
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            print("OwnershipService: Invalid URL created")
            throw OwnershipError.invalidURL
        }
        
        print("OwnershipService: Making request to \(url.absoluteString)")
        print("OwnershipService: Request headers:")
        print("- Authorization: Bearer \(authToken.prefix(20))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // Changed to GET to match curl example
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        request.timeoutInterval = 15
        
        do {
            print("OwnershipService: Sending request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("OwnershipService: Invalid response type")
                throw OwnershipError.unknown
            }
            
            print("OwnershipService: Received response with status code \(httpResponse.statusCode)")
            print("OwnershipService: Response headers:")
            httpResponse.allHeaderFields.forEach { key, value in
                print("- \(key): \(value)")
            }
            
            // Handle specific status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - continue processing
                break
            case 401, 403:
                print("OwnershipService: Authentication error")
                throw OwnershipError.unauthorized
            default:
                // Other server errors
                if let errorString = String(data: data, encoding: .utf8) {
                    print("OwnershipService: Error details: \(errorString)")
                }
                throw OwnershipError.serverError(httpResponse.statusCode)
            }
            
            // Debug - print response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("OwnershipService: Response: \(responseString.prefix(200))...")
            }
            
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(FilerSearchResponse.self, from: data)
            } catch {
                print("OwnershipService: Decoding error details: \(error)")
                throw OwnershipError.decodingError(error)
            }
        } catch let decodingError as DecodingError {
            print("OwnershipService: Decoding error: \(decodingError)")
            throw OwnershipError.decodingError(decodingError)
        } catch let networkError {
            print("OwnershipService: Network error: \(networkError.localizedDescription)")
            throw OwnershipError.networkError(networkError)
        }
    }
    
    // MARK: - Mock Data
    
    /// Get mock filer data for testing or offline mode
    func getMockFilers() -> [Filer] {
        return [
            Filer(
                id: "160da621-16a4-4723-aebc-19bfc147d2c9",
                parentId: nil,
                name: "BERKSHIRE ASSET MANAGEMENT LLC/PA",
                type: nil,
                addressLine1: "46 public square",
                addressLine2: nil,
                city: "wilkes barre",
                country: "PA",
                phone: nil,
                style: nil,
                orientation: nil,
                website: nil,
                dateOfLatestReport: "2025-02-07",
                dateOfPriorReport: nil,
                isActive: true,
                externalId1: "0000949012",
                externalId2: nil,
                aum: 2114721910.0,
                createdAt: "2025-03-27T06:00:22.780407Z",
                updatedAt: "2025-03-27T06:00:22.780407Z"
            ),
            Filer(
                id: "3cc6876f-6567-4d66-9b9b-3eaed4bdd959",
                parentId: nil,
                name: "Berkshire Money Management, Inc.",
                type: nil,
                addressLine1: "161 main st",
                addressLine2: nil,
                city: "dalton",
                country: "MA",
                phone: nil,
                style: nil,
                orientation: nil,
                website: nil,
                dateOfLatestReport: "2025-01-27",
                dateOfPriorReport: nil,
                isActive: true,
                externalId1: "0001535172",
                externalId2: nil,
                aum: 919761993.0,
                createdAt: "2025-03-27T06:00:22.780725Z",
                updatedAt: "2025-03-27T06:00:22.780725Z"
            ),
            Filer(
                id: "f82c03b6-0d22-4ff9-b47d-ede30a9d1f54",
                parentId: nil,
                name: "Berkshire Bank",
                type: nil,
                addressLine1: "99 north street",
                addressLine2: nil,
                city: "pittsfield",
                country: "MA",
                phone: nil,
                style: nil,
                orientation: nil,
                website: nil,
                dateOfLatestReport: "2025-01-22",
                dateOfPriorReport: nil,
                isActive: true,
                externalId1: "0001831984",
                externalId2: nil,
                aum: 430024549.0,
                createdAt: "2025-03-27T06:00:23.931566Z",
                updatedAt: "2025-03-27T06:00:23.931567Z"
            ),
            Filer(
                id: "ddc4f807-e500-4c6a-9b68-e21a31b68376",
                parentId: nil,
                name: "BERKSHIRE CAPITAL HOLDINGS INC",
                type: nil,
                addressLine1: "475 milan drive",
                addressLine2: "suite 103",
                city: "san jose",
                country: "CA",
                phone: nil,
                style: nil,
                orientation: nil,
                website: nil,
                dateOfLatestReport: "2025-02-11",
                dateOfPriorReport: nil,
                isActive: true,
                externalId1: "0001133742",
                externalId2: nil,
                aum: 276741085.0,
                createdAt: "2025-03-27T06:00:22.78053Z",
                updatedAt: "2025-03-27T06:00:22.780531Z"
            ),
            Filer(
                id: "5e53f227-a6dc-48a3-87c8-4551c58583cf",
                parentId: nil,
                name: "Berkshire Partners LLC",
                type: nil,
                addressLine1: "200 clarendon street",
                addressLine2: "35th floor",
                city: "boston",
                country: "MA",
                phone: nil,
                style: nil,
                orientation: nil,
                website: nil,
                dateOfLatestReport: "2025-02-14",
                dateOfPriorReport: nil,
                isActive: true,
                externalId1: "0001312988",
                externalId2: nil,
                aum: 35298551.0,
                createdAt: "2025-03-27T06:00:22.780579Z",
                updatedAt: "2025-03-27T06:00:22.780579Z"
            ),
            Filer(
                id: "1918b5d3-49d6-4543-9335-bcd3c1238731",
                parentId: nil,
                name: "BERKSHIRE HATHAWAY INC",
                type: nil,
                addressLine1: nil,
                addressLine2: nil,
                city: "omaha",
                country: "NE",
                phone: nil,
                style: nil,
                orientation: nil,
                website: nil,
                dateOfLatestReport: "2025-02-14",
                dateOfPriorReport: nil,
                isActive: true,
                externalId1: "0001067983",
                externalId2: nil,
                aum: 0,
                createdAt: "2025-03-27T06:00:22.780494Z",
                updatedAt: "2025-03-27T06:00:22.780494Z"
            )
        ]
    }
    
    // MARK: - Sort Order
    
    enum SortOrder {
        case ascending
        case descending
    }
} 