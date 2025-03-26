import SwiftUI

@main
struct HummingbirdApp: App {
    // MARK: - Properties
    @StateObject private var appConfiguration = AppConfiguration()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color("AccentColor"))
                .environmentObject(appConfiguration)
        }
    }
}

// MARK: - App Configuration
@MainActor
final class AppConfiguration: ObservableObject {
    init() {
        configureAppearance()
    }
    
    private func configureAppearance() {
        let accent = UIColor(named: "AccentColor") ?? .systemBlue
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.stackedLayoutAppearance.selected.iconColor = accent
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = accent
    }
} 