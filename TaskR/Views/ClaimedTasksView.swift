import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct ClaimedTasksView: View {
    @StateObject var viewModel = TaskViewModel()
    @State private var selectedTask: Task?
    @State private var showTaskDetails = false
    @State private var loadError: String? = nil
    @State private var manuallyLoading = false
    @State private var loadingTimeout = 5.0 // Increased timeout
    
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
            .refreshable {
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
                .foregroundColor(AppColors.secondaryGray)
                .padding(.top, 8)
                .onAppear {
                    // Force stop loading after a delay if it gets stuck
                    DispatchQueue.main.asyncAfter(deadline: .now() + loadingTimeout) {
                        if viewModel.isLoading {
                            viewModel.isLoading = false
                            loadError = "Loading took too long. Your tasks may not have loaded properly."
                            manuallyLoading = false // Reset manual loading state
                        }
                    }
                }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primaryRed) // Keep original error color
                .padding()
            
            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(AppColors.primaryGray)  // Keep original color
                .padding(.bottom, 8)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryGray) // Keep original color
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadError = nil
                fetchClaimedTasksWithTimeout()
            }
            .padding()
            .background(AppColors.primaryBlue) // Keep original button color
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
                .foregroundColor(.gray) // Keep original color
                .padding()
            
            Text("You Haven't Claimed Any Tasks Yet")
                .font(.headline)
                .foregroundColor(AppColors.primaryGray) // Keep original color
                .padding()
            
            Text("Browse the task list to find tasks you can help with!")
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryGray) // Keep original color
                .multilineTextAlignment(.center)
                .padding()
            
            NavigationLink(destination: TaskListView()) {
                Text("Browse Available Tasks")
                    .padding()
                    .background(AppColors.primaryBlue) // Keep original button color
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Button("Refresh") {
                fetchClaimedTasksWithTimeout()
            }
            .padding()
            .background(AppColors.primaryGreen) // Use forest green
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
                    .foregroundColor(AppColors.secondaryGray) // Keep original color
                
                HStack {
                    Text("By: \(viewModel.usernames[task.creatorID] ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.gray) // Keep original color
                    
                    Spacer()
                    
                    Text("Due: \(formatDate(task.dueDate))")
                        .font(.caption)
                        .foregroundColor(.gray) // Keep original color
                }
                
                HStack {
                    Text("\(task.payType): $\(task.pay)")
                        .font(.caption)
                        .foregroundColor(AppColors.primaryGreen) // Use forest green
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.lightGreen) // Use lightGreen
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    Text(task.category)
                        .font(.caption)
                        .foregroundColor(AppColors.primaryBlue) // Keep original color
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.lightBlue) // Keep original color
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
            color = AppColors.primaryBlue // Keep original color.  Consider if this fits with forestGreen
            text = "Available"
        case "inProgress":
            color = AppColors.primaryYellow // Keep original color. Consider if this fits with forestGreen
            text = "In Progress"
        case "completed":
            color = AppColors.primaryGreen // Use forest green
            text = "Completed"
        default:
            color = .gray // Keep original color
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
    @State private var showRatingSheet = false
    
    // Add these missing state variables
    @State private var showChatView = false
    @State private var showChatAccessAlert = false
    @StateObject var viewModel = TaskViewModel() // Use StateObject
    
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
                                .foregroundColor(AppColors.secondaryGray) // Keep original color
                            
                            Text(task.status.capitalized)
                                .font(.subheadline)
                                .foregroundColor(statusColor(task.status))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor(task.status).opacity(0.15)) // Slightly lighter
                                .cornerRadius(4)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3)) // Lighter divider
                    
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
                        .foregroundColor(Color.gray.opacity(0.3)) // Lighter divider
                        .padding(.vertical, 8)
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    
                    Text(task.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
                        .background(AppColors.primaryBlue) // Keep original button color
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
                    
                    if task.status == "inProgress" && task.creatorID != Auth.auth().currentUser?.uid{
                        Button("Mark Completed") {
                            showingCompleteAlert = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGreen) // Use forest green
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 8)
                    }
                    
                }
                .padding()
                
                if task.status == "completed" {
                    ratingButton
                }
                
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
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
                            print("Send Message")
                        },
                        .default(Text("Call")) {
                            // Implement call logic
                            print("Call")
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
                .foregroundColor(AppColors.secondaryGray) // Keep original color
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available": return AppColors.primaryBlue // Keep original. Consider if it fits.
        case "inProgress": return AppColors.primaryYellow // Keep original. Consider if it fits.
        case "completed": return AppColors.primaryGreen // Use forest green
        default: return .gray // Keep original
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
        print("completeTask")
        //viewModel.completeTask(taskID: task.id)  // Removed:  viewModel is not in scope.
        dismiss()
    }
    var ratingButton: some View {
        Button(action: {
            showRatingSheet = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Rate Assignees")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.primaryYellow) // Keep original. Consider if it fits.
            .foregroundColor(.black)    //Make text black
            .cornerRadius(10)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showRatingSheet) {
            TaskCompletionView(task: task)
        }
    }
}

