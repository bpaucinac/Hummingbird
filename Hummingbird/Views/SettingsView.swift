import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var appConfiguration: AppConfiguration
    @State private var showConfirmLogout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header styled like Stocks app
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.systemGray4))
            }
            
            List {
                Section {
                    NavigationLink(destination: AccountView()) {
                        SettingsRow(title: "Account", icon: "person.circle.fill", color: .blue)
                    }
                    
                    NavigationLink(destination: NotificationsSettingsView()) {
                        SettingsRow(title: "Notifications", icon: "bell.fill", color: .red)
                    }
                    
                    NavigationLink(destination: APIKeySetupView().environmentObject(appConfiguration)) {
                        SettingsRow(title: "API Keys", icon: "key.fill", color: .purple)
                    }
                }
                
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(title: "Appearance", icon: "paintbrush.fill", color: .orange)
                    }
                    
                    NavigationLink(destination: PrivacySecurityView()) {
                        SettingsRow(title: "Privacy & Security", icon: "lock.fill", color: .green)
                    }
                }
                
                Section {
                    Button {
                        showConfirmLogout = true
                    } label: {
                        SettingsRow(title: "Log Out", icon: "rectangle.portrait.and.arrow.right", color: .gray)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .alert("Confirm Logout", isPresented: $showConfirmLogout) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                userViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Account View
struct AccountView: View {
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("John Doe")
                            .font(.headline)
                        
                        Text("john.doe@example.com")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                
                NavigationLink(destination: Text("Profile Information")) {
                    SettingsRow(title: "Edit Profile", icon: "pencil", color: .blue)
                }
                
                NavigationLink(destination: Text("Subscription Information")) {
                    SettingsRow(title: "Subscription", icon: "star.fill", color: .orange)
                }
            }
            
            Section(header: Text("Connected Accounts")) {
                SettingsRow(title: "Apple ID", icon: "apple.logo", color: .black)
                
                SettingsRow(title: "Google", icon: "g.circle", color: .blue)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Account")
    }
}

// MARK: - Notifications Settings View
struct NotificationsSettingsView: View {
    @State private var marketAlerts = true
    @State private var priceAlerts = true
    @State private var newsAlerts = false
    @State private var weeklyReports = true
    
    var body: some View {
        List {
            Section(header: Text("Alerts")) {
                Toggle("Market Updates", isOn: $marketAlerts)
                    .frame(minHeight: 44)
                
                Toggle("Price Alerts", isOn: $priceAlerts)
                    .frame(minHeight: 44)
                
                Toggle("News Alerts", isOn: $newsAlerts)
                    .frame(minHeight: 44)
            }
            
            Section(header: Text("Reports")) {
                Toggle("Weekly Performance", isOn: $weeklyReports)
                    .frame(minHeight: 44)
            }
            
            Section(footer: Text("You will receive notifications based on your preferences")) {
                NavigationLink(destination: Text("Advanced notification settings")) {
                    Text("Advanced Settings")
                        .frame(minHeight: 44)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
    }
}

// MARK: - Appearance Settings View
struct AppearanceSettingsView: View {
    @State private var selectedAppearance = 0
    private let appearances = ["System Default", "Light", "Dark"]
    
    @State private var selectedAccentColor = 0
    private let accentColors: [Color] = [.blue, .green, .orange, .pink, .purple, .red]
    private let colorNames = ["Blue", "Green", "Orange", "Pink", "Purple", "Red"]
    
    @State private var useDynamicType = true
    
    var body: some View {
        List {
            Section(header: Text("Theme")) {
                Picker("Appearance", selection: $selectedAppearance) {
                    ForEach(0..<appearances.count, id: \.self) { index in
                        Text(appearances[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Accent Color")) {
                ForEach(0..<accentColors.count, id: \.self) { index in
                    Button {
                        selectedAccentColor = index
                    } label: {
                        HStack {
                            Circle()
                                .fill(accentColors[index])
                                .frame(width: 24, height: 24)
                            
                            Text(colorNames[index])
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedAccentColor == index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .frame(minHeight: 44)
                }
            }
            
            Section(header: Text("Accessibility")) {
                Toggle("Use Dynamic Type", isOn: $useDynamicType)
                    .frame(minHeight: 44)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
    }
}

// MARK: - Privacy & Security View
struct PrivacySecurityView: View {
    @State private var useBiometrics = true
    @State private var askForAuthentication = true
    @State private var shareAnalytics = false
    
    var body: some View {
        List {
            Section(header: Text("Authentication")) {
                Toggle("Use Face ID / Touch ID", isOn: $useBiometrics)
                    .frame(minHeight: 44)
                
                Toggle("Require Authentication for Transactions", isOn: $askForAuthentication)
                    .frame(minHeight: 44)
                
                NavigationLink(destination: Text("Change password screen")) {
                    Text("Change Password")
                        .frame(minHeight: 44)
                }
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Share Analytics", isOn: $shareAnalytics)
                    .frame(minHeight: 44)
                
                NavigationLink(destination: Text("Data usage information")) {
                    Text("Data & Privacy")
                        .frame(minHeight: 44)
                }
            }
            
            Section {
                NavigationLink(destination: Text("Terms of Service")) {
                    Text("Terms of Service")
                        .frame(minHeight: 44)
                }
                
                NavigationLink(destination: Text("Privacy Policy")) {
                    Text("Privacy Policy")
                        .frame(minHeight: 44)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy & Security")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(UserViewModel())
            .environmentObject(AppConfiguration())
    }
} 
