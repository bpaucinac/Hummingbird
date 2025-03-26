import Foundation
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    private let authService = AuthService()
    private let tokenKey = "userToken"
    private let userKey = "userData"
    private let lastLoginDateKey = "lastLoginDate"
    
    // For token validation (in a real app, this would depend on backend rules)
    private let tokenValidityDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    var token: String {
        user?.token ?? ""
    }
    
    init() {
        loadUserFromKeychain()
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await authService.login(email: email, password: password)
            saveUserToKeychain(user)
            self.user = user
            self.isAuthenticated = true
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
    
    func logout() {
        removeUserFromKeychain()
        user = nil
        isAuthenticated = false
    }
    
    // Method to check if the token is still valid
    private func isTokenValid() -> Bool {
        guard let lastLoginDate = UserDefaults.standard.object(forKey: lastLoginDateKey) as? Date else {
            return false
        }
        
        // Check if token is expired
        let currentDate = Date()
        let timeElapsed = currentDate.timeIntervalSince(lastLoginDate)
        
        return timeElapsed < tokenValidityDuration
    }
    
    private func saveUserToKeychain(_ user: User) {
        // In a real app, you would use the Keychain
        // For simplicity, we're using UserDefaults
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
            UserDefaults.standard.set(user.token, forKey: tokenKey)
            UserDefaults.standard.set(Date(), forKey: lastLoginDateKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadUserFromKeychain() {
        // Check if we have user data and a valid token
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData),
           isTokenValid() {
            
            self.user = user
            self.isAuthenticated = true
            
            // Refresh login date if needed (in a real app, you might want to refresh the token here)
            if let lastLoginDate = UserDefaults.standard.object(forKey: lastLoginDateKey) as? Date {
                let currentDate = Date()
                let timeElapsed = currentDate.timeIntervalSince(lastLoginDate)
                
                // If last login was more than a day ago, refresh the login date
                if timeElapsed > (24 * 60 * 60) {
                    UserDefaults.standard.set(Date(), forKey: lastLoginDateKey)
                }
            }
        } else {
            // Token is invalid or missing, clear data
            removeUserFromKeychain()
        }
    }
    
    private func removeUserFromKeychain() {
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: lastLoginDateKey)
        UserDefaults.standard.synchronize()
    }
} 