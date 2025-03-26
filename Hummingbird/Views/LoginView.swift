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
                    .frame(width: 120, height: 120)
                    .accessibilityHidden(true)
                
                Text("Hummingbird")
                    .font(.title)
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
                        .foregroundStyle(.secondary)
                    
                    TextField("name@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .padding()
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    SecureField("Enter your password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .padding()
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            .controlSize(.large)
            .frame(height: 50)
            .padding(.horizontal, 24)
            .disabled(email.isEmpty || password.isEmpty || userViewModel.isLoading)
            
            // Error Message
            if let error = userViewModel.error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 16) {
                Button("Forgot Password?") {
                    // Handle forgot password
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding()
                .frame(minWidth: 44, minHeight: 44)
                
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        // Handle sign up
                    }
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.bottom, 16)
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