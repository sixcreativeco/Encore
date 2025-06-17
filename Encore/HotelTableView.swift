import SwiftUI

struct HotelTableView: View {
    let hotels: [HotelModel]
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

            ForEach(hotels) { hotel in
                HStack {
                    Text(hotel.name).frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.city).frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.address).frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.bookingReference ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    Text(hotel.contactName ?? "").frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }
}
