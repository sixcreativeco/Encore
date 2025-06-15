import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tourID: String
    var userID: String

    @State private var itineraryItems: [ItineraryItemModel] = []
    @State private var showTimingItems: [ItineraryItemModel] = []
    @State private var flightItems: [ItineraryItemModel] = []

    @State private var showAddItem = false
    @State private var selectedItemForEdit: ItineraryItemModel? = nil
    @State private var expandedItemID: String? = nil
    @State private var availableDates: [Date] = []
    @State private var selectedDate: Date = Date()

    let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Itinerary", onAdd: { showAddItem = true })

            if !availableDates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(availableDates, id: \.self) { date in
                            Text(formattedDate(date))
                                .fontWeight(isSameDay(date, selectedDate) ? .bold : .regular)
                                .foregroundColor(isSameDay(date, selectedDate) ? .white : .primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(isSameDay(date, selectedDate) ? Color.blue : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedDate = date
                                    refreshForSelectedDate()
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            let allItems = mergedItemsForDate()

            if allItems.isEmpty {
                Text("No items for this date").foregroundColor(.gray).padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(allItems.sorted(by: { $0.time < $1.time })) { item in
                            ItineraryItemCard(
                                item: item,
                                isExpanded: expandedItemID == item.id,
                                onExpandToggle: { toggleExpanded(item) },
                                onEdit: { selectedItemForEdit = item },
                                onDelete: { deleteItem(item) }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .onAppear {
            loadTourDates {
                refreshForSelectedDate()
            }
        }
        .sheet(isPresented: $showAddItem) {
            ItineraryItemAddView(tourID: tourID, userID: userID, presetDate: selectedDate) {
                refreshForSelectedDate()
            }
        }
        .sheet(item: $selectedItemForEdit) { item in
            ItineraryItemEditView(tourID: tourID, userID: userID, item: item) {
                refreshForSelectedDate()
            }
        }
    }

    private func mergedItemsForDate() -> [ItineraryItemModel] {
        let merged = (itineraryItems + showTimingItems + flightItems)
            .filter { isSameDay($0.time, selectedDate) }
        print("✅ Merged items for \(formattedDate(selectedDate)): \(merged.count) items")
        return merged
    }

    private func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        calendar.isDate(d1, equalTo: d2, toGranularity: .day)
    }

    private func toggleExpanded(_ item: ItineraryItemModel) {
        withAnimation {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }

    private func refreshForSelectedDate() {
        loadItinerary {
            loadShowTimings {
                loadFlights()
            }
        }
    }

    private func loadItinerary(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary")
            .getDocuments { snapshot, _ in
                self.itineraryItems = snapshot?.documents.compactMap { ItineraryItemModel(from: $0) } ?? []
                print("🟢 Loaded \(self.itineraryItems.count) itinerary items")
                completion()
            }
    }

    private func deleteItem(_ item: ItineraryItemModel) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary").document(item.id).delete { _ in
            refreshForSelectedDate()
        }
    }

    private func loadTourDates(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID)
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data(),
                      let start = (data["startDate"] as? Timestamp)?.dateValue(),
                      let end = (data["endDate"] as? Timestamp)?.dateValue() else { return }

                self.availableDates = generateDateRange(from: start, to: end)
                self.selectedDate = start
                print("📅 Loaded tour dates \(formattedDate(start)) → \(formattedDate(end))")
                completion()
            }
    }

    private func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func loadShowTimings(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("shows")
            .getDocuments { snapshot, _ in
                var timings: [ItineraryItemModel] = []

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

                    if let fullLoadIn = buildFullDate(base: showDate, timeStamp: data["loadIn"] as? Timestamp) {
                        timings.append(ItineraryItemModel(type: .loadIn, title: "Load In", time: fullLoadIn))
                    }
                    if let fullSoundcheck = buildFullDate(base: showDate, timeStamp: data["soundCheck"] as? Timestamp) {
                        timings.append(ItineraryItemModel(type: .soundcheck, title: "Soundcheck", time: fullSoundcheck))
                    }
                    if let fullDoors = buildFullDate(base: showDate, timeStamp: data["doorsOpen"] as? Timestamp) {
                        timings.append(ItineraryItemModel(type: .doors, title: "Doors Open", time: fullDoors))
                    }
                    if let fullHeadline = buildFullDate(base: showDate, timeStamp: data["headlinerSetTime"] as? Timestamp) {
                        timings.append(ItineraryItemModel(type: .headline, title: "Headliner Set", time: fullHeadline))
                    }
                    if let fullPackOut = buildFullDate(base: showDate, timeStamp: data["packOut"] as? Timestamp) {
                        timings.append(ItineraryItemModel(type: .packOut, title: "Pack Out", time: fullPackOut))
                    }
                }

                self.showTimingItems = timings
                print("🟠 Loaded \(self.showTimingItems.count) total show timing items")
                completion()
            }
    }

    private func loadFlights() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("flights")
            .getDocuments { snapshot, _ in
                let flights = snapshot?.documents.compactMap { doc -> ItineraryItemModel? in
                    guard let data = doc.data() as? [String: Any],
                          let airline = data["airline"] as? String,
                          let flightNumber = data["flightNumber"] as? String,
                          let depAirport = data["departureAirport"] as? String,
                          let arrAirport = data["arrivalAirport"] as? String,
                          let depTimeStamp = data["departureTime"] as? Timestamp
                    else { return nil }

                    let depTime = depTimeStamp.dateValue()
                    let title = "\(airline) \(flightNumber) \(depAirport) → \(arrAirport)"
                    return ItineraryItemModel(type: .flight, title: title, time: depTime)
                } ?? []
                self.flightItems = flights
                print("🔵 Loaded \(self.flightItems.count) flights")
            }
    }
}
