import SwiftUI

struct SignUpView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Create Account")
                .font(.system(size: 32, weight: .bold))
            
            CustomTextField(placeholder: "Name", text: $name)
                .frame(width: 300)
            CustomTextField(placeholder: "Email", text: $email)
                .frame(width: 300)
            SecureField("Password", text: $password)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .frame(width: 300)
            
            Button(action: handleSignUp) {
                Text("Sign Up")
                    .font(.headline)
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func handleSignUp() {
        // Sign up logic will go here
        presentationMode.wrappedValue.dismiss()
    }
}
