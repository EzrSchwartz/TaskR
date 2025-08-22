import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReportUserView: View {
    @State private var searchText = ""
    @State private var matchingUsers: [UserProfile] = []
    @State private var selectedUser: UserProfile?
    @State private var reportReason = ""

    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        VStack(spacing: 16) {
            TextField("Search username", text: $searchText)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .onChange(of: searchText) { newText in
                    fetchMatchingUsers(query: newText)
                }

            if !matchingUsers.isEmpty {
                List(matchingUsers) { user in
                    Button {
                        selectedUser = user
                    } label: {
                        HStack {
                            Text(user.username)
                            if selectedUser?.id == user.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 200)
            }

            if let selectedUser = selectedUser {
                TextField("Reason for report", text: $reportReason)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                HStack(spacing: 12) {
                    Button("Submit Report") {
                        submitReport(for: selectedUser)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Block User") {
                        blockUser(selectedUser)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }

    // MARK: - Fetch users manually (matching your UserProfile)
    private func fetchMatchingUsers(query: String) {
        guard !query.isEmpty else {
            matchingUsers = []
            return
        }

        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    matchingUsers = docs.map { doc in
                        let data = doc.data()
                        return UserProfile(
                            id: doc.documentID,
                            username: data["username"] as? String ?? data["firstName"] as? String ?? "Anonymous",
                            firstName: data["firstName"] as? String ?? "",
                            lastName: data["lastName"] as? String ?? "",
                            bio: data["bio"] as? String ?? "",
                            interests: data["interests"] as? [String] ?? [],
                            isKid: data["role"] as? String == "Kid",
                            age: data["age"] as? String,
                            averageRating: data["averageRating"] as? Double,
                            totalRatings: data["totalRatings"] as? Int,
                            blockedUsers: data["blockedUsers"] as? [String] ?? []
                        )
                    }
                } else {
                    matchingUsers = []
                }
            }
    }

    // MARK: - Report
    private func submitReport(for user: UserProfile) {
        guard !reportReason.isEmpty else { return }

        db.collection("reports").addDocument(data: [
            "reporterId": currentUserId,
            "reportedUserId": user.id,
            "reason": reportReason,
            "timestamp": Timestamp(),
            "resolved": false
        ]) { error in
            if let error = error {
                print("Error submitting report: \(error.localizedDescription)")
            } else {
                resetUI()
            }
        }
    }

    // MARK: - Block
    private func blockUser(_ user: UserProfile) {
        let userRef = db.collection("users").document(currentUserId)
        userRef.updateData([
            "blockedUsers": FieldValue.arrayUnion([user.id])
        ]) { error in
            if let error = error {
                print("Error blocking user: \(error.localizedDescription)")
            } else {
                print("User blocked successfully")
                resetUI()
            }
        }
    }

    // MARK: - Reset UI
    private func resetUI() {
        searchText = ""
        matchingUsers = []
        selectedUser = nil
        reportReason = ""
    }
}
