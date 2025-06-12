import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tourID: String

    // Mock data — you'll later replace with Firestore pull
    @State private var itineraryItems: [ItineraryItem] = [
        ItineraryItem(type: .flight, title: "MEL - MNL", time: "1:30PM", note: "50min stop at BWN"),
        ItineraryItem(type: .arrival, title: "Arrive in Manila", time: "8:45PM", note: "Meet with driver at Arrivals"),
        ItineraryItem(type: .loadIn, title: "Load In", time: "8:45PM", note: "Meet with driver at Arrivals")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Itinerary", onAdd: {
                // Add itinerary logic
            })

            ForEach(itineraryItems, id: \.self) { item in
                ItineraryCard(item: item)
            }
        }
    }
}

struct ItineraryItem: Hashable {
    enum ItemType { case flight, arrival, loadIn }
    var type: ItemType
    var title: String
    var time: String
    var note: String
}

struct ItineraryCard: View {
    var item: ItineraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                icon
                Text(item.title).font(.headline)
                Spacer()
                Text(item.time).font(.subheadline)
            }
            Text(item.note).font(.footnote).foregroundColor(.gray)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var icon: some View {
        switch item.type {
        case .flight: return Image(systemName: "airplane").font(.title2)
        case .arrival: return Image(systemName: "airplane.arrival").font(.title2)
        case .loadIn: return Image(systemName: "truck").font(.title2)
        }
    }
}
