
//
//import SwiftUI
//import FirebaseAuth
//
//struct AdultHomeView: View {
//    @ObservedObject var viewModel: TaskViewModel
//    @State private var selectedTab = 0
//    
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            // Create Task tab
//            CreateTaskView()
//                .tabItem {
//                    Label("Create", systemImage: "plus.circle")
//                }
//                .tag(0)
//            
//            // My Tasks tab
//            MyTasksView(viewModel: viewModel)
//                .tabItem {
//                    Label("My Tasks", systemImage: "list.bullet.clipboard")
//                }
//                .tag(1)
//            
//            // Pending Requests tab
//            
//            
//            // Prior Tasks tab
//            MyPreviousTasksView(viewModel: viewModel)
//                .tabItem {
//                    Label("Prior Tasks", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
//                }
//                .tag(2)
//            
//            // Profile tab
//            ZStack {
//                if let currentUserID = Auth.auth().currentUser?.uid {
//                    AdultUserProfileView(userID: currentUserID, isEditable: true)
//                } else {
//                    Text("Please log in to view your profile")
//                }
//            }
//            .tabItem {
//                Label("Profile", systemImage: "person.crop.circle")
//            }
//            .tag(4)
//        }
//        .onAppear {
//            viewModel.fetchAllData()
//        }
//    }
//}


import SwiftUI
import FirebaseAuth



struct AdultHomeView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Create Task tab
            CreateTaskView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
                .tag(0)
            
            // My Tasks tab
            MyTasksView(viewModel: viewModel)
                .tabItem {
                    Label("My Tasks", systemImage: "list.bullet.clipboard")
                }
                .tag(1)
            

            
            // Prior Tasks tab
            MyPreviousTasksView(viewModel: viewModel)
                .tabItem {
                    Label("Prior Tasks", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                .tag(2)
            
            // Profile tab
            ZStack {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    AdultUserProfileView(userID: currentUserID, isEditable: true)
                } else {
                    Text("Please log in to view your profile")
                        .foregroundColor(Color(AppColors.forestGreen))
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(4)
        }
        .accentColor(Color(AppColors.forestGreen)) // Tint color for selected tab
        .onAppear {
            viewModel.fetchAllData()
        }
    }
}


