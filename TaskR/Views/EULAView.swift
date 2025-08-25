//
//  EULAView.swift
//  TaskR
//
//  Created by Ezra on 8/25/25.
//


import SwiftUI

struct EULAView: View {
    var onAgree: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("End User License Agreement")
                .font(.title)
                .bold()
                .padding(.top)
            
            Text("Please read and agree to the Terms of Service and EULA before continuing.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Link("View Terms of Service", destination: URL(string: "https://aboutteentaskr.com/terms.html")!)
                .foregroundColor(.blue)
            
            Spacer()
            
            Button(action: onAgree) {
                Text("I Agree")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
