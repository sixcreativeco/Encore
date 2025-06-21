import SwiftUI
import FirebaseFirestore

struct VenuesSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    // FIX: The state now uses our new, top-level 'Venue' model.
    @State private var venues: [Venue] = []
    @State private var isLoading: Bool = true
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            } else {
                ScrollView {
                    // This will cause an error in VenueTableView next, which is expected.
                    VenueTableView(venues: filteredAndSorted(), sortField: $sortField, sortAscending: $sortAscending)
                }
            }
        }
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
    }

    // --- FIX IS HERE ---
    private func setupListener() {
        self.isLoading = true
        listener?.remove()
        
        let db = Firestore.firestore()
        
        // This is now ONE simple, real-time listener on the top-level /venues collection.
        // It only fetches venues created by the current user.
        listener = db.collection("venues")
            .whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading venues: \(error?.localizedDescription ?? "Unknown")")
                    self.isLoading = false
                    return
                }
                
                // We use Codable to automatically decode into our new [Venue] model.
                self.venues = documents.compactMap { try? $0.data(as: Venue.self) }
                self.isLoading = false
            }
    }

    private func filteredAndSorted() -> [Venue] {
        let filtered = venues.filter { venue in
            let matchesFilter = selectedFilter == "All" || venue.city == selectedFilter
            let matchesSearch = searchText.isEmpty || venue.name.lowercased().contains(searchText.lowercased())
            return matchesFilter && matchesSearch
        }

        return filtered.sorted { lhs, rhs in
            let lhsValue = sortFieldValue(lhs)
            let rhsValue = sortFieldValue(rhs)
            return sortAscending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }

    private func sortFieldValue(_ venue: Venue) -> String {
        switch sortField {
        case "City": return venue.city
        default: return venue.name
        }
    }
}
