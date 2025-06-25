import Foundation
@preconcurrency import FirebaseCore
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseMessaging // Import FirebaseMessaging

#if os(macOS)
import AppKit
#endif

class AuthManager: ObservableObject {

    static let shared = AuthManager()
    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        self.user = Auth.auth().currentUser
    }

    @Published var user: User?
    
    func updateFCMToken() {
        guard let userID = user?.uid else { return }
        
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM registration token: \(error)")
                return
            }
            
            guard let fcmToken = token else {
                print("❌ FCM token was nil.")
                return
            }
            
            print("✅ FCM Registration Token: \(fcmToken)")
            
            let db = Firestore.firestore()
            let ref = db.collection("users").document(userID)
            
            // Using arrayUnion prevents duplicate tokens from being added.
            // We will store FCM tokens in a new field to avoid confusion.
            ref.updateData([
                "fcmTokens": FieldValue.arrayUnion([fcmToken])
            ]) { error in
                if let error = error {
                    print("❌ Error saving FCM token: \(error.localizedDescription)")
                } else {
                    print("✅ FCM token saved for user: \(userID)")
                }
            }
        }
    }

    func handleEmailSignIn(email: String, password: String) async throws -> User? {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = authResult.user
            return authResult.user
        } catch {
            print("LOG: ❌ ERROR in AuthManager.handleEmailSignIn: \(error.localizedDescription)")
            throw error
        }
    }

    func handleEmailSignUp(email: String, password: String, displayName: String) async throws -> User? {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            self.user = Auth.auth().currentUser
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid)
            
            return authResult.user
        } catch {
            print("LOG: ❌ ERROR in AuthManager.handleEmailSignUp: \(error.localizedDescription)")
            throw error
        }
    }

    #if os(macOS)
    func handleGoogleSignIn(presentingWindow: NSWindow) async -> User? {
        print("LOG: 1. AuthManager.handleGoogleSignIn called.")
        
        let config = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")
        GIDSignIn.sharedInstance.configuration = config

        do {
            guard let result = try? await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) else {
                print("LOG: ❌ GIDSignIn returned nil. User may have cancelled.")
                return nil
            }
            
            print("LOG: 2. GIDSignIn successful. User: \(result.user.profile?.name ?? "N/A")")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("LOG: ❌ Could not get idToken from Google result.")
                return nil
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            
            print("LOG: 3. Firebase signIn successful. UID: \(authResult.user.uid)")
            
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid)
            
            return authResult.user
            
        } catch {
            print("LOG: ❌ ERROR in AuthManager.handleGoogleSignIn: \(error.localizedDescription)")
            return nil
        }
    }
    #endif

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
            print("✅ User document created for UID: \(userID)")

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
