import SwiftUI
import Kingfisher
import FirebaseAuth

struct JoinTourView: View {
    @Environment(\.dismiss) var dismiss
    let invitationDetails: InvitationService.InvitationDetails

    @State private var name: String
    @State private var email: String
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(invitationDetails: InvitationService.InvitationDetails) {
        self.invitationDetails = invitationDetails
        self._name = State(initialValue: invitationDetails.crew.name)
        self._email = State(initialValue: invitationDetails.crew.email ?? "")
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("You're Invited!")
                .font(.largeTitle.bold())

            tourPreview

            Text("Create an account to join the tour as **\(invitationDetails.crew.roles.joined(separator: ", "))**.")
                .font(.headline)
                .multilineTextAlignment(.center)

            form
            
            Spacer()
            
            joinButton
        }
        .padding(32)
        .frame(width: 450)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var tourPreview: some View {
        VStack {
            KFImage(URL(string: invitationDetails.tour.posterURL ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .shadow(radius: 5)
            
            Text(invitationDetails.tour.artist)
                .font(.headline)
            Text(invitationDetails.tour.tourName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var form: some View {
        VStack(spacing: 16) {
            CustomTextField(placeholder: "Full Name", text: $name)
            CustomTextField(placeholder: "Email", text: $email)
            CustomSecureField(placeholder: "Create Password", text: $password)
        }
    }

    private var joinButton: some View {
        Button(action: joinAndCreateAccount) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView().colorInvert()
                } else {
                    Text("Join & Create Account")
                }
                Spacer()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(!isFormValid || isLoading)
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6
    }
    
    private func joinAndCreateAccount() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let newUser = try await AuthManager.shared.handleEmailSignUp(email: email, password: password, displayName: name) else {
                    throw URLError(.cannotCreateFile)
                }
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    InvitationService.shared.acceptInvitation(withCode: invitationDetails.code, forNewUser: newUser.uid) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
