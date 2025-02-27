import SwiftUI
import Firebase

@main
struct TaskRApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = user != nil
                self?.currentUser = user
            }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
}