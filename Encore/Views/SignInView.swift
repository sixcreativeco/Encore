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
                    Text("Sign In")
                        .fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 280)

            VStack(spacing: 6) {
                Text("Don't have an account?").font(.footnote)
                Button("Sign Up") { showSignUp = true }.font(.footnote.bold())
                    .sheet(isPresented: $showSignUp) { SignUpView().environmentObject(appState) }
            }
            Spacer()
        }
        .padding(32)
    }

    private func handleGoogleSignIn() async {
        // ADDED: Log the initial button press action.
        print("LOG: 0. Google Sign-In button pressed in SignInView.")
        
        guard let presentingWindow = NSApplication.shared.keyWindow else {
            print("LOG: ❌ Could not get key window.")
            return
        }
        
        let user = await AuthManager.shared.handleGoogleSignIn(presentingWindow: presentingWindow)
        
        // ADDED: Log the result from the AuthManager and the subsequent state change.
        if let user = user {
            print("LOG: 4. AuthManager returned user. Updating appState with UID: \(user.uid)")
            appState.userID = user.uid
        } else {
            print("LOG: 4. AuthManager returned nil. No state change.")
        }
    }
    
    private func handleEmailSignIn() {}
}
