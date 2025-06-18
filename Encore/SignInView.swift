import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            signInForm
                .frame(width: 450)
            
            SignInDynamicContentView()
        }
        .background(Color(.windowBackgroundColor))
        .ignoresSafeArea()
    }
    
    private var signInForm: some View {
        VStack(spacing: 40) {
            Spacer()

            Image("EncoreLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                GoogleSignInButton {
                    handleGoogleSignIn()
                }
                .frame(width: 280, height: 44)

                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in /* Configure request */ },
                    onCompletion: { result in /* Handle result */ }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(width: 280, height: 44)
                
                HStack(spacing: 12) {
                    VStack { Divider() }
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                    VStack { Divider() }
                }

                CustomTextField(placeholder: "Email", text: $email)
                CustomSecureField(placeholder: "Password", text: $password)
                
                Button(action: handleEmailSignIn) {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 280)

            VStack(spacing: 6) {
                Text("Don't have an account?")
                    .font(.footnote)

                Button("Sign Up") {
                    showSignUp = true
                }
                .font(.footnote.bold())
                .sheet(isPresented: $showSignUp) {
                    SignUpView()
                        .environmentObject(appState)
                }
            }

            Spacer()
        }
        .padding(32)
    }

    private func handleGoogleSignIn() {
        guard let presentingWindow = NSApplication.shared.keyWindow else { return }
        Task {
            await AuthManager.shared.handleGoogleSignIn(presentingWindow: presentingWindow, appState: appState)
        }
    }
    
    private func handleEmailSignIn() {
        // Email & Password sign in logic will go here
    }
}
