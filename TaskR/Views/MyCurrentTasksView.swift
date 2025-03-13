//
//  MyCurrentTasksView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyCurrentTasksView: View {
    @StateObject var viewModel = TaskViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.myCurrentTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Current Tasks")
            .onAppear {
                viewModel.fetchMyCurrentTasks()
            }
        }
    }
    
    // MARK: - Subviews
    private var emptyStateView: some View {
        VStack {
            Text("You Have No Current Tasks")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
    }
    
    private var taskListView: some View {
        List(viewModel.myCurrentTasks, id: \.id) { task in
            taskCell(task)
        }
    }
    
    private func taskCell(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                
                Spacer()
                
                if task.status == "inProgress" {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if let approvedAssignee = task.assignees.first(where: { $0.approved }) {
                Text("Claimed by: \(viewModel.usernames[approvedAssignee.userID] ?? "Unknown User")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Not Claimed Yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(task.description)
                .font(.subheadline)
                .lineLimit(2)
            
            Text("Due: \(task.dueDate, style: .date)")
                .font(.footnote)
                .foregroundColor(.gray)
            
            if task.creatorID == Auth.auth().currentUser?.uid {
                Button(role: .destructive) {
                    deleteTask(task)
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    private func deleteTask(_ task: Task) {
        TaskService.shared.deleteTask(taskID: task.id) { result in
            switch result {
            case .success:
                viewModel.fetchMyCurrentTasks()
            case .failure(let error):
                print("Delete error: \(error.localizedDescription)")
            }
        }
    }
}
