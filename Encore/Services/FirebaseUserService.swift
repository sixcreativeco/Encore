import Foundation
import FirebaseFirestore

class FirebaseUserService {
    
    static let shared = FirebaseUserService()
    private let db = Firestore.firestore()
    
    /// Checks if a user document exists for a given email.
    /// - a `userID` string if found, otherwise `nil`.
    func checkUserExists(byEmail email: String, completion: @escaping (String?) -> Void) {
        // This query correctly checks the top-level /users collection.
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                // A user with this email exists, return their ID.
                completion(doc.documentID)
            } else {
                // No user found with this email.
                completion(nil)
            }
        }
    }
    
    // The shared tour function can remain, though it may need refactoring later.
    func addSharedTour(for userID: String, tourID: String, creatorUserID: String, role: [String], visibility: String) {
        let sharedTourRef = db.collection("users").document(userID).collection("sharedTours").document(tourID)
        let data: [String: Any] = [
            "creatorUserID": creatorUserID,
            "dateAdded": Date(),
            "roles": role,
            "visibility": visibility
        ]
        sharedTourRef.setData(data)
    }
}
