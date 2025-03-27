import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var securityViewModel: SecurityViewModel
    @EnvironmentObject var appConfiguration: AppConfiguration
    @StateObject private var assistantViewModel = AssistantViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TabView {
            // AI Assistant Tab
            NavigationStack {
                AssistantView()
                    .toolbar(.hidden, for: .navigationBar)
                    .environmentObject(assistantViewModel)
                    .environmentObject(appConfiguration)
                    .onAppear {
                        // Set the userViewModel on the assistantViewModel
                        assistantViewModel.setUserViewModel(userViewModel)
                    }
            }
            .tabItem {
                Label("Assistant", systemImage: "message.and.waveform.fill")
            }
            
            // Notifications Tab
            NavigationStack {
                InsightsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.xaxis")
            }
            
            // Markets Tab
            NavigationStack {
                MarketsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label("Markets", systemImage: "chart.xyaxis.line")
            }
            
            // Applications Folder Tab
            NavigationStack {
                ApplicationsFolderView()
                    .toolbar(.hidden, for: .navigationBar)
                    .environmentObject(securityViewModel)
            }
            .tabItem {
                Label("Applications", systemImage: "square.grid.2x2.fill")
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
                    .toolbar(.hidden, for: .navigationBar)
                    .environmentObject(userViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .accentColor(.accentColor)
        .onAppear {
            // Load initial data
            Task {
                await securityViewModel.loadSecurities(token: userViewModel.token)
            }
        }
        .onChange(of: userViewModel.isAuthenticated) { oldValue, newValue in
            if !newValue {
                dismiss()
            }
        }
    }
}

// MARK: - Assistant View
struct AssistantView: View {
    @EnvironmentObject var assistantViewModel: AssistantViewModel
    @EnvironmentObject var appConfiguration: AppConfiguration
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header styled like Stocks app
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Assistant")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button {
                        assistantViewModel.startNewConversation()
                        messageText = ""
                        isTextFieldFocused = false
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.systemGray4))
            }
            
            // Chat history
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if assistantViewModel.currentConversation.messages.isEmpty {
                            // Welcome screen when no messages
                            VStack(spacing: 20) {
                                Image(systemName: "message.and.waveform.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.accentColor)
                                    .padding(.top, 32)
                                    .accessibilityHidden(true)
                                
                                Text("Financial Assistant")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Ask me anything about finance and markets")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 16)
                                
                                // Sample questions
                                VStack(spacing: 12) {
                                    ForEach(["How do stocks work?", "Explain market capitalization", "What is a bond yield?"], id: \.self) { question in
                                        Button {
                                            messageText = question
                                            sendMessage()
                                        } label: {
                                            HStack {
                                                Image(systemName: "text.bubble")
                                                    .foregroundColor(.accentColor)
                                                    .frame(width: 24, height: 24)
                                                Text(question)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.body)
                                                Image(systemName: "arrow.forward.circle.fill")
                                                    .foregroundColor(.accentColor)
                                                    .frame(width: 24, height: 24)
                                            }
                                            .padding()
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .cornerRadius(16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding()
                        } else {
                            // Show conversation
                            ForEach(assistantViewModel.currentConversation.messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            
                            // Loading indicator
                            if assistantViewModel.isProcessing {
                                HStack {
                                    ProgressView()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .id("loader")
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                .onChange(of: assistantViewModel.currentConversation.messages.count) { oldValue, newValue in
                    // Scroll to bottom when new messages appear
                    if let lastMessage = assistantViewModel.currentConversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: assistantViewModel.isProcessing) { oldValue, newValue in
                    if newValue {
                        withAnimation {
                            proxy.scrollTo("loader", anchor: .bottom)
                        }
                    }
                }
                // Add tap gesture to dismiss keyboard when tapping on the scroll view
                .onTapGesture {
                    isTextFieldFocused = false
                }
            }
            
            // Error message
            if let error = assistantViewModel.error, assistantViewModel.showError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            
            // Input field
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $messageText, axis: .vertical)
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .frame(minHeight: 44)
                    .focused($isTextFieldFocused)
                    .disabled(assistantViewModel.isProcessing)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.accentColor)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistantViewModel.isProcessing)
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.systemGray5)),
                alignment: .top
            )
        }
        .toolbar {
            // Add keyboard dismiss button when keyboard is visible
            ToolbarItem(placement: .keyboard) {
                Button {
                    isTextFieldFocused = false
                } label: {
                    Text("Done")
                        .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $assistantViewModel.showAPIKeySetup) {
            APIKeySetupView()
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        Task {
            await assistantViewModel.sendMessage(trimmedMessage)
            messageText = ""
        }
    }
}

// MARK: - Insights View
struct InsightsView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header styled like Stocks app
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.systemGray4))
            }
            
            List {
                Section {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Market Analysis")
                                .font(.headline)
                            Text("Latest market trends and patterns")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Now")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Image(systemName: "chart.pie.fill")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio Insights")
                                .font(.headline)
                            Text("Your portfolio performance analysis")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("1h ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Markets View
struct MarketsView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header styled like Stocks app
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Markets")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.systemGray4))
            }
            
            List {
                Section(header: Text("Major Indices")) {
                    MarketItemRow(name: "S&P 500", value: "5,254.67", change: "+0.54%", isPositive: true)
                    MarketItemRow(name: "Nasdaq", value: "16,384.45", change: "+0.34%", isPositive: true)
                    MarketItemRow(name: "Dow Jones", value: "39,170.35", change: "-0.12%", isPositive: false)
                }
                
                Section(header: Text("Currencies")) {
                    MarketItemRow(name: "EUR/USD", value: "1.0831", change: "+0.05%", isPositive: true)
                    MarketItemRow(name: "USD/JPY", value: "151.45", change: "-0.22%", isPositive: false)
                }
                
                Section(header: Text("Commodities")) {
                    MarketItemRow(name: "Gold", value: "2,178.35", change: "+0.64%", isPositive: true)
                    MarketItemRow(name: "Oil WTI", value: "81.35", change: "-1.02%", isPositive: false)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct MarketItemRow: View {
    let name: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(name)
                .font(.body)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(value)
                    .font(.body)
                    .bold()
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Message View
struct MessageView: View {
    let message: Message
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack(alignment: .top) {
            if isUser {
                Spacer(minLength: 60)
            } else {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                    .padding(.top, 4)
            }
            
            VStack(alignment: isUser ? .trailing : .leading) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isUser ? Color.accentColor : Color(.systemGray6))
                    .foregroundColor(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if isUser {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                    .padding(.top, 4)
            } else {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



#Preview {
    MainTabView()
        .environmentObject(UserViewModel())
        .environmentObject(SecurityViewModel())
        .environmentObject(AppConfiguration())
} 