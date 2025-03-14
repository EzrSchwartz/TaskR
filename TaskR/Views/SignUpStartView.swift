import SwiftUI
import FirebaseAuth

// MARK: - Signup Entry (Email & Password)
struct SignupEntryView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack {
                Text("Create an Account")
                    .font(.title)
                    .bold()
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                NavigationLink(destination: SignupTypeSelectionView(email: email, password: password)) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
    }
}











//import SwiftUI
//import FirebaseStorage
//import FirebaseAuth
//import FirebaseFirestore
//import _PhotosUI_SwiftUI
//
//// MARK: - Signup Entry (Email & Password)
//struct SignupEntryView: View {
//    @State private var email = ""
//    @State private var password = ""
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Text("Create an Account")
//                    .font(.title)
//                    .bold()
//                    .padding()
//
//                TextField("Email", text: $email)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .autocapitalization(.none)
//                    .padding()
//
//                SecureField("Password", text: $password)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding()
//
//                NavigationLink(destination: SignupTypeSelectionView(email: email, password: password)) {
//                    Text("Next")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//
//                .padding()
//            }
//            .padding()
//        }
//    }
//}
//
//// MARK: - Signup Type Selection (Kid or Adult)
//struct SignupTypeSelectionView: View {
//    let email: String
//    let password: String
//    @State private var isKid: Bool? = nil
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Text("Are you signing up as a Kid or an Adult?")
//                    .font(.title2)
//                    .padding()
//
//                HStack {
//                    Button(action: { isKid = true }) {
//                        Text("Kid")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(isKid == true ? Color.green : Color.gray.opacity(0.2))
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//
//                    Button(action: { isKid = false }) {
//                        Text("Adult")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(isKid == false ? Color.blue : Color.gray.opacity(0.2))
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                }
//                .padding()
//
//                if let isKid = isKid {
//                    NavigationLink(destination: isKid ? AnyView(KidSignupView(email: email, password: password)) : AnyView(AdultSignupView(email: email, password: password))) {
//                        Text("Next")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .padding()
//                }
//            }
//            .padding()
//        }
//    }
//}
//
//// MARK: - Kid Signup Flow
//struct KidSignupView: View {
//    let email: String
//    let password: String
//    @State private var firstName = ""
//    @State private var lastName = ""
//    @State private var age = "15"
//    @State private var selectedInterests: [String] = []
//    @State private var bio = ""
//    @State private var isSignedUp = false
//
//    var body: some View {
//        NavigationStack {
//            KidNameView(firstName: $firstName, lastName: $lastName, email: email, password: password, age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp)
//                .navigationDestination(isPresented: $isSignedUp) {
//                    ContentView()
//                }
//        }
//    }
//}
//
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
//// MARK: - Kid Signup Steps
//struct KidNameView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var age: String
//    @Binding var selectedInterests: [String]
//    @Binding var bio: String
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
//            NavigationLink("Next", destination: KidAgeView(firstName: $firstName, lastName: $lastName, email: email, password: password, age: $age, selectedInterests: $selectedInterests, bio: $bio, isSignedUp: $isSignedUp))
//        }
//        .padding()
//    }
//}
//
//// Kid Age Selection
//struct KidAgeView: View {
//    @Binding var firstName: String
//    @Binding var lastName: String
//    let email: String
//    let password: String
//    @Binding var age: String
//    @Binding var selectedInterests: [String]
//    @Binding var bio: String
//    @Binding var isSignedUp: Bool
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
//    func registerUser() {
//        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
//            if let error = error {
//                print("Error creating user: \(error.localizedDescription)")
//            } else if let user = authResult?.user {
//                print("User created successfully! UID: \(user.uid)")
//
//                // ✅ Send Email Verification
//                user.sendEmailVerification { error in
//                    if let error = error {
//                        print("Error sending verification email: \(error.localizedDescription)")
//                    } else {
//                        print("Verification email sent! User must verify before logging in.")
//                    }
//                }
//
//                // Prepare user data
//                let userData: [String: Any] = [
//                    "uid": user.uid,
//                    "email": email,
//                    "firstName": firstName,
//                    "lastName": lastName,
//                    "role": "Kid",
//                    "age": age,
//                    "bio": bio,
//                    "timestamp": Timestamp(),
//                    "emailVerified": false // ✅ Store verification status
//                ]
//
//                // Save to Firestore
//                let db = Firestore.firestore()
//                db.collection("users").document(user.uid).setData(userData) { error in
//                    if let error = error {
//                        print("Error saving user data: \(error.localizedDescription)")
//                    } else {
//                        print("User data saved successfully!")
//                        isSignedUp = true // Navigate to ContentView
//                    }
//                }
//            }
//        }
//    }
//
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
//    
//    var body: some View {
//        VStack {
//            TextField("Enter Your Town", text: $town)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
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
//    
//    func registerUser() {
//        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
//            if let error = error {
//                print("Error creating user: \(error.localizedDescription)")
//            } else if let user = authResult?.user {
//                print("User created successfully! UID: \(user.uid)")
//                
//                // ✅ Send Email Verification
//                user.sendEmailVerification { error in
//                    if let error = error {
//                        print("Error sending verification email: \(error.localizedDescription)")
//                    } else {
//                        print("Verification email sent! User must verify before logging in.")
//                    }
//                }
//                uploadImage(profilePhoto, path: "profile_photos/\(user.uid).jpg") { profileURL in
//                    uploadImage(licenseImage, path: "license_images/\(user.uid).jpg") { licenseURL in
//                        // Prepare user data
//                        let userData: [String: Any] = [
//                            "uid": user.uid,
//                            "email": email,
//                            "firstName": firstName,
//                            "lastName": lastName,
//                            "role": "Adult",
//                            "town": town,
//                            "profilePhotoURL": profileURL ?? NSNull(),
//                            "licensePhotoURL": licenseURL ?? NSNull(),
//                            "timestamp": Timestamp(),
//                            "emailVerified": false // ✅ Store verification status
//                        ]
//                        
//                        // Save to Firestore
//                        let db = Firestore.firestore()
//                        db.collection("users").document(user.uid).setData(userData) { error in
//                            if let error = error {
//                                print("Error saving user data: \(error.localizedDescription)")
//                            } else {
//                                print("User data saved successfully!")
//                                isSignedUp = true // Navigate to ContentView
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        
//        
//        
//        
//    }
//    
//    // MARK: - Extra Stuff
//    
//    
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
//}
