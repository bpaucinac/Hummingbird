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
                Section(header: Text("Claude API Key")) {
                    SecureField("Enter your API key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("Instructions"), footer: Text("Your API key will be stored securely in the Keychain.")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. Get your API key from your Anthropic account")
                        Text("2. Enter the key in the field above")
                        Text("3. Tap Save to store it securely")
                        
                        Link("Get Claude API Key", destination: URL(string: "https://console.anthropic.com/keys")!)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Button("Save API Key") {
                    saveKey()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(apiKey.isEmpty)
            }
            .navigationTitle("Set Up Claude AI")
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
                }
            }
        }
    }
    
    private func saveKey() {
        // Validate the API key format (basic check)
        if !apiKey.hasPrefix("sk-ant-api") {
            showingError = true
            errorMessage = "Invalid API key format. Claude API keys start with sk-ant-api."
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