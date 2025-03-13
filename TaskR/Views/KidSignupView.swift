//
//  KidSignupView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Kid Signup Flow
struct KidSignupView: View {
    let email: String
    let password: String
    @State private var username = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = "15"
    @State private var selectedInterests: [String] = []
    @State private var bio = ""
    @State private var isSignedUp = false

    var body: some View {
        NavigationStack {
            KidNameView(firstName: $firstName, lastName: $lastName, email: email, password: password, age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp)
                .navigationDestination(isPresented: $isSignedUp) {
                    ContentView()
                }
        }
    }
}

// MARK: - Kid Signup Steps
struct KidNameView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let email: String
    let password: String
    @Binding var age: String
    @Binding var selectedInterests: [String]
    @Binding var bio: String
    @Binding var isSignedUp: Bool

    var body: some View {
        VStack {
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            NavigationLink("Next", destination: KidInterestsView(firstName: $firstName, lastName: $lastName, email: email, password: password, age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp))
        }
        .padding()
    }
}
// Kid Age Selection
struct KidAgeView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let email: String
    let password: String
    @Binding var age: String
    @Binding var selectedInterests: [String]
    @Binding var bio: String
    @Binding var isSignedUp: Bool

    var body: some View {
        VStack {
            Picker("Age", selection: $age) {
                ForEach(15...19, id: \.self) { age in
                    Text("\(age)").tag("\(age)")
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
                        var userData: [String: Any] = [
                            "uid": user.uid,
                            "email": email,
                            "firstName": firstName,
                            "lastName": lastName,
                            "username": username,
                            "age": age,
                            "selectedInterests": selectedInterests,
                            "role": "Kid",
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


    // Helper function to upload images
    func uploadImage(_ image: UIImage?, path: String, completion: @escaping (String?) -> Void) {
        guard let image = image, let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        completion(url?.absoluteString)
                    }
                }
            }
        }
    }



// Kid Interests Selection
struct KidInterestsView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let email: String
    let password: String
    @Binding var age: String
    @Binding var selectedInterests: [String]
    @Binding var bio: String
    @Binding var isSignedUp: Bool
    let allInterests = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports"]

    var body: some View {
        VStack {
            Text("Select Your Interests")
                .font(.title2)
                .padding()

            List(allInterests, id: \.self) { interest in
                HStack {
                    Text(interest)
                    Spacer()
                    if selectedInterests.contains(interest) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .onTapGesture {
                    if let index = selectedInterests.firstIndex(of: interest) {
                        selectedInterests.remove(at: index)
                    } else {
                        selectedInterests.append(interest)
                    }
                }
                .padding()
            }


            NavigationLink("Next", destination: KidAgeView(firstName: $firstName, lastName: $lastName, email: email, password: password,age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp))
            
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
}
