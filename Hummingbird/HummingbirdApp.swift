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
                .onAppear {
                    // Setup initial Claude API key on first launch for development
                    // In production, you would use a proper API key management system
                    appConfiguration.setupInitialAPIKeyIfNeeded()
                }
        }
    }
}

// MARK: - App Configuration
@MainActor
final class AppConfiguration: ObservableObject {
    @Published var showAPIKeySetupSheet = false
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
    
    // Setup initial API key for development (should be removed in production)
    func setupInitialAPIKeyIfNeeded() {
        #if DEBUG
        // Only set up the key for development if it's not already set
        if KeychainService.getAPIKey(service: "com.hummingbird.claude") == nil {
            // Use the run-time prompt for setting up the API key instead of hardcoding
            showAPIKeySetupSheet = true
        }
        #endif
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
        let accent = UIColor(named: "AccentColor") ?? .systemBlue
        
        // Configure Tab Bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        // Regular tab bar appearance
        tabBarAppearance.backgroundColor = .systemBackground
        tabBarAppearance.shadowColor = .clear
        
        // Stack layout (icon and title)
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = accent
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accent]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure Navigation Bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.backgroundColor = .systemBackground
        
        // Title text attributes
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Large title text attributes
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Set appearances for all states
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = accent
        
        // Configure list appearance
        UITableView.appearance().backgroundColor = .systemGroupedBackground
        UITableViewCell.appearance().backgroundColor = .secondarySystemGroupedBackground
        
        // For iOS 15+, we can use button styles in SwiftUI instead of UIKit configuration
        // If needed, additional button customization can be done in individual views
    }
} 
