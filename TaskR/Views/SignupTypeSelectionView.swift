//
//  SignupTypeSelectionView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/10/25.
//


import SwiftUI

// MARK: - Signup Type Selection (Kid or Adult)
struct SignupTypeSelectionView: View {
    let email: String
    let password: String
    @State private var isKid: Bool? = nil
    @Binding var isAuthenticated: Bool
    var body: some View {
        NavigationStack {
            VStack {
                Text("Are you signing up as a Kid or an Adult?")
                    .font(.title2)
                    .padding()

                HStack {
                    Button(action: { isKid = true }) {
                        Text("Kid")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isKid == true ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: { isKid = false }) {
                        Text("Adult")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isKid == false ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()

                if let isKid = isKid {
                    NavigationLink(destination: isKid ? AnyView(KidSignupView(email: email, password: password, isAuthenticated: $isAuthenticated)) : AnyView(AdultSignupView(email: email, password: password, isAuthenticated: $isAuthenticated))) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}
