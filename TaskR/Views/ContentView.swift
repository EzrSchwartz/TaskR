import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                TabView {
                    TaskListView(viewModel: viewModel)
                        .tabItem { Label("Tasks", systemImage: "list.bullet") }
                    
                    CreateTaskView()
                        .tabItem { Label("Create", systemImage: "plus.circle") }
                    
                    ClaimedTasksView(viewModel: viewModel)
                        .tabItem { Label("Claimed", systemImage: "checkmark.circle") }
                    
                    MyTasksView(viewModel: viewModel)
                        .tabItem { Label("My Tasks", systemImage: "rectangle.and.pencil.and.ellipsis") }
                }
                .onAppear {
                    viewModel.fetchTasks() // ✅ Correct function call
                    viewModel.fetchClaimedTasks()
                    viewModel.fetchMyTasks()
                }
            } else {
                AuthSelectionView(isAuthenticated: $isAuthenticated)
            }
        }
        .onAppear {
            checkAuthentication()
        }
    }
    
    private func checkAuthentication() {
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    private func forceLogout() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}
