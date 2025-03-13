////
////  KidHomeView.swift
////  TaskR
////
////  Created by Ezra Schwartz on 3/11/25.
////
//
//import SwiftUI
//import FirebaseAuth
//
//struct KidHomeView: View {
//    @ObservedObject var viewModel: TaskViewModel
//    
//    var body: some View {
//        TabView {
//            // Your available tasks view
//            TaskListView(viewModel: viewModel)
//                .tabItem { Label("Available", systemImage: "list.bullet") }
//            
//            // Your current tasks view
//            ClaimedTasksView(viewModel: viewModel)
//                .tabItem { Label("My Tasks", systemImage: "checkmark.circle") }
//
//            // Profile tab
//            Text("Profile")
//                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
//        }
//        .onAppear {
//            viewModel.fetchAllData()
//        }
//    }
//}


//
//  KidHomeView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//

import SwiftUI
import FirebaseAuth

struct KidHomeView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Available tasks view
            TaskListView(viewModel: viewModel)
                .tabItem {
                    Label("Available", systemImage: "list.bullet")
                }
                .tag(0)
            
            // Claimed tasks view
            ClaimedTasksView(viewModel: viewModel)
                .tabItem {
                    Label("My Tasks", systemImage: "checkmark.circle")
                }
                .tag(1)
            
            // Profile tab
            ZStack {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    UserProfileView(userID: currentUserID, isEditable: true)
                } else {
                    Text("Please log in to view your profile")
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
        .onAppear {
            viewModel.fetchAllData()
        }
    }
}
