import Foundation
import FirebaseFirestore

struct FirebaseTourService {
    static let db = Firestore.firestore()

    // NEW: Function to search for existing contacts by name
    static func searchContacts(forName query: String, ownerId: String) async throws -> [Contact] {
        guard !query.isEmpty else { return [] }
        
        let snapshot = try await db.collection("contacts")
            .whereField("ownerId", isEqualTo: ownerId)
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments()

        let contacts = snapshot.documents.compactMap { try? $0.data(as: Contact.self) }
        return contacts
    }

    // FIX: Updated to fetch from the top-level /tourCrew collection.
    static func loadCrew(forTour tourID: String) async throws -> [TourCrew] {
        let snapshot = try await db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .getDocuments()

        let crew = snapshot.documents.compactMap { try? $0.data(as: TourCrew.self) }
        return crew
    }
    
    // FIX: Updated to fetch from the top-level /shows collection.
    static func fetchShows(forTour tourID: String) async throws -> [Show] {
        let snapshot = try await db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "date", descending: false)
            .getDocuments()
            
        let shows = snapshot.documents.compactMap { try? $0.data(as: Show.self) }
        return shows
    }
}
