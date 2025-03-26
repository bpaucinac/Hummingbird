import SwiftUI

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
                    Label("Account", systemImage: "person.fill")
                        .frame(minHeight: 44)
                }
                
                NavigationLink(destination: Text("Notification Settings")) {
                    Label("Notifications", systemImage: "bell.fill")
                        .frame(minHeight: 44)
                }
                
                NavigationLink(destination: Text("Appearance Settings")) {
                    Label("Appearance", systemImage: "paintbrush.fill")
                        .frame(minHeight: 44)
                }
            }
            
            Section(header: Text("Advanced")) {
                NavigationLink(destination: APIKeySetupView()) {
                    Label("API Settings", systemImage: "key.fill")
                        .frame(minHeight: 44)
                }
            }
            
            Section {
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Text("Sign Out")
                            .foregroundColor(Color.red)
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                            .foregroundColor(Color.red)
                    }
                    .frame(minHeight: 44)
                }
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
    NavigationStack {
        SettingsView()
            .environmentObject(UserViewModel())
    }
} 