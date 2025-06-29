import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tour: Tour
    @EnvironmentObject var appState: AppState

    // Data Sources
    @State private var allItems: [ItineraryItem] = []
    @State private var shows: [Show] = []
    @State private var itemsByDate: [DateComponents: [ItineraryItem]] = [:]
    @State private var sortedDates: [DateComponents] = []

    // State
    @State private var selectedDate: DateComponents?
    @State private var itemToEdit: ItineraryItem?
    @State private var expandedItemID: String?
    @State private var listeners: [ListenerRegistration] = []
    @State private var isAddingItem = false
    
    @State private var everyoneItems: [ItineraryItem] = []
    @State private var customItems: [ItineraryItem] = []
    @State private var showTimingItems: [ItineraryItem] = []

    let calendar = Calendar.current
    
    private var showForSelectedDate: Show? {
        guard let selectedDate = selectedDate,
              let date = calendar.date(from: selectedDate) else { return nil }
        return shows.first { show in
            guard let showTimezone = TimeZone(identifier: show.timezone ?? "UTC") else { return false }
            var localCalendar = calendar
            localCalendar.timeZone = showTimezone
            return localCalendar.isDate(show.date.dateValue(), inSameDayAs: date)
        }
    }
    
    private var itemsForSelectedDate: [ItineraryItem] {
        guard let selectedDate = selectedDate else { return [] }
        return itemsByDate[selectedDate] ?? []
    }
    
    var body: some View {
        #if os(iOS)
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            mainContent
                .background(.clear)
        }
        #else
        mainContent
            .frame(height: 500) // Fixed height only for macOS
        #endif
    }
    
    // Extracted main content to a helper view to avoid code duplication
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SectionHeader(title: "Itinerary", onAdd: { isAddingItem = true })
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    #if os(iOS)
                    .padding(.top, 8)
                    #endif

                if !sortedDates.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(sortedDates, id: \.self) { dateComponents in
                                let city = shows.first { $0.id == itemsByDate[dateComponents]?.first?.showId }?.city ?? ""
                                DateButtonView(
                                    dateComponents: dateComponents,
                                    city: city,
                                    selectedDate: $selectedDate
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50)
                    .padding(.bottom, 12)
                }
            }

            ScrollView {
                LazyVStack(spacing: 16) {
                    if itemsForSelectedDate.isEmpty {
                        Text("No items scheduled for this date.")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else {
                        ForEach(itemsForSelectedDate) { item in
                            let locationHint = shows.first { $0.id == item.showId }?.city
                            ItineraryItemCard(
                                 item: item,
                                locationHint: locationHint,
                                isExpanded: expandedItemID == item.id,
                                 onExpandToggle: { toggleExpanded(item) },
                                onEdit: { self.itemToEdit = item },
                                onDelete: { deleteItem(item) }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .onAppear {
            setupListeners()
            fetchShowsForTour()
        }
        .onDisappear {
            listeners.forEach { $0.remove() }
        }
        .sheet(item: $itemToEdit) { item in
            if let index = allItems.firstIndex(where: { $0.id == item.id }) {
                ItineraryItemEditView(item: $allItems[index], onSave: {})
            }
        }
        .sheet(isPresented: $isAddingItem) {
            ItineraryItemAddView(
                tourID: tour.id ?? "",
                userID: tour.ownerId,
                onSave: {},
                showForTimezone: showForSelectedDate
            )
        }
    }
    
    private struct DateButtonView: View {
        let dateComponents: DateComponents
        let city: String
        @Binding var selectedDate: DateComponents?
        private var isSelected: Bool {
            selectedDate == dateComponents
        }

        var body: some View {
            VStack(spacing: 2) {
                Text(formattedDate(from: dateComponents))
                    .font(.system(size: 14, weight: .semibold))
                if !city.isEmpty {
                    Text(city)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 80, minHeight: 38)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            .cornerRadius(10)
            .onTapGesture {
                selectedDate = dateComponents
            }
        }
        
        private func formattedDate(from components: DateComponents) -> String {
            var calendar = Calendar.current
            calendar.timeZone = components.timeZone ?? .current
            
            guard let date = calendar.date(from: components) else { return "Invalid Date" }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            formatter.timeZone = components.timeZone ?? .current
            
            return formatter.string(from: date)
        }
    }

    private func processAndGroupItems(_ items: [ItineraryItem]) {
        let grouped = Dictionary(grouping: items) { item -> DateComponents in
            guard let timeZoneIdentifier = item.timezone, let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
                return calendar.dateComponents([.year, .month, .day, .timeZone], from: item.timeUTC.dateValue())
            }
            var localCalendar = Calendar(identifier: .gregorian)
            localCalendar.timeZone = timeZone
            return localCalendar.dateComponents([.year, .month, .day, .timeZone], from: item.timeUTC.dateValue())
        }

        DispatchQueue.main.async {
            self.itemsByDate = grouped.mapValues { $0.sorted(by: { $0.timeUTC.dateValue() < $1.timeUTC.dateValue() }) }
            self.sortedDates = self.itemsByDate.keys.sorted {
                let d1 = calendar.date(from: $0) ?? .distantPast
                let d2 = calendar.date(from: $1) ?? .distantPast
                return d1 < d2
            }

            if self.selectedDate == nil || !self.itemsByDate.keys.contains(self.selectedDate!) {
                self.selectedDate = self.sortedDates.first
            }
        }
    }

    private func setupListeners() {
        guard let tourID = tour.id, let currentUserID = appState.userID else { return }
        listeners.forEach { $0.remove() }
        
        let db = Firestore.firestore()
        
        let everyoneListener = db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("visibility", in: ["Everyone", nil])
            .addSnapshotListener { snapshot, _ in
                self.everyoneItems = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
                updateCombinedItems()
            }
            
        let customListener = db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("visibleTo", arrayContains: currentUserID)
            .addSnapshotListener { snapshot, _ in
                self.customItems = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
                updateCombinedItems()
            }
        
        let showTimingTypes = ItineraryItemType.allCases.filter { $0.isShowTiming }.map { $0.rawValue }
        if !showTimingTypes.isEmpty {
            let showTimingsListener = db.collection("itineraryItems")
                .whereField("tourId", isEqualTo: tourID)
                .whereField("type", in: showTimingTypes)
                .addSnapshotListener { snapshot, _ in
                    self.showTimingItems = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
                    updateCombinedItems()
                }
            self.listeners.append(showTimingsListener)
        }
            
        self.listeners.append(everyoneListener)
        self.listeners.append(customListener)
    }
    
    private func updateCombinedItems() {
        let combined = everyoneItems + customItems + showTimingItems
        
        var uniqueItems = [ItineraryItem]()
        var seenIDs = Set<String>()
        for item in combined {
            if let id = item.id, !seenIDs.contains(id) {
                uniqueItems.append(item)
                seenIDs.insert(id)
            }
        }
        
        self.allItems = uniqueItems
        processAndGroupItems(self.allItems)
    }

    private func fetchShowsForTour() {
        guard let tourID = tour.id else { return }
        Task {
            do {
                self.shows = try await FirebaseTourService.fetchShows(forTour: tourID)
            } catch {
                print("Error fetching shows for itinerary view: \(error.localizedDescription)")
            }
        }
    }

    private func toggleExpanded(_ item: ItineraryItem) {
        withAnimation {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }

    private func deleteItem(_ item: ItineraryItem) {
        guard let itemID = item.id else { return }
        Firestore.firestore().collection("itineraryItems").document(itemID).delete()
    }

    private func formattedSectionHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}
