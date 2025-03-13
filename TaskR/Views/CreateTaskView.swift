//
//
//
//import SwiftUI
//import FirebaseAuth
//
//struct CreateTaskView: View {
//    @State private var title = ""
//    @State private var description = ""
//    @State private var dueDate = Date()
//    @State private var errorMessage: String?
//    @State private var creatorUsername: String = "Loading..." // Default before fetching
//
//    var body: some View {
//        VStack {
//            TextField("Title", text: $title)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            TextField("Description", text: $description)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
//                .padding()
//
//            Button(action: createTask) {
//                Text("Create Task")
//            }
//            .padding()
//
//            if let errorMessage = errorMessage {
//                Text(errorMessage).foregroundColor(.red)
//            }
//        }
//        .onAppear {
//            fetchUsername() // ✅ Fetch username when view loads
//        }
//    }
//
//    // ✅ Create Task Function
//    private func createTask() {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            errorMessage = "User not authenticated!"
//            return
//        }
//
//        TaskService.shared.createTask(
//            title: title,
//            description: description,
//            creatorID: userID,
//            dueDate: dueDate
//        ) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let taskID):
//                    print("✅ Task created with ID: \(taskID)")
//                    errorMessage = "Task created!"
//                    title = "" // Reset input fields
//                    description = ""
//                    dueDate = Date()
//                case .failure(let error):
//                    print("❌ Error creating task: \(error.localizedDescription)")
//                    errorMessage = "Error: \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//
//    // ✅ Fetch Username
//    private func fetchUsername() {
//        guard let userID = Auth.auth().currentUser?.uid else { return }
//        
//        AuthService.shared.fetchUsername(userID: userID) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let username):
//                    self.creatorUsername = username
//                case .failure:
//                    self.creatorUsername = "Unknown User"
//                }
//            }
//        }
//    }
//}





import SwiftUI
import FirebaseAuth
import FirebaseFirestore


// MARK: - Task Creation Screens

// Screen 1: Basic Details
struct TaskBasicDetailsView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var dueDate: Date
    
    var body: some View {
        VStack {
            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Basic Details")
    }
}

// Screen 2: Job Details
struct TaskJobDetailsView: View {
    @Binding var people: Int
    @Binding var payType: String
    @Binding var pay: Int
    
    let payTypes = ["Fixed", "Hourly"]
    
    var body: some View {
        VStack {
            Stepper("Number of People: \(people)", value: $people, in: 1...10)
                .padding()
            
            Picker("Pay Type", selection: $payType) {
                ForEach(payTypes, id: \.self) { type in
                    Text(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            TextField("Pay Amount ($)", value: $pay, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Job Details")
    }
}

// Screen 3: Location and Expertise
struct TaskLocationExpertiseView: View {
    @Binding var town: String 
    @Binding var expertise: String
    @Binding var category: String
    
    let categories = ["Tutoring", "Babysitting", "Yard Work", "Pet Care", "Tech Help", "Art", "Music", "Sports"]
    
    var body: some View {
        VStack {

            TextField("Expertise (Optional)", text: $expertise)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Picker("Category", selection: $category) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Location & Expertise")
    }
}

// MARK: - Main Task Creation View
struct CreateTaskView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var people = 1
    @State private var payType = "Fixed"
    @State private var pay = 0
    @State private var town = "Westport" // Default town, can be fetched from user profile
    @State private var expertise = ""
    @State private var category = "Other"
    @State private var errorMessage: String?
    @State private var creatorUsername: String = "Loading..."
    @State private var currentStep: Int = 1
    
    var body: some View {
        NavigationView {
            VStack {
                if currentStep == 1 {
                    TaskBasicDetailsView(title: $title, description: $description, dueDate: $dueDate)
                } else if currentStep == 2 {
                    TaskJobDetailsView(people: $people, payType: $payType, pay: $pay)
                } else if currentStep == 3 {
                    TaskLocationExpertiseView(town: $town, expertise: $expertise, category: $category)
                }
                
                HStack {
                    if currentStep > 1 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    if currentStep < 3 {
                        Button("Next") {
                            currentStep += 1
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Button("Create Task") {
                            createTask()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Create Task")
            .onAppear {
                fetchUsername()
            }
        }
    }
    
    private func createTask() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated!"
            return
        }
        

        let task = Task(
            id: UUID().uuidString,
            title: title,
            description: description,
            creatorID: Auth.auth().currentUser?.uid ?? "",
            creatorUsername: creatorUsername,
            assignees: [], // Empty array for new task
            status: "available",
            dueDate: dueDate,
            people: people,
            payType: payType,
            pay: pay,
            town: town,
            expertise: expertise,
            category: category
        )
        
        // 2. Then use TaskService to save it
        TaskService.shared.createTask(task: task) { result in
            DispatchQueue.main.async {
                
                switch result {
                case .success(let taskID):
                    print("✅ Task created successfully with ID: \(taskID)")
                    resetForm()
                    
                case .failure(let error):
                    print("❌ Error creating task: \(error.localizedDescription)")
                    errorMessage = "Failed to create task: \(error.localizedDescription)"
                }
            }
        }}
    private func resetForm() {
        title = ""
        description = ""
        dueDate = Date()
        people = 1
        payType = "Fixed"
        pay = 0
        expertise = ""
        category = "Cleaning"
        currentStep = 1
    }
    
    private func fetchUsername() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        AuthService.shared.fetchUsername(userID: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let username):
                    self.creatorUsername = username
                case .failure:
                    self.creatorUsername = "Unknown User"
                }
            }
        }
    }
}
