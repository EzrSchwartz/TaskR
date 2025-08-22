////
////  AdultRatingView.swift
////  TaskR
////
////  Created by Ezra Schwartz on 4/22/25.
////
//

import SwiftUI
import FirebaseAuth

struct AdultRatingView: View {
    let task: Task
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var rating: Double = 0
    @State private var feedback: String = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Rate Your Experience")
                .font(.title2)
                .bold()
                .padding(.top)
            
            // Task info
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.headline)
                
                Text("Created by: \(task.creatorUsername)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Completed: \(formatDate(Date()))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Rating section
            VStack(spacing: 12) {
                Text("How would you rate working with this adult?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                
                // Star rating
                StarRatingView(
                    rating: rating,
                    maxRating: 5,
                    size: 36,
                    color: .yellow,
                    onTap: { value in
                        rating = Double(value)
                    }
                )
                .padding(.vertical, 12)
                
                // Feedback text area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Feedback (Optional)")
                        .font(.subheadline)
                    
                    TextEditor(text: $feedback)
                        .frame(height: 120)
                        .padding(8)
                        .background(AppColors.pearlWhite.opacity(0.7)) // Use pearlWhite
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
            }
            .padding()
            
            // Submit button
            Button(action: {
                showConfirmation = true
            }) {
                Text("Submit Rating")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(rating > 0 ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
            }
            .disabled(rating == 0 || isSubmitting)
            .padding(.horizontal, 40)
            .alert("Submit Rating", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit", role: .none) {
                    submitRating()
                }
            } message: {
                Text("Are you sure you want to submit your rating?")
            }
            
            // Skip button
            Button("Skip Rating") {
                onCancel()
            }
            .foregroundColor(.gray)
            .padding(.top, 8)
            
            if isSubmitting {
                ProgressView("Submitting rating...")
                    .padding()
            }
        }
        .frame(maxWidth: 500)
        .padding()
        .disabled(isSubmitting)
    }
    
    private func submitRating() {
        isSubmitting = true
        
        // Submit rating from kid to adult (task creator)
        TaskService.shared.rateUser(
            userID: task.creatorID,
            taskID: task.id,
            rating: rating,
            completion: { result in
                DispatchQueue.main.async {
                    isSubmitting = false
                    
                    switch result {
                    case .success:
                        onComplete()
                    case .failure(let error):
                        print("Error submitting rating: \(error.localizedDescription)")
                        // Even if there's an error, we proceed
                        onComplete()
                    }
                }
            }
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
