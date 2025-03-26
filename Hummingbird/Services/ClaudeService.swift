import Foundation

class ClaudeService {
    // Remove hardcoded API key
    private var apiKey: String {
        return KeychainService.getAPIKey(service: "com.hummingbird.claude") ?? ""
    }
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let debugMode = true // Set to false in production
    
    func sendMessage(messages: [Message], systemPrompt: String? = nil) async throws -> ChatResponse {
        // Check if API key is available
        guard !apiKey.isEmpty else {
            throw NSError(domain: "ClaudeService", code: 3, userInfo: [NSLocalizedDescriptionKey: "API key not found. Please set up your Claude API key."])
        }
        
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "ClaudeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        if debugMode {
            print("🔷 Claude API Request to: \(baseURL)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        // Set up the request body
        var requestBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 4096,
            "messages": messages.map { $0.toDictionary() }
        ]
        
        if let systemPrompt = systemPrompt {
            requestBody["system"] = systemPrompt
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        if debugMode {
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("🔷 Request Body: \(jsonString)")
            }
            print("🔷 Request Headers:")
            for (key, value) in request.allHTTPHeaderFields ?? [:] {
                print("   \(key): \(key == "x-api-key" ? "[REDACTED]" : value)")
            }
        }
        
        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if debugMode {
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔷 Response Data: \(responseString)")
            }
        }
        
        // Check for successful response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ClaudeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API request failed: No HTTP response"])
        }
        
        if debugMode {
            print("🔷 Response Status Code: \(httpResponse.statusCode)")
        }
        
        // If the request failed, try to parse the error message
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorData["error"] as? [String: Any],
               let errorMessage = errorInfo["message"] as? String {
                if debugMode {
                    print("🔴 API Error: \(errorMessage)")
                }
                throw NSError(domain: "ClaudeService", code: httpResponse.statusCode, 
                              userInfo: [NSLocalizedDescriptionKey: "API request failed: \(errorMessage)"])
            } else {
                if debugMode {
                    print("🔴 API Error with status code: \(httpResponse.statusCode)")
                }
                throw NSError(domain: "ClaudeService", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "API request failed with status code: \(httpResponse.statusCode)"])
            }
        }
        
        // Decode the response
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(ChatResponse.self, from: data)
            if debugMode {
                print("🔷 Successfully decoded response from Claude API")
            }
            return response
        } catch {
            print("🔴 Response decoding error: \(error)")
            throw NSError(domain: "ClaudeService", code: 2, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to decode API response: \(error.localizedDescription)"])
        }
    }
    
    // Initialize API key (call this once during app setup)
    func setAPIKey(_ key: String) -> Bool {
        return KeychainService.saveAPIKey(key, service: "com.hummingbird.claude")
    }
} 