import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct User: Codable {
    let uid: String
    let status: String
    let createDate: String
    let lastModifiedDate: String
    let name: String
    let email: String
    let token: String
}

struct AuthResponse: Codable {
    let success: Bool
    let result: User
} 