import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var securityViewModel = SecurityViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            NavigationStack {
                AssistantView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            CustomTabHeader(title: "Assistant")
                        }
                    }
            }
            .tabItem {
                Label("Assistant", systemImage: "message.fill")
            }
            
            NavigationStack {
                NotificationsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            CustomTabHeader(title: "Notifications")
                        }
                    }
            }
            .tabItem {
                Label("Notifications", systemImage: "bell.fill")
            }
            
            NavigationStack {
                MarketsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            CustomTabHeader(title: "Markets")
                        }
                    }
            }
            .tabItem {
                Label("Markets", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationStack {
                ApplicationsView()
                    .environmentObject(userViewModel)
                    .environmentObject(securityViewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            CustomTabHeader(title: "Applications")
                        }
                    }
            }
            .tabItem {
                Label("Applications", systemImage: "folder.fill")
            }
            
            NavigationStack {
                SettingsView()
                    .environmentObject(userViewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            CustomTabHeader(title: "Settings")
                        }
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            Task {
                await securityViewModel.loadSecurities(token: userViewModel.token)
            }
        }
        .onChange(of: userViewModel.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                dismiss()
            }
        }
    }
}

struct AssistantView: View {
    var body: some View {
        VStack {
            Text("AI Assistant")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(systemName: "ellipsis.bubble.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
            
            Text("Ask me anything about your finances")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct NotificationsView: View {
    var body: some View {
        VStack {
            Text("No new notifications")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct MarketsView: View {
    var body: some View {
        VStack {
            Text("Market Overview")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(systemName: "chart.xyaxis.line")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
            
            Text("Track markets and indices")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(userViewModel.user?.name ?? "User")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Text(userViewModel.user?.email ?? "Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Section {
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                userViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserViewModel())
} 