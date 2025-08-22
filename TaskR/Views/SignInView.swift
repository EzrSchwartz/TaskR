import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct SignInView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss // ✅ Fix: Use `.dismiss` instead of `presentationMode`

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button("Log In") {
                login(email: email, password: password)
            }
            .padding()
            
            Button("Use Face ID") {
                authenticateWithFaceID()
            }
            .padding()
            
            Button("Forgot Password?") {
                resetPassword()
            }
            .padding()
            Button("Back") {
                dismiss() // ✅ Fix: Dismiss the current view properly
            }
            .padding()
        }
        .onAppear {
            checkForStoredCredentials() // ✅ Automatically checks for stored credentials on launch
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email to reset your password."
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                print("📧 Attempting to reset password for: \(email)")

                self.errorMessage = "Password reset email sent. Check your inbox."
            }
        }
    }
    
    
    public func login(email: String, password: String) {
        AuthService.shared.signInUser(email: email, password: password) { result in
            switch result {
            case .success:
                isAuthenticated = true
                
                saveCredentials() // ✅ Save credentials for Face ID
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in with Face ID") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.loadCredentialsAndLogin()
                    } else {
                        self.errorMessage = "Face ID Authentication Failed."
                    }
                }
            }
        } else {
            errorMessage = "Face ID not available."
        }
    }
    
    private func saveCredentials() {
        KeychainService.saveCredentials(email: email, password: password)
    }
    
    private func checkForStoredCredentials() {
        if let credentials = KeychainService.loadCredentials() {
            email = credentials.email
            password = credentials.password
        }
    }
    
    private func loadCredentialsAndLogin() {
        if let credentials = KeychainService.loadCredentials() {
            email = credentials.email
            password = credentials.password
            login(email: email, password: password) // ✅ Auto-login after Face ID success
        } else {
            errorMessage = "No saved credentials found."
        }
    }
}
