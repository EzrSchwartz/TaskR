import Foundation

struct Task: Identifiable {
    let id: String
    let title: String
    let description: String
    let creatorID: String
    let creatorUsername: String
    var assigneeID: String?
    var status: String
    var dueDate: Date
}
