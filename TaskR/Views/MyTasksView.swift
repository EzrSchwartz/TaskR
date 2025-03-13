import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyTasksView: View {
    @StateObject var viewModel = TaskViewModel()
    @State private var selectedTask: Task? = nil
    
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
            .sheet(item: $selectedTask) { task in
                RequestersView(task: task)
            }
            .onAppear {
                viewModel.fetchMyTasks()
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
                Text("Due: \(task.dueDate, style: .date)")
                Spacer()
                Text("\(task.assignees.count) requests")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            Button("View Requests") {
                selectedTask = task
            }
            .buttonStyle(.bordered)
            .disabled(task.assignees.isEmpty)
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

struct RequestersView: View {
    let task: Task
    @State private var requesters: [UserProfile] = []
    
    var body: some View {
        NavigationView {
            Group {
                if requesters.isEmpty {
                    Text("No pending requests")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(requesters) { user in
                        UserProfileView(user: user, task: task)
                    }
                }
            }
            .navigationTitle("Task Requests")
            .onAppear {
                fetchRequesters()
            }
        }
    }
    
    private func fetchRequesters() {
        let group = DispatchGroup()
        var profiles = [UserProfile]()
        
        for assignee in task.assignees {
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
        }
    }
}

struct UserProfileView: View {
    let user: UserProfile
    let task: Task
    @State private var showingActionSheet = false
    
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
            
            WrapView(items: user.interests, spacing: 8) { interest in
                Text(interest)
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if !isApproved {
                HStack {
                    Button("Approve") {
                        approveRequest()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Reject") {
                        rejectRequest()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .padding()
        .contextMenu {
            if !isApproved {
                Button("Approve Request") {
                    approveRequest()
                }
                
                Button("Reject Request") {
                    rejectRequest()
                }
            }
        }
    }
    
    private var isApproved: Bool {
        task.assignees.first { $0.userID == user.id }?.approved ?? false
    }
    
    private func approveRequest() {
        TaskService.shared.approveClaimRequest(taskID: task.id, assigneeID: user.id) { _ in }
    }
    
    private func rejectRequest() {
        TaskService.shared.rejectClaimRequest(taskID: task.id, assigneeID: user.id) { _ in }
    }
}

// MARK: - Helper Views
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

// MARK: - User Profile Model
struct UserProfile: Identifiable {
    let id: String
    let username: String
    let bio: String
    let interests: [String]
}

// MARK: - User Service
class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    func fetchUserProfile(userID: String, completion: @escaping (UserProfile?) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            let profile = UserProfile(
                id: userID,
                username: data["username"] as? String ?? "Anonymous",
                bio: data["bio"] as? String ?? "",
                interests: data["interests"] as? [String] ?? []
            )
            
            completion(profile)
        }
    }
}
