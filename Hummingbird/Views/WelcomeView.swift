import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var moveToMainView = false
    @AppStorage("hasSeenWelcomeScreen") private var hasSeenWelcomeScreen = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
            
            Text("Welcome back,")
                .font(.title)
                .fontWeight(.medium)
            
            Text(userViewModel.user?.name ?? "User")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Skip welcome screen if the user has seen it before
            if hasSeenWelcomeScreen {
                moveToMainView = true
            } else {
                // Set the flag so subsequent launches will skip the welcome screen
                hasSeenWelcomeScreen = true
                
                // For first time, still show welcome screen for 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    moveToMainView = true
                }
            }
        }
        .navigationDestination(isPresented: $moveToMainView) {
            MainTabView()
                .environmentObject(userViewModel)
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
            .environmentObject(UserViewModel())
    }
} 