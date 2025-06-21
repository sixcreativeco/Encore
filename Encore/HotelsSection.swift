import SwiftUI
import FirebaseFirestore

struct HotelsSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    // FIX: The state now uses our new, top-level 'Hotel' model.
    @State private var hotels: [Hotel] = []
    @State private var isLoading: Bool = true
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            } else {
                // This will cause an error in HotelTableView next, which is expected.
                HotelTableView(hotels: filteredAndSorted(), sortField: $sortField, sortAscending: $sortAscending)
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
        
        // This is now ONE simple, real-time listener on the top-level /hotels collection.
        listener = db.collection("hotels")
            .whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading hotels: \(error?.localizedDescription ?? "Unknown")")
                    self.isLoading = false
                    return
                }
                
                self.hotels = documents.compactMap { try? $0.data(as: Hotel.self) }
                self.isLoading = false
            }
    }

    private func filteredAndSorted() -> [Hotel] {
        let filtered = hotels.filter { hotel in
            let matchesFilter = selectedFilter == "All" || (hotel.city ?? "") == selectedFilter
            let matchesSearch = searchText.isEmpty || hotel.name.lowercased().contains(searchText.lowercased())
            return matchesFilter && matchesSearch
        }

        return filtered.sorted { lhs, rhs in
            let lhsValue = sortFieldValue(lhs)
            let rhsValue = sortFieldValue(rhs)
            return sortAscending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }

    private func sortFieldValue(_ hotel: Hotel) -> String {
        switch sortField {
        case "City": return hotel.city ?? ""
        default: return hotel.name
        }
    }
}
