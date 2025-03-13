import SwiftUI
import FirebaseAuth

struct TaskListView: View {
    @StateObject var viewModel = TaskViewModel()
    @State private var selectedTask: Task?
    @State private var navigateToChat = false
    @State private var selectedCategory: String?
    
    // Sample categories - replace with your actual categories
    let categories = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports", "Other"]
    
    var filteredTasks: [Task] {
        if let category = selectedCategory {
            return viewModel.tasks.filter { $0.category == category }
        } else {
            return viewModel.tasks
        }
    }
    
    var featuredTask: Task? {
        // Get the most recent task that matches user interests
        let userInterests = viewModel.getCurrentUserInterests() // Implement this in your viewModel
        
        let matchingTasks = viewModel.tasks.filter { task in
            userInterests.contains(task.category)
        }
        
        return matchingTasks.sorted(by: { $0.dueDate > $1.dueDate }).first ??
               viewModel.tasks.sorted(by: { $0.dueDate > $1.dueDate }).first
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            Text("All")
                                .fontWeight(selectedCategory == nil ? .bold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .fontWeight(selectedCategory == category ? .bold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                List {
                    // Featured task section (only shown when viewing all tasks)
                    if selectedCategory == nil, let task = featuredTask {
                        Section(header: Text("Recommended For You")) {
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
                                        .foregroundColor(.blue)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
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
                                
                                Button("Request To Claim Task") {
                                    requestToClaimTask(task)
                                }
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // All tasks or filtered by category
                    Section(header: Text(selectedCategory ?? "Available Tasks")) {
                        ForEach(filteredTasks) { task in
                            // Skip the featured task if it's already shown
                            if selectedCategory != nil || task.id != featuredTask?.id {
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
                                    
                                    Button("Request To Claim Task") {
                                        requestToClaimTask(task)
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Tasks")
            .onAppear {
                viewModel.fetchTasks()
                viewModel.fetchUserInterests() // Implement this in your viewModel
            }
            .background(
                NavigationLink(
                    destination: ChatView(
                        taskID: selectedTask?.id ?? "",
                        creatorID: selectedTask?.creatorID ?? "",
                        assigneeID: Auth.auth().currentUser?.uid ?? ""
                    ),
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
            )
        }
    }
    private func requestToClaimTask(_ task: Task) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        AuthService.shared.fetchUsername(userID: userID) { result in
            switch result {
            case .success(let username):
                TaskService.shared.requestToClaimTask(taskID: task.id, userID: userID, username: username) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            print("✅ Request to claim task sent successfully")
                        case .failure(let error):
                            print("❌ Error requesting to claim task: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("❌ Error fetching username: \(error.localizedDescription)")
            }
        }
    }
}


// Extension for TaskViewModel to handle user interests

