import SwiftUI
import FirebaseFirestore

struct VenuesSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    @State private var venues: [Venue] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            } else if venues.isEmpty {
                Text("No venue information found in your shows.")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
                Spacer()
            } else {
                VenueTableView(venues: filteredAndSorted(), sortField: $sortField, sortAscending: $sortAscending)
            }
        }
        .onAppear {
            Task {
                await fetchVenuesFromShows()
            }
        }
    }

    private func fetchVenuesFromShows() async {
        self.isLoading = true
        let db = Firestore.firestore()
        
        do {
            // Step 1: Find all tours owned by the current user
            let toursSnapshot = try await db.collection("tours").whereField("ownerId", isEqualTo: userID).getDocuments()
            let tourIDs = toursSnapshot.documents.compactMap { $0.documentID }

            if tourIDs.isEmpty {
                self.venues = []
                self.isLoading = false
                return
            }

            // Step 2: Find all shows associated with those tours
            let showsSnapshot = try await db.collection("shows").whereField("tourId", in: tourIDs).getDocuments()
            let shows = showsSnapshot.documents.compactMap { try? $0.data(as: Show.self) }
            
            // Step 3: Transform Show data into Venue data and remove duplicates by venue name
            var uniqueVenues: [String: Venue] = [:]
            for show in shows {
                let venue = Venue(
                    id: show.id, // Use show's ID as it's a convenient unique identifier
                    ownerId: userID,
                    name: show.venueName,
                    address: show.venueAddress,
                    city: show.city,
                    country: show.country,
                    capacity: nil, // Not available in Show model
                    contactName: show.contactName,
                    contactEmail: show.contactEmail,
                    contactPhone: show.contactPhone,
                    createdAt: show.createdAt
                )
                
                // Use the venue name as the key to handle de-duplication
                if uniqueVenues[venue.name] == nil {
                    uniqueVenues[venue.name] = venue
                }
            }
            
            await MainActor.run {
                self.venues = Array(uniqueVenues.values)
                self.isLoading = false
            }
            
        } catch {
            print("Error fetching venues from shows: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
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
