import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SelectTourViewModel: ObservableObject {
    @Published var toursWithShowCounts: [(tour: Tour, showCount: Int)] = []
    @Published var isLoading = true
    
    private let db = Firestore.firestore()
    
    func fetchTours(for userID: String) async {
        self.isLoading = true
        do {
            // 1. Fetch all tours for the user
            let toursSnapshot = try await db.collection("tours").whereField("ownerId", isEqualTo: userID).getDocuments()
            let tours = toursSnapshot.documents.compactMap { try? $0.data(as: Tour.self) }
            
            guard !tours.isEmpty else {
                self.toursWithShowCounts = []
                self.isLoading = false
                return
            }
            
            // 2. Fetch all shows for all of those tours in one query
            let tourIDs = tours.compactMap { $0.id }
            let showsSnapshot = try await db.collection("shows").whereField("tourId", in: tourIDs).getDocuments()
            let shows = showsSnapshot.documents.compactMap { try? $0.data(as: Show.self) }
            
            // 3. Group shows by tourId to get counts client-side
            let showCountsByTourID = Dictionary(grouping: shows, by: { $0.tourId })
                .mapValues { $0.count }
            
            // 4. Combine tours with their show counts and sort
            self.toursWithShowCounts = tours.map { tour in
                let count = showCountsByTourID[tour.id ?? ""] ?? 0
                return (tour: tour, showCount: count)
            }.sorted { $0.tour.startDate.dateValue() > $1.tour.startDate.dateValue() }
            
            self.isLoading = false
            
        } catch {
            print("Error fetching tours and show counts: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
}
