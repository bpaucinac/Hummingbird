import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var moveToMainView = false
    @State private var animateWelcome = false
    @AppStorage("hasSeenWelcomeScreen") private var hasSeenWelcomeScreen = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .scaleEffect(animateWelcome ? 1.0 : 0.8)
                .opacity(animateWelcome ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6), value: animateWelcome)
            
            VStack(spacing: 12) {
                Text("Welcome back,")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .opacity(animateWelcome ? 1.0 : 0.0)
                    .offset(y: animateWelcome ? 0 : 10)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateWelcome)
                
                Text(userViewModel.user?.name ?? "User")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(animateWelcome ? 1.0 : 0.0)
                    .offset(y: animateWelcome ? 0 : 10)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateWelcome)
            }
            
            Spacer()
            
            // Only show this button if user has seen the welcome screen before
            if hasSeenWelcomeScreen {
                Button {
                    moveToMainView = true
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .opacity(animateWelcome ? 1.0 : 0.0)
                .offset(y: animateWelcome ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: animateWelcome)
                .accessibilityHint("Tap to continue to the main view")
            }
        }
        .padding()
        .onAppear {
            // Start animations
            withAnimation {
                animateWelcome = true
            }
            
            // Skip welcome screen if the user has seen it before
            if hasSeenWelcomeScreen {
                // Don't automatically navigate, let user tap the button
            } else {
                // Set the flag so subsequent launches will show the button
                hasSeenWelcomeScreen = true
                
                // For first time, automatically navigate after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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