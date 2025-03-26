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
                        .environmentObject(userViewModel)
                        .environmentObject(appConfiguration)
                } else {
                    LoginView()
                        .environmentObject(userViewModel)
                }
            }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppConfiguration())
} 