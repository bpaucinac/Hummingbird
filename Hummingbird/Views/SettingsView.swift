import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    
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
                        .frame(minHeight: 44)
                }
                
                NavigationLink(destination: Text("Insights Settings")) {
                    Label("Insights", systemImage: "chart.bar.fill")
                        .frame(minHeight: 44)
                }
                
                NavigationLink(destination: Text("Appearance Settings")) {
                    Label("Appearance", systemImage: "paintpalette")
                        .frame(minHeight: 44)
                }
            }
            
            Section(header: Text("Advanced")) {
                NavigationLink(destination: APIKeySetupView()) {
                    Label("API Settings", systemImage: "key.horizontal")
                        .frame(minHeight: 44)
                }
            }
            
            Section {
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.forward")
                            .foregroundColor(Color.red)
                        Spacer()
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