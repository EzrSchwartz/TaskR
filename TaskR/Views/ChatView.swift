import SwiftUI
import FirebaseAuth

struct ChatView: View {
    let taskID: String
    @State private var messages: [Message] = []
    @State private var messageText = ""

    var body: some View {
        VStack {
            List(messages) { message in
                HStack {
                    Text(message.messageText)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Send") {
                    guard let senderID = Auth.auth().currentUser?.uid else { return }
                    ChatService.shared.sendMessage(taskID: taskID, senderID: senderID, messageText: messageText)
                    messageText = ""
                }
            }
            .padding()
        }
        .onAppear {
            ChatService.shared.fetchMessages(taskID: taskID) { fetchedMessages in
                self.messages = fetchedMessages
            }
        }
    }
}
