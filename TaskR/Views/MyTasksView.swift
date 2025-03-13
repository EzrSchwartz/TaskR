//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//struct MyTasksView: View {
//    @StateObject var viewModel = TaskViewModel()
//    @State private var selectedTask: Task? = nil
//    
//    var body: some View {
//        NavigationView {
//            Group {
//                if viewModel.myTasks.isEmpty {
//                    Text("You haven't created any tasks yet")
//                        .font(.headline)
//                        .foregroundColor(.gray)
//                        .padding()
//                } else {
//                    List(viewModel.myTasks, id: \.id) { task in
//                        taskCell(task)
//                            .swipeActions {
//                                Button(role: .destructive) {
//                                    deleteTask(task)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
//                    }
//                }
//            }
//            .navigationTitle("My Tasks")
//            .sheet(item: $selectedTask) { task in
//                RequestersView(task: task)
//            }
//            .onAppear {
//                viewModel.fetchMyTasks()
//            }
//        }
//    }
//    
//    private func taskCell(_ task: Task) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text(task.title)
//                    .font(.headline)
//                
//                Spacer()
//                
//                Text(task.status.capitalized)
//                    .font(.caption)
//                    .foregroundColor(statusColor(task.status))
//                    .padding(4)
//                    .background(statusColor(task.status).opacity(0.2))
//                    .cornerRadius(4)
//            }
//            
//            Text(task.description)
//                .font(.subheadline)
//                .lineLimit(2)
//            HStack{
//                Text("\(task.assignees.count)) / \(task.people)")
//                    
//                
//            }
//            HStack {
//                Text("Due: \(task.dueDate, style: .date)")
//                Spacer()
//                Text("\(task.assignees.count) requests")
//            }
//            .font(.caption)
//            .foregroundColor(.gray)
//            
//            Button("View Requests") {
//                selectedTask = task
//            }
//            .buttonStyle(.bordered)
//            .disabled(task.assignees.isEmpty)
//        }
//        .padding(.vertical, 8)
//    }
//    
//    private func statusColor(_ status: String) -> Color {
//        switch status {
//        case "available": return .blue
//        case "inProgress": return .orange
//        case "completed": return .green
//        default: return .gray
//        }
//    }
//    
//    private func deleteTask(_ task: Task) {
//        TaskService.shared.deleteTask(taskID: task.id) { result in
//            switch result {
//            case .success:
//                viewModel.fetchMyTasks()
//            case .failure(let error):
//                print("Delete error: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//struct RequestersView: View {
//    let task: Task
//    @State private var requesters: [UserProfile] = []
//    
//    var body: some View {
//        NavigationView {
//            Group {
//                if requesters.isEmpty {
//                    Text("No pending requests")
//                        .font(.headline)
//                        .foregroundColor(.gray)
//                        .padding()
//                } else {
//                    List(requesters) { user in
//                        RequesterProfileView(user: user, task: task)
//                    }
//                }
//            }
//            .navigationTitle("Task Requests")
//            .onAppear {
//                fetchRequesters()
//            }
//        }
//    }
//    
//    private func fetchRequesters() {
//        let group = DispatchGroup()
//        var profiles = [UserProfile]()
//        
//        for assignee in task.assignees {
//            group.enter()
//            UserService.shared.fetchUserProfile(userID: assignee.userID) { profile in
//                if let profile = profile {
//                    profiles.append(profile)
//                }
//                group.leave()
//            }
//        }
//        
//        group.notify(queue: .main) {
//            requesters = profiles
//        }
//    }
//}
//
//struct RequesterProfileView: View {
//    let user: UserProfile
//    let task: Task
//    @State private var showingActionSheet = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Text(user.username)
//                    .font(.title3.bold())
//                
//                Spacer()
//                
//                if isApproved {
//                    Image(systemName: "checkmark.seal.fill")
//                        .foregroundColor(.green)
//                }
//            }
//            
//            Text(user.bio)
//                .font(.body)
//                .foregroundColor(.secondary)
//            
//            WrapView(items: user.interests, spacing: 8) { interest in
//                Text(interest)
//                    .font(.caption)
//                    .padding(6)
//                    .background(Color.blue.opacity(0.1))
//                    .cornerRadius(6)
//            }
//            
//            if !isApproved {
//                HStack {
//                    Button("Approve") {
//                        approveRequest()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.green)
//                    
//                    Button("Reject") {
//                        rejectRequest()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.red)
//                }
//            }
//        }
//        .padding()
//        .contextMenu {
//            if !isApproved {
//                Button("Approve Request") {
//                    approveRequest()
//                }
//                
//                Button("Reject Request") {
//                    rejectRequest()
//                }
//            }
//        }
//    }
//    
//    private var isApproved: Bool {
//        task.assignees.first { $0.userID == user.id }?.approved ?? false
//    }
//    
//    private func approveRequest() {
//        TaskService.shared.approveClaimRequest(taskID: task.id, assigneeID: user.id) { _ in }
//    }
//    
//    private func rejectRequest() {
//        TaskService.shared.rejectClaimRequest(taskID: task.id, assigneeID: user.id) { _ in }
//    }
//}
//
//// MARK: - Helper Views
//// This can stay here as it's only used in this view
//struct WrapView<Content: View, T: Hashable>: View {
//    let items: [T]
//    let spacing: CGFloat
//    let content: (T) -> Content
//    
//    var body: some View {
//        GeometryReader { geometry in
//            self.generateContent(in: geometry)
//        }
//    }
//    
//    private func generateContent(in geometry: GeometryProxy) -> some View {
//        var width = CGFloat.zero
//        var height = CGFloat.zero
//        
//        return ZStack(alignment: .topLeading) {
//            ForEach(items, id: \.self) { item in
//                content(item)
//                    .padding(.all, 4)
//                    .alignmentGuide(.leading) { d in
//                        if (abs(width - d.width) > geometry.size.width) {
//                            width = 0
//                            height -= d.height
//                        }
//                        let result = width
//                        if item == self.items.last! {
//                            width = 0
//                        } else {
//                            width -= d.width + self.spacing
//                        }
//                        return result
//                    }
//                    .alignmentGuide(.top) { d in
//                        let result = height
//                        if item == self.items.last! {
//                            height = 0
//                        }
//                        return result
//                    }
//            }
//        }
//    }
//}



import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyTasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedTask: Task? = nil
    @State private var showRequesters = false
    @State private var showTaskDetails = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.myTasks.isEmpty {
                    Text("You haven't created any tasks yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.myTasks, id: \.id) { task in
                        taskCell(task)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTask = task
                                showTaskDetails = true
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("My Tasks")
            .sheet(isPresented: $showRequesters) {
                if let task = selectedTask {
                    RequestersView(task: task)
                }
            }
            .sheet(isPresented: $showTaskDetails) {
                if let task = selectedTask {
                    CreatorTaskDetailsView(task: task, onClosed: {
                        viewModel.fetchMyTasks()
                    })
                }
            }
            .onAppear {
                viewModel.fetchMyTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .showRequests)) { notification in
                if let taskID = notification.userInfo?["taskID"] as? String,
                   let task = viewModel.myTasks.first(where: { $0.id == taskID }) {
                    selectedTask = task
                    showRequesters = true
                }
            }
        }
    }
    private func taskCell(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                
                Spacer()
                
                Text(task.status.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor(task.status))
                    .padding(4)
                    .background(statusColor(task.status).opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(task.description)
                .font(.subheadline)
                .lineLimit(2)
                
            HStack {
                Text("Assignees: \(task.assignees.filter { $0.approved }.count)/\(task.people)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Due: \(formattedDate(task.dueDate))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if task.assignees.filter({ !$0.approved }).count > 0 {
                Button("View Requests (\(task.assignees.filter { !$0.approved }.count))") {
                    selectedTask = task
                    showRequesters = true
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available": return .blue
        case "inProgress": return .orange
        case "completed": return .green
        default: return .gray
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deleteTask(_ task: Task) {
        TaskService.shared.deleteTask(taskID: task.id) { result in
            switch result {
            case .success:
                viewModel.fetchMyTasks()
            case .failure(let error):
                print("Delete error: \(error.localizedDescription)")
            }
        }
    }
}

// Original RequestersView and RequesterProfileView remain unchanged

// Original RequestersView (kept from the original implementation)
struct RequestersView: View {
    let task: Task
    @State private var requesters: [UserProfile] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading requests...")
                } else if requesters.isEmpty {
                    VStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No pending requests")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("All requests have been handled")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                } else {
                    List(requesters) { user in
                        RequesterProfileView(user: user, task: task)
                    }
                }
            }
            .navigationTitle("Task Requests")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                fetchRequesters()
            }
            .onReceive(NotificationCenter.default.publisher(for: .taskApproved)) { _ in
                // Refresh data when notification received
                fetchRequesters()
            }
        }
    }
    
    private func fetchRequesters() {
        isLoading = true
        
        let group = DispatchGroup()
        var profiles: [UserProfile] = []
        
        // Only fetch non-approved assignees
        let pendingAssignees = task.assignees.filter { !$0.approved }
        
        if pendingAssignees.isEmpty {
            isLoading = false
            requesters = []
            return
        }
        
        for assignee in pendingAssignees {
            group.enter()
            UserService.shared.fetchUserProfile(userID: assignee.userID) { profile in
                if let profile = profile {
                    profiles.append(profile)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            requesters = profiles
            isLoading = false
        }
    }
}

// Original RequesterProfileView (kept from the original implementation)
struct RequesterProfileView: View {
    let user: UserProfile
    let task: Task
    @State private var showingActionSheet = false
    @State private var isProcessing = false
    @State private var isApproved = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(user.username)
                    .font(.title3.bold())
                
                Spacer()
                
                if isApproved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text(user.bio)
                .font(.body)
                .foregroundColor(.secondary)
            
            // For the WrapView in RequesterProfileView
            WrapView(items: user.selectedInterests, spacing: 8) { interest in
                Text(interest)
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .frame(minHeight: 70)  // Min height instead of fixed height
            .fixedSize(horizontal: false, vertical: true)  // Allow vertical growth
            
            if !isApproved {
                HStack {
                    Button {
                        approveRequest()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Approve")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isProcessing)
                    
                    Button {
                        rejectRequest()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Reject")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isProcessing)
                }
            }
        }
        .padding()
        .onAppear {
            // Initialize the approval state correctly on appear
            isApproved = task.assignees.first { $0.userID == user.id }?.approved ?? false
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") {
                if isApproved {
                    // If approved, dismiss after showing message
                    dismiss()
                }
            }
        }
    }
    
    private func approveRequest() {
        isProcessing = true
        
        TaskService.shared.approveClaimRequest(taskID: task.id, assigneeID: user.id) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success:
                    isApproved = true
                    alertMessage = "Request approved successfully!"
                    showAlert = true
                    // Notify to refresh data
                    NotificationCenter.default.post(name: .taskApproved, object: nil)
                    
                case .failure(let error):
                    alertMessage = "Error approving request: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func rejectRequest() {
        isProcessing = true
        
        TaskService.shared.rejectClaimRequest(taskID: task.id, assigneeID: user.id) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success:
                    alertMessage = "Request rejected successfully."
                    showAlert = true
                    // Notify to refresh data
                    NotificationCenter.default.post(name: .taskApproved, object: nil)
                    
                case .failure(let error):
                    alertMessage = "Error rejecting request: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// New Task Details View for Task Creator

// Update CreatorTaskDetailsView in MyTasksView.swift

struct CreatorTaskDetailsView: View {
    let task: Task
    let onClosed: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingCompleteAlert = false
    @State private var showChatView = false
    @State private var showingAssigneesList = false
    @State private var showingRatingView = false
    
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
                        
                        HStack {
                            Text("Assignees")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(task.assignees.filter { $0.approved }.count)/\(task.people)")
                                .font(.subheadline)
                            
                            if !task.assignees.filter({ $0.approved }).isEmpty {
                                Button("View") {
                                    showingAssigneesList = true
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
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
                    if task.status == "inProgress" {
                        Button(action: {
                            showingCompleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Completed")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 16)
                        }
                    }
                    
                    // Chat button - only available if there are approved assignees
                    if !task.assignees.filter({ $0.approved }).isEmpty {
                        Button(action: {
                            showChatView = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Chat with Assignees")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 8)
                        }
                    }
                    
                    // View requests button
                    if !task.assignees.filter({ !$0.approved }).isEmpty {
                        Button(action: {
                            dismiss()
                            // A delay to ensure the current sheet is dismissed before showing the requests view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(name: .showRequests, object: nil, userInfo: ["taskID": task.id])
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.2.badge.gearshape")
                                Text("View Requests (\(task.assignees.filter { !$0.approved }.count))")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 8)
                        }
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
                Button("Continue", role: .none) {
                    // Instead of immediately completing the task, show the rating view
                    showingRatingView = true
                }
            } message: {
                Text("Before completing, you'll be asked to rate each assignee's performance.")
            }
            .fullScreenCover(isPresented: $showChatView) {
                NavigationView {
                    // Use the TaskChatView defined in your project
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
            .sheet(isPresented: $showingAssigneesList) {
                AssigneesListView(task: task)
            }
            .sheet(isPresented: $showingRatingView) {
                AssigneeRatingView(
                    task: task,
                    onComplete: {
                        // Task is already marked as completed in the AssigneeRatingView
                        showingRatingView = false
                        dismiss() // Dismiss the task details view
                        onClosed() // Call the callback to refresh the tasks list
                    },
                    onCancel: {
                        showingRatingView = false
                    }
                )
            }
        }
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
}
// Assignees List View
struct AssigneesListView: View {
    let task: Task
    @Environment(\.dismiss) var dismiss
    @State private var assigneeProfiles: [UserProfile] = []
    
    var body: some View {
        NavigationView {
            Group {
                if assigneeProfiles.isEmpty {
                    ProgressView("Loading assignees...")
                } else {
                    List(assigneeProfiles) { profile in
                        HStack {
                            Text(profile.username)
                                .font(.headline)
                            
                            Spacer()
                            
                            if let age = profile.age {
                                Text("Age: \(age)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assignees")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                loadAssigneeProfiles()
            }
        }
    }
    
    private func loadAssigneeProfiles() {
        let approvedAssignees = task.assignees.filter { $0.approved }
        let group = DispatchGroup()
        var profiles: [UserProfile] = []
        
        for assignee in approvedAssignees {
            group.enter()
            UserService.shared.fetchUserProfile(userID: assignee.userID) { profile in
                if let profile = profile {
                    profiles.append(profile)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.assigneeProfiles = profiles
        }
    }
}

// MARK: - Helper Views
// WrapView for displaying interests (kept from the original implementation)

struct WrapView<Content: View, T: Hashable>: View {
    let items: [T]
    let spacing: CGFloat
    let content: (T) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.all, 4)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.items.last! {
                            width = 0
                        } else {
                            width -= d.width + self.spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == self.items.last! {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}


// Add this notification name extension
extension Notification.Name {
    static let showRequests = Notification.Name("showRequests")
}
