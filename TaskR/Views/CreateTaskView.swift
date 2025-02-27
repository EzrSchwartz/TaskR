


import SwiftUI
import FirebaseAuth

struct CreateTaskView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var errorMessage: String?
    @State private var creatorUsername: String = "Loading..." // Default before fetching

    var body: some View {
        VStack {
            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                .padding()

            Button(action: createTask) {
                Text("Create Task")
            }
            .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
        }
        .onAppear {
            fetchUsername() // ✅ Fetch username when view loads
        }
    }

    // ✅ Create Task Function
    private func createTask() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated!"
            return
        }

        TaskService.shared.createTask(
            title: title,
            description: description,
            creatorID: userID,
            dueDate: dueDate
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let taskID):
                    print("✅ Task created with ID: \(taskID)")
                    errorMessage = "Task created!"
                    title = "" // Reset input fields
                    description = ""
                    dueDate = Date()
                case .failure(let error):
                    print("❌ Error creating task: \(error.localizedDescription)")
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    // ✅ Fetch Username
    private func fetchUsername() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        AuthService.shared.fetchUsername(userID: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let username):
                    self.creatorUsername = username
                case .failure:
                    self.creatorUsername = "Unknown User"
                }
            }
        }
    }
}
