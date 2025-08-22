//
//  UserRatingView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 4/22/25.
//



import SwiftUI
import FirebaseAuth

struct UserRatingView: View {
    let userID: String
    let taskID: String
    let username: String
    let isCreator: Bool // True if we're rating the task creator, false if rating an assignee
    
    @State private var selectedRating: Int = 0
    @State private var isRatingComplete = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentAverageRating: Double = 0
    @State private var totalRatings: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Rate \(isCreator ? "Task Creator" : "Helper")")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(username)
                .font(.headline)
            
            // Existing rating display
            if totalRatings > 0 {
                VStack(spacing: 5) {
                    Text("Current Rating")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        StarRatingView(
                            rating: currentAverageRating,
                            maxRating: 5,
                            size: 16,
                            color: .yellow
                        )
                        
                        Text("(\(totalRatings) ratings)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 10)
            }
            
            // Rating instruction
            if !isRatingComplete {
                Text("How would you rate your experience?")
                    .font(.headline)
                    .padding(.top, 10)
                
                // Interactive star rating
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(star <= selectedRating ? .yellow : .gray)
                            .onTapGesture {
                                selectedRating = star
                            }
                    }
                }
                .padding()
                
                // Submit button
                Button(action: submitRating) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Submit Rating")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(selectedRating > 0 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(selectedRating == 0 || isSubmitting)
                .padding(.horizontal)
                .padding(.top, 20)
            } else {
                // Rating submitted view
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Rating Submitted")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Thank you for your feedback!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .onAppear {
            fetchCurrentRating()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Rating Status"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func fetchCurrentRating() {
        TaskService.shared.getUserRating(userID: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ratingData):
                    self.currentAverageRating = ratingData.0
                    self.totalRatings = ratingData.1
                case .failure(let error):
                    print("Error fetching user rating: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func submitRating() {
        guard selectedRating > 0 else { return }
        
        // Simple validation to prevent self-rating
        guard let currentUserID = Auth.auth().currentUser?.uid, currentUserID != userID else {
            showAlert(message: "You cannot rate yourself")
            return
        }
        
        isSubmitting = true
        
        let rating = Double(selectedRating)
        TaskService.shared.rateUser(userID: userID, taskID: taskID, rating: rating) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success:
                    isRatingComplete = true
                    selectedRating = 0
                    // Refresh the current rating
                    fetchCurrentRating()
                    
                case .failure(let error):
                    showAlert(message: "Failed to submit rating: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// Extension to use in task completion view
extension UserRatingView {
    static func forTaskCreator(task: Task) -> some View {
        UserRatingView(
            userID: task.creatorID,
            taskID: task.id,
            username: task.creatorUsername,
            isCreator: true
        )
    }
    
    static func forAssignee(task: Task, assignee: Assignee) -> some View {
        UserRatingView(
            userID: assignee.userID,
            taskID: task.id,
            username: assignee.username,
            isCreator: false
        )
    }
}

// Task Completion View (to show after a task is finished)
struct TaskCompletionView: View {
    let task: Task
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Task completion header
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                        
                        Text("Task Completed!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(task.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3))
                    
                    // Determine if we're showing rating for creator or assignees
                    if isCurrentUserCreator {
                        rateAssigneesSection
                    } else {
                        rateCreatorSection
                    }
                }
                .padding()
            }
            .navigationBarTitle("Task Complete", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private var isCurrentUserCreator: Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        return currentUserID == task.creatorID
    }
    
    private var rateCreatorSection: some View {
        VStack(spacing: 20) {
            Text("Rate the Task Creator")
                .font(.headline)
            
            UserRatingView.forTaskCreator(task: task)
        }
    }
    
    private var rateAssigneesSection: some View {
        VStack(spacing: 20) {
            Text("Rate the Helpers")
                .font(.headline)
            
            // Only show approved assignees
            ForEach(task.assignees.filter { $0.approved }, id: \.id) { assignee in
                VStack {
                    UserRatingView.forAssignee(task: task, assignee: assignee)
                    
                    if assignee.id != task.assignees.filter({ $0.approved }).last?.id {
                        Divider()
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }
}
