import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyTasksView: View {
    @StateObject var viewModel = TaskViewModel() // ✅ Correct initialization

    var body: some View {
        List(viewModel.mytasks, id: \.id) { task in // ✅ Use `viewModel.tasks` to show available tasks
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
                Button("Delete Task") {
                    guard let userID = Auth.auth().currentUser?.uid else { return }
                    
                    TaskService.shared.deleteTask(taskID: task.id) { result in
                        switch result {
                        case .success:
                            print("✅ Task deleted successfully")
                            DispatchQueue.main.async {
                                viewModel.fetchTasks() // ✅ Refresh the task list after deletion
                            }
                        case .failure(let error):
                            print("❌ Error deleting task: \(error.localizedDescription)")
                        }
                    }
                }

                }
                .padding(.top, 5)
            }
        
        .onAppear {
            DispatchQueue.main.async {
                viewModel.fetchTasks() // ✅ Fetch available tasks, not claimed ones
            }
        }
    }
}
