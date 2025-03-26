import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var securityViewModel = SecurityViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            NavigationStack {
                AssistantView()
                    .navigationTitle("Assistant")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Assistant", systemImage: "bubble.left.and.bubble.right")
            }
            
            NavigationStack {
                NotificationsView()
                    .navigationTitle("Notifications")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }
            .badge(2) // Example badge, adjust based on actual notifications
            
            NavigationStack {
                MarketsView()
                    .navigationTitle("Markets")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Markets", systemImage: "chart.xyaxis.line")
            }
            
            NavigationStack {
                ApplicationsView()
                    .environmentObject(userViewModel)
                    .environmentObject(securityViewModel)
                    .navigationTitle("Applications")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Applications", systemImage: "square.grid.2x2")
            }
            
            NavigationStack {
                SettingsView()
                    .environmentObject(userViewModel)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
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
            VStack(spacing: 20) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.accentColor)
                    .padding(.top, 32)
                    .accessibilityHidden(true)
                
                Text("AI Assistant")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Ask me anything about your finances")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)
                
                // Chat interface placeholder
                VStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        MessageBubble()
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct MessageBubble: View {
    var body: some View {
        HStack(alignment: .top) {
            Text("Sample message that demonstrates the chat interface")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(minHeight: 44)
            Spacer(minLength: 60)
        }
    }
}

struct NotificationsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "bell.badge")
                        .frame(width: 30, height: 30)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Market Update")
                            .font(.headline)
                        Text("New report available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .frame(width: 30, height: 30)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portfolio Alert")
                            .font(.headline)
                        Text("Your watchlist has changed by 3.5%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("1h ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MarketsView: View {
    var body: some View {
        List {
            Section(header: Text("Major Indices")) {
                MarketItemRow(name: "S&P 500", value: "5,254.67", change: "+0.54%", isPositive: true)
                MarketItemRow(name: "Nasdaq", value: "16,384.45", change: "+0.34%", isPositive: true)
                MarketItemRow(name: "Dow Jones", value: "39,170.35", change: "-0.12%", isPositive: false)
            }
            
            Section(header: Text("Currencies")) {
                MarketItemRow(name: "EUR/USD", value: "1.0831", change: "+0.05%", isPositive: true)
                MarketItemRow(name: "USD/JPY", value: "151.45", change: "-0.22%", isPositive: false)
            }
            
            Section(header: Text("Commodities")) {
                MarketItemRow(name: "Gold", value: "2,178.35", change: "+0.64%", isPositive: true)
                MarketItemRow(name: "Oil WTI", value: "81.35", change: "-1.02%", isPositive: false)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MarketItemRow: View {
    let name: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(name)
                .font(.body)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(value)
                    .font(.body)
                    .bold()
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(height: 44)
    }
}

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userViewModel.user?.name ?? "User")
                            .font(.headline)
                        
                        Text(userViewModel.user?.email ?? "Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                NavigationLink(destination: Text("Account Settings")) {
                    Label("Account", systemImage: "person")
                }
                .frame(height: 44)
                
                NavigationLink(destination: Text("Notification Settings")) {
                    Label("Notifications", systemImage: "bell")
                }
                .frame(height: 44)
                
                NavigationLink(destination: Text("Appearance Settings")) {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .frame(height: 44)
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
                .frame(height: 44)
            }
        }
        .listStyle(.insetGrouped)
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