import SwiftUI
import FirebaseFirestore

struct MobileTourItineraryView: View {
    let tour: Tour
    
    // State for the fetched items and loading status
    @State private var itemsByDate: [Date: [ItineraryItem]] = [:]
    @State private var sortedDates: [Date] = []
    @State private var isLoading = true

    // Formatter for section headers
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Itinerary...")
            } else if sortedDates.isEmpty {
                Text("No itinerary items for this tour.")
                    .foregroundColor(.secondary)
            } else {
                // Use a List with Sections to group items by date, which is ideal for iOS.
                List {
                    ForEach(sortedDates, id: \.self) { date in
                        Section(header: Text(dateFormatter.string(from: date))) {
                            ForEach(itemsByDate[date] ?? []) { item in
                                itineraryRow(for: item)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onAppear(perform: loadItinerary)
    }

    // A simple, read-only view for each itinerary item.
    @ViewBuilder
    private func itineraryRow(for item: ItineraryItem) -> some View {
        HStack(spacing: 15) {
            Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "questionmark.circle")
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 25)
            
            VStack(alignment: .leading) {
                Text(item.title)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(item.timeUTC.dateValue(), style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    // Fetches and groups itinerary items for the specified tour.
    private func loadItinerary() {
        guard let tourID = tour.id else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "timeUTC")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching itinerary items: \(error?.localizedDescription ?? "Unknown")")
                    isLoading = false
                    return
                }
                
                let items = documents.compactMap { try? $0.data(as: ItineraryItem.self) }
                
                // Group items by date on the main thread
                DispatchQueue.main.async {
                    let grouped = Dictionary(grouping: items) { item in
                        Calendar.current.startOfDay(for: item.timeUTC.dateValue())
                    }
                    self.itemsByDate = grouped
                    self.sortedDates = grouped.keys.sorted()
                    self.isLoading = false
                }
            }
    }
}
