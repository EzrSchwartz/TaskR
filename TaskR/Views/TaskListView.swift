//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//// Use the extension from PendingTaskRequestsView
//// If you place this in a separate file, you can remove this declaration
//// extension Notification.Name {
////     static let taskApproved = Notification.Name("TaskApproved")
//// }
//
//struct TaskListView: View {
//    @StateObject var viewModel = TaskViewModel()
//    @State private var selectedTask: Task?
//    @State private var navigateToChat = false
//    @State private var selectedCategory: String?
//    @State private var showingAlert = false
//    @State private var alertTitle = ""
//    @State private var alertMessage = ""
//    @State private var selectedTaskForClaim: Task?
//    @State private var showClaimedAlert = false
//    
//    // Sample categories - replace with your actual categories
//    let categories = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports", "Other"]
//    
//    var filteredTasks: [Task] {
//        if let category = selectedCategory {
//            return viewModel.tasks.filter { $0.category == category }
//        } else {
//            return viewModel.tasks
//        }
//    }
//    
//    var featuredTask: Task? {
//        // Get the most recent task that matches user interests
//        let userInterests = viewModel.getCurrentUserInterests()
//        
//        let matchingTasks = viewModel.tasks.filter { task in
//            userInterests.contains(task.category)
//        }
//        
//        return matchingTasks.sorted(by: { $0.dueDate > $1.dueDate }).first ??
//               viewModel.tasks.sorted(by: { $0.dueDate > $1.dueDate }).first
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Category selector
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 10) {
//                        Button(action: {
//                            selectedCategory = nil
//                        }) {
//                            Text("All")
//                                .fontWeight(selectedCategory == nil ? .bold : .regular)
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 8)
//                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
//                                .foregroundColor(selectedCategory == nil ? .white : .primary)
//                                .cornerRadius(20)
//                        }
//                        
//                        ForEach(categories, id: \.self) { category in
//                            Button(action: {
//                                selectedCategory = category
//                            }) {
//                                Text(category)
//                                    .fontWeight(selectedCategory == category ? .bold : .regular)
//                                    .padding(.horizontal, 16)
//                                    .padding(.vertical, 8)
//                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
//                                    .foregroundColor(selectedCategory == category ? .white : .primary)
//                                    .cornerRadius(20)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical, 8)
//                }
//                
//                if viewModel.isLoading {
//                    ProgressView("Loading tasks...")
//                        .padding()
//                } else {
//                    if filteredTasks.isEmpty {
//                        VStack {
//                            Image(systemName: "tray")
//                                .font(.system(size: 60))
//                                .foregroundColor(.gray)
//                                .padding()
//                            
//                            Text("No tasks found")
//                                .font(.headline)
//                                .foregroundColor(.gray)
//                                .padding()
//                            
//                            Button("Check Your Claimed Tasks") {
//                                showClaimedAlert = true
//                            }
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                        }
//                        .padding()
//                    } else {
//                        List {
//                            // Featured task section (only shown when viewing all tasks)
//                            if selectedCategory == nil, let task = featuredTask {
//                                Section(header: Text("Recommended For You")) {
//                                    taskCell(task, isFeatured: true)
//                                }
//                            }
//                            
//                            // All tasks or filtered by category
//                            Section(header: Text(selectedCategory ?? "Available Tasks")) {
//                                ForEach(filteredTasks) { task in
//                                    // Skip the featured task if it's already shown
//                                    if selectedCategory != nil || task.id != featuredTask?.id {
//                                        taskCell(task, isFeatured: false)
//                                    }
//                                }
//                            }
//                        }
//                        .listStyle(InsetGroupedListStyle())
//                    }
//                }
//            }
//            .navigationTitle("Tasks")
//            .onAppear {
//                refreshTasks()
//            }
//            .background(
//                NavigationLink(
//                    destination: TaskChatView(
//                        taskID: selectedTask?.id ?? "",
//                        taskTitle: selectedTask?.title ?? "Task Chat"
//                    ),
//                    isActive: $navigateToChat
//                ) {
//                    EmptyView()
//                }
//            )
//            .alert(isPresented: $showingAlert) {
//                Alert(
//                    title: Text(alertTitle),
//                    message: Text(alertMessage),
//                    dismissButton: .default(Text("OK"))
//                )
//            }
//            .alert("Check Your Claimed Tasks", isPresented: $showClaimedAlert) {
//                Button("View Claimed Tasks", role: .none) {
//                    // Navigate to claimed tasks - this depends on your app structure
//                }
//                Button("Cancel", role: .cancel) {}
//            } message: {
//                Text("You may not see some tasks here if you've already claimed them. Check your claimed tasks to see all tasks you're working on.")
//            }
//            .refreshable {
//                refreshTasks()
//            }
//            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.taskApproved)) { _ in
//                print("⚡️ TaskListView: Received task approved notification")
//                refreshTasks()
//            }
//        }
//    }
//    
//    private func taskCell(_ task: Task, isFeatured: Bool) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(task.title)
//                .font(.headline)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            HStack {
//                Text("Created by: \(viewModel.usernames[task.creatorID] ?? "Loading...")")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                Spacer()
//                Text("Pay (\(task.payType)): $\(task.pay)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            
//            HStack(spacing: 4) {
//                Image(systemName: "person.3.fill")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                Text("\(task.people)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                Spacer()
//                Text("Category: \(task.category)")
//                    .font(.subheadline)
//                    .foregroundColor(isFeatured ? .blue : .gray)
//                    .padding(4)
//                    .background(isFeatured ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
//                    .cornerRadius(4)
//            }
//            
//            HStack {
//                Text("Expertise: \(task.expertise)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                Spacer()
//                Text("Town: \(task.town)")
//                    .font(.footnote)
//                    .foregroundColor(.gray)
//            }
//            
//            let dateFormatter: DateFormatter = {
//                let formatter = DateFormatter()
//                formatter.dateStyle = .medium
//                formatter.timeStyle = .short
//                formatter.timeZone = .current
//                return formatter
//            }()
//            
//            Text("Time: \(dateFormatter.string(from: task.dueDate))")
//                .font(.footnote)
//                .foregroundColor(.gray)
//            
//            Text(task.description)
//                .font(.subheadline)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.vertical, 4)
//            
//            // Check if current user already requested this task
//            if isUserRequestedTask(task) {
//                if isUserApprovedForTask(task) {
//                    HStack {
//                        Image(systemName: "checkmark.circle.fill")
//                            .foregroundColor(.green)
//                        Text("You've been approved for this task!")
//                            .foregroundColor(.green)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.vertical, 5)
//                } else {
//                    HStack {
//                        Image(systemName: "clock.fill")
//                            .foregroundColor(.orange)
//                        Text("Request pending approval")
//                            .foregroundColor(.orange)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.vertical, 5)
//                }
//            } else {
//                Button("Request To Claim Task") {
//                    requestToClaimTask(task)
//                }
//                .padding(.vertical, 5)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .buttonStyle(.borderedProminent)
//                .disabled(!canRequestTask(task))
//            }
//        }
//        .padding(.vertical, 8)
//    }
//    
//    private func refreshTasks() {
//        print("🔄 TaskListView: Refreshing tasks")
//        viewModel.isLoading = true
//        viewModel.fetchTasks()
//        viewModel.fetchClaimedTasks()
//        viewModel.fetchUserInterests()
//        
//        // Delay to allow firestore to update
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            viewModel.isLoading = false
//        }
//    }
//    
//    // Check if current user has already requested this task
//    private func isUserRequestedTask(_ task: Task) -> Bool {
//        guard let userID = Auth.auth().currentUser?.uid else { return false }
//        return task.assignees.contains { $0.userID == userID }
//    }
//    
//    // Check if current user is approved for this task
//    private func isUserApprovedForTask(_ task: Task) -> Bool {
//        guard let userID = Auth.auth().currentUser?.uid else { return false }
//        return task.assignees.contains { $0.userID == userID && $0.approved }
//    }
//    
//    // Check if user can request this task
//    private func canRequestTask(_ task: Task) -> Bool {
//        guard let userID = Auth.auth().currentUser?.uid else { return false }
//        
//        // Can't claim own task
//        if task.creatorID == userID {
//            return false
//        }
//        
//        // Can't claim if already requested
//        if isUserRequestedTask(task) {
//            return false
//        }
//        
//        // Can't claim if already full
//        let approvedCount = task.assignees.filter { $0.approved }.count
//        if approvedCount >= task.people {
//            return false
//        }
//        
//        return true
//    }
//    
//    private func requestToClaimTask(_ task: Task) {
//        selectedTaskForClaim = task
//        
//        // First check if this is the user's own task
//        guard let userID = Auth.auth().currentUser?.uid else { return }
//        guard task.creatorID != userID else {
//            alertTitle = "Cannot Claim"
//            alertMessage = "You cannot claim your own task."
//            showingAlert = true
//            return
//        }
//        
//        // Check if user has already requested this task
//        if task.assignees.contains(where: { $0.userID == userID }) {
//            alertTitle = "Already Requested"
//            alertMessage = "You have already requested to claim this task."
//            showingAlert = true
//            return
//        }
//        
//        // Check if the task is already full
//        let approvedCount = task.assignees.filter { $0.approved }.count
//        if approvedCount >= task.people {
//            alertTitle = "Task Full"
//            alertMessage = "This task already has the maximum number of people."
//            showingAlert = true
//            return
//        }
//        
//        // Proceed with claim request
//        AuthService.shared.fetchUsername(userID: userID) { result in
//            switch result {
//            case .success(let username):
//                TaskService.shared.requestToClaimTask(taskID: task.id, userID: userID, username: username) { result in
//                    DispatchQueue.main.async {
//                        switch result {
//                        case .success:
//                            self.alertTitle = "Request Sent"
//                            self.alertMessage = "Your request to claim this task has been sent! The task creator will review your profile and approve or reject your request."
//                            self.showingAlert = true
//                            // Refresh available tasks
//                            self.refreshTasks()
//                            
//                        case .failure(let error):
//                            self.alertTitle = "Error"
//                            self.alertMessage = "Failed to request task: \(error.localizedDescription)"
//                            self.showingAlert = true
//                        }
//                    }
//                }
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self.alertTitle = "Error"
//                    self.alertMessage = "Failed to fetch username: \(error.localizedDescription)"
//                    self.showingAlert = true
//                }
//            }
//        }
//    }
//}


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TaskListView: View {
    @StateObject var viewModel = TaskViewModel()
    @State private var selectedTask: Task?
    @State private var navigateToChat = false
    @State private var selectedCategory: String?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedTaskForClaim: Task?
    @State private var showClaimedAlert = false
    @State private var creatorRatings: [String: (Double, Int)] = [:] // Store creator ratings (rating, count)
    
    // Sample categories - replace with your actual categories
    let categories = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports", "Other"]
    
    var filteredTasks: [Task] {
        if let category = selectedCategory {
            return viewModel.tasks.filter { $0.category == category }
        } else {
            return viewModel.tasks
        }
    }
    
    var featuredTask: Task? {
        // Get the most recent task that matches user interests
        let userInterests = viewModel.getCurrentUserInterests()
        
        let matchingTasks = viewModel.tasks.filter { task in
            userInterests.contains(task.category)
        }
        
        return matchingTasks.sorted(by: { $0.dueDate > $1.dueDate }).first ??
               viewModel.tasks.sorted(by: { $0.dueDate > $1.dueDate }).first
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("All")
                                .fontWeight(selectedCategory == nil ? .bold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .fontWeight(selectedCategory == category ? .bold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                if viewModel.isLoading {
                    ProgressView("Loading tasks...")
                        .padding()
                } else {
                    if filteredTasks.isEmpty {
                        VStack {
                            Image(systemName: "tray")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No tasks found")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding()
                            
                            Button("Check Your Claimed Tasks") {
                                showClaimedAlert = true
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        List {
                            // Featured task section (only shown when viewing all tasks)
                            if selectedCategory == nil, let task = featuredTask {
                                Section(header: Text("Recommended For You")) {
                                    taskCell(task, isFeatured: true)
                                }
                            }
                            
                            // All tasks or filtered by category
                            Section(header: Text(selectedCategory ?? "Available Tasks")) {
                                ForEach(filteredTasks) { task in
                                    // Skip the featured task if it's already shown
                                    if selectedCategory != nil || task.id != featuredTask?.id {
                                        taskCell(task, isFeatured: false)
                                    }
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("Tasks")
            .onAppear {
                refreshTasks()
            }
            .background(
                NavigationLink(
                    destination: TaskChatView(
                        taskID: selectedTask?.id ?? "",
                        taskTitle: selectedTask?.title ?? "Task Chat"
                    ),
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Check Your Claimed Tasks", isPresented: $showClaimedAlert) {
                Button("View Claimed Tasks", role: .none) {
                    // Navigate to claimed tasks - this depends on your app structure
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You may not see some tasks here if you've already claimed them. Check your claimed tasks to see all tasks you're working on.")
            }
            .refreshable {
                refreshTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.taskApproved)) { _ in
                print("⚡️ TaskListView: Received task approved notification")
                refreshTasks()
            }
        }
    }
    
    private func taskCell(_ task: Task, isFeatured: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row with creator info and rating
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text("Created by: \(viewModel.usernames[task.creatorID] ?? "Loading...")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // Show the creator's rating
                        CreatorRatingBadge(creatorID: task.creatorID)
                    }
                }
                
                Spacer()
                
                // Payment information
                Text("$\(task.pay)")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            // Task details rows
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(task.people)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(task.category)
                    .font(.subheadline)
                    .foregroundColor(isFeatured ? .blue : .gray)
                    .padding(4)
                    .background(isFeatured ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            HStack {
                Text(task.expertise.isEmpty ? "No expertise required" : "Expertise: \(task.expertise)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(task.town)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.timeZone = .current
                return formatter
            }()
            
            Text("Due: \(dateFormatter.string(from: task.dueDate))")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text(task.description)
                .font(.subheadline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            
            // Task action buttons
            if isUserRequestedTask(task) {
                if isUserApprovedForTask(task) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You've been approved for this task!")
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
                } else {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Request pending approval")
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
                }
            } else {
                Button("Request To Claim Task") {
                    requestToClaimTask(task)
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .buttonStyle(.borderedProminent)
                .disabled(!canRequestTask(task))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func refreshTasks() {
        print("🔄 TaskListView: Refreshing tasks")
        viewModel.isLoading = true
        viewModel.fetchTasks()
        viewModel.fetchClaimedTasks()
        viewModel.fetchUserInterests()
        
        // Fetch ratings for all task creators
        fetchCreatorRatings()
        
        // Delay to allow firestore to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            viewModel.isLoading = false
        }
    }
    
    // Fetch ratings for all task creators
    private func fetchCreatorRatings() {
        // Get unique creator IDs
        let creatorIDs = Set(viewModel.tasks.map { $0.creatorID })
        
        for creatorID in creatorIDs {
            TaskService.shared.getUserRating(userID: creatorID) { result in
                switch result {
                case .success(let ratingData):
                    DispatchQueue.main.async {
                        self.creatorRatings[creatorID] = ratingData
                    }
                case .failure(let error):
                    print("⚠️ Error fetching rating for creator \(creatorID): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper functions
    
    // Check if current user has already requested this task
    private func isUserRequestedTask(_ task: Task) -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        return task.assignees.contains { $0.userID == userID }
    }
    
    // Check if current user is approved for this task
    private func isUserApprovedForTask(_ task: Task) -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        return task.assignees.contains { $0.userID == userID && $0.approved }
    }
    
    // Check if user can request this task
    private func canRequestTask(_ task: Task) -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        
        // Can't claim own task
        if task.creatorID == userID {
            return false
        }
        
        // Can't claim if already requested
        if isUserRequestedTask(task) {
            return false
        }
        
        // Can't claim if already full
        let approvedCount = task.assignees.filter { $0.approved }.count
        if approvedCount >= task.people {
            return false
        }
        
        return true
    }
    
    private func requestToClaimTask(_ task: Task) {
        selectedTaskForClaim = task
        
        // First check if this is the user's own task
        guard let userID = Auth.auth().currentUser?.uid else { return }
        guard task.creatorID != userID else {
            alertTitle = "Cannot Claim"
            alertMessage = "You cannot claim your own task."
            showingAlert = true
            return
        }
        
        // Check if user has already requested this task
        if task.assignees.contains(where: { $0.userID == userID }) {
            alertTitle = "Already Requested"
            alertMessage = "You have already requested to claim this task."
            showingAlert = true
            return
        }
        
        // Check if the task is already full
        let approvedCount = task.assignees.filter { $0.approved }.count
        if approvedCount >= task.people {
            alertTitle = "Task Full"
            alertMessage = "This task already has the maximum number of people."
            showingAlert = true
            return
        }
        
        // Proceed with claim request
        AuthService.shared.fetchUsername(userID: userID) { result in
            switch result {
            case .success(let username):
                TaskService.shared.requestToClaimTask(taskID: task.id, userID: userID, username: username) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self.alertTitle = "Request Sent"
                            self.alertMessage = "Your request to claim this task has been sent! The task creator will review your profile and approve or reject your request."
                            self.showingAlert = true
                            // Refresh available tasks
                            self.refreshTasks()
                            
                        case .failure(let error):
                            self.alertTitle = "Error"
                            self.alertMessage = "Failed to request task: \(error.localizedDescription)"
                            self.showingAlert = true
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to fetch username: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
}

// Compact rating badge component specifically for creator ratings
struct CreatorRatingBadge: View {
    let creatorID: String
    
    @State private var rating: Double = 0.0
    @State private var totalRatings: Int = 0
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Show minimal loading indicator
                Text("★...")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if totalRatings > 0 {
                // Show compact rating
                HStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                // No ratings yet
                Text("New")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            fetchRating()
        }
    }
    
    private func fetchRating() {
        isLoading = true
        
        TaskService.shared.getUserRating(userID: creatorID) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let ratingData):
                    self.rating = ratingData.0
                    self.totalRatings = ratingData.1
                case .failure(let error):
                    print("❌ Error loading creator rating: \(error.localizedDescription)")
                    self.rating = 0
                    self.totalRatings = 0
                }
            }
        }
    }
}
