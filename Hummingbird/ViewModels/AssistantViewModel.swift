import Foundation
import SwiftUI

@MainActor
class AssistantViewModel: ObservableObject {
    @Published var currentConversation: Conversation
    @Published var savedConversations: [Conversation] = []
    @Published var isProcessing = false
    @Published var error: String?
    @Published var showError = false
    @Published var showAPIKeySetup = false
    
    private let claudeService = ClaudeService()
    private let securityService = SecurityService()
    // Reference to the UserViewModel for authentication
    private var userViewModel: UserViewModel?
    private let defaultSystemPrompt = "You are Claude, an AI assistant focused on helping with financial information and research. Be concise, helpful, and accurate. If you're unsure about financial information, acknowledge the limitations."
    
    // Inject security-related data sources that we can reference
    private let enhancedSystemPrompt = """
    You are Claude, an AI assistant focused on helping with financial information and research. Be concise, helpful, and accurate.
    
    IMPORTANT INSTRUCTION FOR SECURITIES DATA QUERIES:
    When the user asks about specific securities, stocks, companies, or financial instruments, you MUST prioritize using the data from the Hummingbird Data Services (HDS) API rather than your general knowledge.
    
    For securities-related queries:
    1. Always begin your answer with "According to Hummingbird Data Services (HDS):" when providing information from the HDS API.
    2. Include any relevant data like ticker, exchange, sector, industry, latest pricing, market cap, etc. when available from HDS.
    3. When market cap data is available from HDS, ALWAYS include it explicitly, mentioning that it comes from the localCurrencyConsolidatedMarketValue field.
    4. If a user specifically asks about market cap and it's available in the HDS data, make it the focus of your answer.
    5. If specific data points are requested but not available in HDS, clearly state "This specific data is not available in HDS."
    6. Only fall back to your general knowledge when the securities data is completely unavailable in HDS, and in that case, clearly indicate "HDS does not have data on this security. Based on my general knowledge:"
    
    For non-securities or general finance questions, use your general knowledge as usual.
    """
    
    init() {
        self.currentConversation = Conversation()
        loadConversations()
    }
    
    // Set the UserViewModel reference
    func setUserViewModel(_ viewModel: UserViewModel) {
        self.userViewModel = viewModel
    }
    
    // Send a message to the Claude API
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message to conversation
        let userMessage = Message(role: .user, content: content)
        currentConversation.messages.append(userMessage)
        
        isProcessing = true
        error = nil
        showError = false
        
        do {
            // First check if the query is securities-related
            if isSecuritiesQuery(content) {
                print("Detected securities-related query: \(content)")
                
                // Try to get security data
                let securityData = await tryFetchSecurityData(content)
                
                // Handle case based on whether security data was found
                if let securityData = securityData, !securityData.isEmpty {
                    print("Security data found, enhancing prompt with HDS data")
                    
                    // Security data found - create an augmented message with the securities data
                    let enhancedPrompt = """
                    The user's question relates to securities. Here is relevant data from the Hummingbird Data Services (HDS) API that you should reference in your answer:

                    \(securityData)

                    IMPORTANT INSTRUCTIONS:
                    1. Start your answer with 'According to Hummingbird Data Services (HDS):'
                    2. Incorporate this data in your response.
                    3. If the data includes market cap information, make sure to highlight it prominently in your response.
                    4. If the user specifically asked about market cap, focus your answer on the market cap data.
                    5. Be explicit that market cap data comes from the 'localCurrencyConsolidatedMarketValue' field in HDS.
                    """
                    
                    // Get response from Claude API with enhanced system prompt and additional context
                    let response = try await claudeService.sendMessage(
                        messages: currentConversation.messages,
                        systemPrompt: enhancedPrompt
                    )
                    
                    handleResponse(response, userContent: content)
                } else {
                    print("No security data found in HDS, using Claude's general knowledge")
                    
                    // No matching security data found - explicitly instruct Claude to use its general knowledge
                    let generalKnowledgePrompt = """
                    The user's question appears to be about securities or companies, but we couldn't find specific matching data in the Hummingbird Data Services (HDS) API.

                    IMPORTANT INSTRUCTIONS:
                    1. Begin your response with: "HDS does not have specific data on this topic."
                    2. Then, provide a helpful, informative answer based on your general knowledge.
                    3. Make your answer clear, accurate, and comprehensive.
                    4. If appropriate, mention that while HDS doesn't have this specific data, you can provide general information.
                    5. Format your answer with clear paragraphs for readability.
                    6. If the query is about market cap or other financial metrics of a company, make sure to provide this information from your general knowledge.
                    """
                    
                    // Get response from Claude API with the general knowledge prompt
                    let response = try await claudeService.sendMessage(
                        messages: currentConversation.messages,
                        systemPrompt: generalKnowledgePrompt
                    )
                    
                    handleResponse(response, userContent: content)
                }
            } else {
                print("Not a securities query, using default prompt")
                
                // Not a securities query, use the default system prompt
                let response = try await claudeService.sendMessage(
                    messages: currentConversation.messages,
                    systemPrompt: defaultSystemPrompt
                )
                
                handleResponse(response, userContent: content)
            }
        } catch {
            // Handle errors
            let nsError = error as NSError
            if nsError.domain == "ClaudeService" && nsError.code == 3 {
                print("API key not found, showing setup view")
                showAPIKeySetup = true
                // Remove the user message from conversation if API key is missing
                if !currentConversation.messages.isEmpty {
                    currentConversation.messages.removeLast()
                }
            } else {
                print("Error sending message: \(error.localizedDescription)")
                setError(error.localizedDescription)
            }
        }
        
        isProcessing = false
    }
    
    private func handleResponse(_ response: ChatResponse, userContent: String) {
        // Process response
        if let textContent = response.content.first(where: { $0.type == "text" })?.text {
            let assistantMessage = Message(role: .assistant, content: textContent)
            currentConversation.messages.append(assistantMessage)
            
            // If this is the first response, try to generate a title for the conversation
            if currentConversation.title == nil && currentConversation.messages.count >= 2 {
                currentConversation.title = generateConversationTitle(from: userContent)
            }
            
            // Save updated conversation
            saveCurrentConversation()
        } else {
            setError("Response didn't contain any text")
        }
    }
    
    // Check if a query is likely securities-related
    private func isSecuritiesQuery(_ query: String) -> Bool {
        let query = query.lowercased()
        // Expand the list of keywords to catch more potential securities queries
        let securityKeywords = [
            "stock", "stocks", "ticker", "share", "shares", "security", "securities",
            "company", "companies", "corporation", "equity", "equities", "bond", "bonds",
            "etf", "fund", "index", "market cap", "price", "nasdaq", "nyse", "exchange", 
            "investment", "investing", "investor", "portfolio", "asset", "assets",
            "dividend", "earnings", "revenue", "profit", "financials", "balance sheet",
            "income statement", "cash flow", "growth", "valuation", "p/e", "eps"
        ]
        
        // If we have a direct company name, it's very likely to be a securities query
        let commonCompanies = ["apple", "microsoft", "google", "amazon", "facebook", "meta", 
                               "tesla", "netflix", "nvidia", "amd", "intel", "ibm", "oracle",
                               "walmart", "target", "costco", "coca cola", "pepsi", "nike"]
        
        // Check for direct company mentions
        if commonCompanies.contains(where: { query.contains($0) }) {
            return true
        }
        
        // Check for security related keywords
        return securityKeywords.contains { query.contains($0) }
    }
    
    // Check if a query is specifically about market cap
    private func isMarketCapQuery(_ query: String) -> Bool {
        let query = query.lowercased()
        let marketCapKeywords = ["market cap", "market capitalization", "marketcap", "cap", "valuation", "worth"]
        
        return marketCapKeywords.contains { query.contains($0) }
    }
    
    // Try to fetch security data related to the query
    private func tryFetchSecurityData(_ query: String) async -> String? {
        print("Trying to fetch security data for query: \(query)")
        
        // Check if this is a market cap specific query
        let isMarketCapQuestion = isMarketCapQuery(query)
        if isMarketCapQuestion {
            print("This is a market cap specific query")
        }
        
        let queryLowercase = query.lowercased()
        
        // Explicit check for common companies that might be missed by ticker detection
        var companyMapping: [String: String] = [
            "apple": "AAPL",
            "microsoft": "MSFT",
            "google": "GOOGL",
            "alphabet": "GOOGL",
            "amazon": "AMZN",
            "tesla": "TSLA",
            "netflix": "NFLX",
            "facebook": "META",
            "meta": "META"
        ]
        
        // Extract potential ticker symbols from the query
        let words = query.components(separatedBy: .whitespacesAndNewlines)
        var potentialTickers: [String] = []
        
        // First check if we have any exact company name matches
        for (company, ticker) in companyMapping {
            if queryLowercase.contains(company) {
                potentialTickers.insert(ticker, at: 0) // Add with priority
                print("Found company name match: \(company) -> \(ticker)")
            }
        }
        
        // Then the usual ticker detection (uppercase 1-5 letter words)
        for word in words {
            let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
            if cleaned.count >= 1 && cleaned.count <= 5 && cleaned.uppercased() == cleaned && cleaned.rangeOfCharacter(from: .letters) != nil {
                // Don't add duplicates
                if !potentialTickers.contains(cleaned) {
                    potentialTickers.append(cleaned)
                    print("Found potential ticker: \(cleaned)")
                }
            }
        }
        
        if potentialTickers.isEmpty {
            print("No potential tickers found in query")
        }
        
        // Also look for company names in the query
        let queryWithoutStopWords = removeStopWords(from: query)
        print("Query without stop words: \(queryWithoutStopWords)")
        
        // Get token from userViewModel if available, otherwise use a demo token
        let token = userViewModel?.token ?? "test_token"
        guard !token.isEmpty else {
            print("Token is empty, cannot query security API")
            return nil
        }
        
        do {
            // First try to search for potential tickers
            if !potentialTickers.isEmpty {
                for ticker in potentialTickers {
                    print("Searching for ticker: \(ticker)")
                    let securities = try await securityService.searchSecurities(
                        token: token,
                        page: 1,
                        pageSize: 1,
                        criteria: ticker,
                        listedOnly: true,
                        primaryOnly: true
                    )
                    
                    if let security = securities.first {
                        // Found a matching security
                        print("Found security for \(ticker): \(security.shortName)")
                        
                        // Special handling for market cap queries
                        if isMarketCapQuestion {
                            if let marketCap = security.latestMktCap {
                                var result = "MARKET CAP DATA SPECIFICALLY REQUESTED:\n"
                                result += "Company: \(security.longName) (\(security.ticker))\n"
                                let formattedMarketCap = Formatters.formatMarketCap(marketCap.localCurrencyConsolidatedMarketValue)
                                result += "Market Cap: \(formattedMarketCap)\n"
                                result += "Raw Market Cap Value: \(marketCap.localCurrencyConsolidatedMarketValue)\n"
                                result += "Market Cap Source: HDS API field 'localCurrencyConsolidatedMarketValue'\n\n"
                                
                                // Add additional context that might be helpful
                                result += "Additional context:\n"
                                result += "Currency: \(security.currency)\n"
                                
                                if let sector = security.classifications.first(where: { $0.subType == "Sector" }) {
                                    result += "Sector: \(sector.name)\n"
                                }
                                
                                if let price = security.latestPrice {
                                    result += "Latest Price: \(Formatters.priceFormatter.string(from: NSNumber(value: price.closeFullAdj)) ?? "N/A") (\(price.tradeDate))\n"
                                }
                                
                                return result
                            } else {
                                print("Market cap data requested but not available for \(security.ticker)")
                            }
                        }
                        
                        return formatSecurityData(security)
                    } else {
                        print("No security found for ticker: \(ticker)")
                    }
                }
            }
            
            // If no ticker matches, try to search for company names
            print("No ticker match, searching by query: \(queryWithoutStopWords)")
            let securities = try await securityService.searchSecurities(
                token: token,
                page: 1,
                pageSize: 3,
                criteria: queryWithoutStopWords,
                listedOnly: true,
                primaryOnly: true
            )
            
            if !securities.isEmpty {
                print("Found \(securities.count) securities by name")
                var result = ""
                
                // If this is a market cap question and we have results, prioritize ones with market cap data
                if isMarketCapQuestion {
                    for security in securities {
                        if let marketCap = security.latestMktCap {
                            var secData = "MARKET CAP DATA SPECIFICALLY REQUESTED:\n"
                            secData += "Company: \(security.longName) (\(security.ticker))\n"
                            let formattedMarketCap = Formatters.formatMarketCap(marketCap.localCurrencyConsolidatedMarketValue)
                            secData += "Market Cap: \(formattedMarketCap)\n"
                            secData += "Raw Market Cap Value: \(marketCap.localCurrencyConsolidatedMarketValue)\n"
                            secData += "Market Cap Source: HDS API field 'localCurrencyConsolidatedMarketValue'\n\n"
                            
                            // Add additional context that might be helpful
                            secData += "Additional context:\n"
                            secData += "Currency: \(security.currency)\n"
                            
                            if let sector = security.classifications.first(where: { $0.subType == "Sector" }) {
                                secData += "Sector: \(sector.name)\n"
                            }
                            
                            if let price = security.latestPrice {
                                secData += "Latest Price: \(Formatters.priceFormatter.string(from: NSNumber(value: price.closeFullAdj)) ?? "N/A") (\(price.tradeDate))\n"
                            }
                            
                            result += secData + "\n\n"
                        } else {
                            print("Market cap data not available for \(security.ticker)")
                            result += formatSecurityData(security) + "\n\n"
                        }
                    }
                } else {
                    // Standard formatting for non-market cap queries
                    for security in securities {
                        result += formatSecurityData(security) + "\n\n"
                    }
                }
                
                return result
            } else {
                print("No securities found for query: \(queryWithoutStopWords)")
            }
        } catch {
            print("Error searching for securities: \(error)")
        }
        
        print("No security data found, returning nil")
        return nil
    }
    
    // Remove common stop words to improve search quality
    private func removeStopWords(from text: String) -> String {
        let stopWords = ["a", "about", "an", "and", "are", "as", "at", "be", "by", "for", "from", "has", "have", "how", "i", "in", "is", "it", "of", "on", "or", "that", "the", "this", "to", "was", "what", "when", "where", "who", "will", "with"]
        
        var words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        words = words.filter { !stopWords.contains($0) }
        return words.joined(separator: " ")
    }
    
    // Format security data for inclusion in the prompt
    private func formatSecurityData(_ security: Security) -> String {
        var result = "SECURITY DATA:\n"
        result += "Name: \(security.longName)\n"
        result += "Ticker: \(security.ticker)\n"
        result += "Asset Class: \(security.assetClass)\n"
        result += "Currency: \(security.currency)\n"
        
        if let sector = security.classifications.first(where: { $0.subType == "Sector" }) {
            result += "Sector: \(sector.name)\n"
        }
        
        if let industry = security.classifications.first(where: { $0.subType == "Industry" }) {
            result += "Industry: \(industry.name)\n"
        }
        
        if let price = security.latestPrice {
            result += "Latest Price: \(Formatters.priceFormatter.string(from: NSNumber(value: price.closeFullAdj)) ?? "N/A") (\(price.tradeDate))\n"
            result += "Total Return: \(Formatters.returnFormatter.string(from: NSNumber(value: price.totalReturn)) ?? "N/A")\n"
        }
        
        // Highlight market cap data prominently
        if let marketCap = security.latestMktCap {
            let formattedMarketCap = Formatters.formatMarketCap(marketCap.localCurrencyConsolidatedMarketValue)
            result += "Market Cap: \(formattedMarketCap) (from localCurrencyConsolidatedMarketValue)\n"
            result += "Raw Market Cap Value: \(marketCap.localCurrencyConsolidatedMarketValue)\n"
        } else {
            result += "Market Cap: Not available in HDS data\n"
        }
        
        result += "Status: \(security.isActive ? "Active" : "Inactive")"
        
        return result
    }
    
    private func setError(_ message: String) {
        self.error = "Error: \(message)"
        self.showError = true
        
        // Clear error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            self.showError = false
        }
    }
    
    // Start a new conversation
    func startNewConversation() {
        // Save current conversation if it has messages
        if !currentConversation.messages.isEmpty {
            saveCurrentConversation()
        }
        
        // Create a new conversation
        currentConversation = Conversation()
    }
    
    // Generate a simple title from the first user message
    private func generateConversationTitle(from message: String) -> String {
        let words = message.split(separator: " ")
        let titleWords = words.prefix(3).joined(separator: " ")
        return titleWords.count > 0 ? titleWords + "..." : "New Conversation"
    }
    
    // Load conversations from UserDefaults
    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: "savedConversations") else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let conversations = try decoder.decode([Conversation].self, from: data)
            self.savedConversations = conversations
        } catch {
            print("Error loading conversations: \(error)")
        }
    }
    
    // Save current conversation to UserDefaults
    private func saveCurrentConversation() {
        var updatedConversations = savedConversations
        
        // Check if we're updating an existing conversation
        if let index = updatedConversations.firstIndex(where: { $0.id == currentConversation.id }) {
            updatedConversations[index] = currentConversation
        } else {
            updatedConversations.append(currentConversation)
        }
        
        savedConversations = updatedConversations
        
        // Save to UserDefaults
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(updatedConversations)
            UserDefaults.standard.set(data, forKey: "savedConversations")
        } catch {
            print("Error saving conversations: \(error)")
            setError("Failed to save conversation")
        }
    }
    
    // Load a specific conversation
    func loadConversation(_ conversation: Conversation) {
        // Save current conversation if needed
        if !currentConversation.messages.isEmpty {
            saveCurrentConversation()
        }
        
        currentConversation = conversation
    }
    
    // Delete a conversation
    func deleteConversation(_ conversation: Conversation) {
        savedConversations.removeAll { $0.id == conversation.id }
        
        // If we're deleting the current conversation, create a new one
        if currentConversation.id == conversation.id {
            currentConversation = Conversation()
        }
        
        // Save updated list
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedConversations)
            UserDefaults.standard.set(data, forKey: "savedConversations")
        } catch {
            print("Error saving after deletion: \(error)")
            setError("Failed to delete conversation")
        }
    }
} 