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
    
    // MARK: - Initialization
    init() {
        fetchUserInterests()
    }
    
    // MARK: - Public Methods
    
    func fetchAllData() {
        fetchTasks()
        fetchMyTasks()
        fetchClaimedTasks()
    }
    
    func fetchTasks() {
        TaskService.shared.fetchAvailableTasks { [weak self] fetchedTasks in
            self?.updateTasks(fetchedTasks, storage: \.tasks)
        }
    }
    
//    func fetchMyTasks() {
//        guard let userID = Auth.auth().currentUser?.uid else { return }
//        TaskService.shared.fetchMyTasks(userID: userID) { [weak self] fetchedTasks in
//            self?.updateTasks(fetchedTasks, storage: \.myTasks)
//            self?.updateTaskFilters(source: fetchedTasks)
//        }
//    }
    func fetchMyTasks() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        TaskService.shared.fetchMyTasks(userID: userID) { tasks in
            DispatchQueue.main.async {
                self.myTasks = tasks
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
    
    func getCurrentUserInterests() -> [String] {
        return userInterests
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
        DispatchQueue.main.async { [weak self] in
            self?.myPriorTasks = prior
            self?.myCurrentTasks = current
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
        
        guard !uniqueIDs.isEmpty else { return }
        
        uniqueIDs.forEach { userID in
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
    
    private func fetchUserInterests() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching interests: \(error.localizedDescription)")
                    self.userInterests = []
                    return
                }
                
                self.userInterests = (snapshot?.data()?["interests"] as? [String]) ?? []
            }
        }
    }
}
