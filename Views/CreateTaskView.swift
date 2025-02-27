import SwiftUI

struct CreateTaskView: View {
    @State private var title = ""
    @State private var description = ""

    var body: some View {
        VStack {
            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Create Task") {
                guard let userID = Auth.auth().currentUser?.uid else { return }
                TaskService.shared.createTask(title: title, description: description, creatorID: userID) { _ in }
            }
            .padding()
        }
    }
}
