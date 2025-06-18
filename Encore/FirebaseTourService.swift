import Foundation
import FirebaseFirestore

struct FirebaseTourService {
    static let db = Firestore.firestore()

    static func loadCrew(userID: String, tourID: String) async throws -> [CrewMember] {
        let snapshot = try await db.collection("users").document(userID).collection("tours").document(tourID).collection("crew").getDocuments()

        let crew: [CrewMember] = snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let email = data["email"] as? String,
                  let roles = data["roles"] as? [String] else {
                return nil
            }
            // This assumes your CrewMember model can be initialized with an id.
            return CrewMember(id: doc.documentID, name: name, email: email, roles: roles)
        }
        return crew
    }
    
    static func fetchShows(forTour tourID: String, ownerID: String) async throws -> [ShowModel] {
        let path = db.collection("users").document(ownerID).collection("tours").document(tourID).collection("shows")
        let snapshot = try await path.order(by: "date", descending: false).getDocuments()
        let shows = snapshot.documents.compactMap { ShowModel(from: $0) }
        return shows
    }
}
