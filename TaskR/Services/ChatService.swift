import FirebaseFirestore

struct Message: Identifiable {
    let id: String
    let senderID: String
    let messageText: String
}

class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()

    func sendMessage(taskID: String, senderID: String, messageText: String) {
        let messageData = ["senderID": senderID, "messageText": messageText]
        db.collection("tasks").document(taskID).collection("chat").addDocument(data: messageData)
    }

    func fetchMessages(taskID: String, completion: @escaping ([Message]) -> Void) {
        db.collection("tasks").document(taskID).collection("chat").addSnapshotListener { snapshot, error in
            let messages = snapshot?.documents.compactMap { doc -> Message? in
                let data = doc.data()
                return Message(id: doc.documentID, senderID: data["senderID"] as! String, messageText: data["messageText"] as! String)
            } ?? []
            completion(messages)
        }
    }
}
