//Created By Ezra Schwartz


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var isAuthenticated = false
    @State private var isLoading = true
    @State private var userRole: String? = nil
    @State private var hasAgreedToEULA = UserDefaults.standard.bool(forKey: "hasAgreedToEULA")

    private let sessionTimeoutInterval: TimeInterval = 1000 // 30 minutes
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        checkAuthentication()
                    }
            } else if isAuthenticated {
                // Key change: Use an ID to force view recreation when auth state changes
                Group {
                    if let role = userRole {
                        if !hasAgreedToEULA {
                            EULAView {
                                UserDefaults.standard.set(true, forKey: "hasAgreedToEULA")
                                hasAgreedToEULA = true
                            }
                        } else if role == "Kid" {
                            KidHomeView(viewModel: viewModel)
                                .navigationBarBackButtonHidden(true)
                        } else if role == "Adult" {
                            AdultHomeView(viewModel: viewModel)
                                .navigationBarBackButtonHidden(true)
                        }
                    } else {
                        ProgressView("Loading role...")
                            .onAppear {
                                checkAuthentication()
                            }
                    }
                }
                .id(isAuthenticated) // This forces view recreation when auth changes
            } else {
                // Present auth flow as full screen cover, not part of main navigation
                AuthSelectionView(isAuthenticated: $isAuthenticated)
            }
        }
        .onChange(of: isAuthenticated) { _, newValue in
            if newValue {
                checkAuthentication()
            }
        }
    }


    private func checkAuthentication() {
        if let user = Auth.auth().currentUser {
            // Force reload user data to ensure the latest email verification status
            user.reload { [self] error in
//                print(fetchUserRole(userID: user.uid){role in
//                userRole=role
//                })

                if let error = error {
                    print("❌ Error reloading user data: \(error.localizedDescription)")
                    forceLogout()
                    return
                }

                if shouldLogoutBasedOnInactivity() {
                    forceLogout()
                } else if isAuthenticated{
                    fetchUserRole(userID: user.uid) { role in
                        userRole = role
                        isAuthenticated = true
                        isLoading = false
                    }
                } else {
                    forceLogout()
                }
            }

        } else {
            isAuthenticated = false
            isLoading = false
        }
    }

    private func fetchUserRole(userID: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("❌ Error fetching user role: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let document = document, document.exists else {
                print("❌ Document does not exist for userID: \(userID)")
                completion(nil)
                return
            }

            if let role = document.data()?["role"] as? String {
                print("✅ Role fetched successfully: \(role)")
                completion(role)
            } else {
                print("❌ Role not found in document.")
                completion(nil)
            }
        }
    }

    private func saveLastActiveTimestamp() {
        let timestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set(timestamp, forKey: "lastActiveTimestamp")
    }

    private func shouldLogoutBasedOnInactivity() -> Bool {
        if let lastTimestamp = UserDefaults.standard.object(forKey: "lastActiveTimestamp") as? TimeInterval {
            let currentTimestamp = Date().timeIntervalSince1970
            let timeSinceLastActive = currentTimestamp - lastTimestamp
            return timeSinceLastActive > sessionTimeoutInterval
        }
        return false
    }

    private func forceLogout() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
