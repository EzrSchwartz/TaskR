//import Foundation
//import FirebaseFirestore
//import FirebaseAuth
//
//// MARK: - Task Model
//struct Task: Identifiable, Codable {
//    let id: String
//    let title: String
//    let description: String
//    let creatorID: String
//    let creatorUsername: String
//    var assignees: [Assignee]  // Replace single assigneeID with array of Assignees
//    var status: String
//    var dueDate: Date
//    var people: Int  // Maximum number of people that can claim the task
//    var payType: String
//    var pay: Int
//    var town: String
//    var expertise: String
//    var category: String
//}
//
//// New struct to track assignees and their approval status
//struct Assignee: Codable, Identifiable {
//    var id: String { userID }  // Computed property to conform to Identifiable
//    let userID: String
//    let username: String
//    let requestDate: Date
//    var approved: Bool
//    var dateApproved: Date?
//}
//
//class TaskService {
//    static let shared = TaskService()
//    private let db = Firestore.firestore()
//
//    // MARK: - Create Task
//    func createTask(task: Task, completion: @escaping (Result<String, Error>) -> Void) {
//        // Convert Assignee array to dictionary for Firestore
//        var assigneesData: [[String: Any]] = []
//        for assignee in task.assignees {
//            var assigneeDict: [String: Any] = [
//                "userID": assignee.userID,
//                "username": assignee.username,
//                "requestDate": Timestamp(date: assignee.requestDate),
//                "approved": assignee.approved
//            ]
//            
//            if let dateApproved = assignee.dateApproved {
//                assigneeDict["dateApproved"] = Timestamp(date: dateApproved)
//            }
//            
//            assigneesData.append(assigneeDict)
//        }
//        
//        let taskData: [String: Any] = [
//            "id": task.id,
//            "title": task.title,
//            "description": task.description,
//            "creatorID": task.creatorID,
//            "creatorUsername": task.creatorUsername,
//            "assignees": assigneesData,  // Store assignees array
//            "status": task.status,
//            "dueDate": Timestamp(date: task.dueDate),
//            "people": task.people,
//            "payType": task.payType,
//            "pay": task.pay,
//            "town": task.town,
//            "expertise": task.expertise,
//            "category": task.category
//        ]
//
//        db.collection("tasks").document(task.id).setData(taskData) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(task.id))
//            }
//        }
//    }
//
//    // MARK: - Request to Claim Task
//    func requestToClaimTask(taskID: String, userID: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//        
//        taskRef.getDocument { document, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = document?.data(),
//                  let creatorID = data["creatorID"] as? String,
//                  let people = data["people"] as? Int else {
//                completion(.failure(NSError(domain: "TaskError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Task not found."])))
//                return
//            }
//            
//            // Check if this is the user's own task
//            if creatorID == userID {
//                completion(.failure(NSError(domain: "TaskError", code: 1, userInfo: [NSLocalizedDescriptionKey: "You cannot claim your own task."])))
//                return
//            }
//            
//            // Check if this task already has the maximum number of approved assignees
//            let assigneesData = data["assignees"] as? [[String: Any]] ?? []
//            
//            // Count approved assignees
//            let approvedAssigneesCount = assigneesData.filter { ($0["approved"] as? Bool) == true }.count
//            
//            if approvedAssigneesCount >= people {
//                completion(.failure(NSError(domain: "TaskError", code: 2, userInfo: [NSLocalizedDescriptionKey: "This task already has the maximum number of people."])))
//                return
//            }
//            
//            // Check if user has already requested to claim this task
//            let userRequested = assigneesData.contains { ($0["userID"] as? String) == userID }
//            
//            if userRequested {
//                completion(.failure(NSError(domain: "TaskError", code: 3, userInfo: [NSLocalizedDescriptionKey: "You have already requested to claim this task."])))
//                return
//            }
//            
//            // Create new assignee object
//            let newAssignee: [String: Any] = [
//                "userID": userID,
//                "username": username,
//                "requestDate": Timestamp(date: Date()),
//                "approved": false
//            ]
//            
//            // Add the new assignee to the assignees array
//            taskRef.updateData([
//                "assignees": FieldValue.arrayUnion([newAssignee])
//            ]) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    // Notify the task creator about the claim request
//                    self.notifyCreatorAboutClaimRequest(taskID: taskID, creatorID: creatorID, claimerID: userID, username: username)
//                    completion(.success(()))
//                }
//            }
//        }
//    }
//    
//    // MARK: - Approve Claim Request
//    func approveClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//        
//        taskRef.getDocument { document, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = document?.data(),
//                  let assigneesData = data["assignees"] as? [[String: Any]] else {
//                completion(.failure(NSError(domain: "TaskError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Task not found or no assignees."])))
//                return
//            }
//            
//            // Update the assignee's approved status in the array
//            var updatedAssignees: [[String: Any]] = []
//            
//            for var assignee in assigneesData {
//                if (assignee["userID"] as? String) == assigneeID {
//                    assignee["approved"] = true
//                    assignee["dateApproved"] = Timestamp(date: Date())
//                }
//                updatedAssignees.append(assignee)
//            }
//            
//            // Update the task with the modified assignees array
//            taskRef.updateData([
//                "assignees": updatedAssignees
//            ]) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    // Check if all approved assignees equals the people count, then update status
//                    let approvedCount = updatedAssignees.filter { ($0["approved"] as? Bool) == true }.count
//                    if let people = data["people"] as? Int, approvedCount >= people {
//                        taskRef.updateData(["status": "inProgress"])
//                    }
//                    
//                    // Notify the assignee that their request was approved
//                    self.notifyAssigneeAboutApproval(taskID: taskID, assigneeID: assigneeID)
//                    completion(.success(()))
//                }
//            }
//        }
//    }
//    
//    // MARK: - Reject Claim Request
//    func rejectClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//        
//        taskRef.getDocument { document, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = document?.data(),
//                  let assigneesData = data["assignees"] as? [[String: Any]] else {
//                completion(.failure(NSError(domain: "TaskError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Task not found or no assignees."])))
//                return
//            }
//            
//            // Filter out the rejected assignee
//            let updatedAssignees = assigneesData.filter { ($0["userID"] as? String) != assigneeID }
//            
//            // Update the task with the modified assignees array
//            taskRef.updateData([
//                "assignees": updatedAssignees
//            ]) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    // Notify the assignee that their request was rejected
//                    self.notifyAssigneeAboutRejection(taskID: taskID, assigneeID: assigneeID)
//                    completion(.success(()))
//                }
//            }
//        }
//    }
//    
//    // MARK: - Helper methods for notifications
//    private func notifyCreatorAboutClaimRequest(taskID: String, creatorID: String, claimerID: String, username: String) {
//        // You could implement this with Firebase Cloud Messaging or your own notification system
//        // For now, let's just create a notification document in Firestore
//        let notificationID = UUID().uuidString
//        let notificationData: [String: Any] = [
//            "id": notificationID,
//            "type": "claimRequest",
//            "taskID": taskID,
//            "creatorID": creatorID,
//            "claimerID": claimerID,
//            "claimerUsername": username,
//            "timestamp": Timestamp(date: Date()),
//            "read": false
//        ]
//        
//        db.collection("notifications").document(notificationID).setData(notificationData)
//    }
//    
//    private func notifyAssigneeAboutApproval(taskID: String, assigneeID: String) {
//        // Notification for approved claim
//        let notificationID = UUID().uuidString
//        let notificationData: [String: Any] = [
//            "id": notificationID,
//            "type": "claimApproved",
//            "taskID": taskID,
//            "assigneeID": assigneeID,
//            "timestamp": Timestamp(date: Date()),
//            "read": false
//        ]
//        
//        db.collection("notifications").document(notificationID).setData(notificationData)
//    }
//    
//    private func notifyAssigneeAboutRejection(taskID: String, assigneeID: String) {
//        // Notification for rejected claim
//        let notificationID = UUID().uuidString
//        let notificationData: [String: Any] = [
//            "id": notificationID,
//            "type": "claimRejected",
//            "taskID": taskID,
//            "assigneeID": assigneeID,
//            "timestamp": Timestamp(date: Date()),
//            "read": false
//        ]
//        
//        db.collection("notifications").document(notificationID).setData(notificationData)
//    }
//    
//    // MARK: - Helper Function to Map Firestore Data to Task Model
//    private func mapTask(from data: [String: Any], id: String) -> Task? {
//        guard let title = data["title"] as? String,
//              let description = data["description"] as? String,
//              let creatorID = data["creatorID"] as? String,
//              let creatorUsername = data["creatorUsername"] as? String,
//              let status = data["status"] as? String,
//              let dueDate = (data["dueDate"] as? Timestamp)?.dateValue(),
//              let people = data["people"] as? Int,
//              let payType = data["payType"] as? String,
//              let pay = data["pay"] as? Int,
//              let town = data["town"] as? String,
//              let category = data["category"] as? String else {
//            return nil
//        }
//
//        let expertise = data["expertise"] as? String ?? ""
//        
//        // Map assignees array from Firestore
//        var assignees: [Assignee] = []
//        if let assigneesData = data["assignees"] as? [[String: Any]] {
//            for assigneeData in assigneesData {
//                if let userID = assigneeData["userID"] as? String,
//                   let username = assigneeData["username"] as? String,
//                   let requestDate = (assigneeData["requestDate"] as? Timestamp)?.dateValue(),
//                   let approved = assigneeData["approved"] as? Bool {
//                    let dateApproved = (assigneeData["dateApproved"] as? Timestamp)?.dateValue()
//                    
//                    let assignee = Assignee(
//                        userID: userID,
//                        username: username,
//                        requestDate: requestDate,
//                        approved: approved,
//                        dateApproved: dateApproved
//                    )
//                    assignees.append(assignee)
//                }
//            }
//        }
//
//        return Task(
//            id: id,
//            title: title,
//            description: description,
//            creatorID: creatorID,
//            creatorUsername: creatorUsername,
//            assignees: assignees,
//            status: status,
//            dueDate: dueDate,
//            people: people,
//            payType: payType,
//            pay: pay,
//            town: town,
//            expertise: expertise,
//            category: category
//        )
//    }
//    
//    // MARK: - Fetch Tasks for User (claimed and approved)
//    func fetchClaimedTasks(userID: String, completion: @escaping ([Task]) -> Void) {
//        db.collection("tasks")
//            .whereField("assignees", arrayContains: ["userID": userID, "approved": true])
//            .addSnapshotListener { snapshot, error in
//                guard let documents = snapshot?.documents else {
//                    completion([])
//                    return
//                }
//
//                let tasks = documents.compactMap { doc -> Task? in
//                    let data = doc.data()
//                    return self.mapTask(from: data, id: doc.documentID)
//                }
//                completion(tasks)
//            }
//    }
//    
//    // Methods to fetch/filter tasks as needed (adapting your existing methods)
//    // ... existing methods with appropriate adjustments ...
//
//    // MARK: - Delete Task
//    func deleteTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//
//        taskRef.delete { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
//
//    // MARK: - Fetch Available Tasks
//    func fetchAvailableTasks(completion: @escaping ([Task]) -> Void) {
//        db.collection("tasks")
//            .whereField("status", isEqualTo: "available")
//            .addSnapshotListener { snapshot, error in
//                guard let documents = snapshot?.documents else {
//                    completion([])
//                    return
//                }
//
//                let tasks = documents.compactMap { doc -> Task? in
//                    let data = doc.data()
//                    return self.mapTask(from: data, id: doc.documentID)
//                }
//                completion(tasks)
//            }
//    }
//
//
//    // MARK: - Fetch Tasks Created by User
//    func fetchMyTasks(userID: String, completion: @escaping ([Task]) -> Void) {
//        db.collection("tasks")
//            .whereField("creatorID", isEqualTo: userID)
//            .addSnapshotListener { snapshot, error in
//                guard let documents = snapshot?.documents else {
//                    completion([])
//                    return
//                }
//
//                let tasks = documents.compactMap { doc -> Task? in
//                    let data = doc.data()
//                    return self.mapTask(from: data, id: doc.documentID)
//                }
//                completion(tasks)
//            }
//    }
//
// 
//}
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Task: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let creatorID: String
    let creatorUsername: String
    var assignees: [Assignee]
    var status: String
    var dueDate: Date
    var people: Int
    var payType: String
    var pay: Int
    var town: String
    var expertise: String
    var category: String
}

struct Assignee: Codable, Identifiable {
    var id: String { userID }
    let userID: String
    let username: String
    let requestDate: Date
    var approved: Bool
    var dateApproved: Date?
}

class TaskService {
    static let shared = TaskService()
    private let db = Firestore.firestore()
    
    // MARK: - Task CRUD Operations
    func createTask(task: Task, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try db.collection("tasks").document(task.id).setData(from: task)
            completion(.success(task.id))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func deleteTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("tasks").document(taskID).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func requestToClaimTask(taskID: String, userID: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)
        
        taskRef.getDocument { document, error in
            if let error = error {
                print("❌ Error fetching task: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                print("❌ Task not found")
                completion(.failure(TaskError.taskNotFound))
                return
            }
            
            do {
                // Try to decode the task
                guard let task = try? document.data(as: Task.self) else {
                    print("❌ Could not decode task data")
                    completion(.failure(TaskError.invalidTaskData))
                    return
                }
                
                // Check if this is the user's own task
                guard task.creatorID != userID else {
                    print("❌ User trying to claim their own task")
                    completion(.failure(TaskError.ownTaskClaim))
                    return
                }
                
                // Check if the task is already full
                let approvedCount = task.assignees.filter { $0.approved }.count
                guard approvedCount < task.people else {
                    print("❌ Task is already full")
                    completion(.failure(TaskError.taskFull))
                    return
                }
                
                // Check if user already requested this task
                guard !task.assignees.contains(where: { $0.userID == userID }) else {
                    print("❌ User already requested this task")
                    completion(.failure(TaskError.duplicateRequest))
                    return
                }
                
                // Create the new assignee
                let newAssignee = Assignee(
                    userID: userID,
                    username: username,
                    requestDate: Date(),
                    approved: false,
                    dateApproved: nil
                )
                
                // Add the assignee to the task
                do {
                    let encodedAssignee = try Firestore.Encoder().encode(newAssignee)
                    taskRef.updateData([
                        "assignees": FieldValue.arrayUnion([encodedAssignee])
                    ]) { error in
                        if let error = error {
                            print("❌ Error updating task: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("✅ Successfully requested task")
                            // Notify the task creator
                            self.notifyCreatorAboutClaimRequest(task: task, requester: newAssignee)
                            completion(.success(()))
                        }
                    }
                } catch {
                    print("❌ Error encoding assignee: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } catch {
                print("❌ Error in task request process: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func approveClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)
        
        taskRef.getDocument { document, error in
            guard let document = document, document.exists,
                  var task = try? document.data(as: Task.self) else {
                completion(.failure(TaskError.taskNotFound))
                return
            }
            
            guard let index = task.assignees.firstIndex(where: { $0.userID == assigneeID }) else {
                completion(.failure(TaskError.assigneeNotFound))
                return
            }
            
            task.assignees[index].approved = true
            task.assignees[index].dateApproved = Date()
            
            // Update task status if all spots filled
            if task.assignees.filter({ $0.approved }).count >= task.people {
                task.status = "inProgress"
            }
            
            do {
                try taskRef.setData(from: task)
                self.notifyAssigneeAboutApproval(taskID: taskID, assigneeID: assigneeID)
                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func rejectClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)
        
        // Fetch the assignee to remove
        taskRef.getDocument { document, error in
            guard let document = document, document.exists,
                  let task = try? document.data(as: Task.self) else {
                completion(.failure(TaskError.taskNotFound))
                return
            }
            
            guard let assignee = task.assignees.first(where: { $0.userID == assigneeID }) else {
                completion(.failure(TaskError.assigneeNotFound))
                return
            }
            
            do {
                // Convert assignee to dictionary for removal
                let assigneeData = try Firestore.Encoder().encode(assignee)
                taskRef.updateData([
                    "assignees": FieldValue.arrayRemove([assigneeData])
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.notifyAssigneeAboutRejection(taskID: taskID, assigneeID: assigneeID)
                        completion(.success(()))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Task Fetching
    func fetchAvailableTasks(completion: @escaping ([Task]) -> Void) {
        db.collection("tasks")
            .whereField("status", isEqualTo: "available")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                completion(documents.compactMap { try? $0.data(as: Task.self) })
            }
    }
    
    func fetchMyTasks(userID: String, completion: @escaping ([Task]) -> Void) {
        db.collection("tasks")
            .whereField("creatorID", isEqualTo: userID)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                completion(documents.compactMap { try? $0.data(as: Task.self) })
            }
    }
    
    func fetchClaimedTasks(userID: String, completion: @escaping ([Task]) -> Void) {
        // We can't directly query for a complex nested object with arrayContains
        // Get all tasks and filter on the client side for the user's approved tasks
        db.collection("tasks")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                do {
                    // Decode all tasks
                    let allTasks = try documents.compactMap { document -> Task? in
                        try document.data(as: Task.self)
                    }
                    
                    // Filter for tasks where user is an approved assignee
                    let claimedTasks = allTasks.filter { task in
                        task.assignees.contains { assignee in
                            assignee.userID == userID && assignee.approved
                        }
                    }
                    
                    completion(claimedTasks)
                } catch {
                    print("Error decoding tasks: \(error)")
                    completion([])
                }
            }
    }
    
    // MARK: - Notifications
    private func notifyCreatorAboutClaimRequest(task: Task, requester: Assignee) {
        let notification = Notification(
            id: UUID().uuidString,
            userID: task.creatorID,
            type: .claimRequest,
            taskID: task.id,
            message: "\(requester.username) wants to claim your task: \(task.title)",
            timestamp: Date(),
            read: false
        )
        
        do {
            try db.collection("notifications").document(notification.id).setData(from: notification)
        } catch {
            print("Error creating notification: \(error.localizedDescription)")
        }
    }
    
    private func notifyAssigneeAboutApproval(taskID: String, assigneeID: String) {
        let notification = Notification(
            id: UUID().uuidString,
            userID: assigneeID,
            type: .claimApproved,
            taskID: taskID,
            message: "Your claim request has been approved!",
            timestamp: Date(),
            read: false
        )
        
        do {
            try db.collection("notifications").document(notification.id).setData(from: notification)
        } catch {
            print("Error creating notification: \(error.localizedDescription)")
        }
    }
    
    private func notifyAssigneeAboutRejection(taskID: String, assigneeID: String) {
        let notification = Notification(
            id: UUID().uuidString,
            userID: assigneeID,
            type: .claimRejected,
            taskID: taskID,
            message: "Your claim request has been rejected",
            timestamp: Date(),
            read: false
        )
        
        do {
            try db.collection("notifications").document(notification.id).setData(from: notification)
        } catch {
            print("Error creating notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Handling
extension TaskService {
    enum TaskError: Error, LocalizedError {
        case taskNotFound
        case invalidTaskData
        case ownTaskClaim
        case taskFull
        case duplicateRequest
        case assigneeNotFound
        
        var errorDescription: String? {
            switch self {
            case .taskNotFound: return "Task not found"
            case .invalidTaskData: return "Invalid task data"
            case .ownTaskClaim: return "You can't claim your own task"
            case .taskFull: return "Task is already full"
            case .duplicateRequest: return "You already requested to claim this task"
            case .assigneeNotFound: return "Assignee not found"
            }
        }
    }
}

// MARK: - Notification Model
struct Notification: Identifiable, Codable {
    let id: String
    let userID: String
    let type: NotificationType
    let taskID: String
    let message: String
    let timestamp: Date
    var read: Bool
}

enum NotificationType: String, Codable {
    case claimRequest = "claimRequest"
    case claimApproved = "claimApproved"
    case claimRejected = "claimRejected"
}
