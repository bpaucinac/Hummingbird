import SwiftUI

@main
struct HummingbirdApp: App {
    // MARK: - Properties
    @StateObject private var appConfiguration = AppConfiguration()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appConfiguration)
                .accentColor(.accentColor)
        }
    }
}

// MARK: - App Configuration
@MainActor
final class AppConfiguration: ObservableObject {
    @Published var apiKeyStatus: APIKeyStatus = .unknown
    
    enum APIKeyStatus {
        case available
        case missing
        case unknown
    }
    
    private let claudeService = ClaudeService()
    
    init() {
        configureAppearance()
        checkAPIKeyStatus()
    }
    
    // Check if API key is available
    func checkAPIKeyStatus() {
        if KeychainService.getAPIKey(service: "com.hummingbird.claude") != nil {
            apiKeyStatus = .available
        } else {
            apiKeyStatus = .missing
        }
    }
    
    // Set Claude API key
    func saveClaudeAPIKey(_ key: String) -> Bool {
        let success = claudeService.setAPIKey(key)
        if success {
            apiKeyStatus = .available
        }
        return success
    }
    
    private func configureAppearance() {
        // Configure Tab Bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        // Use system colors for a more native look
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure Navigation Bar appearance - using system defaults for more consistency
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
} 
