import SwiftUI
import FirebaseAuth

struct AuthSelectionView: View {
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        VStack {
            Button("Log In") {
                // Navigate to Login View
                isLoggingIn = true
            }
            .padding()
            .fullScreenCover(isPresented: $isLoggingIn) {
                SigninView(isAuthenticated: $isAuthenticated)
            }
            
            Button("Sign Up") {
                // Navigate to Sign Up View
                isSigningUp = true
            }
            .padding()
            .fullScreenCover(isPresented: $isSigningUp) {
                SignUpView(isAuthenticated: $isAuthenticated)
            }
        }
    }
    
    @State private var isLoggingIn = false
    @State private var isSigningUp = false
}

