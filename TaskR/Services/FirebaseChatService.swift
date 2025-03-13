import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestore

// MARK: - Chat Models

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderID: String
    let senderName: String
    let content: String
    let timestamp: Date
    let isRead: Bool
    
    // For group chats (task-related)
    let taskID: String?
    
    // For direct messages
    let receiverID: String?
}

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    let taskID: String?
    let participants: [String]
    let createdAt: Date
    let lastMessageTimestamp: Date?
    let lastMessageContent: String?
    let lastMessageSenderID: String?
    let lastMessageSenderName: String?
    let type: ChatType
    
    enum ChatType: String, Codable {
        case taskGroup
        case directMessage
    }
}

// MARK: - Chat Service

class FirebaseChatService {
    static let shared = FirebaseChatService()
    private let db = Firestore.firestore()
    
    // MARK: - Chat Existence & Creation
    
    /// Check if a chat exists for a specific task
    func checkIfChatExists(taskID: String, completion: @escaping (Bool) -> Void) {
        // Add more debug logging
        print("Checking if chat exists for task: \(taskID)")
        
        // Explicitly check the user is authenticated first
        guard Auth.auth().currentUser != nil else {
            print("User not authenticated, can't check for chat existence")
            completion(false)
            return
        }
        
        // Try to avoid permission errors by using a more direct query
        db.collection("chats")
            .whereField("taskID", isEqualTo: taskID)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for chat existence: \(error.localizedDescription)")
                    // If there's an error, assume the chat doesn't exist
                    completion(false)
                    return
                }
                
                let exists = !(snapshot?.documents.isEmpty ?? true)
                print("Chat for task \(taskID) exists: \(exists)")
                completion(exists)
            }
    }
    
    /// Create a new chat for a task
    func createChatForTask(task: Task, completion: @escaping (Result<String, Error>) -> Void) {
        print("Creating new chat for task: \(task.id)")
        
        // Check if a chat already exists for this task to prevent duplicates
        checkIfChatExists(taskID: task.id) { [weak self] exists in
            guard let self = self else { return }
            
            if exists {
                print("Chat already exists for this task, getting existing chat ID")
                
                // Find the existing chat and return its ID
                self.db.collection("chats")
                    .whereField("taskID", isEqualTo: task.id)
                    .limit(to: 1)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error getting existing chat: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        if let chatDoc = snapshot?.documents.first {
                            let chatID = chatDoc.documentID
                            print("Found existing chat with ID: \(chatID)")
                            completion(.success(chatID))
                        } else {
                            print("No existing chat found despite exists check returning true")
                            // Fall back to creating a new chat
                            self.createNewChat(for: task, completion: completion)
                        }
                    }
            } else {
                // No existing chat, create a new one
                print("No existing chat for task, creating new one")
                self.createNewChat(for: task, completion: completion)
            }
        }
    }
    private func createNewChat(for task: Task, completion: @escaping (Result<String, Error>) -> Void) {
        // Get participant IDs (creator + approved assignees)
        let assigneeIDs = task.assignees.filter { $0.approved }.map { $0.userID }
        var participants = [task.creatorID]
        participants.append(contentsOf: assigneeIDs)
        
        // Remove duplicates
        participants = Array(Set(participants))
        
        print("Creating chat with participants: \(participants)")
        
        // Create chat
        let chat = Chat(
            id: nil,
            taskID: task.id,
            participants: participants,
            createdAt: Date(),
            lastMessageTimestamp: nil,
            lastMessageContent: nil,
            lastMessageSenderID: nil,
            lastMessageSenderName: nil,
            type: .taskGroup
        )
        
        do {
            let ref = try db.collection("chats").addDocument(from: chat)
            print("Successfully created chat with ID: \(ref.documentID)")
            
            // Send initial system message
            sendSystemMessage(
                chatID: ref.documentID,
                content: "Task chat created for '\(task.title)'",
                taskID: task.id
            ) { result in
                switch result {
                case .success:
                    print("Added system message to chat")
                case .failure(let error):
                    print("Failed to add system message: \(error.localizedDescription)")
                    // Continue anyway since this is not critical
                }
                
                // Return the new chat ID regardless of system message
                completion(.success(ref.documentID))
            }
        } catch {
            print("Error creating chat: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Update participants in an existing chat
    func updateChatParticipants(taskID: String, participants: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        // Find the chat
        db.collection("chats")
            .whereField("taskID", isEqualTo: taskID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error finding chat: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let chatDoc = snapshot?.documents.first else {
                    print("❌ Chat not found for task ID: \(taskID)")
                    completion(.failure(NSError(domain: "FirebaseChatService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat not found"])))
                    return
                }
                
                // Update participants
                chatDoc.reference.updateData([
                    "participants": participants
                ]) { error in
                    if let error = error {
                        print("❌ Error updating chat participants: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        // Get current participants before the update for comparison
                        if let oldParticipants = chatDoc.data()["participants"] as? [String] {
                            let newParticipants = participants.filter { !oldParticipants.contains($0) }
                            
                            // If there are new participants, send a system message
                            if !newParticipants.isEmpty {
                                // Get usernames for notification
                                self.getUsernames(for: newParticipants) { usernames in
                                    let usernamesJoined = usernames.joined(separator: ", ")
                                    self.sendSystemMessage(
                                        chatID: chatDoc.documentID,
                                        content: "\(usernamesJoined) joined the chat",
                                        taskID: taskID
                                    ) { _ in
                                        // Ignore result
                                    }
                                }
                            }
                        }
                        
                        completion(.success(()))
                    }
                }
            }
    }
    
    // MARK: - Message Handling
    
    /// Send a message in a chat
    func sendMessage(chatID: String, senderID: String, content: String, taskID: String? = nil, receiverID: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        // Get sender name
        UserService.shared.fetchUserProfile(userID: senderID) { profile in
            guard let profile = profile else {
                completion(.failure(NSError(domain: "FirebaseChatService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])))
                return
            }
            
            let message = ChatMessage(
                id: nil,
                senderID: senderID,
                senderName: profile.username,
                content: content,
                timestamp: Date(),
                isRead: false,
                taskID: taskID,
                receiverID: receiverID
            )
            
            do {
                // Add to the messages subcollection
                let ref = try self.db.collection("chats").document(chatID).collection("messages").addDocument(from: message)
                
                // Update the chat with last message info
                self.db.collection("chats").document(chatID).updateData([
                    "lastMessageTimestamp": message.timestamp,
                    "lastMessageContent": message.content,
                    "lastMessageSenderID": message.senderID,
                    "lastMessageSenderName": message.senderName
                ]) { error in
                    if let error = error {
                        print("⚠️ Warning: Failed to update chat with last message: \(error.localizedDescription)")
                    }
                }
                
                completion(.success(ref.documentID))
            } catch {
                print("❌ Error sending message: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    /// Send a system message (no actual sender)
    private func sendSystemMessage(chatID: String, content: String, taskID: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        let message = ChatMessage(
            id: nil,
            senderID: "system",
            senderName: "System",
            content: content,
            timestamp: Date(),
            isRead: true,
            taskID: taskID,
            receiverID: nil
        )
        
        do {
            let ref = try self.db.collection("chats").document(chatID).collection("messages").addDocument(from: message)
            
            // Update the chat with last message info
            self.db.collection("chats").document(chatID).updateData([
                "lastMessageTimestamp": message.timestamp,
                "lastMessageContent": message.content,
                "lastMessageSenderID": message.senderID,
                "lastMessageSenderName": message.senderName
            ]) { error in
                if let error = error {
                    print("⚠️ Warning: Failed to update chat with system message: \(error.localizedDescription)")
                }
            }
            
            completion(.success(ref.documentID))
        } catch {
            print("❌ Error sending system message: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Message Fetching
    
    /// Fetch messages for a specific chat
    func fetchMessages(for chatID: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        db.collection("chats").document(chatID).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching messages: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let messages = documents.compactMap { doc -> ChatMessage? in
                    try? doc.data(as: ChatMessage.self)
                }
                
                completion(.success(messages))
            }
    }
    
    /// Mark a message as read
    func markMessageAsRead(chatID: String, messageID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("chats").document(chatID).collection("messages").document(messageID)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("❌ Error marking message as read: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Chat Listing
    
    /// Fetch all chats for a user
    func fetchChats(for userID: String, completion: @escaping (Result<[Chat], Error>) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: userID)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching chats: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let chats = documents.compactMap { doc -> Chat? in
                    try? doc.data(as: Chat.self)
                }
                
                completion(.success(chats))
            }
    }
    
    /// Create a direct message chat between two users
    func createDirectMessageChat(senderID: String, receiverID: String, initialMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if chat already exists
        checkIfDirectChatExists(between: senderID, and: receiverID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let existingChatID):
                if let chatID = existingChatID {
                    // Chat exists, send message
                    self.sendMessage(
                        chatID: chatID,
                        senderID: senderID,
                        content: initialMessage,
                        receiverID: receiverID
                    ) { messageResult in
                        switch messageResult {
                        case .success:
                            completion(.success(chatID))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    // Create new chat
                    let chat = Chat(
                        id: nil,
                        taskID: nil,
                        participants: [senderID, receiverID],
                        createdAt: Date(),
                        lastMessageTimestamp: nil,
                        lastMessageContent: nil,
                        lastMessageSenderID: nil,
                        lastMessageSenderName: nil,
                        type: .directMessage
                    )
                    
                    do {
                        let ref = try self.db.collection("chats").addDocument(from: chat)
                        
                        // Send initial message
                        self.sendMessage(
                            chatID: ref.documentID,
                            senderID: senderID,
                            content: initialMessage,
                            receiverID: receiverID
                        ) { messageResult in
                            switch messageResult {
                            case .success:
                                completion(.success(ref.documentID))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    } catch {
                        print("❌ Error creating direct message chat: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Check if a direct message chat exists between two users
    private func checkIfDirectChatExists(between userID1: String, and userID2: String, completion: @escaping (Result<String?, Error>) -> Void) {
        db.collection("chats")
            .whereField("type", isEqualTo: Chat.ChatType.directMessage.rawValue)
            .whereField("participants", arrayContains: userID1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking for direct chat: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                // Find a chat where both users are participants
                if let chatDoc = snapshot?.documents.first(where: {
                    guard let participants = $0.data()["participants"] as? [String] else { return false }
                    return participants.contains(userID2)
                }) {
                    completion(.success(chatDoc.documentID))
                } else {
                    // No existing chat found
                    completion(.success(nil))
                }
            }
    }
    
    // MARK: - Utilities
    
    /// Get usernames for a list of user IDs
    private func getUsernames(for userIDs: [String], completion: @escaping ([String]) -> Void) {
        let group = DispatchGroup()
        var usernames: [String] = []
        
        for userID in userIDs {
            group.enter()
            
            UserService.shared.fetchUserProfile(userID: userID) { profile in
                if let profile = profile {
                    usernames.append(profile.username)
                } else {
                    usernames.append("Unknown User")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(usernames)
        }
    }
    
    /// Count unread messages for a user
    func countUnreadMessages(for userID: String, completion: @escaping (Result<Int, Error>) -> Void) {
        // First get all chats the user participates in
        fetchChats(for: userID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let chats):
                let group = DispatchGroup()
                var totalUnread = 0
                
                // For each chat, count unread messages
                for chat in chats {
                    guard let chatID = chat.id else { continue }
                    
                    group.enter()
                    self.fetchUnreadMessageCount(chatID: chatID, userID: userID) { count in
                        totalUnread += count
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(totalUnread))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Count unread messages in a specific chat
    private func fetchUnreadMessageCount(chatID: String, userID: String, completion: @escaping (Int) -> Void) {
        db.collection("chats").document(chatID).collection("messages")
            .whereField("isRead", isEqualTo: false)
            .whereField("senderID", isNotEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error counting unread messages: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                completion(snapshot?.documents.count ?? 0)
            }
    }
}
