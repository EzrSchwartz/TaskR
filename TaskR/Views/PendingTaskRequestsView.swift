import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PendingTaskRequestsView: View {
    @StateObject var viewModel = PendingRequestsViewModel()
    @State private var selectedRequest: PendingRequest?
    @State private var showingProfile = false
    @State private var requestActionInProgress = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading requests...")
                        .onAppear {
                            // Set a timeout to prevent infinite loading
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isLoading = false
                            }
                        }
                } else if viewModel.pendingRequests.isEmpty {
                    VStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No pending requests")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("When kids request to help with your tasks, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                            
                        Button("Refresh Requests") {
                            isLoading = true
                            viewModel.fetchPendingRequests()
                            // Set a timeout for the loading state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isLoading = false
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.pendingRequests) { request in
                            Button(action: {
                                selectedRequest = request
                                showingProfile = true
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(request.taskTitle)
                                            .font(.headline)
                                        Spacer()
                                        Label("\(request.daysAgo) days ago", systemImage: "clock")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                        Text(request.requesterUsername)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("Tap to view profile")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Pending Requests")
            .onAppear {
                // Reset loading state and fetch requests
                isLoading = true
                viewModel.fetchPendingRequests()
                
                // Set a timeout to prevent infinite loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
            .refreshable {
                isLoading = true
                viewModel.fetchPendingRequests()
                
                // Set a timeout to prevent infinite loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }
            .sheet(isPresented: $showingProfile) {
                            if let request = selectedRequest {
                                // Use the enhanced UserProfileView with approval buttons
                                NavigationView {
                                    VStack {
                                        // Embed the UserProfileView
                                        KidUserProfileView(userID: request.requesterID, isEditable: false)
                                        
                                        // Add approval buttons at the bottom
                                        VStack(spacing: 16) {
                                            Button(action: { approveRequest(request) }) {
                                                HStack {
                                                    if requestActionInProgress {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                            .padding(.trailing, 8)
                                                    } else {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .padding(.trailing, 8)
                                                    }
                                                    Text("Approve Request")
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                                .font(.headline)
                                            }
                                            .disabled(requestActionInProgress)
                                            
                                            Button(action: { rejectRequest(request) }) {
                                                HStack {
                                                    if requestActionInProgress {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                            .padding(.trailing, 8)
                                                    } else {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .padding(.trailing, 8)
                                                    }
                                                    Text("Reject Request")
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.red)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                                .font(.headline)
                                            }
                                            .disabled(requestActionInProgress)
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 32)
                                    }
                                    .navigationTitle("Request from \(request.requesterUsername)")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .navigationBarItems(trailing: Button("Close") {
                                        showingProfile = false
                                    })
                                }
                                .interactiveDismissDisabled(requestActionInProgress)
                            }
                        }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func approveRequest(_ request: PendingRequest) {
        requestActionInProgress = true
        
        TaskService.shared.approveClaimRequest(taskID: request.taskID, assigneeID: request.requesterID) { result in
            DispatchQueue.main.async {
                requestActionInProgress = false
                
                switch result {
                case .success:
                    // Notify both adults and kids about this change by updating the shared data
                    // This is critical for ensuring changes are reflected on the kid's side
                    NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": request.taskID])
                    
                    alertMessage = "Request approved successfully! The kid has been assigned to the task."
                    showAlert = true
                    showingProfile = false
                    isLoading = true
                    viewModel.fetchPendingRequests()
                    
                    // Set a timeout to prevent infinite loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                    
                case .failure(let error):
                    alertMessage = "Error approving request: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func rejectRequest(_ request: PendingRequest) {
        requestActionInProgress = true
        
        TaskService.shared.rejectClaimRequest(taskID: request.taskID, assigneeID: request.requesterID) { result in
            DispatchQueue.main.async {
                requestActionInProgress = false
                
                switch result {
                case .success:
                    alertMessage = "Request rejected successfully."
                    showAlert = true
                    showingProfile = false
                    isLoading = true
                    viewModel.fetchPendingRequests()
                    
                    // Set a timeout to prevent infinite loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                    
                case .failure(let error):
                    alertMessage = "Error rejecting request: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Kid Profile View
struct KidProfileView: View {
    let request: PendingRequest
    let onApprove: () -> Void
    let onReject: () -> Void
    @Binding var isProcessing: Bool
    
    @State private var profile: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .padding()
                            Text("Loading profile...")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else if let profile = profile {
                        // Kid's info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(profile.firstName) \(profile.lastName)")
                                .font(.title)
                                .bold()
                            
                            if let age = profile.age {
                                Text("Age: \(age)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Bio section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Me")
                                .font(.headline)
                            
                            Text(profile.bio.isEmpty ? "No bio provided" : profile.bio)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 4)
                        }
                        
                        // Interests section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interests")
                                .font(.headline)
                            
                            if profile.selectedInterests.isEmpty {
                                Text("No interests listed")
                                    .foregroundColor(.gray)
                                    .italic()
                            } else {
                                ProfileWrapView(items: profile.selectedInterests, spacing: 8) { interest in
                                    Text(interest)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                                .frame(height: CGFloat(60 * (1 + profile.selectedInterests.count / 3)))
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Task Request section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Request")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Task: \(request.taskTitle)")
                                    .font(.subheadline)
                                    .bold()
                                
                                Text("Requested: \(request.requestDate.formatted(.dateTime.day().month().year()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.bottom, 24)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button(action: onApprove) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .padding(.trailing, 8)
                                    }
                                    Text("Approve Request")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
                            }
                            .disabled(isProcessing)
                            
                            Button(action: onReject) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                            .padding(.trailing, 8)
                                    }
                                    Text("Reject Request")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
                            }
                            .disabled(isProcessing)
                        }
                    } else {
                        Text("Could not load profile information")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Kid Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        isLoading = true
        UserService.shared.fetchUserProfile(userID: request.requesterID) { fetchedProfile in
            DispatchQueue.main.async {
                self.profile = fetchedProfile
                self.isLoading = false
            }
        }
    }
}

// MARK: - Helper Views
struct ProfileWrapView<Content: View, T: Hashable>: View {
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

// Model for pending requests
struct PendingRequest: Identifiable {
    var id: String { "\(taskID)-\(requesterID)" }
    let taskID: String
    let taskTitle: String
    let requesterID: String
    let requesterUsername: String
    let requestDate: Date
    
    var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: requestDate, to: Date()).day ?? 0
    }
}

// ViewModel for pending requests
class PendingRequestsViewModel: ObservableObject {
    @Published var pendingRequests: [PendingRequest] = []
    private let db = Firestore.firestore()
    
    func fetchPendingRequests() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ PendingRequestsViewModel: No user logged in")
            return
        }
        
        print("🔍 PendingRequestsViewModel: Fetching pending requests for user \(userID)")
        
        db.collection("tasks")
            .whereField("creatorID", isEqualTo: userID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ PendingRequestsViewModel: Error fetching tasks: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ PendingRequestsViewModel: No documents found")
                    return
                }
                
                print("✅ PendingRequestsViewModel: Found \(documents.count) tasks")
                
                var requests: [PendingRequest] = []
                
                for document in documents {
                    print("🔍 PendingRequestsViewModel: Examining task: \(document.documentID)")
                    let data = document.data()
                    let taskID = document.documentID
                    let taskTitle = data["title"] as? String ?? "Unknown Task"
                    
                    if let assigneesData = data["assignees"] as? [[String: Any]] {
                        print("✅ PendingRequestsViewModel: Task has \(assigneesData.count) assignees")
                        
                        for assigneeData in assigneesData {
                            let approved = assigneeData["approved"] as? Bool ?? false
                            let requesterID = assigneeData["userID"] as? String ?? ""
                            
                            print("🔍 PendingRequestsViewModel: Assignee \(requesterID) - approved: \(approved)")
                            
                            if !approved,
                               !requesterID.isEmpty,
                               let requesterUsername = assigneeData["username"] as? String,
                               let requestDate = (assigneeData["requestDate"] as? Timestamp)?.dateValue() {
                                
                                let request = PendingRequest(
                                    taskID: taskID,
                                    taskTitle: taskTitle,
                                    requesterID: requesterID,
                                    requesterUsername: requesterUsername,
                                    requestDate: requestDate
                                )
                                
                                print("✅ PendingRequestsViewModel: Added pending request for \(requesterUsername)")
                                requests.append(request)
                            }
                        }
                    } else {
                        print("❌ PendingRequestsViewModel: No assignees found for task")
                    }
                }
                
                // Sort by most recent first
                requests.sort { $0.requestDate > $1.requestDate }
                
                print("✅ PendingRequestsViewModel: Total pending requests: \(requests.count)")
                
                DispatchQueue.main.async {
                    self.pendingRequests = requests
                }
            }
    }
}
