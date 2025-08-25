import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseMessaging

#if os(macOS)
import AppKit
#else
import UIKit
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
    
    // --- CORRECTED SIGN UP FUNCTION ---
    // The signOut() call has been removed. The user will remain logged in
    // to complete the onboarding process.
    func handleEmailSignUp(email: String, password: String, displayName: String) async throws -> (user: User?, needsVerification: Bool) {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            self.user = Auth.auth().currentUser
            
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid, phoneNumber: nil)
            
            // Send the verification email
            try await authResult.user.sendEmailVerification()
            
            // DO NOT SIGN OUT HERE.
            
            return (authResult.user, true)
            
        } catch {
            print("LOG: ❌ ERROR in AuthManager.handleEmailSignUp: \(error.localizedDescription)")
            throw error
        }
    }
    
    // --- Other functions remain the same ---

    func updateFCMToken() {
        guard let userID = user?.uid else { return }
        Messaging.messaging().token { token, error in
            if let error = error { print("❌ Error fetching FCM token: \(error)"); return }
            guard let fcmToken = token else { print("❌ FCM token was nil."); return }
            let ref = Firestore.firestore().collection("users").document(userID)
            ref.updateData(["fcmTokens": FieldValue.arrayUnion([fcmToken])])
        }
    }

    func handleEmailSignIn(email: String, password: String) async throws -> User? {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = authResult.user
            return authResult.user
        } catch {
            throw error
        }
    }

    #if os(macOS)
    func handleGoogleSignIn(presentingWindow: NSWindow) async -> User? {
        let config = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")
        GIDSignIn.sharedInstance.configuration = config
        do {
            guard let result = try? await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) else { return nil }
            guard let idToken = result.user.idToken?.tokenString else { return nil }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid, phoneNumber: nil)
            return authResult.user
        } catch {
            return nil
        }
    }
    #endif
    
    #if os(iOS)
    func handleGoogleSignIn() async -> User? {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return nil }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else { return nil }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            await self.createUserDocumentIfNeeded(userID: authResult.user.uid, phoneNumber: nil)
            return authResult.user
        } catch {
            return nil
        }
    }
    #endif

    private func createUserDocumentIfNeeded(userID: String, phoneNumber: String?) async {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userID)
        do {
            let document = try await ref.getDocument()
            if document.exists { return }
            
            var userData: [String: Any] = [
                "uid": userID,
                "email": self.user?.email ?? "",
                "displayName": self.user?.displayName ?? "",
                "createdAt": Timestamp(date: Date())
            ]
            if let phone = phoneNumber, !phone.isEmpty {
                userData["phone"] = phone
            }
            
            try await ref.setData(userData)
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
