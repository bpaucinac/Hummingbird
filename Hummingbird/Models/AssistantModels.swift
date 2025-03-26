import Foundation

// Enum to represent the role of a message
enum MessageRole: String, Codable {
    case user
    case assistant
}

// Model for a single message in the conversation
struct Message: Identifiable, Codable {
    var id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(role: MessageRole, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    // Helper method to convert to dictionary for API
    func toDictionary() -> [String: Any] {
        return [
            "role": role.rawValue,
            "content": content
        ]
    }
    
    // Coding keys to handle the UUID
    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
        case id
    }
    
    // Custom encoding to handle UUID
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(id.uuidString, forKey: .id)
    }
    
    // Custom decoding to handle UUID
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(MessageRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Handle the UUID
        if let idString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID()
        }
    }
}

// Claude API response structure
struct ChatResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model, usage
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
    }
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
    
    // Add custom init to handle potential null values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
    }
    
    enum CodingKeys: String, CodingKey {
        case type, text
    }
}

struct Usage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// For tracking conversation state
struct Conversation: Identifiable, Codable {
    var id: UUID
    var messages: [Message]
    var title: String?
    
    init(id: UUID = UUID(), messages: [Message] = [], title: String? = nil) {
        self.id = id
        self.messages = messages
        self.title = title
    }
    
    var lastUpdated: Date {
        messages.map { $0.timestamp }.max() ?? Date()
    }
} 
