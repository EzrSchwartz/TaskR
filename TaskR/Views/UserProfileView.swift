//
//  UserProfileView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/29/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct AdultUserProfileView: View {
    // If userID is not provided, show the current user's profile
    let userID: String?
    let isEditable: Bool
    let onComplete: (() -> Void)?
    
    @State private var profile: UserProfile?
    @State private var averageRating: Double = 0.0
    @State private var totalRatings: Int = 0
    @State private var isLoading = true
    @State private var showingEditView = false
    @State private var profileImage: UIImage?
    @State private var imageLoading = true
    @State private var errorMessage: String?
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePickerOptions = false
    @State private var uploadingImage = false
    @State var showingDeleteConfirmation = false
    @State private var showReportSheet = false

    // For edit mode
    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var editBio = ""
    @State private var editInterests: [String] = []
    
    init(userID: String? = nil, isEditable: Bool = false, onComplete: (() -> Void)? = nil) {
        self.userID = userID
        self.isEditable = isEditable
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            content
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProfile()
        }
        .sheet(isPresented: $showingEditView) {
            EditProfileView(
                originalProfile: profile,
                firstName: $editFirstName,
                lastName: $editLastName,
                bio: $editBio,
                interests: $editInterests,
                onSave: updateProfile
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                .onDisappear {
                    if let image = selectedImage {
                        uploadProfileImage(image)
                    }
                }
        }
        .actionSheet(isPresented: $showingImagePickerOptions) {
            ActionSheet(
                title: Text("Change Profile Picture"),
                buttons: [
                    .default(Text("Choose from Library")) {
                        showingImagePicker = true
                    },
                    .destructive(Text("Remove Photo")) {
                        removeProfilePhoto()
                    },
                    .cancel()
                ]
            )
        }
    }

    // Break up the content into smaller computed properties
    private var content: some View {
        Group {
            if isLoading {
                loadingView
            } else if let profile = profile {
                profileContentView(profile)
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else {
                Text("Could not load profile")
                    .foregroundColor(.gray)
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading profile...")
    }

    private func errorView(_ message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()
            
            Text("Error Loading Profile")
                .font(.headline)
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Try Again") {
                loadProfile()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    
    
    private func profileContentView(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Profile Picture
                profileImageView(profile)

                // Name and age
                nameAndAgeView(profile)

                // Ratings
                ratingsView

                Divider()
                    .padding(.horizontal)

                // Bio Section
                bioSectionView(profile)

                Divider()
                    .padding(.horizontal)

                // Interests Section (assuming it's here)
                // interestsSectionView(profile) // Add your interests view here if you have one

                if isEditable {
                    editButton
                }

                Spacer(minLength: 40)
                Divider()
                    .padding(.horizontal)
                // --Report+Block--
                Button("Report or Block Users") {
                            showReportSheet = true
                        }
                        .sheet(isPresented: $showReportSheet) {
                            ReportUserView()
                        }
                Divider()
                    .padding(.horizontal)
                // --- Delete Account Button ---
                Button("Delete Account") {
                    // Action to perform when the button is tapped
                    // Typically, you'd show a confirmation alert first
                    showingDeleteConfirmation = true // Make sure you have @State var showingDeleteConfirmation
                }
                .foregroundColor(.red) // Text color
                .padding(.horizontal, 25) // Horizontal padding
                .padding(.vertical, 12) // Vertical padding
                .background(
                    RoundedRectangle(cornerRadius: 15) // Rounded rectangle background
                        .stroke(Color.red, lineWidth: 2) // Red border
                )
                .padding(.top, 30) // Add some space above the button
            }
            .padding(.bottom, 20)
        }
        // --- Confirmation Alert ---
        .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // Call your Firebase deletion logic here
                // This assumes deletionManager is accessible (e.g., as @StateObject or from environment)
                // You should also handle errors and UI updates after deletion
                AccountDeletionManager().deleteAccount() { error in
                    if let error = error {
                        print("Error deleting account: \(error.localizedDescription)")
                        // Present an error alert to the user
                    } else {
                        print("Account successfully deleted.")
                        // Navigate user to login screen or handle success
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Do nothing, alert dismissed
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
    
//
    private func profileImageView(_ profile: UserProfile) -> some View {
        ZStack {
            if imageLoading {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                ProgressView()
            } else if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            } else {
                // Default profile image
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
            }
            
            if isEditable {
                editPhotoButton
            }
        }
        .padding(.top, 20)
    }

    private var editPhotoButton: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 30, height: 30)
            .overlay(
                Group {
                    if uploadingImage {
                        ProgressView()
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                }
            )
            .offset(x: 40, y: 40)
            .onTapGesture {
                showingImagePickerOptions = true
            }
            .disabled(uploadingImage)
    }

    private func nameAndAgeView(_ profile: UserProfile) -> some View {
        VStack {
            Text("\(profile.firstName) \(profile.lastName)")
                .font(.title2)
                .bold()
            
            if profile.isKid, let age = profile.age {
                Text("Age: \(age)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private var ratingsView: some View {
        HStack {
            StarRatingView(rating: averageRating, maxRating: 5, size: 24, color: .yellow)
            Text("(\(totalRatings) ratings)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.leading, 5)
        }
        .padding(.vertical, 5)
    }

    private func bioSectionView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.headline)
                .padding(.horizontal)
            
            Text(profile.bio.isEmpty ? "No bio provided" : profile.bio)
                .font(.body)
                .foregroundColor(profile.bio.isEmpty ? .gray : .primary)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func interestsSectionView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interests")
                .font(.headline)
                .padding(.horizontal)
            
            if profile.selectedInterests.isEmpty {
                Text("No interests listed")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                interestsListView(profile.selectedInterests)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func interestsListView(_ interests: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
        }
    }

    private var editButton: some View {
        Button(action: {
            showingEditView = true
        }) {
            Text("Edit Profile")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 20)
        }
    }
    private func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        let profileID = userID ?? Auth.auth().currentUser?.uid
        
        guard let userID = profileID else {
            isLoading = false
            errorMessage = "No user is logged in"
            return
        }
        
        UserService.shared.fetchUserProfile(userID: userID) { fetchedProfile in
            DispatchQueue.main.async {
                if let profile = fetchedProfile {
                    self.profile = profile
                    self.editFirstName = profile.firstName
                    self.editLastName = profile.lastName
                    self.editBio = profile.bio
                    self.editInterests = profile.selectedInterests
                    
                    // Load rating data
                    self.loadRatingData(userID: userID)
                    
                    // Load profile image if available
                    self.loadProfileImage(userID: userID)
                } else {
                    self.errorMessage = "Failed to load profile information"
                }
                
                self.isLoading = false
            }
        }
    }
    
    private func loadRatingData(userID: String) {
        TaskService.shared.getUserRating(userID: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ratingData):
                    // Now we're getting the tuple with (rating, count)
                    self.averageRating = ratingData.0
                    self.totalRatings = ratingData.1
                    print("✅ Loaded rating: \(self.averageRating) from \(self.totalRatings) ratings")
                case .failure(let error):
                    print("❌ Error loading rating data: \(error.localizedDescription)")
                    self.averageRating = 0
                    self.totalRatings = 0
                }
            }
        }
    }
    
    private func loadProfileImage(userID: String) {
        imageLoading = true
        
        // First check if the user has a profileImageURL in Firestore
        Firestore.firestore().collection("users").document(userID).getDocument { snapshot, error in
            // Remove [weak self] since UserProfileView is a struct
            
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                self.tryLoadFromStorage(userID: userID)
                return
            }
            
            if let data = snapshot?.data(),
               let profileImageURL = data["profileImageURL"] as? String,
               let url = URL(string: profileImageURL) {
                
                // Load image from URL
                URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        self.imageLoading = false
                        
                        if let error = error {
                            print("Error loading profile image from URL: \(error.localizedDescription)")
                            self.profileImage = nil
                            return
                        }
                        
                        if let data = data, let image = UIImage(data: data) {
                            self.profileImage = image
                        } else {
                            self.profileImage = nil
                        }
                    }
                }.resume()
            } else {
                // No profile image URL, try to load directly from Storage
                self.tryLoadFromStorage(userID: userID)
            }
        }
    }

    private func tryLoadFromStorage(userID: String) {
        let storageRef = Storage.storage().reference()
        let profileRef = storageRef.child("profile_photos/\(userID).jpg")
        
        profileRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            // Remove [weak self] here as well
            
            DispatchQueue.main.async {
                self.imageLoading = false
                
                if let error = error {
                    print("Error loading profile image from storage: \(error.localizedDescription)")
                    self.profileImage = nil
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    self.profileImage = image
                } else {
                    self.profileImage = nil
                }
            }
        }
    }
    
    private func updateProfile() {
        guard let profile = profile, 
              let userID = Auth.auth().currentUser?.uid, 
              userID == profile.id else {
            return
        }
        
        isLoading = true
        
        // Create an updated map with the fields we want to update
        let updates: [String: Any] = [
            "firstName": editFirstName,
            "lastName": editLastName,
            "bio": editBio,
            "interests": editInterests
        ]
        
        Firestore.firestore().collection("users").document(userID).updateData(updates) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                    self.errorMessage = "Failed to update profile"
                } else {
                    // Update successful, refresh profile
                    self.loadProfile()
                    self.showingEditView = false
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        uploadingImage = true
        
        ProfileUploadService.shared.uploadProfileImage(image, userID: userID) { result in
            DispatchQueue.main.async {
                self.uploadingImage = false
                
                switch result {
                case .success:
                    // Update the UI with the new image
                    self.profileImage = image
                    self.selectedImage = nil
                    
                case .failure(let error):
                    print("Error uploading profile image: \(error.localizedDescription)")
                    self.errorMessage = "Failed to upload profile image"
                }
            }
        }
    }
    
    private func removeProfilePhoto() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        uploadingImage = true
        
        ProfileUploadService.shared.deleteProfileImage(userID: userID) { result in
            DispatchQueue.main.async {
                self.uploadingImage = false
                
                switch result {
                case .success:
                    // Clear the profile image
                    self.profileImage = nil
                    
                case .failure(let error):
                    print("Error removing profile image: \(error.localizedDescription)")
                    self.errorMessage = "Failed to remove profile image"
                }
            }
        }
    }
}


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage // Assuming you use Firebase Storage for images

// Make sure your AccountDeletionManager is defined somewhere accessible, e.g., in its own file
// class AccountDeletionManager: ObservableObject { /* ... (code from previous response) ... */ }

struct KidUserProfileView: View {
    // If userID is not provided, show the current user's profile
    let userID: String?
    let isEditable: Bool
    let onComplete: (() -> Void)?

    @State private var profile: UserProfile?
    @State private var averageRating: Double = 0.0
    @State private var totalRatings: Int = 0
    @State private var isLoading = true
    @State private var showingEditView = false
    @State private var profileImage: UIImage?
    @State private var imageLoading = true
    @State private var errorMessage: String?
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePickerOptions = false
    @State private var uploadingImage = false
    // For edit mode
    @State private var showReportSheet = false

    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var editBio = ""
    @State private var editInterests: [String] = []

    // MARK: - New State for Account Deletion
    @State private var showingDeleteConfirmation = false // Controls delete alert visibility
    @State private var showingDeletionSuccessAlert = false // To show success message
    @State private var deletionErrorMessage: String? // To show specific deletion error

    // MARK: - AccountDeletionManager
    // This should be an @StateObject or @EnvironmentObject in your view
    @StateObject private var deletionManager = AccountDeletionManager()


    init(userID: String? = nil, isEditable: Bool = false, onComplete: (() -> Void)? = nil) {
        self.userID = userID
        self.isEditable = isEditable
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            content
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProfile()
        }
        .sheet(isPresented: $showingEditView) {
            EditProfileView(
                originalProfile: profile,
                firstName: $editFirstName,
                lastName: $editLastName,
                bio: $editBio,
                interests: $editInterests,
                onSave: updateProfile
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                .onDisappear {
                    if let image = selectedImage {
                        uploadProfileImage(image)
                    }
                }
        }
        .actionSheet(isPresented: $showingImagePickerOptions) {
            ActionSheet(
                title: Text("Change Profile Picture"),
                buttons: [
                    .default(Text("Choose from Library")) {
                        showingImagePicker = true
                    },
                    .destructive(Text("Remove Photo")) {
                        removeProfilePhoto()
                    },
                    .cancel()
                ]
            )
        }
        // MARK: - Delete Confirmation Alert Modifier
        .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                performAccountDeletion()
            }
            Button("Cancel", role: .cancel) {
                // Do nothing, alert dismissed
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        // MARK: - Deletion Result Alert Modifier
        .alert("Account Deletion", isPresented: $showingDeletionSuccessAlert) {
            Button("OK") {
                // Perform actions after successful deletion (e.g., navigate to login)
                onComplete?() // Call the completion handler if provided
                // You might want to pop to root or present a new view here
                // For example:
                // self.presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(deletionErrorMessage ?? "Your account has been successfully deleted.")
        }
    }

    // Break up the content into smaller computed properties
    private var content: some View {
        Group {
            if isLoading {
                loadingView
            } else if let profile = profile {
                profileContentView(profile)
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else {
                Text("Could not load profile")
                    .foregroundColor(.gray)
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading profile...")
    }

    private func errorView(_ message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()

            Text("Error Loading Profile")
                .font(.headline)

            Text(message)
                .multilineTextAlignment(.center)
                .padding()

            Button("Try Again") {
                loadProfile()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    // MARK: - Modified profileContentView to include the Delete Button
    private func profileContentView(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Profile Picture
                profileImageView(profile)

                // Name and age
                nameAndAgeView(profile)

                // Ratings
                ratingsView

                Divider()
                    .padding(.horizontal)

                // Bio Section
                bioSectionView(profile)

                Divider()
                    .padding(.horizontal)

                // Interests Section
                interestsSectionView(profile)

                if isEditable {
                    editButton
                }

                Spacer(minLength: 40) // Increased spacer for button placement
                    .padding(.horizontal)
                // --Report+Block--
                Button("Report or Block Users") {
                            showReportSheet = true
                        }
                        .sheet(isPresented: $showReportSheet) {
                            ReportUserView()
                        }
                Divider()
                // --- Delete Account Button ---
                // Only show if the profile is editable (i.e., it's the current user's profile)
                Button("Delete Account") {
                    // Action to perform when the button is tapped
                    // Typically, you'd show a confirmation alert first
                    showingDeleteConfirmation = true // Make sure you have @State var showingDeleteConfirmation
                }
                .foregroundColor(.red) // Text color
                .padding(.horizontal, 25) // Horizontal padding
                .padding(.vertical, 12) // Vertical padding
                .background(
                    RoundedRectangle(cornerRadius: 15) // Rounded rectangle background
                        .stroke(Color.red, lineWidth: 2) // Red border
                )
                .padding(.top, 30) // Add some space above the button
            }
            .padding(.bottom, 20)
        }
        // --- Confirmation Alert ---
        .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // Call your Firebase deletion logic here
                // This assumes deletionManager is accessible (e.g., as @StateObject or from environment)
                // You should also handle errors and UI updates after deletion
                AccountDeletionManager().deleteAccount() { error in
                    if let error = error {
                        print("Error deleting account: \(error.localizedDescription)")
                        // Present an error alert to the user
                    } else {
                        print("Account successfully deleted.")
                        // Navigate user to login screen or handle success
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Do nothing, alert dismissed
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }

    private func profileImageView(_ profile: UserProfile) -> some View {
        ZStack {
            if imageLoading {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                ProgressView()
            } else if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            } else {
                // Default profile image
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
            }

            if isEditable {
                editPhotoButton
            }
        }
        .padding(.top, 20)
    }

    private var editPhotoButton: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 30, height: 30)
            .overlay(
                Group {
                    if uploadingImage {
                        ProgressView()
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                }
            )
            .offset(x: 40, y: 40)
            .onTapGesture {
                showingImagePickerOptions = true
            }
            .disabled(uploadingImage)
    }

    private func nameAndAgeView(_ profile: UserProfile) -> some View {
        VStack {
            Text("\(profile.firstName) \(profile.lastName)")
                .font(.title2)
                .bold()

            if profile.isKid, let age = profile.age {
                Text("Age: \(age)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private var ratingsView: some View {
        HStack {
            StarRatingView(rating: averageRating, maxRating: 5, size: 24, color: .yellow)
            Text("(\(totalRatings) ratings)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.leading, 5)
        }
        .padding(.vertical, 5)
    }

    private func bioSectionView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.headline)
                .padding(.horizontal)

            Text(profile.bio.isEmpty ? "No bio provided" : profile.bio)
                .font(.body)
                .foregroundColor(profile.bio.isEmpty ? .gray : .primary)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func interestsSectionView(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interests")
                .font(.headline)
                .padding(.horizontal)

            if profile.selectedInterests.isEmpty {
                Text("No interests listed")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                interestsListView(profile.selectedInterests)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func interestsListView(_ interests: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
        }
    }

    private var editButton: some View {
        Button(action: {
            showingEditView = true
        }) {
            Text("Edit Profile")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 20)
        }
    }

    // MARK: - Firebase Interaction Methods

    private func loadProfile() {
        isLoading = true
        errorMessage = nil

        let profileID = userID ?? Auth.auth().currentUser?.uid

        guard let userID = profileID else {
            isLoading = false
            errorMessage = "No user is logged in"
            return
        }

        UserService.shared.fetchUserProfile(userID: userID) { fetchedProfile in
            DispatchQueue.main.async {
                if let profile = fetchedProfile {
                    self.profile = profile
                    self.editFirstName = profile.firstName
                    self.editLastName = profile.lastName
                    self.editBio = profile.bio
                    self.editInterests = profile.selectedInterests

                    // Load rating data
                    self.loadRatingData(userID: userID)

                    // Load profile image if available
                    self.loadProfileImage(userID: userID)
                } else {
                    self.errorMessage = "Failed to load profile information"
                }

                self.isLoading = false
            }
        }
    }

    private func loadRatingData(userID: String) {
        TaskService.shared.getUserRating(userID: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ratingData):
                    self.averageRating = ratingData.0
                    self.totalRatings = ratingData.1
                    print("✅ Loaded rating: \(self.averageRating) from \(self.totalRatings) ratings")
                case .failure(let error):
                    print("❌ Error loading rating data: \(error.localizedDescription)")
                    self.averageRating = 0
                    self.totalRatings = 0
                }
            }
        }
    }

    private func loadProfileImage(userID: String) {
        imageLoading = true

        Firestore.firestore().collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                self.tryLoadFromStorage(userID: userID)
                return
            }

            if let data = snapshot?.data(),
               let profileImageURL = data["profileImageURL"] as? String,
               let url = URL(string: profileImageURL) {

                URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        self.imageLoading = false

                        if let error = error {
                            print("Error loading profile image from URL: \(error.localizedDescription)")
                            self.profileImage = nil
                            return
                        }

                        if let data = data, let image = UIImage(data: data) {
                            self.profileImage = image
                        } else {
                            self.profileImage = nil
                        }
                    }
                }.resume()
            } else {
                self.tryLoadFromStorage(userID: userID)
            }
        }
    }

    private func tryLoadFromStorage(userID: String) {
        let storageRef = Storage.storage().reference()
        let profileRef = storageRef.child("profile_photos/\(userID).jpg")

        profileRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                self.imageLoading = false

                if let error = error {
                    print("Error loading profile image from storage: \(error.localizedDescription)")
                    self.profileImage = nil
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    self.profileImage = image
                } else {
                    self.profileImage = nil
                }
            }
        }
    }

    private func updateProfile() {
        guard let profile = profile,
              let userID = Auth.auth().currentUser?.uid,
              userID == profile.id else {
            return
        }

        isLoading = true

        let updates: [String: Any] = [
            "firstName": editFirstName,
            "lastName": editLastName,
            "bio": editBio,
            "interests": editInterests
        ]

        Firestore.firestore().collection("users").document(userID).updateData(updates) { error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                    self.errorMessage = "Failed to update profile"
                } else {
                    self.loadProfile()
                    self.showingEditView = false
                }
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }

        uploadingImage = true

        ProfileUploadService.shared.uploadProfileImage(image, userID: userID) { result in
            DispatchQueue.main.async {
                self.uploadingImage = false

                switch result {
                case .success:
                    self.profileImage = image
                    self.selectedImage = nil

                case .failure(let error):
                    print("Error uploading profile image: \(error.localizedDescription)")
                    self.errorMessage = "Failed to upload profile image"
                }
            }
        }
    }

    private func removeProfilePhoto() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }

        uploadingImage = true

        ProfileUploadService.shared.deleteProfileImage(userID: userID) { result in
            DispatchQueue.main.async {
                self.uploadingImage = false

                switch result {
                case .success:
                    self.profileImage = nil

                case .failure(let error):
                    print("Error removing profile image: \(error.localizedDescription)")
                    self.errorMessage = "Failed to remove profile image"
                }
            }
        }
    }

    // MARK: - Account Deletion Logic
        private func performAccountDeletion() {
            // Show loading state if applicable (e.g., disable UI, show spinner)
            isLoading = true // Re-use existing loading state for now

            deletionManager.deleteAccount { error in // <--- Corrected this line
                // Use DispatchQueue.main.async to update UI, as the completion handler
                // from Firebase might not be on the main thread.
                DispatchQueue.main.async {
//                    guard let self = self else { return } // Safely unwrap self

                    self.isLoading = false // End loading state

                    if let error = error {
                        print("Account deletion failed: \(error.localizedDescription)")
                        self.deletionErrorMessage = "There was an issue deleting your account: \(error.localizedDescription). Please try again."

                        // Handle re-authentication specifically if needed
                        if let authErrorCode = AuthErrorCode(rawValue: error._code), authErrorCode == .requiresRecentLogin {
                             self.deletionErrorMessage = "Authentication required. Please sign in again recently to delete your account."
                             // You might want to trigger a re-authentication flow here (e.g., navigate to a login screen)
                        }
                        self.showingDeletionSuccessAlert = true // Use this to show the error message too
                    } else {
                        print("Account successfully deleted. Navigating away.")
                        self.deletionErrorMessage = nil // Clear any previous error message
                        self.showingDeletionSuccessAlert = true // Show success alert
                        // The navigation away will happen in the completion handler of the alert
                    }
                }
            }
        }
    }


// MARK: - Edit Profile View
struct EditProfileView: View {
    let originalProfile: UserProfile?
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var bio: String
    @Binding var interests: [String]
    
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // For interest selection
    @State private var newInterest = ""
    let allInterests = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                
                Section(header: Text("About")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Interests")) {
                    ForEach(interests, id: \.self) { interest in
                        HStack {
                            Text(interest)
                            Spacer()
                            Button(action: {
                                if let index = interests.firstIndex(of: interest) {
                                    interests.remove(at: index)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Picker("Add Interest", selection: $newInterest) {
                        Text("Select an interest").tag("")
                        ForEach(allInterests.filter { !interests.contains($0) }, id: \.self) { interest in
                            Text(interest).tag(interest)
                        }
                    }
                    
                    if !newInterest.isEmpty {
                        Button("Add \(newInterest)") {
                            interests.append(newInterest)
                            newInterest = ""
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views for Ratings

// View to show and collect ratings
struct RatingInputView: View {
    let userID: String
    let taskID: String
    @State private var rating: Int = 0
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How would you rate this user's work?")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 30))
                        .foregroundColor(star <= rating ? .yellow : .gray)
                        .onTapGesture {
                            rating = star
                        }
                }
            }
            .padding()
            
            Button(action: submitRating) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Submit Rating")
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(rating == 0 ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(rating == 0 || isSubmitting)
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Thank You"),
                message: Text("Your rating has been submitted."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func submitRating() {
        isSubmitting = true
        
        TaskService.shared.rateUser(
            userID: userID,
            taskID: taskID,
            rating: Double(rating)
        ) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success:
                    showConfirmation = true
                case .failure:
                    // Handle error
                    break
                }
            }
        }
    }
}




class AccountDeletionManager : ObservableObject{
    
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let authenticated = false
    // MARK: - Public Methods
    
    /// Deletes the current user's document from Firestore and then deletes the user from Firebase Authentication.
    /// - Parameter completion: A closure that is called when the deletion process is complete.
    ///   It takes an optional Error object. If nil, the deletion was successful.
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        
        // 1. Get the current authenticated user
        guard let user = auth.currentUser else {
            print("Error: No authenticated user found.")
            completion(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."]))
            return
        }
        
        let userId = user.uid
        print("Attempting to delete account for user ID: \(userId)")
        
        // 2. Define the path to the user's document in Firestore
        //    Adjust "users" and "profile" to match your actual Firestore collection structure.
        //    Example: /artifacts/{appId}/users/{userId}/profile
        let userDocumentRef = db.collection("users").document(userId) // Assuming a 'profile' subcollection with a 'userProfile' document


        // 3. Delete the user's document from Firestore
        userDocumentRef.delete { error in
            if let error = error {
                print("Error deleting user document from Firestore: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            print("User document successfully deleted from Firestore.")
            
            // 4. Delete the user from Firebase Authentication
            user.delete { authError in
                if let authError = authError {
                    print("Error deleting user from Firebase Auth: \(authError.localizedDescription)")
                    completion(authError)
                    return
                }
                
                print("User successfully deleted from Firebase Authentication.")
                completion(nil) // Indicate success
            }
        }
    }
}
