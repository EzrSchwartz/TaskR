import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Message: Identifiable, Codable {
    let id: String
    let senderID: String
    let receiverID: String
    let text: String
    let timestamp: Date
}

class MessagingService {
    static let shared = MessagingService()
    private let db = Firestore.firestore()
    
    func createChat(taskID: String, creatorID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let chatData: [String: Any] = [
            "taskID": taskID,
            "creatorID": creatorID,
            "assigneeID": assigneeID,
            "timestamp": Timestamp()
        ]
        
        db.collection("chats").document(taskID).setData(chatData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func sendMessage(taskID: String, senderID: String, receiverID: String, text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let messageID = UUID().uuidString
        let messageData: [String: Any] = [
            "id": messageID,
            "senderID": senderID,
            "receiverID": receiverID,
            "text": text,
            "timestamp": Timestamp()
        ]
        
        db.collection("chats").document(taskID).collection("messages").document(messageID).setData(messageData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchMessages(taskID: String, completion: @escaping ([Message]) -> Void) {
        db.collection("chats").document(taskID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        senderID: data["senderID"] as? String ?? "",
                        receiverID: data["receiverID"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                completion(messages)
            }
    }
    
    func deleteChat(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let chatRef = db.collection("chats").document(taskID)
        
        chatRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
