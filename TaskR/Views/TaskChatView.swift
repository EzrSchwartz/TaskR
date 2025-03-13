//
//  TaskChatView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/13/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Task chat view - for communication about a specific task
struct TaskChatView: View {
    let taskID: String
    let taskTitle: String
    
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var chatID: String?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading chat...")
                    .padding()
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Retry") {
                        loadChat()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if messages.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No messages yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Start the conversation about this task")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                // Messages list
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastMessage = messages.last {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Task Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadChat()
        }
    }
    
    private func loadChat() {
        isLoading = true
        errorMessage = nil
        
        print("Loading chat for task: \(taskID)")
        
        // First check if a chat exists for this task
        FirebaseChatService.shared.checkIfChatExists(taskID: taskID) { exists in
            if exists {
                print("Chat exists for task, loading messages")
                // Get the chat ID
                Firestore.firestore().collection("chats")
                    .whereField("taskID", isEqualTo: self.taskID)
                    .limit(to: 1)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error getting chat document: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.isLoading = false
                                // Show empty messages instead of error for better UX
                                self.messages = []
                            }
                            return
                        }
                        
                        if let chatDocument = snapshot?.documents.first {
                            let foundChatID = chatDocument.documentID
                            print("Found chat with ID: \(foundChatID)")
                            self.chatID = foundChatID
                            
                            // Now fetch messages
                            FirebaseChatService.shared.fetchMessages(for: foundChatID) { result in
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    
                                    switch result {
                                    case .success(let fetchedMessages):
                                        print("Loaded \(fetchedMessages.count) messages")
                                        self.messages = fetchedMessages
                                    case .failure(let error):
                                        print("Error loading messages: \(error.localizedDescription)")
                                        // Show empty state instead of error
                                        self.messages = []
                                    }
                                }
                            }
                        } else {
                            print("Chat exists but document not found, creating new chat")
                            // This shouldn't happen, but create a new chat if it does
                            self.createChatForTask()
                        }
                    }
            } else {
                print("No chat exists for task, creating new one")
                // No chat exists, create one
                self.createChatForTask()
            }
        }
    }
    static func forTask(_ task: Task) -> some View {
        TaskChatView(taskID: task.id, taskTitle: task.title)
    }
    private func createChatForTask() {
        guard let task = getTaskData() else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Unable to load task data"
            }
            return
        }
        
        FirebaseChatService.shared.createChatForTask(task: task) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let newChatID):
                    print("Successfully created chat with ID: \(newChatID)")
                    self.chatID = newChatID
                    self.messages = [] // New chat, no messages yet
                case .failure(let error):
                    print("Error creating chat: \(error.localizedDescription)")
                    self.errorMessage = "Failed to create chat: \(error.localizedDescription)"
                }
            }
        }
    }
    // Replace the placeholder getTaskData method with this actual implementation
    
    private func getTaskData() -> Task? {
        // This method retrieves the task data synchronously (for use in createChatForTask)
        guard !taskID.isEmpty else {
            print("Error: Task ID is empty")
            return nil
        }
        
        print("Getting task data for ID: \(taskID)")
        
        var loadedTask: Task?
        let semaphore = DispatchSemaphore(value: 0)
        let db = Firestore.firestore()
        
        db.collection("tasks").document(taskID).getDocument { snapshot, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("Error loading task: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot, document.exists else {
                print("Task document doesn't exist")
                return
            }
            
            do {
                loadedTask = try document.data(as: Task.self)
                print("Successfully loaded task: \(loadedTask?.title ?? "Unknown title")")
            } catch {
                print("Error parsing task data: \(error.localizedDescription)")
            }
        }
        
        // Wait for the task to load (with timeout)
        // Note: This blocks the current thread, so ensure this method isn't called on the main thread
        let result = semaphore.wait(timeout: .now() + 5)
        
        if result == .timedOut {
            print("Timeout while loading task data")
            return nil
        }
        
        return loadedTask
    }
    
    private func sendMessage() {
        guard let chatID = chatID,
              let currentUserID = Auth.auth().currentUser?.uid,
              !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Sending message: \(trimmedMessage)")
        
        // Clear the input field immediately for better UX
        newMessage = ""
        
        FirebaseChatService.shared.sendMessage(
            chatID: chatID,
            senderID: currentUserID,
            content: trimmedMessage,
            taskID: taskID
        ) { result in
            switch result {
            case .success:
                print("Message sent successfully")
            case .failure(let error):
                print("Error sending message: \(error.localizedDescription)")
                // You might want to show a small error indicator here
            }
        }
    }
    
    // Message row component
    struct MessageRow: View {
        let message: ChatMessage
        @State private var senderName: String = ""
        
        private var isFromCurrentUser: Bool {
            message.senderID == Auth.auth().currentUser?.uid
        }
        
        private var isSystemMessage: Bool {
            message.senderID == "system"
        }
        
        var body: some View {
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // System messages are centered
                if isSystemMessage {
                    Text(message.content)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                } else {
                    // Regular message
                    HStack {
                        if isFromCurrentUser {
                            Spacer()
                        }
                        
                        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                            if !isFromCurrentUser && senderName.isEmpty {
                                Text(message.senderName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text(message.content)
                                .padding(12)
                                .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(isFromCurrentUser ? .white : .primary)
                                .cornerRadius(16)
                            
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        if !isFromCurrentUser {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        
        private func formatTimestamp(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // Use this extension to create a destination from a task
 
}
