import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if userViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(userViewModel)
        }
    }
}

#Preview {
    ContentView()
} 