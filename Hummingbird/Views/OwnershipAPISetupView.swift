import SwiftUI

struct OwnershipAPISetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var viewModel: OwnershipViewModel
    
    @State private var apiKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var isSuccess = false
    
    private let ownershipService = OwnershipService()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ownership API Key")) {
                    SecureField("Enter API Key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .disabled(isLoading)
                }
                
                Section(footer: errorMessage.map { Text($0).foregroundColor(.red) }) {
                    Button(action: saveAPIKey) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save API Key")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(apiKey.isEmpty || isLoading)
                }
                
                Section(header: Text("About Ownership API")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The Ownership API provides data on institutional investors (13F filers) and their holdings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("To use this feature, you need to enter a valid authorization token from the Ownership API.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            Text("Your API key is stored securely in the keychain.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Ownership API Setup")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("API Key Saved", isPresented: $isSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your Ownership API key has been saved successfully.")
            }
        }
    }
    
    private func saveAPIKey() {
        // Don't proceed if API key is empty
        guard !apiKey.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Validate API key format (basic check that it looks like a JWT)
        guard apiKey.contains(".") && apiKey.count > 20 else {
            errorMessage = "API key format is invalid. Please check your token."
            isLoading = false
            return
        }
        
        // Save to KeychainService
        let success = KeychainService.saveAPIKey(apiKey, service: "com.hummingbird.ownership")
        
        if success {
            // Set the key in the service
            ownershipService.setAuthToken(apiKey)
            
            // Update ViewModel auth status
            viewModel.authStatus = .authenticated
            viewModel.isOfflineMode = false
            
            // Reload data with the new API key
            Task {
                await viewModel.loadFilers()
            }
            
            isSuccess = true
        } else {
            errorMessage = "Failed to save API key to secure storage."
        }
        
        isLoading = false
    }
} 