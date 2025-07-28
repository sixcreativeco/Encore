import SwiftUI

struct HotelTableView: View {
    let hotels: [Hotel]
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Header Row
                HStack {
                    SortableHeader(title: "Name", field: "Name", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "City", field: "City", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "Address", field: "Address", sortField: $sortField, sortAscending: $sortAscending)
                    SortableHeader(title: "Booking Ref", field: "BookingRef", sortField: $sortField, sortAscending: $sortAscending)
                }
                .padding(.vertical, 8)

                Divider()

                // Data Rows
                ForEach(sortedHotels) { hotel in
                    HStack {
                        Text(hotel.name).frame(maxWidth: .infinity, alignment: .leading)
                        Text(hotel.city).frame(maxWidth: .infinity, alignment: .leading)
                        Text(hotel.address).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
                        Text(hotel.bookingReference ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }

    private var sortedHotels: [Hotel] {
        hotels.sorted { a, b in
            let lhs: String
            let rhs: String
            switch sortField {
            case "Name":
                lhs = a.name
                rhs = b.name
            case "City":
                lhs = a.city
                rhs = b.city
            case "Address":
                lhs = a.address
                rhs = b.address
            case "BookingRef":
                lhs = a.bookingReference ?? ""
                rhs = b.bookingReference ?? ""
            default:
                lhs = a.name
                rhs = b.name
            }
            return sortAscending ? lhs.localizedCompare(rhs) == .orderedAscending : lhs.localizedCompare(rhs) == .orderedDescending
        }
    }
}
