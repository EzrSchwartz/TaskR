//
//  MyPreviousClaimedTasksView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//



import SwiftUI
import FirebaseAuth

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyPreviousClaimedTasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var navigateToChat = false
    @State private var selectedTask: Task?
    @State private var showRatingSheet = false
    
    var body: some View {
        VStack {
            if viewModel.priorClaimedTasks.isEmpty {
                Text("You Have No Previous Tasks")
                    .font(.headline)
                    .padding()
            } else {
                List(viewModel.priorClaimedTasks) { task in
                    Button(action: {
                        selectedTask = task
                    }) {
                        taskCell(task)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Prior Claimed Tasks")

        .onAppear {
            viewModel.fetchAllData()
        }
        .sheet(item: $selectedTask) { task in
            TaskClaimedDetailsView(
                task: task,
                onClose: {
                    selectedTask = nil
                }
            )
        }
    }
    
    private func taskCell(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("Created by: \(viewModel.usernames[task.creatorID] ?? "Loading...")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("Pay (\(task.payType)): $\(task.pay)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\(task.people)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("Category: \(task.category)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Expertise: \(task.expertise)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("Town: \(task.town)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.timeZone = .current
                return formatter
            }()
            
            Text("Time: \(dateFormatter.string(from: task.dueDate))")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text(task.description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            
            // Status badge
            HStack {
                Spacer()
                
                Text(task.status.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor(task.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(task.status).opacity(0.1))
                    .cornerRadius(5)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available": return .blue
        case "inProgress": return .orange
        case "completed": return .green
        default: return .gray
        }
    }
}

// Task details view for claimed tasks
struct TaskClaimedDetailsView: View {
    let task: Task
    let onClose: () -> Void
    
    @State private var showRatingSheet = false
    @State private var showChatView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Task header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            Text("Status: ")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(task.status.capitalized)
                                .font(.subheadline)
                                .foregroundColor(statusColor(task.status))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor(task.status).opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                    
                    // Details
                    Group {
                        detailRow(title: "Due Date", value: formatDate(task.dueDate))
                        detailRow(title: "Payment", value: "\(task.payType): $\(task.pay)")
                        detailRow(title: "Category", value: task.category)
                        detailRow(title: "Expertise", value: task.expertise.isEmpty ? "None" : task.expertise)
                        detailRow(title: "Town", value: task.town)
                    }
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    
                    Text(task.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Chat button
                    if canAccessChat() {
                        Button(action: {
                            showChatView = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Chat")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 16)
                        }
                    }
                    
                    // Rating button for completed tasks
                    if task.status == "completed" {
                        ratingButton
                    }
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                onClose()
            })
            .sheet(isPresented: $showRatingSheet) {
                CreatorRatingView(
                    task: task,
                    onComplete: {
                        showRatingSheet = false
                    },
                    onCancel: {
                        showRatingSheet = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showChatView) {
                NavigationView {
                    TaskChatView(taskID: task.id, taskTitle: task.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Close") {
                                    showChatView = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    // Rating button
    var ratingButton: some View {
        Button(action: {
            showRatingSheet = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Rate Task Creator")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.yellow)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 8)
        }
        .disabled(!canRateCreator())
    }
    
    private func canRateCreator() -> Bool {
        // Only allow rating if the task is completed
        return task.status == "completed"
    }
    
    private func canAccessChat() -> Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        
        // Task creator can always access chat
        if task.creatorID == currentUserID { return true }
        
        // Approved assignees can access chat
        return task.assignees.contains { $0.userID == currentUserID && $0.approved }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available": return .blue
        case "inProgress": return .orange
        case "completed": return .green
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CreatorRatingView: View {
    let task: Task
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedRating: Int = 0
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Rate Task Creator")
                .font(.title2)
                .bold()
                .padding(.top)
            
            // Creator info card
            VStack(spacing: 12) {
                Text(task.creatorUsername)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Text("How would you rate your experience with this task creator?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Rating stars
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
                .padding(.vertical, 12)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Submit button
            Button(action: {
                showConfirmation = true
            }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .padding(.trailing, 8)
                    }
                    Text("Submit Rating")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedRating > 0 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline)
            }
            .disabled(selectedRating == 0 || isSubmitting)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .alert("Submit Rating", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit", role: .none) {
                    submitRating()
                }
            } message: {
                Text("Are you sure you want to submit this rating?")
            }
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
            
            if isSubmitting {
                ProgressView("Submitting rating...")
                    .padding()
            }
        }
        .padding()
        .disabled(isSubmitting)
    }
    
    private func submitRating() {
        guard selectedRating > 0 else { return }
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // Make sure user isn't rating themselves
        guard currentUserID != task.creatorID else {
            // Show an error if needed
            return
        }
        
        isSubmitting = true
        
        // Convert to Double rating
        let rating = Double(selectedRating)
        
        // Call the rateUser function with the creator's ID
        TaskService.shared.rateUser(userID: task.creatorID, taskID: task.id, rating: rating) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success:
                    print("✅ Successfully rated creator \(task.creatorID) with \(rating) stars")
                    onComplete()
                    
                case .failure(let error):
                    print("❌ Error rating creator: \(error.localizedDescription)")
                    // Here you could show an error alert
                }
            }
        }
    }
}
