//
//  PendingTaskRequestsView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/12/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PendingTaskRequestsView: View {
    @StateObject var viewModel = PendingRequestsViewModel()
    
    var body: some View {
        if viewModel.pendingRequests.isEmpty {
            Text("No pending requests")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
        } else {
            List {
                ForEach(viewModel.pendingRequests, id: \.taskID) { request in
                    VStack(alignment: .leading) {
                        Text(request.taskTitle)
                            .font(.headline)
                        
                        Text("Requested by: \(request.requesterUsername)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Requested on: \(request.requestDate, style: .date)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Button("Approve") {
                                approveRequest(request)
                            }
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            
                            Button("Reject") {
                                rejectRequest(request)
                            }
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Pending Requests")
            .onAppear {
                viewModel.fetchPendingRequests()
            }
        }
    }
    
    private func approveRequest(_ request: PendingRequest) {
        TaskService.shared.approveClaimRequest(taskID: request.taskID, assigneeID: request.requesterID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Request approved successfully")
                    viewModel.fetchPendingRequests()
                    
                case .failure(let error):
                    print("❌ Error approving request: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func rejectRequest(_ request: PendingRequest) {
        TaskService.shared.rejectClaimRequest(taskID: request.taskID, assigneeID: request.requesterID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Request rejected successfully")
                    viewModel.fetchPendingRequests()
                    
                case .failure(let error):
                    print("❌ Error rejecting request: \(error.localizedDescription)")
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
}

// ViewModel for pending requests
class PendingRequestsViewModel: ObservableObject {
    @Published var pendingRequests: [PendingRequest] = []
    private let db = Firestore.firestore()
    
    func fetchPendingRequests() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("tasks")
            .whereField("creatorID", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                var requests: [PendingRequest] = []
                
                for document in documents {
                    let data = document.data()
                    let taskID = document.documentID
                    let taskTitle = data["title"] as? String ?? "Unknown Task"
                    
                    if let assigneesData = data["assignees"] as? [[String: Any]] {
                        for assigneeData in assigneesData {
                            if let approved = assigneeData["approved"] as? Bool,
                               !approved,
                               let requesterID = assigneeData["userID"] as? String,
                               let requesterUsername = assigneeData["username"] as? String,
                               let requestDate = (assigneeData["requestDate"] as? Timestamp)?.dateValue() {
                                
                                let request = PendingRequest(
                                    taskID: taskID,
                                    taskTitle: taskTitle,
                                    requesterID: requesterID,
                                    requesterUsername: requesterUsername,
                                    requestDate: requestDate
                                )
                                
                                requests.append(request)
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.pendingRequests = requests
                }
            }
    }
}