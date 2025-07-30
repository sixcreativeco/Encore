import SwiftUI

struct GuestListCard: View {
    var guest: GuestListItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(guest.name).font(.body)
                if let additional = guest.additionalGuests, !additional.isEmpty, additional != "0" {
                    Text("+\(additional)").font(.subheadline).foregroundColor(.gray)
                }
            }

            if let note = guest.note, !note.isEmpty {
                Text(note).font(.subheadline).foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
}
