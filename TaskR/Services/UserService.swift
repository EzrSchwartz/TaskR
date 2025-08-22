//
//  UserService.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/12/25.
//

import Foundation
import FirebaseFirestore

// MARK: - User Profile Model
// In the same file, add this struct definition or update it if it exists:

struct UserProfile: Identifiable {
    let id: String
    let username: String
    let firstName: String
    let lastName: String
    let bio: String
    let interests: [String]
    let isKid: Bool
    let age: String?
    let averageRating: Double?
    let totalRatings: Int?
    let blockedUsers: [String]?
    
    
    // For compatibility with existing code
    var selectedInterests: [String] {
        return interests
    }
    
    // Helper method to get a display-ready rating and count
    var ratingStats: (Double, Int) {
        if let rating = averageRating, let count = totalRatings {
            return (rating, count)
        }
        return (0, 0)
    }
    
    // Checks if this profile has ratings
    var hasRatings: Bool {
        if let count = totalRatings, count > 0, averageRating != nil {
            return true
        }
        return false
    }
    
    // The profile view can display formatted rating information
    var formattedRating: String {
        if let rating = averageRating, let total = totalRatings, total > 0 {
            return String(format: "%.1f/5 (\(total) ratings)", rating)
        }
        return "No ratings yet"
    }
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
            let interests = data["interests"] as? [String] ?? []
            let isKid = data["isKid"] as? Bool ?? false
            let age = data["age"] as? String
            let averageRating = data["averageRating"] as? Double
            let totalRatings = data["totalRatings"] as? Int
            
            let profile = UserProfile(
                id: userID,
                username: username,
                firstName: firstName,
                lastName: lastName,
                bio: bio,
                interests: interests,
                isKid: isKid,
                age: age,
                averageRating: averageRating,
                totalRatings: totalRatings,
                blockedUsers: []
            )
            
            print("✅ User profile fetched successfully: \(username)")
            completion(profile)
        }
    }
}
