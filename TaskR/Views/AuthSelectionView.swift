import SwiftUI
import FirebaseAuth

struct AuthSelectionView: View {
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // App logo or title
                Text("TaskR")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                
                Spacer()
                
                // Login button
                Button(action: {
                    isLoggingIn = true
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Log In")
                    }
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                }
                
                // Signup button
                Button(action: {
                    isSigningUp = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus.fill")
                        Text("Sign Up")
                    }
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .fullScreenCover(isPresented: $isLoggingIn) {
            SignInView(isAuthenticated: $isAuthenticated)
        }
        .fullScreenCover(isPresented: $isSigningUp) {
            SignupEntryView()
        }
    }
    
    @State private var isLoggingIn = false
    @State private var isSigningUp = false
}
