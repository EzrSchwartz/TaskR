import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            
            Button("Sign Up") {
                AuthService.shared.signUpUser(email: email, password: password) { _ in }
            }.padding()

            Button("Login") {
                AuthService.shared.signInUser(email: email, password: password) { _ in }
            }.padding()
        }
    }
}

