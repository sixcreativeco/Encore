import Foundation
import FirebaseFirestore

class FirebaseUserService {
    
    static let shared = FirebaseUserService()
    private let db = Firestore.firestore()
    
    // Check if user exists by email
    func checkUserExists(byEmail email: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                completion(doc.documentID)
            } else {
                completion(nil)
            }
        }
    }
    
    // Create shared tour reference
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
