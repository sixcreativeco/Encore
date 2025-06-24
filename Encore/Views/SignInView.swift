import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var inviteCode: String = ""
    @State private var showSignUp: Bool = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // State for the Join with Code flow
    @State private var showJoinView = false
    @State private var invitationDetails: InvitationService.InvitationDetails?

    var body: some View {
        HStack(spacing: 0) {
            signInForm
                .frame(width: 450)
                .background(.regularMaterial)
            
            SignInDynamicContentView()
        }
        .ignoresSafeArea()
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
        .sheet(isPresented: $showJoinView) {
            if let details = invitationDetails {
                JoinTourView(invitationDetails: details)
            }
        }
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
                GoogleSignInButton { Task { await handleGoogleSignIn() } }
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
                        if isLoading && inviteCode.isEmpty { ProgressView().colorInvert() }
                        else { Text("Sign In") }
                        Spacer()
                    }
                    .fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(10)
                }
                .buttonStyle(.plain).disabled(isLoading || email.isEmpty || password.isEmpty)
                
                HStack(spacing: 8) {
                    CustomTextField(placeholder: "Join with Code", text: $inviteCode)
                    Button("Join") { handleJoinWithCode() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || inviteCode.isEmpty)
                }
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
    
    private func handleJoinWithCode() {
        isLoading = true
        errorMessage = nil
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        InvitationService.shared.fetchInvitationDetails(with: code) { result in
            isLoading = false
            switch result {
            case .success(let details):
                self.invitationDetails = details
                self.showJoinView = true
            case .failure(let error as InvitationService.InvitationError):
                switch error {
                case .notFound:
                    self.errorMessage = "Invitation code not found."
                case .expired:
                    self.errorMessage = "This invitation code has expired."
                default:
                    self.errorMessage = "There was a problem with this invitation code. Please contact the tour manager."
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func handleGoogleSignIn() async {
        guard let presentingWindow = NSApplication.shared.keyWindow else {
            return
        }
        
        _ = await AuthManager.shared.handleGoogleSignIn(presentingWindow: presentingWindow)
    }
    
    private func handleEmailSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await AuthManager.shared.handleEmailSignIn(email: email, password: password)
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
