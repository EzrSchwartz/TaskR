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
//
//// MARK: - Adult Signup Flow
//struct AdultSignupView: View {
//    let email: String
//    let password: String
//    @Environment(\.dismiss) private var dismiss
//    @State private var currentStep = 1
//    @State private var firstName = ""
//    @State private var lastName = ""
//    @State private var town = "Westport" // Default selection
//    @State private var licenseImage: UIImage?
//    @State private var profilePhoto: UIImage?
//    @Binding var isAuthenticated: Bool
//    
//    let towns = ["Westport", "Weston", "Darien", "Wilton", "Fairfield"]
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                // Content changes based on current step
//                if currentStep == 1 {
//                    // Name View
//                    VStack {
//                        TextField("First Name", text: $firstName)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .padding()
//                        TextField("Last Name", text: $lastName)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .padding()
//                    }
//                    .padding()
//                } else if currentStep == 2 {
//                    // Town Selection View
//                    VStack {
//                        Text("Select Your Town")
//                            .font(.title2)
//                            .padding()
//                            
//                        Picker("Town", selection: $town) {
//                            ForEach(towns, id: \.self) { town in
//                                Text(town)
//                            }
//                        }
//                        .pickerStyle(WheelPickerStyle())
//                        .padding()
//                    }
//                }
//                
//                // Navigation buttons
//                HStack {
//                    if currentStep > 1 {
//                        Button("Back") {
//                            withAnimation {
//                                currentStep -= 1
//                            }
//                        }
//                        .padding()
//                        .foregroundColor(.blue)
//                    }
//                    
//                    Spacer()
//                    
//                    if currentStep < 2 {
//                        Button("Next") {
//                            withAnimation {
//                                currentStep += 1
//                            }
//                        }
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                    } else {
//                        Button("Complete Signup") {
//                            registerUser()
//                        }
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("Adult Signup")
//        }
//    }
//    
//    private func registerUser() {
//        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
//            if let error = error {
//                print("Error creating user: \(error.localizedDescription)")
//            } else if let user = authResult?.user {
//                print("User created successfully! UID: \(user.uid)")
//                let username = firstName + lastName
//                
//                let userData: [String: Any] = [
//                    "uid": user.uid,
//                    "email": email,
//                    "firstName": firstName,
//                    "lastName": lastName,
//                    "username": username,
//                    "role": "Adult",
//                    "town": town,
//                    "timestamp": Timestamp(),
//                    "averageRating": 0.0,
//                    "totalRatings": 0
//                ]
//                
//                let db = Firestore.firestore()
//                db.collection("users").document(user.uid).setData(userData) { error in
//                    if let error = error {
//                        print("Error saving user data: \(error.localizedDescription)")
//                    } else {
//                        print("User data saved successfully!")
//                        
//                        DispatchQueue.main.async {
//                            dismiss()
//                            
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                isAuthenticated = true
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//




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
                        .foregroundColor(AppColors.forestGreen) // Use forestGreen
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .padding()
                        .background(AppColors.forestGreen) // Use forestGreen
                        .foregroundColor(AppColors.pearlWhite) // Use pearlWhite
                        .cornerRadius(10)
                    } else {
                        Button("Complete Signup") {
                            registerUser()
                        }
                        .padding()
                        .background(AppColors.forestGreen) // Use forestGreen
                        .foregroundColor(AppColors.pearlWhite) // Use pearlWhite
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
                    "timestamp": Timestamp(),
                    "averageRating": 0.0,
                    "totalRatings": 0
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

