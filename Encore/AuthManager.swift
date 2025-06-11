import Foundation
import FirebaseCore
import FirebaseAuth
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
    
    func handleGoogleSignIn(presentingWindow: NSWindow, appState: AppState) async {
        let config = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")
        GIDSignIn.sharedInstance.configuration = config
        
        guard let result = try? await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) else { return }
        guard let idToken = result.user.idToken?.tokenString else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            DispatchQueue.main.async {
                appState.isLoggedIn = true
            }
            
            // Create user Firestore document if needed
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid)
            
        } catch {
            print("❌ Firebase Sign In Failed: \(error.localizedDescription)")
        }
    }
    
    private func createUserDocumentIfNeeded(userID: String) async {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userID)
        
        do {
            let document = try await ref.getDocument()
            if document.exists {
                return // user document already exists
            } else {
                let userData: [String: Any] = [
                    "uid": userID,
                    "email": self.user?.email ?? "",
                    "displayName": self.user?.displayName ?? "",
                    "createdAt": Timestamp(date: Date())
                ]
                
                try await ref.setData(userData)
                print("✅ User document created in Firestore")
            }
        } catch {
            print("❌ Failed creating user document: \(error.localizedDescription)")
        }
    }
    
    func signOut(appState: AppState) {
        do {
            try Auth.auth().signOut()
            self.user = nil
            DispatchQueue.main.async {
                appState.isLoggedIn = false
            }
        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")
        }
    }
}
