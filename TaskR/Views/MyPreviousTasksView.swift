//
//  MyTasksView 2.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyPreviousTasksView: View {
    @StateObject var viewModel = TaskViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.myPriorTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .navigationTitle("Prior Tasks")
            .onAppear {
                viewModel.fetchAllData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack {
            Text("You Have No Prior Tasks")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
    }
    
    private var taskListView: some View {
        List(viewModel.myPriorTasks) { task in
            taskCell(task)
        }
    }
    
    private func taskCell(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.headline)
            
            if let assigneeID = task.assignees.first?.userID {
                Text("Claimed by: \(viewModel.usernames[assigneeID] ?? "Unknown User")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Never Claimed")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(task.description)
                .font(.subheadline)
                .lineLimit(2)
            
            Text("Completed: \(task.dueDate, style: .date)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
