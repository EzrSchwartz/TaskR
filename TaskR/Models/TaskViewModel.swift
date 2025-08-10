
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var tasks: [Task] = []
    @Published var myTasks: [Task] = []
    @Published var claimedTasks: [Task] = []
    @Published var priorClaimedTasks: [Task] = []
    @Published var currentClaimedTasks: [Task] = []
    @Published var myPriorTasks: [Task] = []
    @Published var myCurrentTasks: [Task] = []
    @Published var usernames: [String: String] = [:]
    @Published var userInterests: [String] = []
    @Published var isLoading = false
    
    // MARK: - Initialization
    init() {
        fetchUserInterests()
    }
    
    // MARK: - Public Methods
    
    func fetchAllData() {
        isLoading = true
        fetchTasks()
        fetchMyTasks()
        fetchClaimedTasks()
        fetchUserInterests()
        
        // Set isLoading back to false after a reasonable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
        }
    }
    
    func fetchTasks() {
        TaskService.shared.fetchAvailableTasks { [weak self] fetchedTasks in
            self?.updateTasks(fetchedTasks, storage: \.tasks)
        }
    }
    
    func fetchMyTasks() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        TaskService.shared.fetchMyTasks(userID: userID) { tasks in
            DispatchQueue.main.async {
                self.myTasks = tasks
                self.updateTaskFilters(source: tasks)
            }
        }
    }
    
    func fetchClaimedTasks() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        TaskService.shared.fetchClaimedTasks(userID: userID) { [weak self] fetchedTasks in
            self?.updateTasks(fetchedTasks, storage: \.claimedTasks)
            self?.updateClaimedFilters(source: fetchedTasks)
        }
    }
    
    func fetchMyCurrentTasks() {
        fetchMyTasks()
    }
    
    func getCurrentUserInterests() -> [String] {
        return userInterests
    }
    
    func fetchUserInterests() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No user logged in to fetch interests")
            return
        }
        
        Firestore.firestore().collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching interests: \(error.localizedDescription)")
                    self.userInterests = []
                    return
                }
                
                if let data = snapshot?.data() {
                    // Try to get interests as an array of strings
                    if let interestsArray = data["interests"] as? [String] {
                        self.userInterests = interestsArray
                        print("✅ Fetched \(interestsArray.count) interests for user")
                    }
                    // Try to get interests as a single comma-separated string
                    else if let interestsString = data["interests"] as? String {
                        let interests = interestsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                        self.userInterests = interests.filter { !$0.isEmpty }
                        print("✅ Parsed \(interests.count) interests from string")
                    } else {
                        self.userInterests = []
                        print("⚠️ No interests found in user data")
                    }
                } else {
                    self.userInterests = []
                    print("⚠️ No user data found")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateTasks(_ tasks: [Task], storage: ReferenceWritableKeyPath<TaskViewModel, [Task]>) {
        DispatchQueue.main.async { [weak self] in
            self?[keyPath: storage] = tasks
            self?.fetchUsernames(for: tasks)
        }
    }
    
    private func updateTaskFilters(source: [Task]) {
        let (prior, current) = filterTasks(source)
        let nonCompletedCurrent = current.filter { $0.status != "completed" }
        
        DispatchQueue.main.async { [weak self] in
            self?.myPriorTasks = prior
            self?.myCurrentTasks = nonCompletedCurrent
        }
    }
    private func updateClaimedFilters(source: [Task]) {
        let (prior, current) = filterTasks(source)
        DispatchQueue.main.async { [weak self] in
            self?.priorClaimedTasks = prior
            self?.currentClaimedTasks = current
        }
    }
    
    private func filterTasks(_ tasks: [Task]) -> (prior: [Task], current: [Task]) {
        let currentDate = Date()
        var prior = [Task]()
        var current = [Task]()
        
        for task in tasks {
            if task.status == "completed" || task.dueDate < currentDate {
                prior.append(task)
            } else {
                current.append(task)
            }
        }
        
        return (prior, current)
    }
    
    private func fetchUsernames(for tasks: [Task]) {
        let uniqueIDs = Set(tasks.map { $0.creatorID }).filter { usernames[$0] == nil }
        
        // Also get usernames for assignees
        let assigneeIDs = tasks.flatMap { task in
            task.assignees.map { $0.userID }
        }
        let uniqueAssigneeIDs = Set(assigneeIDs).filter { usernames[$0] == nil }
        
        // Combine all unique IDs
        let allUniqueIDs = uniqueIDs.union(uniqueAssigneeIDs)
        
        guard !allUniqueIDs.isEmpty else { return }
        
        allUniqueIDs.forEach { userID in
            AuthService.shared.fetchUsername(userID: userID) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let username):
                        self?.usernames[userID] = username
                    case .failure:
                        self?.usernames[userID] = "Unknown User"
                    }
                }
            }
        }
    }
}
