import SwiftUI
import FirebaseFirestore

struct VenueTableView: View {
    // FIX: The view now accepts an array of our new 'Venue' model.
    let venues: [Venue]
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    var body: some View {
        ScrollView { // make the table scrollable
            VStack(alignment: .leading) {
                HStack {
                    SortableHeader(title: "Name", field: "Name", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "City", field: "City", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "Address", field: "Address", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "Contact Name", field: "ContactName", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "Contact Email", field: "ContactEmail", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "Contact Phone", field: "ContactPhone", sortField: $sortField, sortAscending: $sortAscending)
                }
                .padding(.vertical, 8)

                Divider()

                // FIX: The ForEach now iterates correctly over the new [Venue] array.
                ForEach(sortedVenues) { venue in
                    HStack {
                        Text(venue.name).frame(maxWidth: .infinity, alignment: .leading)
                        Text(venue.city).frame(maxWidth: .infinity, alignment: .leading)
                        Text(venue.address ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        Text(venue.contactName ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        Text(venue.contactEmail ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        Text(venue.contactPhone ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }

    // FIX: This computed property now sorts the new [Venue] array directly.
    private var sortedVenues: [Venue] {
        venues.sorted { a, b in
            let lhs = sortValue(for: a)
            let rhs = sortValue(for: b)
            return sortAscending ? lhs < rhs : lhs > rhs
        }
    }

    // FIX: This function now accepts the new 'Venue' model.
    private func sortValue(for venue: Venue) -> String {
        switch sortField {
        case "Name": return venue.name
        case "City": return venue.city
        case "Address": return venue.address ?? ""
        case "ContactName": return venue.contactName ?? ""
        case "ContactEmail": return venue.contactEmail ?? ""
        case "ContactPhone": return venue.contactPhone ?? ""
        default: return venue.name
        }
    }
}
