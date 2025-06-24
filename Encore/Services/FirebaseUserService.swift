import Foundation
import FirebaseFirestore

class FirebaseUserService {
    
    static let shared = FirebaseUserService()
    private let db = Firestore.firestore()
    
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
        // The fix is here: The map closure requires an argument, which we ignore with `_ in`.
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
