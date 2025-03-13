//
//  AdultSignupView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Adult Signup Flow
struct AdultSignupView: View {
    let email: String
    let password: String
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var town = ""
    @State private var licenseImage: UIImage?
    @State private var profilePhoto: UIImage?
    @State private var isSignedUp = false

    var body: some View {
        NavigationStack {
            AdultNameView(firstName: $firstName, lastName: $lastName, email: email, password: password, town: $town, licenseImage: $licenseImage, profilePhoto: $profilePhoto, isSignedUp: $isSignedUp)
                .navigationDestination(isPresented: $isSignedUp) {
                    ContentView()
                }
        }
    }
}

// MARK: - Adult Signup Steps
struct AdultNameView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let email: String
    let password: String
    @Binding var town: String
    @Binding var licenseImage: UIImage?
    @Binding var profilePhoto: UIImage?
    @Binding var isSignedUp: Bool

    var body: some View {
        VStack {
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            NavigationLink("Next", destination: AdultTownView(firstName: $firstName, lastName: $lastName, email: email, password: password, town: $town, licenseImage: $licenseImage, profilePhoto: $profilePhoto, isSignedUp: $isSignedUp))
        }
        .padding()
    }
}

// Adult Town Input
struct AdultTownView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let email: String
    let password: String
    @Binding var town: String
    @Binding var licenseImage: UIImage?
    @Binding var profilePhoto: UIImage?
    @Binding var isSignedUp: Bool
    @State private var towns: [String] = ["Westport", "Weston","Darien","Wilton","Fairfield"]
    
    var body: some View {
        VStack {
            Picker("Town", selection: $town) {
                ForEach(towns, id: \.self) { town in
                    Text(town)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()

        }
        .padding()
        Button("Complete Signup") {
            registerUser()
        }
    }

    func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                print("User created successfully! UID: \(user.uid)")
                var username = firstName
                username += lastName
                
                        // Prepare user data for Firestore
                        let userData: [String: Any] = [
                            "uid": user.uid,
                            "email": email,
                            "firstName": firstName,
                            "lastName": lastName,
                            "username": username,
                            "role": "Adult",
                            "town": town,
                            "timestamp": Timestamp()
                        ]
                        
                        // Add age and town only if they are applicable

                        let db = Firestore.firestore()
                        db.collection("users").document(user.uid).setData(userData) { error in
                            if let error = error {
                                print("Error saving user data: \(error.localizedDescription)")
                            } else {
                                print("User data saved successfully!")

                                // Set isSignedUp to true after successful signup and saving data
                                isSignedUp = true
                                
                            }
                        }
                    }
                }
            }
        }



