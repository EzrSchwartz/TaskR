import SwiftUI
import FirebaseAuth


struct SignUpView: View {
    @Binding var isAuthenticated: Bool
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
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
            
            Button("Sign Up") {
                AuthService.shared.createUser(username: username, email: email, password: password) { result in
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
