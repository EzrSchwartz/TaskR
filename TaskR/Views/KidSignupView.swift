////
////  KidSignupView.swift
////  TaskR
////
////  Created by Ezra Schwartz on 3/10/25.
////
///
///

//
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


// MARK: - Kid Signup Flow
struct KidSignupView: View {
    let email: String
    let password: String
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = "15"
    @State private var selectedInterests: [String] = []
    @State private var bio = ""
    @Binding var isAuthenticated: Bool

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
                    // Interests View
                    InterestsSelectionView(selectedInterests: $selectedInterests)
                } else if currentStep == 3 {
                    // Bio View
                    BioInputView(bio: $bio)
                } else if currentStep == 4 {
                    // Age View
                    AgeSelectionView(age: $age)
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
                    
                    if currentStep < 4 {
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
            .navigationTitle("Kid Signup")
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
                    "age": age,
                    "selectedInterests": selectedInterests,
                    "bio": bio,
                    "role": "Kid",
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

// Helper Views
struct InterestsSelectionView: View {
    @Binding var selectedInterests: [String]
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
                .padding(.vertical, 4)
            }
        }
    }
}

struct BioInputView: View {
    @Binding var bio: String
    @FocusState private var isBioFocused: Bool
    
    var body: some View {
        VStack {
            Text("Tell Us About Yourself")
                .font(.title2)
                .padding()
            
            Text("Write a short bio that describes who you are and what you like to do")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
            
            TextEditor(text: $bio)
                .padding()
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                .focused($isBioFocused)
            
            Text("\(bio.count)/300 characters")
                .font(.caption)
                .foregroundColor(bio.count > 300 ? .red : .gray)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isBioFocused = true
            }
        }
    }
}

struct AgeSelectionView: View {
    @Binding var age: String
    
    var body: some View {
        VStack {
            Text("Select Your Age")
                .font(.title2)
                .padding()
            
            Picker("Age", selection: $age) {
                ForEach(15...19, id: \.self) { ageValue in
                    Text("\(ageValue)").tag("\(ageValue)")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
        }
    }
}


////// MARK: - Kid Signup Flow
////struct KidSignupView: View {
////    let email: String
////    let password: String
////    @State private var username = ""
////    @State private var firstName = ""
////    @State private var lastName = ""
////    @State private var age = "15"
////    @State private var selectedInterests: [String] = []
////    @State private var bio = ""
////    @State private var isSignedUp = false
////
////    var body: some View {
////        NavigationStack {
////            KidNameView(firstName: $firstName, lastName: $lastName, email: email, password: password, age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp)
////                .navigationDestination(isPresented: $isSignedUp) {
////                    ContentView()
////                }
////        }
////    }
////}
//// MARK: - Kid Signup Flow
//struct KidSignupView: View {
//    let email: String
//    let password: String
//    @Environment(\.dismiss) private var dismiss
//    @State private var username = ""
//    @State private var firstName = ""
//    @State private var lastName = ""
//    @State private var age = "15"
//    @State private var selectedInterests: [String] = []
//    @State private var bio = ""
//    @State private var isSignedUp = false
//    @Binding var isAuthenticated: Bool
//
//    var body: some View {
//        NavigationStack {
//            KidNameView(
//                firstName: $firstName,
//                lastName: $lastName,
//                email: email,
//                password: password,
//                age: $age,
//                selectedInterests: $selectedInterests,
//                bio: $bio,
//                isSignedUp: $isSignedUp,
//                isAuthenticated: $isAuthenticated,
//                rootDismiss: dismiss
//            )
//        }
//    }
//}
//
//
////MARK: - Kid Name View
//
//struct KidNameView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var age: String
//    @Binding var selectedInterests: [String]
//    @Binding var bio: String
//    @Binding var isSignedUp: Bool
//    @Binding var isAuthenticated: Bool
//    let rootDismiss: DismissAction
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
//            NavigationLink {
//                KidInterestsView(
//                    firstName: $firstName,
//                    lastName: $lastName,
//                    email: email,
//                    password: password,
//                    age: $age,
//                    selectedInterests: $selectedInterests,
//                    bio: $bio,
//                    isSignedUp: $isSignedUp,
//                    isAuthenticated: $isAuthenticated,
//                    rootDismiss: rootDismiss
//                )
//            } label: {
//                Text("Next")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .padding()
//        }
//        .padding()
//    }
//}
//
//// MARK: - Kid Age View
//
//struct KidAgeView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var age: String
//    @Binding var selectedInterests: [String]
//    @Binding var bio: String
//    @Binding var isSignedUp: Bool
//    @Binding var isAuthenticated: Bool
//    let rootDismiss: DismissAction
//
//    var body: some View {
//        VStack {
//            Picker("Age", selection: $age) {
//                ForEach(15...19, id: \.self) { age in
//                    Text("\(age)").tag("\(age)")
//                }
//            }
//            .pickerStyle(WheelPickerStyle())
//            .padding()
//
//            Button("Complete Signup") {
//                registerUser()
//            }
//            .padding()
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//        }
//        .padding()
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
//                // Prepare user data for Firestore
//                let userData: [String: Any] = [
//                    "uid": user.uid,
//                    "email": email,
//                    "firstName": firstName,
//                    "lastName": lastName,
//                    "username": username,
//                    "age": age,
//                    "selectedInterests": selectedInterests,
//                    "role": "Kid",
//                    "timestamp": Timestamp()
//                ]
//                
//                let db = Firestore.firestore()
//                db.collection("users").document(user.uid).setData(userData) { error in
//                    if let error = error {
//                        print("Error saving user data: \(error.localizedDescription)")
//                    } else {
//                        print("User data saved successfully!")
//
//                        // IMPORTANT: Dismiss first, then set isAuthenticated
//                        DispatchQueue.main.async {
//                            rootDismiss()
//                            
//                            // Give time for dismiss to complete, then authenticate
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
//// Kid Age Selection
////struct KidAgeView: View {
////    @Binding var firstName: String
////    @Binding var lastName: String
////    let email: String
////    let password: String
////    @Binding var age: String
////    @Binding var selectedInterests: [String]
////    @Binding var bio: String
////    @Binding var isSignedUp: Bool
////
////    var body: some View {
////        VStack {
////            Picker("Age", selection: $age) {
////                ForEach(15...19, id: \.self) { age in
////                    Text("\(age)").tag("\(age)")
////                }
////            }
////            .pickerStyle(WheelPickerStyle())
////            .padding()
////
////        }
////        .padding()
////        Button("Complete Signup") {
////            registerUser()
////        }
////    }
////    
////    func registerUser() {
////        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
////            if let error = error {
////                print("Error creating user: \(error.localizedDescription)")
////            } else if let user = authResult?.user {
////                print("User created successfully! UID: \(user.uid)")
////                var username = firstName
////                username += lastName
////                
////                        // Prepare user data for Firestore
////                        let userData: [String: Any] = [
////                            "uid": user.uid,
////                            "email": email,
////                            "firstName": firstName,
////                            "lastName": lastName,
////                            "username": username,
////                            "age": age,
////                            "selectedInterests": selectedInterests,
////                            "role": "Kid",
////                            "timestamp": Timestamp()
////                        ]
////                        
////                        // Add age and town only if they are applicable
////
////                        let db = Firestore.firestore()
////                        db.collection("users").document(user.uid).setData(userData) { error in
////                            if let error = error {
////                                print("Error saving user data: \(error.localizedDescription)")
////                            } else {
////                                print("User data saved successfully!")
////
////                                // Set isSignedUp to true after successful signup and saving data
////                                isSignedUp = true
////                                
////                            }
////                        }
////                    }
////                }
////            }
////        }
//
//
//    // Helper function to upload images
//    func uploadImage(_ image: UIImage?, path: String, completion: @escaping (String?) -> Void) {
//        guard let image = image, let imageData = image.jpegData(compressionQuality: 0.75) else {
//            completion(nil)
//            return
//        }
//        
//        let storageRef = Storage.storage().reference().child(path)
//        let metadata = StorageMetadata()
//        metadata.contentType = "image/jpeg"
//        
//        storageRef.putData(imageData, metadata: metadata) { _, error in
//            if let error = error {
//                print("Error uploading image: \(error.localizedDescription)")
//                completion(nil)
//            } else {
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        print("Error getting download URL: \(error.localizedDescription)")
//                        completion(nil)
//                    } else {
//                        completion(url?.absoluteString)
//                    }
//                }
//            }
//        }
//    }
//
//
//// MARK: - Kid Interests View
//
//// Kid Interests Selection
//struct KidInterestsView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//
//    @Binding var age: String
//    @Binding var selectedInterests: [String]
//    @Binding var bio: String
//    @Binding var isSignedUp: Bool
//    @Binding var isAuthenticated: Bool
//    let rootDismiss: DismissAction
//    let allInterests = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports"]
//
//    var body: some View {
//        VStack {
//            Text("Select Your Interests")
//                .font(.title2)
//                .padding()
//
//            List(allInterests, id: \.self) { interest in
//                HStack {
//                    Text(interest)
//                    Spacer()
//                    if selectedInterests.contains(interest) {
//                        Image(systemName: "checkmark.circle.fill")
//                            .foregroundColor(.green)
//                    }
//                }
//                .onTapGesture {
//                    if let index = selectedInterests.firstIndex(of: interest) {
//                        selectedInterests.remove(at: index)
//                    } else {
//                        selectedInterests.append(interest)
//                    }
//                }
//                .padding()
//            }
//
//
//            NavigationLink("Next", destination: KidBioView(firstName: $firstName, lastName: $lastName, email: email, password: password,age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp, isAuthenticated: $isAuthenticated, rootDismiss: rootDismiss))
//            
//            .padding()
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//        }
//        .padding()
//    }
//    
//}
//
//// MARK: - Kid BIO View
//
//// Kid Bio Input
//struct KidBioView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var age: String
//
//    @Binding var selectedInterests: [String]
//    @Binding var bio: String
//    @Binding var isSignedUp: Bool
//    @Binding var isAuthenticated: Bool
//    let rootDismiss: DismissAction
//    @FocusState private var isBioFocused: Bool
//    @State private var shouldNavigate = false
//    
//    var body: some View {
//        VStack {
//            Text("Tell Us About Yourself")
//                .font(.title2)
//                .padding()
//            
//            Text("Write a short bio that describes who you are and what you like to do")
//                .font(.subheadline)
//                .foregroundColor(.gray)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//                .padding(.bottom)
//                
//            // Bio text editor with a nice border
//            TextEditor(text: $bio)
//                .padding()
//                .frame(height: 200)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                )
//                .background(Color.gray.opacity(0.05))
//                .cornerRadius(8)
//                .padding(.horizontal)
//                .focused($isBioFocused)
//                .onSubmit {
//                    shouldNavigate = true
//                }
//            
//            Text("\(bio.count)/300 characters")
//                .font(.caption)
//                .foregroundColor(bio.count > 300 ? .red : .gray)
//                .padding(.top, 4)
//                .frame(maxWidth: .infinity, alignment: .trailing)
//                .padding(.horizontal)
//            
//            NavigationLink(destination: KidAgeView(firstName: $firstName, lastName: $lastName, email: email, password: password, age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp, isAuthenticated: $isAuthenticated, rootDismiss: rootDismiss), isActive: $shouldNavigate) {
//                EmptyView()
//            }
//            
//            Button(action: {
//                shouldNavigate = true
//            }) {
//                Text("Continue")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .padding()
//            .disabled(bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//            
//            Spacer()
//        }
//        .padding()
//        .onAppear {
//            // Focus the bio input when the view appears
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                isBioFocused = true
//            }
//        }
//        .navigationBarTitle("Your Bio", displayMode: .inline)
//    }
//}
