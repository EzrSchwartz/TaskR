import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            TabView {
                TaskListView()
                    .tabItem { Label("Tasks", systemImage: "list.bullet") }
                
                CreateTaskView()
                    .tabItem { Label("Create", systemImage: "plus.circle") }
            }
        } else {
            AuthView()
        }
    }
}
