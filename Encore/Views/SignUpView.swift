import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    // Form state
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    // View state
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPasswordVisible = false
    @State private var showVerificationMessage = false
    
    // State to trigger the onboarding flow
    @State private var showOnboardingFlow = false
    @State private var newUserID: String?
    
    @Environment(\.dismiss) var dismiss

    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
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
            #endif

            Spacer()

            if showVerificationMessage {
                verificationMessageView
            } else {
                signUpForm
            }
            
            Spacer()
            Spacer()
        }
        .frame(width: 450, height: 550)
        // --- THIS IS THE FIX ---
        // The sheet is presented when showOnboardingFlow is true.
        // When it dismisses, we sign the user out and show the verification message.
        .sheet(isPresented: $showOnboardingFlow, onDismiss: {
            print("🔵 [SignUpView DEBUG] Onboarding sheet dismissed. Signing user out.")
            AuthManager.shared.signOut()
            showVerificationMessage = true
        }) {
            if let userID = newUserID {
                OnboardingFlowView(userID: userID) {
                    // This completion is called from OnboardingFlowView when the user is done.
                    // It tells this sheet to dismiss itself.
                    print("🔵 [SignUpView DEBUG] Onboarding onComplete called. Dismissing sheet.")
                    showOnboardingFlow = false
                }
            }
        }
        .alert("Sign Up Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }
    
    private var signUpForm: some View {
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
                
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        CustomTextField(placeholder: "Password (6+ characters)", text: $password)
                    } else {
                        CustomSecureField(placeholder: "Password (6+ characters)", text: $password)
                    }
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                }
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
            .frame(width: 300)
            .padding()
            .background(isFormValid ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .buttonStyle(.plain)
            .disabled(!isFormValid || isLoading)
        }
    }
    
    private var verificationMessageView: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.check.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Check Your Email")
                .font(.largeTitle.bold())
            
            Text("We've sent a verification link to **\(email)**. Please check your inbox to activate your account before signing in.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
            .frame(width: 300)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .buttonStyle(.plain)
        }
        .padding(32)
    }
    
    private func handleSignUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔵 [SignUpView DEBUG] Attempting to create account...")
                let result = try await AuthManager.shared.handleEmailSignUp(
                    email: email,
                    password: password,
                    displayName: name
                )
                
                if let newUser = result.user {
                    print("✅ [SignUpView DEBUG] Account created for UID: \(newUser.uid). Triggering onboarding flow.")
                    self.newUserID = newUser.uid
                    self.showOnboardingFlow = true
                } else {
                    errorMessage = "Could not create user account."
                }
            } catch {
                print("❌ [SignUpView DEBUG] Sign-up failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
