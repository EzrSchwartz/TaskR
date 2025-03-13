//
//  MyPreviousClaimedTasksView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyPreviousClaimedTasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var navigateToChat = false
    @State private var selectedTaskID: String?
    @State private var selectedCreatorID: String?
    @State private var selectedAssigneeID: String?
    
    var body: some View {
        VStack {
            if viewModel.priorClaimedTasks.isEmpty {
                Text("You Have No Current Tasks")
                    .font(.headline)
                    .padding()
            } else {
                List(viewModel.priorClaimedTasks) { task in
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
                        
                       
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Prior Claimed Tasks")
            }
        }
        .onAppear {
            viewModel.fetchAllData()
        }
        .background(
 
        )
    }
}

