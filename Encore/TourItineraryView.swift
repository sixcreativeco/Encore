import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tourID: String
    var userID: String
    var ownerUserID: String

    @State private var allItems: [ItineraryItemModel] = []
    @State private var availableDates: [Date] = []
    @State private var selectedDate: Date? = nil

    @State private var showAddItem = false
    @State private var selectedItemForEdit: ItineraryItemModel? = nil
    @State private var expandedItemID: String? = nil

    @State private var listeners: [ListenerRegistration] = []
    
    let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Itinerary", onAdd: { showAddItem = true }).padding()

            if !availableDates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(availableDates, id: \.self) { date in
                            Text(formattedDate(date))
                                .fontWeight(isSameDay(date, selectedDate) ? .bold : .regular)
                                .foregroundColor(isSameDay(date, selectedDate) ? .white : .primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(isSameDay(date, selectedDate) ? Color.accentColor : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedDate = date
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let itemsForSelectedDate = allItems.filter { isSameDay($0.time, selectedDate) }

                if itemsForSelectedDate.isEmpty {
                    Text("No items for this date.").foregroundColor(.gray).padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(itemsForSelectedDate.sorted(by: { $0.time < $1.time })) { item in
                            ItineraryItemCard(
                                item: item,
                                isExpanded: expandedItemID == item.id,
                                onExpandToggle: { toggleExpanded(item) },
                                onEdit: { selectedItemForEdit = item },
                                onDelete: { deleteItem(item) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear { setupListeners() }
        .onDisappear { listeners.forEach { $0.remove() } }
        .sheet(isPresented: $showAddItem) {
            // ItineraryItemAddView would be presented here
        }
        .sheet(item: $selectedItemForEdit) { item in
            // This now correctly passes the onSave closure
            ItineraryItemEditView(tourID: tourID, userID: ownerUserID, item: item) {
                // The listeners will handle the refresh automatically.
            }
        }
    }

    private func isSameDay(_ d1: Date, _ d2: Date?) -> Bool {
        guard let d2 = d2 else { return false }
        return calendar.isDate(d1, inSameDayAs: d2)
    }

    private func toggleExpanded(_ item: ItineraryItemModel) {
        withAnimation {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }

    private func deleteItem(_ item: ItineraryItemModel) {
        if item.type == .flight, let flightID = item.flightId {
            TourDataManager.shared.deleteFlight(ownerUserID: ownerUserID, tourID: tourID, flightID: flightID) { error in
                if let error = error { print("Error deleting flight: \(error.localizedDescription)") }
            }
        } else {
            let db = Firestore.firestore()
            db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("itinerary").document(item.id).delete()
        }
    }

    private func setupListeners() {
        // Clear existing listeners before setting up new ones
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        let db = Firestore.firestore()
        let tourRef = db.collection("users").document(ownerUserID).collection("tours").document(tourID)
        
        let tourListener = tourRef.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data(),
                  let start = (data["startDate"] as? Timestamp)?.dateValue(),
                  let end = (data["endDate"] as? Timestamp)?.dateValue() else { return }
            
            let newDates = generateDateRange(from: start, to: end)
            if self.availableDates != newDates {
                self.availableDates = newDates
                self.selectedDate = newDates.first
            }
        }
        
        let itemsListener = tourRef.collection("itinerary").addSnapshotListener { snapshot, _ in
            let generalItems = snapshot?.documents.compactMap { ItineraryItemModel(from: $0) } ?? []
            mergeAndRefresh(source: .general, items: generalItems)
        }
        
        let flightsListener = tourRef.collection("flights").addSnapshotListener { snapshot, _ in
            let flightItems = snapshot?.documents.compactMap { FlightModel(from: $0)?.toItineraryItem() } ?? []
            mergeAndRefresh(source: .flights, items: flightItems)
        }
        
        let showsListener = tourRef.collection("shows").addSnapshotListener { snapshot, _ in
            var showItems: [ItineraryItemModel] = []
            snapshot?.documents.forEach { doc in
                let data = doc.data()
                guard let showDate = (data["date"] as? Timestamp)?.dateValue() else { return }

                func buildFullDate(base: Date, timeStamp: Timestamp?) -> Date? {
                    guard let timeStamp = timeStamp else { return nil }
                    let timeOnly = timeStamp.dateValue()
                    let hour = calendar.component(.hour, from: timeOnly)
                    let minute = calendar.component(.minute, from: timeOnly)
                    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base)
                }
                
                if let time = buildFullDate(base: showDate, timeStamp: data["loadIn"] as? Timestamp) { showItems.append(.init(id: "show-\(doc.documentID)-loadin", type: .loadIn, title: "Load In", time: time, subtitle: data["venue"] as? String)) }
                if let time = buildFullDate(base: showDate, timeStamp: data["soundCheck"] as? Timestamp) { showItems.append(.init(id: "show-\(doc.documentID)-soundcheck", type: .soundcheck, title: "Soundcheck", time: time, subtitle: data["venue"] as? String)) }
                if let time = buildFullDate(base: showDate, timeStamp: data["doorsOpen"] as? Timestamp) { showItems.append(.init(id: "show-\(doc.documentID)-doors", type: .doors, title: "Doors Open", time: time, subtitle: data["venue"] as? String)) }
                if let time = buildFullDate(base: showDate, timeStamp: data["headlinerSetTime"] as? Timestamp) { showItems.append(.init(id: "show-\(doc.documentID)-headline", type: .headline, title: "Headliner Set", time: time, subtitle: data["venue"] as? String)) }
                if let time = buildFullDate(base: showDate, timeStamp: data["packOut"] as? Timestamp) { showItems.append(.init(id: "show-\(doc.documentID)-packout", type: .packOut, title: "Pack Out", time: time, subtitle: data["venue"] as? String)) }
            }
            mergeAndRefresh(source: .shows, items: showItems)
        }
        
        // Store listeners to be removed on disappear
        self.listeners = [tourListener, itemsListener, flightsListener, showsListener]
    }
    
    // Using a temporary dictionary to hold results from listeners before merging
    // to prevent race conditions and view update issues.
    @State private var itemSources: [SourceType: [ItineraryItemModel]] = [:]
    private enum SourceType { case general, flights, shows }
    
    private func mergeAndRefresh(source: SourceType, items: [ItineraryItemModel]) {
        itemSources[source] = items
        self.allItems = itemSources.values.flatMap { $0 }
    }

    private func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        while calendar.isDate(current, inSameDayAs: end) || current < end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
}
