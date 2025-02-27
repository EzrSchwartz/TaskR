import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var claimedTasks: [Task] = []
    @Published var usernames: [String: String] = [:] // Stores usernames mapped by user ID
    @Published var mytasks: [Task] = []
    
    func fetchTasks() {
        TaskService.shared.fetchAvailableTasks { fetchedTasks in
            DispatchQueue.main.async {
                self.tasks = fetchedTasks
                self.fetchUsernames(for: fetchedTasks) // Fetch usernames for task creators
            }
        }
    }
    func fetchMyTasks() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        TaskService.shared.fetchMyTasks(userID: userID) { fetchedTasks in
            DispatchQueue.main.async {
                self.mytasks = fetchedTasks
                self.fetchUsernames(for: fetchedTasks) // Fetch usernames for task creators
            }
        }
    }

    func fetchClaimedTasks() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        TaskService.shared.fetchClaimedTasks(userID: userID) { fetchedTasks in
            DispatchQueue.main.async {
                self.claimedTasks = fetchedTasks
                self.fetchUsernames(for: fetchedTasks) // Fetch usernames for task creators
            }
        }
    }

    private func fetchUsernames(for tasks: [Task]) {
        for task in tasks {
            if self.usernames[task.creatorID] == nil { // Avoid duplicate fetches
                AuthService.shared.fetchUsername(userID: task.creatorID) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let username):
                            self.usernames[task.creatorID] = username
                        case .failure:
                            self.usernames[task.creatorID] = "Unknown User"
                        }
                    }
                }
            }
        }
    }
}
