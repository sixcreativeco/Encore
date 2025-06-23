import SwiftUI

struct SignUpView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) var dismiss

    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 0) {
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
                    CustomSecureField(placeholder: "Password (6+ characters)", text: $password)
                }
                .frame(width: 300)
                
                Button(action: handleSignUp) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Create Account")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .buttonStyle(.plain)
                .disabled(!isFormValid || isLoading)
            }
            
            Spacer()
            Spacer()
        }
        .frame(width: 450, height: 550)
        .alert("Sign Up Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }
    
    private func handleSignUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await AuthManager.shared.handleEmailSignUp(email: email, password: password, displayName: name)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
