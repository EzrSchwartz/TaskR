import SwiftUI
import FirebaseFirestore
import FirebaseAuth
//import FirebaseFunctions


import FirebaseFirestore
import FirebaseAuth

class TaskService {
    static let shared = TaskService()
    private let db = Firestore.firestore()

    // ✅ Create Task Function
    func createTask(title: String, description: String, creatorID: String, dueDate: Date, completion: @escaping (Result<String, Error>) -> Void) {
        AuthService.shared.fetchUsername(userID: creatorID) { result in
            switch result {
            case .success(let username):
                let taskID = UUID().uuidString
                let taskData: [String: Any] = [
                    "title": title,
                    "description": description,
                    "creatorID": creatorID,
                    "creatorUsername": username, // ✅ Fetched username
                    "status": "available",
                    "timestamp": Timestamp(),
                    "dueDate": Timestamp(date: dueDate)
                ]

                self.db.collection("tasks").document(taskID).setData(taskData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
//                        self.sendNotification(title: "New Task Added!", body: "\(title) - \(description)")
                        completion(.success(taskID))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func claimTask(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)

        taskRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = document?.data(),
                  let creatorID = data["creatorID"] as? String else {
                completion(.failure(NSError(domain: "TaskError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Task not found."])))
                return
            }

            if creatorID == assigneeID {
                completion(.failure(NSError(domain: "TaskError", code: 1, userInfo: [NSLocalizedDescriptionKey: "You cannot claim your own task."])))
                return
            }

            // Proceed with claiming the task
            taskRef.updateData([
                "assigneeID": assigneeID,
                "status": "inProgress"
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
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
                completion(.success(()))
            }
        }
    }

    func deleteTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)
        
        taskRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }


    // Create a new task


    // Fetch available tasks
    func fetchAvailableTasks(completion: @escaping ([Task]) -> Void) {
        db.collection("tasks").whereField("status", isEqualTo: "available").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let tasks = documents.compactMap { doc -> Task? in
                let data = doc.data()
                return Task(
                    id: doc.documentID,
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    creatorID: data["creatorID"] as? String ?? "",
                    creatorUsername:  data["creatorUsername"] as? String ?? "",
                    assigneeID: data["assigneeID"] as? String,
                    status: data["status"] as? String ?? "available",
                    dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
            completion(tasks)
        }
    }
    
    
    func fetchClaimedTasks(userID: String, completion: @escaping ([Task]) -> Void) {
            db.collection("tasks").whereField("assigneeID", isEqualTo: userID).addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let tasks = documents.compactMap { doc -> Task? in
                    let data = doc.data()
                    return Task(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        creatorID: data["creatorID"] as? String ?? "",
                        creatorUsername: data["creatorUsername"] as? String ?? "",
                        assigneeID: data["assigneeID"] as? String,
                        status: data["status"] as? String ?? "inProgress",
                        dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                completion(tasks)
            }
        }
    func fetchMyTasks(userID: String, completion: @escaping ([Task]) -> Void) {
            db.collection("tasks").whereField("creatorID", isEqualTo: userID).addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let tasks = documents.compactMap { doc -> Task? in
                    let data = doc.data()
                    
                    return Task(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        creatorID: data["creatorID"] as? String ?? "",
                        creatorUsername: data["creatorUsername"] as? String ?? "",
                        assigneeID: data["assigneeID"] as? String,
                        status: data["status"] as? String ?? "inProgress",
                        dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                completion(tasks)
            }
        }
    
//    private func sendNotification(title: String, body: String) {
//        functions.httpsCallable("sendTaskNotification").call(["title": title, "body": body]) { result, error in
//            if let error = error {
//                print("❌ Error sending notification: \(error.localizedDescription)")
//            } else {
//                print("✅ Notification sent successfully")
//            }
//        }
//    }
}
