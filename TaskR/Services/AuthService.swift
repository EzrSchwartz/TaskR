import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    func fetchUsername(userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = document?.data(), let username = data["username"] as? String {
                completion(.success(username))
            } else {
                completion(.failure(NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Username not found."])))
            }
        }
    }

    func createUser(username: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let userID = result?.user.uid else {
                    completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found."])))
                    return
                }
                
                let userData: [String: Any] = [
                    "username": username,
                    "email": email,
                    "userID": userID,
                    "createdAt": Timestamp()
                ]
                
                self.db.collection("users").document(userID).setData(userData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    

    func signInUser(usernameOremail: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: usernameOremail, password: password) { authResult, error in
            error == nil ? completion(.success(authResult!.user)) : completion(.failure(error!))
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
