//
//  KidHomeView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//


import SwiftUI

struct KidHomeView: View {
    @ObservedObject var viewModel: TaskViewModel

    var body: some View {
        TabView {
            TaskListView(viewModel: viewModel)
                .tabItem { Label("Tasks", systemImage: "list.bullet") }

            ClaimedTasksView(viewModel: viewModel)
                .tabItem { Label("Claimed Tasks", systemImage: "checkmark.circle") }
            MyPreviousClaimedTasksView(viewModel: viewModel)
                .tabItem{ Label("Previous Tasks", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")}
        }
        .onAppear {
            viewModel.fetchTasks()
            viewModel.fetchMyTasks()
        }
    }
}
