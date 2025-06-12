import SwiftUI

struct ItineraryItemCard: View {
    let item: ItineraryItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.type.iconName)
                    .font(.title2)
                Text(item.title).font(.headline)
                Spacer()
                Text(item.time.formatted(date: .omitted, time: .shortened))
            }
            if let note = item.note, !note.isEmpty {
                Text(note).font(.subheadline).foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
