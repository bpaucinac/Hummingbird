import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var securityViewModel = SecurityViewModel()
    @EnvironmentObject var appConfiguration: AppConfiguration
    
    var body: some View {
        NavigationStack {
            Group {
                if userViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(securityViewModel)
                        .environmentObject(appConfiguration)
                } else {
                    LoginView()
                }
            }
            .environmentObject(userViewModel)
        }
        .sheet(isPresented: $appConfiguration.showAPIKeySetupSheet) {
            APIKeySetupView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppConfiguration())
} 