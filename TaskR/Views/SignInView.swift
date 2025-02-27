import SwiftUI
import FirebaseAuth

struct SigninView: View {
    @Binding var isAuthenticated: Bool
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            TextField("Username or Email", text: $usernameOrEmail)
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
                AuthService.shared.signInUser(usernameOremail: usernameOrEmail, password: password) { result in
                    switch result {
                    case .success:
                        isAuthenticated = true
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .padding()
        }
    }
}
