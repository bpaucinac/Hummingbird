import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var securityViewModel = SecurityViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            NavigationStack {
                AssistantView()
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Assistant")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
            }
            .tabItem {
                Label("Assistant", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            NavigationStack {
                NotificationsView()
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
            }
            .tabItem {
                Label("Notifications", systemImage: "bell.badge.fill")
            }
            .badge(2) // Example badge, adjust based on actual notifications
            
            NavigationStack {
                MarketsView()
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Markets")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
            }
            .tabItem {
                Label("Markets", systemImage: "chart.xyaxis.line")
            }
            
            NavigationStack {
                ApplicationsView()
                    .environmentObject(userViewModel)
                    .environmentObject(securityViewModel)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Applications")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
            }
            .tabItem {
                Label("Applications", systemImage: "doc.text.fill")
            }
            
            NavigationStack {
                SettingsView()
                    .environmentObject(userViewModel)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Settings")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(Color("AccentColor"))
        .onAppear {
            Task {
                await securityViewModel.loadSecurities(token: userViewModel.token)
            }
        }
        .onChange(of: userViewModel.isAuthenticated) { oldValue, newValue in
            if !newValue {
                dismiss()
            }
        }
    }
}

struct AssistantView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.accentColor)
                    .padding(.top, 32)
                
                Text("AI Assistant")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Ask me anything about your finances")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
                
                // Chat interface placeholder
                VStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        MessageBubble()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MessageBubble: View {
    var body: some View {
        HStack {
            Text("Sample message that demonstrates the chat interface")
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(minLength: 60)
        }
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
                .foregroundColor(.accentColor)
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