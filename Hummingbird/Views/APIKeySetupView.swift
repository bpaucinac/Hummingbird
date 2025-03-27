import SwiftUI

struct APIKeySetupView: View {
    @EnvironmentObject var appConfiguration: AppConfiguration
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Enter your API key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .frame(minHeight: 44)
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Your API key will be stored securely in the Keychain.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                                .frame(width: 24, height: 24)
                            Text("Get your API key from your account")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 44)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                                .frame(width: 24, height: 24)
                            Text("Enter the key in the field above")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 44)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                                .frame(width: 24, height: 24)
                            Text("Tap Save to store it securely")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 44)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Link(destination: URL(string: "https://hummingbird.app/api-keys")!) {
                            HStack {
                                Image(systemName: "arrow.up.forward.app")
                                Text("Get API Key")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.accentColor)
                        .frame(minHeight: 44)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Instructions")
                }
                
                Section {
                    Button {
                        saveKey()
                    } label: {
                        Text("Save API Key")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                    .disabled(apiKey.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Set Up API")
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }
    
    private func saveKey() {
        // Validate the API key format (basic check)
        if apiKey.isEmpty {
            showingError = true
            errorMessage = "API key cannot be empty."
            return
        }
        
        // Try to save the key
        if appConfiguration.saveClaudeAPIKey(apiKey) {
            dismiss()
        } else {
            showingError = true
            errorMessage = "Failed to save the API key securely. Please try again."
        }
    }
}

#Preview {
    APIKeySetupView()
        .environmentObject(AppConfiguration())
} 