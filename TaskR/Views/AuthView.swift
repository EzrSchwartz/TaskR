import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Sign Up") {
                            guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
                                errorMessage = "All fields are required."
                                return
                            }

                            AuthService.shared.createUser(username: username, email: email, password: password) { result in
                                switch result {
                                case .success:
                                    print("✅ User created successfully!")
                                    errorMessage = nil
                                case .failure(let error):
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
            .padding()

            Button("Login") {
                guard !email.isEmpty, !password.isEmpty else {
                    errorMessage = "Email and password cannot be empty."
                    return
                }

                Auth.auth().signIn(withEmail: email, password: password) { result, error in
                    if let error = error {
                        errorMessage = error.localizedDescription
                    } else {
                        isAuthenticated = true
                    }
                }
            }
            .padding()
        }
    }
}
