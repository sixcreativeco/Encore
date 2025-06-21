import SwiftUI

struct HotelTableView: View {
    // FIX: The view now accepts an array of our new 'Hotel' model.
    let hotels: [Hotel]
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SortableHeader(title: "Name", field: "Name", sortField: $sortField, sortAscending: $sortAscending)
                SortableHeader(title: "City", field: "City", sortField: $sortField, sortAscending: $sortAscending)
                SortableHeader(title: "Address", field: "Address", sortField: $sortField, sortAscending: $sortAscending)
                SortableHeader(title: "Booking Ref", field: "BookingRef", sortField: $sortField, sortAscending: $sortAscending)
                SortableHeader(title: "Contact", field: "Contact", sortField: $sortField, sortAscending: $sortAscending)
            }
            .padding(.vertical, 8)

            Divider()

            // FIX: The ForEach now iterates correctly over the new [Hotel] array.
            ForEach(hotels) { hotel in
                HStack {
                    Text(hotel.name).frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.city ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.address ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    // The new Hotel model doesn't have a bookingReference, so this is removed for now.
                    // It can be added back to the model if needed.
                    Text("").frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.contactInfo ?? "").frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }
}
