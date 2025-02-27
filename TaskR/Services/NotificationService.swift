import FirebaseMessaging

class NotificationService {
    static let shared = NotificationService()
    private let messaging = Messaging.messaging()

    // Send Push Notification
    func sendPushNotification(recipientUserID: String, title: String, body: String) {
        let _: [String: Any] = [
            "to": "/topics/\(recipientUserID)",
            "notification": ["title": title, "body": body]
        ]
        
        // Here, implement the actual Firebase Cloud Messaging API call
    }
}
