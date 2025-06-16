import Foundation
import FirebaseFirestore

struct FirebaseTourService {
    static let db = Firestore.firestore()

    static func loadCrew(userID: String, tourID: String, completion: @escaping ([CrewMember]) -> Void) {
        db.collection("users").document(userID).collection("tours").document(tourID).collection("crew")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let crew: [CrewMember] = documents.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let email = data["email"] as? String,
                          let roles = data["roles"] as? [String] else {
                        return nil
                    }
                    return CrewMember(id: doc.documentID, name: name, email: email, roles: roles)
                }
                completion(crew)
            }
    }
}
