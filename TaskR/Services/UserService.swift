//
//  UserService.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/12/25.
//

import Foundation
import FirebaseFirestore

// MARK: - User Profile Model
struct UserProfile: Identifiable {
    let id: String
    let username: String
    let firstName: String
    let lastName: String
    let bio: String
    let selectedInterests: [String]
    let isKid: Bool
    let age: String?
}

// MARK: - User Service
class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    func fetchUserProfile(userID: String, completion: @escaping (UserProfile?) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            guard let data = snapshot?.data() else {
                print("❌ Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // Extract user data with proper type checking
            let username = data["username"] as? String ?? data["firstName"] as? String ?? "Anonymous"
            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""
            let bio = data["bio"] as? String ?? ""
            let interests = data["interests"] as? [String] ?? data["selectedInterests"] as? [String] ?? []
            let isKid = data["isKid"] as? Bool ?? false
            let age = data["age"] as? String
            
            let profile = UserProfile(
                id: userID,
                username: username,
                firstName: firstName,
                lastName: lastName,
                bio: bio,
                selectedInterests: interests,
                isKid: isKid,
                age: age
            )
            
            print("✅ User profile fetched successfully: \(username)")
            completion(profile)
        }
    }
}
