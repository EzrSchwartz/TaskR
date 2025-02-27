import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClaimedTasksView: View {
    @ObservedObject var viewModel: TaskViewModel

    var body: some View {
        List(viewModel.claimedTasks) { task in
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

                Button("Unclaim") {
                    TaskService.shared.unclaimTask(taskID: task.id) { result in
                        switch result {
                        case .success:
                            viewModel.fetchClaimedTasks()
                        case .failure(let error):
                            print("Error unclaiming task: \(error.localizedDescription)")
                        }
                    }
                }
                .padding(.top, 5)
            }
        }
        .onAppear {
            viewModel.fetchClaimedTasks()
        }
    }
}
