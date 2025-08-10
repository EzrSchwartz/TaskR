//
//  TaskNotification.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/12/25.
//

// Notification names


import Foundation

// Define a global notification name for task approval
extension Notification.Name {
    static let taskApproved = Notification.Name("TaskApproved")
    static let taskCompleted = Notification.Name("TaskCompleted")
}

// MARK: - Task Notification Model
struct TaskNotification: Identifiable, Codable {
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
    case taskCompleted = "taskCompleted"
}
