import SwiftUI

struct SignUpView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Dismiss Button for the sheet
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            .padding(.trailing, 8)

            Spacer()

            VStack(spacing: 40) {
                Image("EncoreLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .foregroundColor(.primary)

                VStack(spacing: 20) {
                    CustomTextField(placeholder: "Full Name", text: $name)
                    CustomTextField(placeholder: "Email", text: $email)
                    CustomSecureField(placeholder: "Password", text: $password)
                }
                .frame(width: 300)
                
                Button(action: handleSignUp) {
                    Text("Create Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .frame(width: 300)
            }
            
            Spacer()
            Spacer()
        }
        .frame(width: 450, height: 550)
    }
    
    private func handleSignUp() {
        // Sign up logic will go here
        dismiss()
    }
}
