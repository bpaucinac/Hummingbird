import Foundation
import SwiftUI

@MainActor
class AssistantViewModel: ObservableObject {
    @Published var currentConversation: Conversation
    @Published var savedConversations: [Conversation] = []
    @Published var isProcessing = false
    @Published var error: String?
    @Published var showError = false
    @Published var showAPIKeySetup = false
    
    private let claudeService = ClaudeService()
    private let defaultSystemPrompt = "You are Claude, an AI assistant focused on helping with financial information and research. Be concise, helpful, and accurate. If you're unsure about financial information, acknowledge the limitations."
    
    init() {
        self.currentConversation = Conversation()
        loadConversations()
    }
    
    // Send a message to the Claude API
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message to conversation
        let userMessage = Message(role: .user, content: content)
        currentConversation.messages.append(userMessage)
        
        isProcessing = true
        error = nil
        showError = false
        
        do {
            // Get response from Claude API
            let response = try await claudeService.sendMessage(
                messages: currentConversation.messages,
                systemPrompt: defaultSystemPrompt
            )
            
            // Process response
            if let textContent = response.content.first(where: { $0.type == "text" })?.text {
                let assistantMessage = Message(role: .assistant, content: textContent)
                currentConversation.messages.append(assistantMessage)
                
                // If this is the first response, try to generate a title for the conversation
                if currentConversation.title == nil && currentConversation.messages.count >= 2 {
                    currentConversation.title = generateConversationTitle(from: content)
                }
                
                // Save updated conversation
                saveCurrentConversation()
            } else {
                setError("Response didn't contain any text")
            }
        } catch {
            // If API key is not found, show setup view
            let nsError = error as NSError
            if nsError.domain == "ClaudeService" && nsError.code == 3 {
                showAPIKeySetup = true
                // Remove the user message from conversation if API key is missing
                if !currentConversation.messages.isEmpty {
                    currentConversation.messages.removeLast()
                }
            } else {
                setError(error.localizedDescription)
            }
        }
        
        isProcessing = false
    }
    
    private func setError(_ message: String) {
        self.error = "Error: \(message)"
        self.showError = true
        
        // Clear error after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            self.showError = false
        }
    }
    
    // Start a new conversation
    func startNewConversation() {
        // Save current conversation if it has messages
        if !currentConversation.messages.isEmpty {
            saveCurrentConversation()
        }
        
        // Create a new conversation
        currentConversation = Conversation()
    }
    
    // Generate a simple title from the first user message
    private func generateConversationTitle(from message: String) -> String {
        let words = message.split(separator: " ")
        let titleWords = words.prefix(3).joined(separator: " ")
        return titleWords.count > 0 ? titleWords + "..." : "New Conversation"
    }
    
    // Load conversations from UserDefaults
    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: "savedConversations") else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let conversations = try decoder.decode([Conversation].self, from: data)
            self.savedConversations = conversations
        } catch {
            print("Error loading conversations: \(error)")
        }
    }
    
    // Save current conversation to UserDefaults
    private func saveCurrentConversation() {
        var updatedConversations = savedConversations
        
        // Check if we're updating an existing conversation
        if let index = updatedConversations.firstIndex(where: { $0.id == currentConversation.id }) {
            updatedConversations[index] = currentConversation
        } else {
            updatedConversations.append(currentConversation)
        }
        
        savedConversations = updatedConversations
        
        // Save to UserDefaults
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(updatedConversations)
            UserDefaults.standard.set(data, forKey: "savedConversations")
        } catch {
            print("Error saving conversations: \(error)")
            setError("Failed to save conversation")
        }
    }
    
    // Load a specific conversation
    func loadConversation(_ conversation: Conversation) {
        // Save current conversation if needed
        if !currentConversation.messages.isEmpty {
            saveCurrentConversation()
        }
        
        currentConversation = conversation
    }
    
    // Delete a conversation
    func deleteConversation(_ conversation: Conversation) {
        savedConversations.removeAll { $0.id == conversation.id }
        
        // If we're deleting the current conversation, create a new one
        if currentConversation.id == conversation.id {
            currentConversation = Conversation()
        }
        
        // Save updated list
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedConversations)
            UserDefaults.standard.set(data, forKey: "savedConversations")
        } catch {
            print("Error saving after deletion: \(error)")
            setError("Failed to delete conversation")
        }
    }
} 