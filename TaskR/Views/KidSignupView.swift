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

