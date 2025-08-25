import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseUserService {
    
    static let shared = FirebaseUserService()
    private let db = Firestore.firestore()
    
    /// Saves the collected onboarding survey data to the user's document in Firestore.
    func saveOnboardingData(_ data: OnboardingData, for userId: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userId)
        do {
            // Use merge: true to add the new onboarding fields without overwriting existing user data.
            try userRef.setData(from: data, merge: true, completion: completion)
        } catch {
            print("Error encoding onboarding data for Firestore: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    func checkUserExists(byEmail email: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                completion(doc.documentID)
            } else {
                completion(nil)
            }
        }
    }
    
    func createInvitationNotification(for tour: Tour, recipientId: String, inviterId: String, inviterName: String, crewDocId: String, roles: [String]) {
        let notification = TourInvitationNotification(
            recipientId: recipientId,
            inviterId: inviterId,
            inviterName: inviterName,
            tourId: tour.id ?? "",
            tourName: tour.tourName,
            artistName: tour.artist,
            crewDocId: crewDocId,
            roles: roles
        )
        
        do {
            try db.collection("notifications").addDocument(from: notification)
        } catch {
            print("Error creating notification: \(error.localizedDescription)")
        }
    }
    
    func createInvitation(for crewDocId: String, tourId: String, inviterId: String, completion: @escaping (String?) -> Void) {
        let code = String((0..<6).map{ _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let invitationData: [String: Any] = [
            "tourId": tourId,
            "crewDocId": crewDocId,
            "inviterId": inviterId,
            "createdAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: expirationDate)
        ]

        db.collection("invitations").document(code).setData(invitationData) { error in
            if let error = error {
                print("Error saving invitation: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(code)
            }
        }
    }
}
