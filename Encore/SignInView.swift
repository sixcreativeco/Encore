import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct SignInView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var showSignUp: Bool = false
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("ENCORE")
                .font(.system(size: 40, weight: .bold))

            VStack(spacing: 20) {
                GoogleSignInButton {
                    handleGoogleSignIn()
                }
                .frame(width: 250, height: 50)

                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in },
                    onCompletion: { result in }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(width: 250, height: 50)

                CustomTextField(placeholder: "Email", text: $email)
                    .frame(width: 250)
            }

            VStack(spacing: 6) {
                Text("Don't have an account?")
                    .font(.footnote)

                Button("Sign Up") {
                    showSignUp = true
                }
                .font(.footnote.bold())
                .sheet(isPresented: $showSignUp) {
                    SignUpView()
                }
            }

            Spacer()
        }
        .padding()
    }

    private func handleGoogleSignIn() {
        guard let presentingWindow = NSApplication.shared.keyWindow else { return }
        Task {
            await AuthManager.shared.handleGoogleSignIn(presentingWindow: presentingWindow, appState: appState)
        }
    }
}
