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
        ScrollView {
            VStack(spacing: 24) {
                // Logo and Welcome Text
                VStack(spacing: 16) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                }
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                
                // Login Button
                Button(action: login) {
                    if userViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
                    .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign Up") {
                            // Handle sign up
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 32)
            }
        }
        .scrollDismissesKeyboard(.immediately)
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