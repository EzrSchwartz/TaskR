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
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var town = "Westport" // Default selection
    @State private var licenseImage: UIImage?
    @State private var profilePhoto: UIImage?
    @Binding var isAuthenticated: Bool
    
    let towns = ["Westport", "Weston", "Darien", "Wilton", "Fairfield"]

    var body: some View {
        NavigationStack {
            VStack {
                // Content changes based on current step
                if currentStep == 1 {
                    // Name View
                    VStack {
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                    .padding()
                } else if currentStep == 2 {
                    // Town Selection View
                    VStack {
                        Text("Select Your Town")
                            .font(.title2)
                            .padding()
                            
                        Picker("Town", selection: $town) {
                            ForEach(towns, id: \.self) { town in
                                Text(town)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .padding()
                    }
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 1 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .padding()
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Button("Complete Signup") {
                            registerUser()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Adult Signup")
        }
    }
    
    private func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                print("User created successfully! UID: \(user.uid)")
                let username = firstName + lastName
                
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
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    } else {
                        print("User data saved successfully!")
                        
                        DispatchQueue.main.async {
                            dismiss()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isAuthenticated = true
                            }
                        }
                    }
                }
            }
        }
    }
}



//// MARK: - Adult Signup Flow
//struct AdultSignupView: View {
//    let email: String
//    let password: String
//    @State private var firstName = ""
//    @State private var lastName = ""
//    @State private var town = ""
//    @State private var licenseImage: UIImage?
//    @State private var profilePhoto: UIImage?
//    @State private var isSignedUp = false
//
//    var body: some View {
//        NavigationStack {
//            AdultNameView(firstName: $firstName, lastName: $lastName, email: email, password: password, town: $town, licenseImage: $licenseImage, profilePhoto: $profilePhoto, isSignedUp: $isSignedUp)
//                .navigationDestination(isPresented: $isSignedUp) {
//                    ContentView()
//                }
//        }
//    }
//}
//
//// MARK: - Adult Signup Steps
//struct AdultNameView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var town: String
//    @Binding var licenseImage: UIImage?
//    @Binding var profilePhoto: UIImage?
//    @Binding var isSignedUp: Bool
//
//    var body: some View {
//        VStack {
//            TextField("First Name", text: $firstName)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//            TextField("Last Name", text: $lastName)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            NavigationLink("Next", destination: AdultTownView(firstName: $firstName, lastName: $lastName, email: email, password: password, town: $town, licenseImage: $licenseImage, profilePhoto: $profilePhoto, isSignedUp: $isSignedUp))
//        }
//        .padding()
//    }
//}
//
//// Adult Town Input
//struct AdultTownView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var town: String
//    @Binding var licenseImage: UIImage?
//    @Binding var profilePhoto: UIImage?
//    @Binding var isSignedUp: Bool
//    @State private var towns: [String] = ["Westport", "Weston","Darien","Wilton","Fairfield"]
//    
//    var body: some View {
//        VStack {
//            Picker("Town", selection: $town) {
//                ForEach(towns, id: \.self) { town in
//                    Text(town)
//                }
//            }
//            .pickerStyle(WheelPickerStyle())
//            .padding()
//
//        }
//        .padding()
//        Button("Complete Signup") {
//            registerUser()
//        }
//    }
//
//    func registerUser() {
//        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
//            if let error = error {
//                print("Error creating user: \(error.localizedDescription)")
//            } else if let user = authResult?.user {
//                print("User created successfully! UID: \(user.uid)")
//                var username = firstName
//                username += lastName
//                
//                        // Prepare user data for Firestore
//                        let userData: [String: Any] = [
//                            "uid": user.uid,
//                            "email": email,
//                            "firstName": firstName,
//                            "lastName": lastName,
//                            "username": username,
//                            "role": "Adult",
//                            "town": town,
//                            "timestamp": Timestamp()
//                        ]
//                        
//                        // Add age and town only if they are applicable
//
//                        let db = Firestore.firestore()
//                        db.collection("users").document(user.uid).setData(userData) { error in
//                            if let error = error {
//                                print("Error saving user data: \(error.localizedDescription)")
//                            } else {
//                                print("User data saved successfully!")
//
//                                // Set isSignedUp to true after successful signup and saving data
//                                isSignedUp = true
//                                
//                            }
//                        }
//                    }
//                }
//            }
//        }
//
//
//
