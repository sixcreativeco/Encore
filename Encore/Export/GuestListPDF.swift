import SwiftUI
import FirebaseFirestore

struct GuestListPDF: View {
    let tour: Tour
    let show: Show
    let guests: [GuestListItemModel]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading) {
                Text(tour.artist.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                Text("Guest List: \(show.city)")
                    .font(.system(size: 36, weight: .bold))
                Text("\(show.venueName) - \(dateFormatter.string(from: show.date.dateValue()))")
                    .font(.title2).foregroundColor(.secondary)
            }
            
            Divider()

            // Guest Table
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("Name").bold().frame(maxWidth: .infinity, alignment: .leading)
                    Text("+").bold().frame(width: 50)
                    Text("Note").bold().frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.callout)
                .padding(12)
                .background(Color.gray.opacity(0.1))

                // Table Rows
                ForEach(guests) { guest in
                    VStack(spacing: 0) {
                        HStack {
                            Text(guest.name).frame(maxWidth: .infinity, alignment: .leading)
                            Text(guest.additionalGuests ?? "0").frame(width: 50)
                            Text(guest.note ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        Divider()
                    }
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4
        .background(Color.white)
    }
}
