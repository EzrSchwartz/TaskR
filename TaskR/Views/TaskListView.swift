import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TaskListView: View {
    @StateObject var viewModel = TaskViewModel() // ✅ Correct initialization

    var body: some View {
        List(viewModel.tasks, id: \.id) { task in // ✅ Use `viewModel.tasks` to show available tasks
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)

                Text("Created by: \(viewModel.usernames[task.creatorID] ?? "Loading...")")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(task.description)
                    .font(.subheadline)

                Text("Due: \(task.dueDate, style: .date)")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Button("Claim Task") {
                    guard let userID = Auth.auth().currentUser?.uid else { return }
                    TaskService.shared.claimTask(taskID: task.id, assigneeID: userID) { result in
                        switch result {
                        case .success:
                            DispatchQueue.main.async {
                                viewModel.fetchTasks() // ✅ Refresh list after claiming
                            }
                        case .failure(let error):
                            print("Error claiming task: \(error.localizedDescription)")
                        }
                    }
                }
                .padding(.top, 5)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                viewModel.fetchTasks() // ✅ Fetch available tasks, not claimed ones
            }
        }
    }
}
