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
                    Image(systemName: "list.bullet")
                    Text("Available")
                }
                .tag(0)
            
            // Claimed tasks view
            ClaimedTasksView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("My Tasks")
                }
                .tag(1)
            
            MyPreviousClaimedTasksView(viewModel: viewModel)
                .tabItem{
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    Text("Prior Tasks")
                }
                .tag(2)
            
            // Profile tab
            ZStack {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    KidUserProfileView(userID: currentUserID, isEditable: true)
                } else {
                    Text("Please log in to view your profile")
                        .foregroundColor(AppColors.secondaryGray)
                }
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(AppColors.primaryGreen) // Use your primary color for tab selection
        .onAppear {
            
            viewModel.fetchAllData()
        }
    }
}
