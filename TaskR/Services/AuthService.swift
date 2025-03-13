import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import Foundation
import FirebaseAuth


class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    func fetchUsername(userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data(), let username = data["username"] as? String {
                completion(.success(username))
            } else {
                completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Username not found."])))
            }
        }
    }
    func createUser(
        isKid: Bool,
        firstName: String,
        lastName: String,
        age: String?,
        email: String,
        password: String,
        bio: String?,
        selectedInterests: String?,
        licenseImage: UIImage?,
        completion: @escaping (Result<Void, Error>) -> Void,
        ratings: Int?,
        averageRating: Double?     )
 {
     auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userID = result?.user.uid else {
                completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found."])))
                return
            }
            
            var userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "userID": userID,
                "createdAt": Timestamp(),
                "isKid": isKid
            ]
            
            if isKid {
                userData["age"] = age
                userData["bio"] = bio ?? ""
                userData["interests"] = selectedInterests ?? ""
            } else {
                userData["licenseVerified"] = false
            }
            
            self.db.collection("users").document(userID).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func signInUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }
    
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
