//
//  AssigneeRatingView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/29/25.
//

import SwiftUI
import FirebaseAuth

struct AssigneeRatingView: View {
    let task: Task
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var ratings: [String: Double] = [:]
    @State private var currentAssigneeIndex = 0
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    
    private var approvedAssignees: [Assignee] {
        task.assignees.filter { $0.approved }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Rate Your Helpers")
                .font(.title2)
                .bold()
                .padding(.top)
            
            if approvedAssignees.isEmpty {
                Text("No assignees to rate for this task")
                    .foregroundColor(.gray)
                    .padding()
                
                Button("Complete Task Without Ratings") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                if currentAssigneeIndex < approvedAssignees.count {
                    let assignee = approvedAssignees[currentAssigneeIndex]
                    
                    // Current assignee card
                    VStack(spacing: 12) {
                        Text(assignee.username)
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text("How would you rate their work?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Rating stars
                        // Using the existing StarRatingView component
StarRatingView(
                            rating: ratings[assignee.userID] ?? 0,
                            maxRating: 5,
                            size: 32,
                            color: .yellow,
                            onTap: { value in
                                ratings[assignee.userID] = Double(value)
                            }
                        )
                        .padding(.vertical, 12)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Text("\(currentAssigneeIndex + 1) of \(approvedAssignees.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentAssigneeIndex > 0 {
                            Button("Previous") {
                                currentAssigneeIndex -= 1
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        if currentAssigneeIndex == approvedAssignees.count - 1 {
                            Button("Submit All Ratings") {
                                showConfirmation = true
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(ratings[approvedAssignees[currentAssigneeIndex].userID] == nil)
                            .alert("Submit Ratings", isPresented: $showConfirmation) {
                                Button("Cancel", role: .cancel) { }
                                Button("Submit", role: .none) {
                                    submitAllRatings()
                                }
                            } message: {
                                Text("Are you sure you want to submit all ratings and complete this task?")
                            }
                        } else {
                            Button("Next") {
                                currentAssigneeIndex += 1
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(ratings[approvedAssignees[currentAssigneeIndex].userID] == nil)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                } else {
                    // All ratings completed
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding()
                        
                        Text("All ratings submitted!")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        Text("Thank you for providing feedback.")
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            
            // Cancel button
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.gray)
            .padding(.top, 30)
            
            if isSubmitting {
                ProgressView("Submitting ratings...")
                    .padding()
            }
        }
        .frame(maxWidth: 500)
        .padding()
        .disabled(isSubmitting)
    }
    
    private func submitAllRatings() {
        isSubmitting = true
        let group = DispatchGroup()
        
        for (assigneeID, rating) in ratings {
            group.enter()
            submitRating(for: assigneeID, rating: rating) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isSubmitting = false
            // Update task status to completed
            TaskService.shared.updateTaskStatus(task: task, status: "completed") { result in
                switch result {
                case .success:
                    onComplete()
                case .failure:
                    // Even if status update fails, we proceed as ratings were submitted
                    onComplete()
                }
            }
        }
    }
    
    private func submitRating(for assigneeID: String, rating: Double, completion: @escaping () -> Void) {
        TaskService.shared.rateUser(userID: assigneeID, taskID: task.id, rating: rating) { result in
            switch result {
            case .success:
                print("✅ Successfully rated user \(assigneeID) with \(rating) stars")
            case .failure(let error):
                print("❌ Error rating user: \(error.localizedDescription)")
            }
            completion()
        }
    }
}

// Preview
struct AssigneeRatingView_Previews: PreviewProvider {
    static var previews: some View {
        AssigneeRatingView(
            task: Task(
                id: "test-task",
                title: "Test Task",
                description: "Test Description",
                creatorID: "creator1",
                creatorUsername: "Creator",
                assignees: [
                    Assignee(userID: "user1", username: "John Doe", requestDate: Date(), approved: true),
                    Assignee(userID: "user2", username: "Jane Smith", requestDate: Date(), approved: true)
                ],
                status: "inProgress",
                dueDate: Date(),
                people: 2,
                payType: "Fixed",
                pay: 20,
                town: "Springfield",
                expertise: "General",
                category: "Yard Work"
            ),
            onComplete: {},
            onCancel: {}
        )
    }
}
