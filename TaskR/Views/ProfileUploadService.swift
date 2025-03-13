//
//  ProfileUploadService.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/29/25.
//


import FirebaseStorage
import FirebaseFirestore
import UIKit

class ProfileUploadService {
    static let shared = ProfileUploadService()
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func uploadProfileImage(_ image: UIImage, userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "ProfileUploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        // Create a storage reference
        let storageRef = storage.reference().child("profile_photos/\(userID).jpg")
        
        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the image
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Error uploading profile image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Error getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "ProfileUploadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                // Update the user's profile with the new profile image URL
                self.db.collection("users").document(userID).updateData([
                    "profileImageURL": downloadURL.absoluteString
                ]) { error in
                    if let error = error {
                        print("❌ Error updating user profile: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("✅ Profile image uploaded and profile updated successfully")
                        completion(.success(downloadURL.absoluteString))
                    }
                }
            }
        }
        
        // Optional: Add observer for upload progress
        uploadTask.observe(.progress) { snapshot in
            // Calculate progress
            let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Upload progress: \(percentComplete * 100)%")
        }
    }
    
    func deleteProfileImage(userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference().child("profile_photos/\(userID).jpg")
        
        // Delete from storage
        storageRef.delete { error in
            if let error = error {
                print("❌ Error deleting profile image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Remove the image URL from the user's profile
            self.db.collection("users").document(userID).updateData([
                "profileImageURL": FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("❌ Error updating user profile: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("✅ Profile image deleted successfully")
                    completion(.success(()))
                }
            }
        }
    }
}