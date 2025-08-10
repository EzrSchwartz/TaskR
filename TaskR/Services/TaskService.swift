//import Foundation
//import FirebaseFirestore
//import FirebaseAuth
//
//
//// Updated Task model that can handle missing assignees field
//struct Task: Identifiable, Codable {
//    let id: String
//    let title: String
//    let description: String
//    let creatorID: String
//    let creatorUsername: String
//    var assignees: [Assignee]
//    var status: String
//    var dueDate: Date
//    var people: Int
//    var payType: String
//    var pay: Int
//    var town: String
//    var expertise: String
//    var category: String
//    
//    // Custom decoder to handle missing fields
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        id = try container.decode(String.self, forKey: .id)
//        title = try container.decode(String.self, forKey: .title)
//        description = try container.decode(String.self, forKey: .description)
//        creatorID = try container.decode(String.self, forKey: .creatorID)
//        creatorUsername = try container.decode(String.self, forKey: .creatorUsername)
//        
//        // Handle missing assignees with a default empty array
//        assignees = try container.decodeIfPresent([Assignee].self, forKey: .assignees) ?? []
//        
//        status = try container.decode(String.self, forKey: .status)
//        dueDate = try container.decode(Date.self, forKey: .dueDate)
//        people = try container.decode(Int.self, forKey: .people)
//        payType = try container.decode(String.self, forKey: .payType)
//        pay = try container.decode(Int.self, forKey: .pay)
//        town = try container.decode(String.self, forKey: .town)
//        expertise = try container.decodeIfPresent(String.self, forKey: .expertise) ?? ""
//        category = try container.decode(String.self, forKey: .category)
//    }
//    // Add this alongside your existing decoder initializer
//    init(
//        id: String,
//        title: String,
//        description: String,
//        creatorID: String,
//        creatorUsername: String,
//        assignees: [Assignee],
//        status: String,
//        dueDate: Date,
//        people: Int,
//        payType: String,
//        pay: Int,
//        town: String,
//        expertise: String,
//        category: String
//    ) {
//        self.id = id
//        self.title = title
//        self.description = description
//        self.creatorID = creatorID
//        self.creatorUsername = creatorUsername
//        self.assignees = assignees
//        self.status = status
//        self.dueDate = dueDate
//        self.people = people
//        self.payType = payType
//        self.pay = pay
//        self.town = town
//        self.expertise = expertise
//        self.category = category
//    }
//}
//
//struct Assignee: Codable, Identifiable {
//    var id: String { userID }
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
//    // MARK: - Task CRUD Operations
//    func createTask(task: Task, completion: @escaping (Result<String, Error>) -> Void) {
//        do {
//            try db.collection("tasks").document(task.id).setData(from: task)
//            completion(.success(task.id))
//        } catch let error {
//            completion(.failure(error))
//        }
//    }
//    func updateTaskStatus(task: Task, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(task.id)
//        
//        taskRef.updateData([
//            "status": status
//        ]) { error in
//            if let error = error {
//                print("❌ Error updating task status: \(error.localizedDescription)")
//                completion(.failure(error))
//            } else {
//                print("✅ Task status updated successfully")
//                completion(.success(()))
//            }
//        }
//    }
//    
//    func deleteTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        db.collection("tasks").document(taskID).delete { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
//    
//    func requestToClaimTask(taskID: String, userID: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//        
//        taskRef.getDocument { document, error in
//            if let error = error {
//                print("❌ Error fetching task: \(error.localizedDescription)")
//                completion(.failure(error))
//                return
//            }
//            
//            guard let document = document, document.exists else {
//                print("❌ Task not found")
//                completion(.failure(TaskError.taskNotFound))
//                return
//            }
//            
//            do {
//                // Try to decode the task
//                guard let task = try? document.data(as: Task.self) else {
//                    print("❌ Could not decode task data")
//                    completion(.failure(TaskError.invalidTaskData))
//                    return
//                }
//                
//                // Check if this is the user's own task
//                guard task.creatorID != userID else {
//                    print("❌ User trying to claim their own task")
//                    completion(.failure(TaskError.ownTaskClaim))
//                    return
//                }
//                
//                // Check if the task is already full
//                let approvedCount = task.assignees.filter { $0.approved }.count
//                guard approvedCount < task.people else {
//                    print("❌ Task is already full")
//                    completion(.failure(TaskError.taskFull))
//                    return
//                }
//                
//                // Check if user already requested this task
//                guard !task.assignees.contains(where: { $0.userID == userID }) else {
//                    print("❌ User already requested this task")
//                    completion(.failure(TaskError.duplicateRequest))
//                    return
//                }
//                
//                // Create the new assignee
//                let newAssignee = Assignee(
//                    userID: userID,
//                    username: username,
//                    requestDate: Date(),
//                    approved: false,
//                    dateApproved: nil
//                )
//                
//                // Add the assignee to the task
//                do {
//                    let encodedAssignee = try Firestore.Encoder().encode(newAssignee)
//                    taskRef.updateData([
//                        "assignees": FieldValue.arrayUnion([encodedAssignee])
//                    ]) { error in
//                        if let error = error {
//                            print("❌ Error updating task: \(error.localizedDescription)")
//                            completion(.failure(error))
//                        } else {
//                            print("✅ Successfully requested task")
//                            // Notify the task creator
//                            self.notifyCreatorAboutClaimRequest(task: task, requester: newAssignee)
//                            completion(.success(()))
//                        }
//                    }
//                } catch {
//                    print("❌ Error encoding assignee: \(error.localizedDescription)")
//                    completion(.failure(error))
//                }
//            } catch {
//                print("❌ Error in task request process: \(error.localizedDescription)")
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    // Modify the approveClaimRequest method to create a chat when task is approved
//    func approveClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//        
//        taskRef.getDocument { [weak self] document, error in
//            guard let self = self else { return }
//            
//            guard let document = document, document.exists,
//                  var task = try? document.data(as: Task.self) else {
//                completion(.failure(TaskError.taskNotFound))
//                return
//            }
//            
//            guard let index = task.assignees.firstIndex(where: { $0.userID == assigneeID }) else {
//                completion(.failure(TaskError.assigneeNotFound))
//                return
//            }
//            
//            task.assignees[index].approved = true
//            task.assignees[index].dateApproved = Date()
//            
//            // Update task status if all spots filled
//            if task.assignees.filter({ $0.approved }).count >= task.people {
//                task.status = "inProgress"
//            }
//            
//            do {
//                try taskRef.setData(from: task)
//                
//                // After successfully updating the task, create or update chat
//                self.ensureChatExists(for: task)
//                
//                self.notifyAssigneeAboutApproval(taskID: taskID, assigneeID: assigneeID)
//                completion(.success(()))
//            } catch let error {
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    // Helper method to create or update chat for a task
//    private func ensureChatExists(for task: Task) {
//        // Check if chat already exists
//        FirebaseChatService.shared.checkIfChatExists(taskID: task.id) { exists in
//            if exists {
//                // Chat exists, update participants if needed
//                let assigneeIDs = task.assignees.filter { $0.approved }.map { $0.userID }
//                var participants = [task.creatorID]
//                participants.append(contentsOf: assigneeIDs)
//                
//                // Remove duplicates
//                participants = Array(Set(participants))
//                
//                // Update chat participants
//                FirebaseChatService.shared.updateChatParticipants(taskID: task.id, participants: participants) { result in
//                    switch result {
//                    case .success:
//                        print("✅ Chat participants updated for task: \(task.title)")
//                    case .failure(let error):
//                        print("❌ Error updating chat participants: \(error.localizedDescription)")
//                    }
//                }
//            } else {
//                // Create new chat
//                FirebaseChatService.shared.createChatForTask(task: task) { result in
//                    switch result {
//                    case .success:
//                        print("✅ Chat created for task: \(task.title)")
//                    case .failure(let error):
//                        print("❌ Error creating chat: \(error.localizedDescription)")
//                    }
//                }
//            }
//        }
//    }
//    
//    func rejectClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let taskRef = db.collection("tasks").document(taskID)
//        
//        // Fetch the assignee to remove
//        taskRef.getDocument { document, error in
//            guard let document = document, document.exists,
//                  let task = try? document.data(as: Task.self) else {
//                completion(.failure(TaskError.taskNotFound))
//                return
//            }
//            
//            guard let assignee = task.assignees.first(where: { $0.userID == assigneeID }) else {
//                completion(.failure(TaskError.assigneeNotFound))
//                return
//            }
//            
//            do {
//                // Convert assignee to dictionary for removal
//                let assigneeData = try Firestore.Encoder().encode(assignee)
//                taskRef.updateData([
//                    "assignees": FieldValue.arrayRemove([assigneeData])
//                ]) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        self.notifyAssigneeAboutRejection(taskID: taskID, assigneeID: assigneeID)
//                        completion(.success(()))
//                    }
//                }
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    // MARK: - Task Fetching
//    func fetchAvailableTasks(completion: @escaping ([Task]) -> Void) {
//        db.collection("tasks")
//            .whereField("status", isEqualTo: "available")
//            .addSnapshotListener { snapshot, _ in
//                guard let documents = snapshot?.documents else {
//                    completion([])
//                    return
//                }
//                completion(documents.compactMap { try? $0.data(as: Task.self) })
//            }
//    }
//    
//    func fetchMyTasks(userID: String, completion: @escaping ([Task]) -> Void) {
//        db.collection("tasks")
//            .whereField("creatorID", isEqualTo: userID)
//            .addSnapshotListener { snapshot, _ in
//                guard let documents = snapshot?.documents else {
//                    completion([])
//                    return
//                }
//                completion(documents.compactMap { try? $0.data(as: Task.self) })
//            }
//    }
//    
//    func fetchClaimedTasks(userID: String, completion: @escaping ([Task]) -> Void) {
//        print("🔍 TaskService: Fetching claimed tasks for user \(userID)")
//        
//        // We can't directly query for a complex nested object with arrayContains
//        // Get all tasks and filter on the client side for the user's approved tasks
//        db.collection("tasks")
//            .addSnapshotListener { snapshot, error in
//                if let error = error {
//                    print("❌ TaskService: Error fetching tasks: \(error.localizedDescription)")
//                    completion([])
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else {
//                    print("❌ TaskService: No documents found")
//                    completion([])
//                    return
//                }
//                
//                print("✅ TaskService: Found \(documents.count) tasks total")
//                
//                // Decode all tasks with error handling for each document
//                var allTasks: [Task] = []
//                var errorCount = 0
//                
//                for document in documents {
//                    do {
//                        let task = try document.data(as: Task.self)
//                        allTasks.append(task)
//                    } catch {
//                        print("⚠️ TaskService: Error decoding task \(document.documentID): \(error.localizedDescription)")
//                        errorCount += 1
//                        
//                    }
//                }
//                
//                if errorCount > 0 {
//                    print("⚠️ TaskService: Failed to decode \(errorCount) out of \(documents.count) tasks")
//                }
//                
//                // Filter for tasks where user is an approved assignee
//                let claimedTasks = allTasks.filter { task in
//                    task.assignees.contains { assignee in
//                        assignee.userID == userID && assignee.approved
//                    }
//                }
//                
//                print("✅ TaskService: Found \(claimedTasks.count) claimed tasks for user \(userID)")
//                
//                // For debugging, print out the claimed tasks
//                if claimedTasks.isEmpty {
//                    print("ℹ️ TaskService: No claimed tasks found for this user")
//                } else {
//                    for task in claimedTasks {
//                        print("📋 TaskService: Claimed task: \(task.title)")
//                    }
//                }
//                
//                completion(claimedTasks)
//            }
//    }
//    
//        //MARK: - Ratings
//        func rateUser(userID: String, taskID: String, rating: Double, completion: @escaping (Result<Void, Error>) -> Void) {
//            guard let raterID = Auth.auth().currentUser?.uid else {
//                completion(.failure(NSError(domain: "TaskService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
//                return
//            }
//            
//            let ratingData: [String: Any] = [
//                "userID": userID,
//                "taskID": taskID,
//                "rating": rating,
//                "raterID": raterID,
//                "timestamp": Timestamp(date: Date())
//            ]
//            
//            // Check if rating already exists
//            db.collection("ratings").document("\(taskID)_\(userID)").setData(ratingData) { error in
//                if let error = error {
//                    print("❌ Error saving rating: \(error.localizedDescription)")
//                    completion(.failure(error))
//                } else {
//                    print("✅ Rating saved successfully")
//                    
//                    // Also update the user's average rating
//                    self.updateUserAverageRating(userID: userID)
//                    
//                    completion(.success(()))
//                }
//            }
//        }
//        
//        func getUserRating(userID: String, completion: @escaping (Result<Double, Error>) -> Void) {
//            db.collection("users").document(userID).getDocument { snapshot, error in
//                if let error = error {
//                    print("❌ Error fetching user: \(error.localizedDescription)")
//                    completion(.failure(error))
//                    return
//                }
//                
//                if let data = snapshot?.data(), let rating = data["averageRating"] as? Double {
//                    completion(.success(rating))
//                } else {
//                    // No rating yet
//                    completion(.success(0))
//                }
//            }
//        }
//        
//        private func updateUserAverageRating(userID: String) {
//            // Calculate average from all ratings
//            db.collection("ratings")
//                .whereField("userID", isEqualTo: userID)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        print("❌ Error fetching ratings: \(error.localizedDescription)")
//                        return
//                    }
//                    
//                    guard let documents = snapshot?.documents, !documents.isEmpty else {
//                        return
//                    }
//                    
//                    let ratings = documents.compactMap { document -> Double? in
//                        return document.data()["rating"] as? Double
//                    }
//                    
//                    let averageRating = ratings.reduce(0, +) / Double(ratings.count)
//                    
//                    // Update user document with average rating
//                    self.db.collection("users").document(userID).updateData([
//                        "averageRating": averageRating
//                    ]) { error in
//                        if let error = error {
//                            print("❌ Error updating user average rating: \(error.localizedDescription)")
//                        } else {
//                            print("✅ User average rating updated successfully")
//                        }
//                    }
//                }
//        }
//    
//
//    
//    
//    
//    
//    // MARK: - Notifications
//    // MARK: - Notifications with better error handling
//    private func notifyCreatorAboutClaimRequest(task: Task, requester: Assignee) {
//        // Still post the UI notification even if Firestore write fails
//        NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": task.id])
//        
//        let notification = TaskNotification(
//            id: UUID().uuidString,
//            userID: task.creatorID,
//            type: .claimRequest,
//            taskID: task.id,
//            message: "\(requester.username) wants to claim your task: \(task.title)",
//            timestamp: Date(),
//            read: false
//        )
//        
//        do {
//            try db.collection("notifications").document(notification.id).setData(from: notification)
//            print("✅ Successfully created notification for claim request")
//        } catch {
//            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
//        }
//    }
//
//    private func notifyAssigneeAboutApproval(taskID: String, assigneeID: String) {
//        // Always post UI notification first
//        NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": taskID])
//        
//        let notification = TaskNotification(
//            id: UUID().uuidString,
//            userID: assigneeID,
//            type: .claimApproved,
//            taskID: taskID,
//            message: "Your claim request has been approved!",
//            timestamp: Date(),
//            read: false
//        )
//        
//        do {
//            try db.collection("notifications").document(notification.id).setData(from: notification)
//            print("✅ Successfully created notification for approval")
//        } catch {
//            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
//        }
//    }
//
//    private func notifyAssigneeAboutRejection(taskID: String, assigneeID: String) {
//        // Post UI notification first
//        NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": taskID])
//        
//        let notification = TaskNotification(
//            id: UUID().uuidString,
//            userID: assigneeID,
//            type: .claimRejected,
//            taskID: taskID,
//            message: "Your claim request has been rejected",
//            timestamp: Date(),
//            read: false
//        )
//        
//        do {
//            try db.collection("notifications").document(notification.id).setData(from: notification)
//            print("✅ Successfully created notification for rejection")
//        } catch {
//            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
//        }
//    }
//    
//}
//
//
//// MARK: - Error Handling
//extension TaskService {
//    enum TaskError: Error, LocalizedError {
//        case taskNotFound
//        case invalidTaskData
//        case ownTaskClaim
//        case taskFull
//        case duplicateRequest
//        case assigneeNotFound
//        
//        var errorDescription: String? {
//            switch self {
//            case .taskNotFound: return "Task not found"
//            case .invalidTaskData: return "Invalid task data"
//            case .ownTaskClaim: return "You can't claim your own task"
//            case .taskFull: return "Task is already full"
//            case .duplicateRequest: return "You already requested to claim this task"
//            case .assigneeNotFound: return "Assignee not found"
//            }
//        }
//    }
//}


import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Task Model
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
    
    // Custom decoder to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        creatorID = try container.decode(String.self, forKey: .creatorID)
        creatorUsername = try container.decode(String.self, forKey: .creatorUsername)
        
        // Handle missing assignees with a default empty array
        assignees = try container.decodeIfPresent([Assignee].self, forKey: .assignees) ?? []
        
        status = try container.decode(String.self, forKey: .status)
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        people = try container.decode(Int.self, forKey: .people)
        payType = try container.decode(String.self, forKey: .payType)
        pay = try container.decode(Int.self, forKey: .pay)
        town = try container.decode(String.self, forKey: .town)
        expertise = try container.decodeIfPresent(String.self, forKey: .expertise) ?? ""
        category = try container.decode(String.self, forKey: .category)
    }
    
    // Manual initializer
    init(
        id: String,
        title: String,
        description: String,
        creatorID: String,
        creatorUsername: String,
        assignees: [Assignee],
        status: String,
        dueDate: Date,
        people: Int,
        payType: String,
        pay: Int,
        town: String,
        expertise: String,
        category: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.creatorID = creatorID
        self.creatorUsername = creatorUsername
        self.assignees = assignees
        self.status = status
        self.dueDate = dueDate
        self.people = people
        self.payType = payType
        self.pay = pay
        self.town = town
        self.expertise = expertise
        self.category = category
    }
}

// MARK: - Assignee Model
struct Assignee: Codable, Identifiable {
    var id: String { userID }
    let userID: String
    let username: String
    let requestDate: Date
    var approved: Bool
    var dateApproved: Date?
    var rating: Double? // Optional: rating given to this assignee for the task
}

// MARK: - Task Service
class TaskService {
    static let shared = TaskService()
    private let db = Firestore.firestore()
    
    // MARK: - Task CRUD Operations
    
    /// Create a new task
    func createTask(task: Task, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            try db.collection("tasks").document(task.id).setData(from: task)
            completion(.success(task.id))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    /// Update the status of a task
    func updateTaskStatus(task: Task, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(task.id)
        
        taskRef.updateData([
            "status": status
        ]) { error in
            if let error = error {
                print("❌ Error updating task status: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Task status updated successfully to \(status)")
                
                // If task is marked as completed, notify assignees
                if status == "completed" {
                    // Notify all approved assignees
                    for assignee in task.assignees.filter({ $0.approved }) {
                        self.notifyAssigneeAboutTaskCompletion(taskID: task.id, assigneeID: assignee.userID)
                    }
                }
                
                completion(.success(()))
            }
        }
    }
    
    /// Delete a task
    func deleteTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("tasks").document(taskID).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Complete a task and notify all assignees
    func completeTask(taskID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // First, fetch the task to get assignee information
        db.collection("tasks").document(taskID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
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
                guard let task = try? document.data(as: Task.self) else {
                    print("❌ Could not decode task data")
                    completion(.failure(TaskError.invalidTaskData))
                    return
                }
                
                // Update task status
                self.updateTaskStatus(task: task, status: "completed") { result in
                    switch result {
                    case .success:
                        // Send notifications to all approved assignees
                        for assignee in task.assignees.filter({ $0.approved }) {
                            self.notifyAssigneeAboutTaskCompletion(taskID: taskID, assigneeID: assignee.userID)
                        }
                        completion(.success(()))
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } catch {
                print("❌ Error in completion process: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Task Claiming & Approval
    
    /// Request to claim a task
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
                    dateApproved: nil,
                    rating: nil
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
    
    /// Approve a claim request
    func approveClaimRequest(taskID: String, assigneeID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let taskRef = db.collection("tasks").document(taskID)
        
        taskRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
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
                
                // After successfully updating the task, create or update chat
                self.ensureChatExists(for: task)
                
                self.notifyAssigneeAboutApproval(taskID: taskID, assigneeID: assigneeID)
                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    /// Reject a claim request
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
    
    // MARK: - Rating System
    
    /// Rate a user for a task
    
    
    /// Update the average rating for a user
    private func updateUserAverageRating(userID: String) {
        // Calculate average from all ratings
        db.collection("ratings")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching ratings: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ No ratings found for user \(userID)")
                    return
                }
                
                let ratings = documents.compactMap { document -> Double? in
                    return document.data()["rating"] as? Double
                }
                
                let totalRatings = ratings.count
                let averageRating = ratings.reduce(0, +) / Double(totalRatings)
                
                print("✅ Calculated average rating for user \(userID): \(averageRating) from \(totalRatings) ratings")
                
                // Update user document with average rating
                self.db.collection("users").document(userID).updateData([
                    "averageRating": averageRating,
                    "totalRatings": totalRatings
                ]) { error in
                    if let error = error {
                        print("❌ Error updating user average rating: \(error.localizedDescription)")
                    } else {
                        print("✅ User average rating updated successfully")
                    }
                }
            }
    }
    
    /// Update a task with a rating for an assignee
    private func updateTaskWithRating(taskID: String, raterID: String, ratedUserID: String, rating: Double) {
        let taskRef = db.collection("tasks").document(taskID)
        
        taskRef.getDocument { document, error in
            if let error = error {
                print("❌ Error fetching task: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  var task = try? document.data(as: Task.self) else {
                print("❌ Task not found or could not decode task")
                return
            }
            
            // Check if we're rating an assignee (kid) or the task creator (adult)
            if task.creatorID == ratedUserID {
                // This is a rating for the task creator (from a kid to an adult)
                // We don't need to update the assignees array
                print("✅ Rating saved for task creator")
            } else if let index = task.assignees.firstIndex(where: { $0.userID == ratedUserID }) {
                // This is a rating for an assignee (from an adult to a kid)
                task.assignees[index].rating = rating
                
                do {
                    try taskRef.setData(from: task)
                    print("✅ Task updated with assignee rating")
                } catch {
                    print("❌ Error updating task with rating: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Task Fetching
    
    /// Fetch available tasks
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
    
    /// Fetch tasks created by a user
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
    
    /// Fetch tasks claimed by a user
    func fetchClaimedTasks(userID: String, completion: @escaping ([Task]) -> Void) {
        print("🔍 TaskService: Fetching claimed tasks for user \(userID)")
        
        // We can't directly query for a complex nested object with arrayContains
        // Get all tasks and filter on the client side for the user's approved tasks
        db.collection("tasks")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ TaskService: Error fetching tasks: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ TaskService: No documents found")
                    completion([])
                    return
                }
                
                print("✅ TaskService: Found \(documents.count) tasks total")
                
                // Decode all tasks with error handling for each document
                var allTasks: [Task] = []
                var errorCount = 0
                
                for document in documents {
                    do {
                        let task = try document.data(as: Task.self)
                        allTasks.append(task)
                    } catch {
                        print("⚠️ TaskService: Error decoding task \(document.documentID): \(error.localizedDescription)")
                        errorCount += 1
                    }
                }
                
                if errorCount > 0 {
                    print("⚠️ TaskService: Failed to decode \(errorCount) out of \(documents.count) tasks")
                }
                
                // Filter for tasks where user is an approved assignee
                let claimedTasks = allTasks.filter { task in
                    task.assignees.contains { assignee in
                        assignee.userID == userID && assignee.approved
                    }
                }
                
                print("✅ TaskService: Found \(claimedTasks.count) claimed tasks for user \(userID)")
                
                // For debugging, print out the claimed tasks
                if claimedTasks.isEmpty {
                    print("ℹ️ TaskService: No claimed tasks found for this user")
                } else {
                    for task in claimedTasks {
                        print("📋 TaskService: Claimed task: \(task.title)")
                    }
                }
                
                completion(claimedTasks)
            }
    }
    
    // MARK: - Chat Integration
    
    /// Ensure a chat exists for a task
    private func ensureChatExists(for task: Task) {
        // Check if chat already exists
        FirebaseChatService.shared.checkIfChatExists(taskID: task.id) { exists in
            if exists {
                // Chat exists, update participants if needed
                let assigneeIDs = task.assignees.filter { $0.approved }.map { $0.userID }
                var participants = [task.creatorID]
                participants.append(contentsOf: assigneeIDs)
                
                // Remove duplicates
                participants = Array(Set(participants))
                
                // Update chat participants
                FirebaseChatService.shared.updateChatParticipants(taskID: task.id, participants: participants) { result in
                    switch result {
                    case .success:
                        print("✅ Chat participants updated for task: \(task.title)")
                    case .failure(let error):
                        print("❌ Error updating chat participants: \(error.localizedDescription)")
                    }
                }
            } else {
                // Create new chat
                FirebaseChatService.shared.createChatForTask(task: task) { result in
                    switch result {
                    case .success:
                        print("✅ Chat created for task: \(task.title)")
                    case .failure(let error):
                        print("❌ Error creating chat: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    /// Notify the task creator about a claim request
    private func notifyCreatorAboutClaimRequest(task: Task, requester: Assignee) {
        // Still post the UI notification even if Firestore write fails
        NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": task.id])
        
        let notification = TaskNotification(
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
            print("✅ Successfully created notification for claim request")
        } catch {
            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
        }
    }

    /// Notify an assignee about claim approval
    private func notifyAssigneeAboutApproval(taskID: String, assigneeID: String) {
        // Always post UI notification first
        NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": taskID])
        
        let notification = TaskNotification(
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
            print("✅ Successfully created notification for approval")
        } catch {
            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
        }
    }

    /// Notify an assignee about claim rejection
    private func notifyAssigneeAboutRejection(taskID: String, assigneeID: String) {
        // Post UI notification first
        NotificationCenter.default.post(name: .taskApproved, object: nil, userInfo: ["taskID": taskID])
        
        let notification = TaskNotification(
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
            print("✅ Successfully created notification for rejection")
        } catch {
            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
        }
    }
    
    /// Notify an assignee about task completion
    private func notifyAssigneeAboutTaskCompletion(taskID: String, assigneeID: String) {
        // Post UI notification first
        NotificationCenter.default.post(
            name: .taskCompleted,
            object: nil,
            userInfo: ["taskID": taskID, "assigneeID": assigneeID]
        )
        
        let notification = TaskNotification(
            id: UUID().uuidString,
            userID: assigneeID,
            type: .taskCompleted,
            taskID: taskID,
            message: "A task you claimed has been marked as completed. Please rate your experience.",
            timestamp: Date(),
            read: false
        )
        
        do {
            try db.collection("notifications").document(notification.id).setData(from: notification)
            print("✅ Successfully created notification for task completion")
        } catch {
            print("⚠️ Error creating notification (but UI will still update): \(error.localizedDescription)")
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


// MARK: - Rating System
extension TaskService {
    /// Rate a user for a task
    func rateUser(userID: String, taskID: String, rating: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let raterID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "TaskService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        print("🔍 Starting rating process: User \(userID) for task \(taskID) with rating \(rating)")
        
        // First get the user's current average rating and total ratings
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching user: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let userData = snapshot?.data() else {
                print("❌ User data not found")
                completion(.failure(NSError(domain: "TaskService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            // Get current ratings
            let currentAverage = userData["averageRating"] as? Double ?? 0.0
            let currentTotal = userData["totalRatings"] as? Int ?? 0
            
            // Calculate new average
            let newTotal = currentTotal + 1
            let newAverage = ((currentAverage * Double(currentTotal)) + rating) / Double(newTotal)
            
            print("🔍 Updating user rating: Old (\(currentAverage) from \(currentTotal) ratings) -> New (\(newAverage) from \(newTotal) ratings)")
            
            // Update the user document
            userRef.updateData([
                "averageRating": newAverage,
                "totalRatings": newTotal
            ]) { error in
                if let error = error {
                    print("❌ Error updating user rating: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("✅ User rating updated successfully")
                    
                    // Also update the task with the rating info
                    self.updateTaskWithRating(taskID: taskID, raterID: raterID, ratedUserID: userID, rating: rating) { success in
                        if success {
                            completion(.success(()))
                        } else {
                            // Still consider it a success even if task update fails
                            print("⚠️ Warning: Failed to update task with rating")
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    /// Get a user's rating and total ratings count
    func getUserRating(userID: String, completion: @escaping (Result<(Double, Int), Error>) -> Void) {
        print("🔍 Fetching rating for user: \(userID)")
        
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching user: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let data = snapshot?.data() {
                let rating = data["averageRating"] as? Double ?? 0
                let totalRatings = data["totalRatings"] as? Int ?? 0
                print("✅ Retrieved rating: \(rating) from \(totalRatings) reviews")
                completion(.success((rating, totalRatings)))
            } else {
                print("⚠️ No rating data found for user")
                completion(.success((0, 0)))
            }
        }
    }
    
    /// Update the average rating for a user
    private func updateUserAverageRating(userID: String, completion: @escaping (Bool) -> Void) {
        print("🔍 Updating average rating for user: \(userID)")
        
        // Calculate average from all ratings
        db.collection("ratings")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("❌ Error fetching ratings: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ No ratings found for user \(userID)")
                    
                    // If no ratings, set default values
                    self.db.collection("users").document(userID).updateData([
                        "averageRating": 0.0,
                        "totalRatings": 0
                    ]) { error in
                        if let error = error {
                            print("❌ Error setting default rating values: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("✅ Default rating values set successfully")
                            completion(true)
                        }
                    }
                    return
                }
                
                // Get all ratings and calculate average
                let ratings = documents.compactMap { document -> Double? in
                    return document.data()["rating"] as? Double
                }
                
                let totalRatings = ratings.count
                let sum = ratings.reduce(0, +)
                let averageRating = totalRatings > 0 ? sum / Double(totalRatings) : 0
                
                print("✅ Calculated average rating for user \(userID): \(averageRating) from \(totalRatings) ratings")
                
                // Update user document with average rating
                self.db.collection("users").document(userID).updateData([
                    "averageRating": averageRating,
                    "totalRatings": totalRatings
                ]) { error in
                    if let error = error {
                        print("❌ Error updating user average rating: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ User average rating updated successfully")
                        completion(true)
                    }
                }
            }
    }
    
    /// Update a task with a rating for an assignee
    private func updateTaskWithRating(taskID: String, raterID: String, ratedUserID: String, rating: Double, completion: @escaping (Bool) -> Void) {
        print("🔍 Updating task \(taskID) with rating \(rating) for user \(ratedUserID)")
        
        let taskRef = db.collection("tasks").document(taskID)
        
        taskRef.getDocument { [weak self] document, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("❌ Error fetching task: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, document.exists else {
                print("❌ Task not found")
                completion(false)
                return
            }
            
            // Try to decode task data
            guard var task = try? document.data(as: Task.self) else {
                print("❌ Could not decode task data")
                completion(false)
                return
            }
            
            // Check if we're rating an assignee (kid) or the task creator (adult)
            if task.creatorID == ratedUserID {
                // This is a rating for the task creator (from a kid to an adult)
                // We don't need to update the assignees array in this case
                print("✅ Rating saved for task creator")
                
                // Create a "creatorRating" field to store this rating
                taskRef.updateData([
                    "creatorRating": rating,
                    "lastRatedAt": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        print("❌ Error updating task with creator rating: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Task updated with creator rating")
                        completion(true)
                    }
                }
            } else {
                // This is a rating for an assignee (from an adult to a kid)
                if let index = task.assignees.firstIndex(where: { $0.userID == ratedUserID }) {
                    print("✅ Found assignee at index \(index) in task")
                    
                    // Update this assignee's rating
                    task.assignees[index].rating = rating
                    
                    // Save the updated task
                    do {
                        // We need to replace the entire task to update the nested assignee array
                        try taskRef.setData(from: task)
                        print("✅ Task updated with assignee rating")
                        completion(true)
                    } catch {
                        print("❌ Error updating task with rating: \(error.localizedDescription)")
                        
                        // Alternative approach using updateData if setData fails
                        self.updateAssigneeRatingAlternative(taskID: taskID, assigneeID: ratedUserID, rating: rating) { success in
                            completion(success)
                        }
                    }
                } else {
                    print("❌ Assignee not found in task")
                    completion(false)
                }
            }
        }
    }
    
    /// Alternative method to update assignee rating if the main method fails
    private func updateAssigneeRatingAlternative(taskID: String, assigneeID: String, rating: Double, completion: @escaping (Bool) -> Void) {
        print("🔍 Using alternative method to update assignee rating")
        
        // This approach uses a transaction to ensure atomic updates
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let taskRef = self.db.collection("tasks").document(taskID)
            
            do {
                let taskDocument = try transaction.getDocument(taskRef)
                guard var task = try? taskDocument.data(as: Task.self) else {
                    return false
                }
                
                if let index = task.assignees.firstIndex(where: { $0.userID == assigneeID }) {
                    task.assignees[index].rating = rating
                    
                    // Encode the entire assignees array for update
                    let encodedAssignees = try Firestore.Encoder().encode(task.assignees)
                    transaction.updateData(["assignees": encodedAssignees], forDocument: taskRef)
                    
                    return true
                } else {
                    return false
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return false
            }
        }) { (result, error) in
            if let error = error {
                print("❌ Transaction failed: \(error.localizedDescription)")
                completion(false)
            } else if let success = result as? Bool, success {
                print("✅ Transaction successfully updated assignee rating")
                completion(true)
            } else {
                print("❌ Transaction failed for unknown reason")
                completion(false)
            }
        }
    }
    
    // Helper method to notify user about new rating
    private func notifyUserAboutNewRating(userID: String, rating: Double, isCreator: Bool) {
        let notification = TaskNotification(
            id: UUID().uuidString,
            userID: userID,
            type: .taskCompleted,
            taskID: "",  // Not specific to a task in notification
            message: "You received a new \(rating) star rating! \(isCreator ? "A kid rated your task." : "An adult rated your work.")",
            timestamp: Date(),
            read: false
        )
        
        do {
            try db.collection("notifications").document(notification.id).setData(from: notification)
            print("✅ Successfully notified user about new rating")
        } catch {
            print("⚠️ Error creating rating notification: \(error.localizedDescription)")
        }
    }
}

// Add rating received notification type
extension NotificationType {
    static let ratingReceived = NotificationType(rawValue: "ratingReceived")
}

// Add notification name for task completion
extension Notification.Name {
}
