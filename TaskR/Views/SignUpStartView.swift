import SwiftUI
import FirebaseAuth

// MARK: - Signup Entry (Email & Password)
struct SignupEntryView: View {
    @State private var email = ""
    @State private var password = ""
    @Binding var isAuthenticated: Bool
    @State private var isSigningUp = false
    var body: some View {
        NavigationStack {
            VStack {
                Text("Create an Account")
                    .font(.title)
                    .bold()
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                NavigationLink(destination: SignupTypeSelectionView(email: email, password: password, isAuthenticated: $isAuthenticated)) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
    }
}





