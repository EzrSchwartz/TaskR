import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    let taskID: String
    let creatorID: String
    let assigneeID: String
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    private let db = Firestore.firestore() // ✅ Declare Firestore instance


    var body: some View {
        VStack {
            List(messages) { message in
                HStack {
                    if message.senderID == Auth.auth().currentUser?.uid {
                        Spacer()
                        Text(message.text)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    } else {
                        Text(message.text)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        Spacer()
                    }
                }
            }
            .onAppear {
                fetchMessages()
            }

            HStack {
                TextField("Enter message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                }
            }
        }
        .navigationTitle("Chat")
    }

    private func fetchMessages() {
        MessagingService.shared.fetchMessages(taskID: taskID) { fetchedMessages in
            DispatchQueue.main.async {
                self.messages = fetchedMessages
            }
        }
    }
    func unclaimTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)

        taskRef.updateData([
            "assigneeID": FieldValue.delete(),
            "status": "available"
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                MessagingService.shared.deleteChat(taskID: taskID) { _ in } // ✅ Deletes chat
                completion(.success(()))
            }
        }
    }


    private func sendMessage() {
        guard let senderID = Auth.auth().currentUser?.uid else { return }
        let receiverID = (senderID == creatorID) ? assigneeID : creatorID

        MessagingService.shared.sendMessage(
            taskID: taskID,
            senderID: senderID,
            receiverID: receiverID,
            text: newMessage
        ) { result in
            switch result {
            case .success:
                self.newMessage = ""
            case .failure(let error):
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
}
