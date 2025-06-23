import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            signInForm
                .frame(width: 450)
                .background(.regularMaterial)
            
            SignInDynamicContentView()
        }
        .ignoresSafeArea()
        .alert("Sign In Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
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
                    Task {
                        await handleGoogleSignIn()
                    }
                }
                .frame(width: 280, height: 44)

                SignInWithAppleButton( .signIn, onRequest: { _ in }, onCompletion: { _ in } )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 280, height: 44)
                
                HStack(spacing: 12) {
                    VStack { Divider() }; Text("OR").font(.caption).foregroundColor(.secondary).padding(.vertical, 16); VStack { Divider() }
                }

                CustomTextField(placeholder: "Email", text: $email)
                CustomSecureField(placeholder: "Password", text: $password)
                
                Button(action: handleEmailSignIn) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView().colorInvert()
                        } else {
                            Text("Sign In")
                        }
                        Spacer()
                    }
                    .fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
            .frame(width: 280)

            VStack(spacing: 6) {
                Text("Don't have an account?").font(.footnote)
                Button("Sign Up") { showSignUp = true }.font(.footnote.bold())
                    .sheet(isPresented: $showSignUp) { SignUpView() }
            }
            Spacer()
        }
        .padding(32)
    }

    private func handleGoogleSignIn() async {
        print("LOG: 0. Google Sign-In button pressed in SignInView.")
        
        guard let presentingWindow = NSApplication.shared.keyWindow else {
            print("LOG: ❌ Could not get key window.")
            return
        }
        
        let user = await AuthManager.shared.handleGoogleSignIn(presentingWindow: presentingWindow)
        
        if let user = user {
            print("LOG: 4. AuthManager returned user. Updating appState with UID: \(user.uid)")
            // AppState listener will handle the transition
        } else {
            print("LOG: 4. AuthManager returned nil. No state change.")
        }
    }
    
    private func handleEmailSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await AuthManager.shared.handleEmailSignIn(email: email, password: password)
                // AppState listener will handle successful sign-in
                await MainActor.run { isLoading = false }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
