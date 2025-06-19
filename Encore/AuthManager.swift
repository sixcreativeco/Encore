import Foundation
@preconcurrency import FirebaseCore
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AppKit

class AuthManager: ObservableObject {

    static let shared = AuthManager()
    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        self.user = Auth.auth().currentUser
    }

    @Published var user: User?

    func handleGoogleSignIn(presentingWindow: NSWindow) async -> User? {
        // ADDED: Log the start of the process.
        print("LOG: 1. AuthManager.handleGoogleSignIn called.")
        
        let config = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")
        GIDSignIn.sharedInstance.configuration = config

        do {
            guard let result = try? await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) else {
                print("LOG: ❌ GIDSignIn returned nil. User may have cancelled.")
                return nil
            }
            
            // ADDED: Log success from Google Sign-In SDK.
            print("LOG: 2. GIDSignIn successful. User: \(result.user.profile?.name ?? "N/A")")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("LOG: ❌ Could not get idToken from Google result.")
                return nil
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            
            // ADDED: Log success from Firebase Auth.
            print("LOG: 3. Firebase signIn successful. UID: \(authResult.user.uid)")
            
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid)
            
            return authResult.user
            
        } catch {
            // ADDED: Log any errors during the process.
            print("LOG: ❌ ERROR in AuthManager.handleGoogleSignIn: \(error.localizedDescription)")
            return nil
        }
    }

    private func createUserDocumentIfNeeded(userID: String) async {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userID)

        do {
            let document = try await ref.getDocument()
            if document.exists {
                print("LOG: User document already exists for UID: \(userID)")
                return
            }
            
            let userData: [String: Any] = [ "uid": userID, "email": self.user?.email ?? "", "displayName": self.user?.displayName ?? "", "createdAt": Timestamp(date: Date()) ]
            try await ref.setData(userData)
            print("LOG: ✅ User document created for UID: \(userID)")

        } catch {
            print("LOG: ❌ Failed creating user document: \(error.localizedDescription)")
        }
    }
  
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("❌ Firebase Sign Out Failed: \(error.localizedDescription)")
        }
    }
}
