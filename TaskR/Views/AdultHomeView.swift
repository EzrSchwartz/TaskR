//
//  AdultHomeView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/11/25.
//


import SwiftUI

struct AdultHomeView: View {
    @ObservedObject var viewModel: TaskViewModel

    var body: some View {
        TabView {
            MyCurrentTasksView(viewModel: viewModel)
                .tabItem { Label("Current Tasks", systemImage: "rectangle.and.pencil.and.ellipsis") }
            
            CreateTaskView()
                .tabItem { Label("Create", systemImage: "plus.circle") }
            
            MyPreviousTasksView(viewModel: viewModel)
                .tabItem { Label("Prior Tasks", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") }

            

            
        }
        .onAppear {
            viewModel.fetchTasks()
            viewModel.fetchClaimedTasks()

        }
    }
}
