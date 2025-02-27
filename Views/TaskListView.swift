import SwiftUI

struct TaskListView: View {
    @State private var tasks: [Task] = []

    var body: some View {
        List(tasks) { task in
            VStack(alignment: .leading) {
                Text(task.title).font(.headline)
                Text(task.description).font(.subheadline)
            }
            .onTapGesture {
                TaskService.shared.claimTask(taskID: task.id, assigneeID: "testUserID") { _ in }
            }
        }
        .onAppear {
            TaskService.shared.fetchAvailableTasks { fetchedTasks in
                self.tasks = fetchedTasks
            }
        }
    }
}
