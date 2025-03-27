import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case email
        case password
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo and Welcome Text
            VStack(spacing: 16) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
                
                Text("Hummingbird")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Login Form
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                        
                        TextField("name@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .frame(minHeight: 44)
                    }
                    .padding()
                    .frame(height: 56)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                        
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .frame(minHeight: 44)
                    }
                    .padding()
                    .frame(height: 56)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            
            // Login Button
            Button(action: login) {
                if userViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .controlSize(.large)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .disabled(email.isEmpty || password.isEmpty || userViewModel.isLoading)
            
            // Error Message
            if let error = userViewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .frame(width: 20, height: 20)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 16) {
                Button {
                    // Handle forgot password
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .frame(minWidth: 44, minHeight: 44)
                }
                
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button {
                        // Handle sign up
                    } label: {
                        Text("Sign Up")
                            .foregroundColor(.accentColor)
                            .fontWeight(.semibold)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
                .font(.subheadline)
                .padding(.bottom, 20)
            }
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                login()
            case .none:
                break
            }
        }
        .alert("Error", isPresented: $userViewModel.showError) {
            Button("OK") {
                userViewModel.error = nil
            }
        } message: {
            Text(userViewModel.error ?? "")
        }
    }
    
    private func login() {
        Task {
            await userViewModel.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserViewModel())
} 