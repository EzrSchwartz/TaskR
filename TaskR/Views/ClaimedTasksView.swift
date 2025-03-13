import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ClaimedTasksView: View {
    @StateObject var viewModel = TaskViewModel()
    @State private var selectedTask: Task?
    @State private var showTaskDetails = false
    @State private var loadError: String? = nil
    @State private var manuallyLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && !manuallyLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if viewModel.currentClaimedTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Claimed Tasks")
            .onAppear {
                print("🔍 ClaimedTasksView: View appeared, fetching claimed tasks")
                fetchClaimedTasksWithTimeout()
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailsView(task: task)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.taskApproved)) { _ in
                print("⚡️ ClaimedTasksView: Received task approved notification")
                fetchClaimedTasksWithTimeout()
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading your tasks...")
                .padding()
            
            // Add a timeout counter to prevent infinite loading
            Text("This should only take a moment...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
                .onAppear {
                    // Force stop loading after 5 seconds if it gets stuck
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if viewModel.isLoading {
                            viewModel.isLoading = false
                            loadError = "Loading took too long. Your tasks may not have loaded properly."
                        }
                    }
                }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()
            
            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadError = nil
                fetchClaimedTasksWithTimeout()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 20)
        }
        .padding()
    }
    
    private func fetchClaimedTasksWithTimeout() {
        manuallyLoading = true
        viewModel.isLoading = true
        loadError = nil
        
        // Need to fetch both tasks the user created and tasks they've claimed
        if let userID = Auth.auth().currentUser?.uid {
            print("🔄 ClaimedTasksView: Refreshing claimed tasks for user \(userID)")
            
            // Add a print statement to the end of fetchClaimedTasks to debug
            viewModel.fetchClaimedTasks()
            print("⏳ ClaimedTasksView: Called fetchClaimedTasks, waiting for completion")
        }
        
        // Delay to ensure everything loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("✅ ClaimedTasksView: Finished refreshing, found \(self.viewModel.currentClaimedTasks.count) claimed tasks")
            if self.viewModel.currentClaimedTasks.isEmpty {
                print("ℹ️ ClaimedTasksView: No claimed tasks found")
            }
            viewModel.isLoading = false
            manuallyLoading = false
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("You Haven't Claimed Any Tasks Yet")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
            
            Text("Browse the task list to find tasks you can help with!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
                
            NavigationLink(destination: TaskListView()) {
                Text("Browse Available Tasks")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button("Refresh") {
                fetchClaimedTasksWithTimeout()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 10)
        }
        .padding()
    }
    
    private var taskListView: some View {
        List {
            ForEach(viewModel.currentClaimedTasks) { task in
                taskCell(task)
            }
        }
        .refreshable {
            fetchClaimedTasksWithTimeout()
        }
    }
    
    private func taskCell(_ task: Task) -> some View {
        Button(action: {
            selectedTask = task
            showTaskDetails = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                    Spacer()
                    statusBadge(for: task.status)
                }
                
                Text(task.description)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("By: \(viewModel.usernames[task.creatorID] ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Due: \(formatDate(task.dueDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("\(task.payType): $\(task.pay)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    Text(task.category)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                }
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusBadge(for status: String) -> some View {
        let color: Color
        let text: String
        
        switch status {
        case "available":
            color = .blue
            text = "Available"
        case "inProgress":
            color = .orange
            text = "In Progress"
        case "completed":
            color = .green
            text = "Completed"
        default:
            color = .gray
            text = status.capitalized
        }
        
        return Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Task Details View
struct TaskDetailsView: View {
    let task: Task
    @Environment(\.dismiss) var dismiss
    @State private var showingCompleteAlert = false
    @State private var showingContactSheet = false
    
    // Add these missing state variables
    @State private var showChatView = false
    @State private var showChatAccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Task header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            Text("Status: ")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(task.status.capitalized)
                                .font(.subheadline)
                                .foregroundColor(statusColor(task.status))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor(task.status).opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                    
                    // Details
                    Group {
                        detailRow(title: "Due Date", value: formatDate(task.dueDate))
                        detailRow(title: "Payment", value: "\(task.payType): $\(task.pay)")
                        detailRow(title: "Category", value: task.category)
                        detailRow(title: "Expertise", value: task.expertise.isEmpty ? "None" : task.expertise)
                        detailRow(title: "Town", value: task.town)
                    }
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    
                    Text(task.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Action buttons
//                    if task.status == "inProgress" {
//                        Button(action: {
//                            showingCompleteAlert = true
//                        }) {
//                            HStack {
//                                Image(systemName: "checkmark.circle.fill")
//                                Text("Mark as Completed")
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.green)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                            .padding(.top, 16)
//                        }
//                    }

                    // Chat button
                    Button(action: {
                        if canAccessChat() {
                            showChatView = true
                        } else {
                            showChatAccessAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Chat")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isChatAvailable())
                    .fullScreenCover(isPresented: $showChatView) {
                        NavigationView {
                            // Replace MessageKitChatView with TaskChatView
                            TaskChatView(taskID: task.id, taskTitle: task.title)
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .primaryAction) {
                                        Button("Close") {
                                            showChatView = false
                                        }
                                    }
                                }
                        }
                    }
                    .alert(isPresented: $showChatAccessAlert) {
                        Alert(
                            title: Text("Chat Not Available"),
                            message: Text("You can chat once your request has been approved or if you created this task."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .alert("Mark Task as Completed?", isPresented: $showingCompleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Complete", role: .destructive) {
                    completeTask()
                }
            } message: {
                Text("Are you sure you've finished this task? The task creator will be notified.")
            }
            .actionSheet(isPresented: $showingContactSheet) {
                ActionSheet(
                    title: Text("Contact Options"),
                    message: Text("How would you like to contact the task creator?"),
                    buttons: [
                        .default(Text("Send Message")) {
                            // Implement message sending logic
                        },
                        .default(Text("Call")) {
                            // Implement call logic
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // These helper methods need to be outside the body property
    private func canAccessChat() -> Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        
        // Task creator can always access chat
        if task.creatorID == currentUserID { return true }
        
        // Approved assignees can access chat
        return task.assignees.contains { $0.userID == currentUserID && $0.approved }
    }

    private func isChatAvailable() -> Bool {
        // Chat is available if task has creator and any approved assignee
        return task.assignees.contains { $0.approved }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available": return .blue
        case "inProgress": return .orange
        case "completed": return .green
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func completeTask() {
        // Implement task completion logic here
        // This could call a method in your TaskService
    }
}


//
//// MARK: - TaskChatView Structure
//// Add this new view to replace MessageKitChatView
//struct TaskChatView: View {
//    let taskID: String
//    let taskTitle: String
//    
//    @State private var messages: [ChatMessage] = []
//    @State private var newMessage = ""
//    @State private var isLoading = true
//    @State private var chatID: String?
//    @State private var errorMessage: String?
//    
//    var body: some View {
//        VStack {
//            if isLoading {
//                ProgressView("Loading chat...")
//                    .padding()
//            } else if let errorMessage = errorMessage {
//                VStack {
//                    Image(systemName: "exclamationmark.triangle")
//                        .font(.system(size: 50))
//                        .foregroundColor(.orange)
//                        .padding()
//                    
//                    Text(errorMessage)
//                        .multilineTextAlignment(.center)
//                        .padding()
//                    
//                    Button("Retry") {
//                        loadChat()
//                    }
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                }
//                .padding()
//            } else if messages.isEmpty {
//                VStack(spacing: 20) {
//                    Image(systemName: "bubble.left.and.bubble.right")
//                        .font(.system(size: 60))
//                        .foregroundColor(.gray)
//                        .padding()
//                    
//                    Text("No messages yet")
//                        .font(.headline)
//                        .foregroundColor(.gray)
//                    
//                    Text("Start the conversation about this task")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal)
//                }
//                .padding()
//                .frame(maxHeight: .infinity)
//            } else {
//                // Messages list
//                ScrollViewReader { scrollView in
//                    ScrollView {
//                        LazyVStack(spacing: 12) {
//                            ForEach(messages) { message in
//                                MessageRow(message: message)
//                                    .id(message.id)
//                            }
//                        }
//                        .padding()
//                    }
//                    .onChange(of: messages.count) { _ in
//                        if let lastMessage = messages.last, let id = lastMessage.id {
//                            withAnimation {
//                                scrollView.scrollTo(id, anchor: .bottom)
//                            }
//                        }
//                    }
//                    .onAppear {
//                        if let lastMessage = messages.last, let id = lastMessage.id {
//                            scrollView.scrollTo(id, anchor: .bottom)
//                        }
//                    }
//                }
//            }
//            
//            // Message input
//            HStack {
//                TextField("Type a message...", text: $newMessage)
//                    .padding(12)
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(20)
//                
//                Button(action: sendMessage) {
//                    Image(systemName: "paperplane.fill")
//                        .font(.system(size: 20))
//                        .foregroundColor(.white)
//                        .frame(width: 40, height: 40)
//                        .background(Color.blue)
//                        .clipShape(Circle())
//                }
//                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//            }
//            .padding()
//        }
//        .navigationTitle("Task Chat")
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//            loadChat()
//        }
//    }
//    
//    private func loadChat() {
//        isLoading = true
//        errorMessage = nil
//        
//        // Check if a chat exists for this task
//        FirebaseChatService.shared.checkIfChatExists(taskID: taskID) { exists in
//            if exists {
//                // Get the chat ID
//                Firestore.firestore().collection("chats")
//                    .whereField("taskID", isEqualTo: taskID)
//                    .getDocuments { snapshot, error in
//                        if let error = error {
//                            DispatchQueue.main.async {
//                                isLoading = false
//                                errorMessage = "Error loading chat: \(error.localizedDescription)"
//                            }
//                            return
//                        }
//                        
//                        if let chatDocument = snapshot?.documents.first {
//                            let foundChatID = chatDocument.documentID
//                            chatID = foundChatID
//                            
//                            // Now fetch messages
//                            FirebaseChatService.shared.fetchMessages(for: foundChatID) { result in
//                                DispatchQueue.main.async {
//                                    isLoading = false
//                                    
//                                    switch result {
//                                    case .success(let fetchedMessages):
//                                        messages = fetchedMessages
//                                    case .failure(let error):
//                                        errorMessage = "Error loading messages: \(error.localizedDescription)"
//                                    }
//                                }
//                            }
//                        } else {
//                            DispatchQueue.main.async {
//                                isLoading = false
//                                errorMessage = "No chat found for this task"
//                            }
//                        }
//                    }
//            } else {
//                // No chat exists yet - need to create one
//                // First, fetch task details
//                Firestore.firestore().collection("tasks").document(taskID).getDocument { snapshot, error in
//                    if let error = error {
//                        DispatchQueue.main.async {
//                            isLoading = false
//                            errorMessage = "Error loading task: \(error.localizedDescription)"
//                        }
//                        return
//                    }
//                    
//                    do {
//                        if let task = try snapshot?.data(as: Task.self) {
//                            // Create a chat for this task
//                            FirebaseChatService.shared.createChatForTask(task: task) { result in
//                                DispatchQueue.main.async {
//                                    switch result {
//                                    case .success(let newChatID):
//                                        chatID = newChatID
//                                        isLoading = false
//                                        messages = []  // New chat, no messages yet
//                                    case .failure(let error):
//                                        isLoading = false
//                                        errorMessage = "Failed to create chat: \(error.localizedDescription)"
//                                    }
//                                }
//                            }
//                        } else {
//                            DispatchQueue.main.async {
//                                isLoading = false
//                                errorMessage = "Invalid task data"
//                            }
//                        }
//                    } catch {
//                        DispatchQueue.main.async {
//                            isLoading = false
//                            errorMessage = "Failed to parse task: \(error.localizedDescription)"
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private func sendMessage() {
//        guard let chatID = chatID,
//              let currentUserID = Auth.auth().currentUser?.uid,
//              !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            return
//        }
//        
//        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
//        newMessage = ""
//        
//        FirebaseChatService.shared.sendMessage(
//            chatID: chatID,
//            senderID: currentUserID,
//            content: trimmedMessage,
//            taskID: taskID
//        ) { _ in
//            // Message sending handled by listener
//        }
//    }
//}
//
//// Message row component
//struct MessageRow: View {
//    let message: ChatMessage
//    @State private var senderName: String = ""
//    
//    private var isFromCurrentUser: Bool {
//        message.senderID == Auth.auth().currentUser?.uid
//    }
//    
//    private var isSystemMessage: Bool {
//        message.senderID == "system"
//    }
//    
//    var body: some View {
//        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
//            // System messages are centered
//            if isSystemMessage {
//                Text(message.content)
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                    .padding(8)
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(10)
//                    .frame(maxWidth: .infinity)
//            } else {
//                // Regular message
//                HStack {
//                    if isFromCurrentUser {
//                        Spacer()
//                    }
//                    
//                    VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
//                        if !isFromCurrentUser && senderName.isEmpty {
//                            Text(message.senderName)
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        
//                        Text(message.content)
//                            .padding(12)
//                            .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
//                            .foregroundColor(isFromCurrentUser ? .white : .primary)
//                            .cornerRadius(16)
//                        
//                        Text(formatTimestamp(message.timestamp))
//                            .font(.caption2)
//                            .foregroundColor(.gray)
//                    }
//                    
//                    if !isFromCurrentUser {
//                        Spacer()
//                    }
//                }
//            }
//        }
//        .padding(.vertical, 2)
//    }
//    
//    private func formatTimestamp(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//}
