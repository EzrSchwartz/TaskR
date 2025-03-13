
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MessagesListView: View {
    @State private var conversations: [ChatConversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading conversations...")
            } else if conversations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No conversations yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("When you chat with other users, your conversations will appear here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else {
                List {
                    ForEach(conversations) { conversation in
                        NavigationLink(destination: ChatDetailView(partnerID: conversation.partnerID, partnerName: conversation.partnerName)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Messages")
        .onAppear {
            loadConversations()
        }
        .refreshable {
            loadConversations()
        }
    }
    
    private func loadConversations() {
        isLoading = true
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        // This is a simplified placeholder - replace with FirebaseChatService when ready
        FirebaseFirestore.Firestore.firestore().collection("chats")
            .whereField("participants", arrayContains: currentUserID)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                // Simple placeholder data - replace with actual chat data
                conversations = []
            }
    }
}

struct ChatDetailView: View {
    let partnerID: String
    let partnerName: String
    @State private var messageText = ""
    @State private var messages: [MessageViewModel] = []
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Message", text: $messageText)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle(partnerName)
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        // Placeholder - replace with actual implementation
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Placeholder - replace with actual implementation
        
        messageText = ""
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation
    
    var body: some View {
        HStack {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 50, height: 50)
                
                Text(String(conversation.partnerName.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.partnerName)
                    .font(.headline)
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(conversation.lastMessageDate))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.blue))
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: date)
        }
    }
}

struct MessageBubble: View {
    let message: MessageViewModel
    
    var body: some View {
        HStack {
            if message.isSentByMe {
                Spacer()
            }
            
            Text(message.text)
                .padding(10)
                .background(message.isSentByMe ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isSentByMe ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isSentByMe {
                Spacer()
            }
        }
    }
}

// MARK: 3. Simple View Models
// Add these to the same file

struct ChatConversation: Identifiable {
    var id: String { partnerID }
    let partnerID: String
    let partnerName: String
    let lastMessage: String
    let lastMessageDate: Date
    let unreadCount: Int
}

struct MessageViewModel: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
    let isSentByMe: Bool
}
