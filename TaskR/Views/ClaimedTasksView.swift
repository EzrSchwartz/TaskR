import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClaimedTasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var navigateToChat = false
    @State private var selectedTaskID: String?
    @State private var selectedCreatorID: String?
    @State private var selectedAssigneeID: String?
    
    var body: some View {
        VStack {
            if viewModel.currentClaimedTasks.isEmpty {
                Text("You Have No Current Tasks")
                    .font(.headline)
                    .padding()
            } else {
                List(viewModel.currentClaimedTasks) { task in
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
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                selectedTaskID = task.id
                                selectedCreatorID = task.creatorID
                                selectedAssigneeID = task.assigneeID ?? ""
                                navigateToChat = true
                            }) {
                                Label("Chat", systemImage: "message.badge.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Unclaim") {
                                TaskService.shared.unclaimTask(taskID: task.id) { result in
                                    switch result {
                                    case .success:
                                        viewModel.fetchClaimedTasks()
                                    case .failure(let error):
                                        print("Error unclaiming task: \(error.localizedDescription)")
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Claimed Tasks")
            }
        }
        .onAppear {
            viewModel.fetchCurrentClaimedTasks()
        }
        .background(
            NavigationLink(
                destination: ChatView(
                    taskID: selectedTaskID ?? "",
                    creatorID: selectedCreatorID ?? "",
                    assigneeID: selectedAssigneeID ?? ""
                ),
                isActive: $navigateToChat
            ) {
                EmptyView()
            }
        )
    }
}
