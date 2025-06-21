import Foundation
import FirebaseFirestore

struct FirebaseTourService {
    static let db = Firestore.firestore()

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
