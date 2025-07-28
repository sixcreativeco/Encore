import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tour: Tour
    @EnvironmentObject var appState: AppState

    struct ItineraryDisplayGroup: Identifiable, Hashable {
        var id: DateComponents { dateComponents }
        let dateComponents: DateComponents
        var items: [ItineraryItem]
        var representativeDate: Date { items.first?.timeUTC.dateValue() ?? Date.distantPast }
        static func == (lhs: ItineraryDisplayGroup, rhs: ItineraryDisplayGroup) -> Bool { lhs.dateComponents == rhs.dateComponents }
        func hash(into hasher: inout Hasher) { hasher.combine(dateComponents) }
    }

    // Data Sources
    @State private var allItems: [ItineraryItem] = []
    @State private var shows: [Show] = []

    // State
    @State private var displayGroups: [ItineraryDisplayGroup] = []
    @State private var selectedGroupID: DateComponents?
    @State private var itemToEdit: ItineraryItem?
    @State private var expandedItemID: String?
    @State private var listeners: [ListenerRegistration] = []
    @State private var isAddingItem = false
    
    private var itemsForSelectedDate: [ItineraryItem] {
        displayGroups.first { $0.id == selectedGroupID }?.items ?? []
    }
    
    private var showForSelectedDate: Show? {
        guard let group = displayGroups.first(where: { $0.id == selectedGroupID }),
              let firstItem = group.items.first else { return nil }
        return shows.first { $0.id == firstItem.showId }
    }
    
    var body: some View {
        #if os(iOS)
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            mainContent.background(.clear)
        }
        #else
        mainContent.frame(height: 500)
        #endif
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SectionHeader(title: "Itinerary", onAdd: { isAddingItem = true }).padding(.horizontal).padding(.bottom, 8)
                #if os(iOS)
                .padding(.top, 8)
                #endif
                if !displayGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(displayGroups) { group in
                                DateButtonView(group: group, shows: shows, selectedGroupID: $selectedGroupID)
                            }
                        }.padding(.horizontal)
                    }.frame(height: 50).padding(.bottom, 12)
                }
            }
            ScrollView {
                LazyVStack(spacing: 16) {
                    if itemsForSelectedDate.isEmpty && !displayGroups.isEmpty {
                        Text("No items scheduled for this date.").foregroundColor(.secondary).padding(.top, 50)
                    } else {
                        ForEach(itemsForSelectedDate) { item in
                            let locationHint = shows.first { $0.id == item.showId }?.city
                            ItineraryItemCard(item: item, locationHint: locationHint, isExpanded: expandedItemID == item.id,
                                onExpandToggle: { toggleExpanded(item) },
                                onEdit: { self.itemToEdit = item },
                                onDelete: { deleteItem(item) })
                        }
                    }
                }.padding(.horizontal).padding(.bottom)
            }
        }
        .onAppear { setupListeners(); fetchShowsForTour() }
        .onDisappear { listeners.forEach { $0.remove() } }
        .sheet(item: $itemToEdit) { item in
            if let index = allItems.firstIndex(where: { $0.id == item.id }) {
                ItineraryItemEditView(item: $allItems[index], onSave: {})
            }
        }
        .sheet(isPresented: $isAddingItem) {
            ItineraryItemAddView(tourID: tour.id ?? "", userID: tour.ownerId, onSave: {}, showForTimezone: showForSelectedDate)
        }
    }
    
    private struct DateButtonView: View {
        let group: ItineraryDisplayGroup; let shows: [Show]; @Binding var selectedGroupID: DateComponents?
        private var isSelected: Bool { selectedGroupID == group.id }
        private var city: String? {
            for item in group.items { if let showId = item.showId, let show = shows.first(where: { $0.id == showId }) { return show.city } }
            return nil
        }
        var body: some View {
            VStack(spacing: 2) {
                Text(formattedDate(from: group.dateComponents)).font(.system(size: 14, weight: .semibold))
                if let city = city, !city.isEmpty { Text(city).font(.system(size: 10, weight: .regular)).foregroundColor(isSelected ? .white.opacity(0.7) : .secondary) }
            }.padding(.horizontal, 12).frame(minWidth: 80, minHeight: 38).background(isSelected ? Color.accentColor : Color.gray.opacity(0.2)).cornerRadius(10)
            .onTapGesture { selectedGroupID = group.id }
        }
        private func formattedDate(from components: DateComponents) -> String {
            let calendar = Calendar.current
            guard let date = calendar.date(from: components) else { return "Invalid Date" }
            let formatter = DateFormatter(); formatter.dateFormat = "E, MMM d"; return formatter.string(from: date)
        }
    }
    
    // --- SORTING FIX IS HERE ---
    private func processAndGroupItems(_ items: [ItineraryItem]) {
        // 1. Sort the entire collection of items by their UTC timestamp first. This is the critical change.
        let sortedItems = items.sorted { $0.timeUTC < $1.timeUTC }

        var newDisplayGroups: [ItineraryDisplayGroup] = []
        guard !sortedItems.isEmpty else {
            DispatchQueue.main.async { self.displayGroups = [] }
            return
        }
        
        // 2. Iterate through the now-sorted list to build the groups.
        for item in sortedItems {
            let itemDateComponents = dateComponents(for: item)
            
            // If the current item belongs to the same day as the last group, append it.
            if let lastGroupIndex = newDisplayGroups.indices.last, newDisplayGroups[lastGroupIndex].id == itemDateComponents {
                newDisplayGroups[lastGroupIndex].items.append(item)
            } else {
                // Otherwise, this item starts a new day group.
                let newGroup = ItineraryDisplayGroup(dateComponents: itemDateComponents, items: [item])
                newDisplayGroups.append(newGroup)
            }
        }
        
        DispatchQueue.main.async {
            self.displayGroups = newDisplayGroups
            if self.selectedGroupID == nil, let firstGroup = self.displayGroups.first {
                self.selectedGroupID = firstGroup.id
            }
        }
    }

    private func dateComponents(for item: ItineraryItem) -> DateComponents {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: item.timezone ?? "UTC") ?? .current
        return calendar.dateComponents([.year, .month, .day], from: item.timeUTC.dateValue())
    }

    private func setupListeners() {
        guard let tourID = tour.id, let currentUserID = appState.userID else { return }
        listeners.forEach { $0.remove() }
        let db = Firestore.firestore()
        let everyoneListener = db.collection("itineraryItems").whereField("tourId", isEqualTo: tourID).whereField("visibility", in: ["Everyone", nil])
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
                self.updateCombinedItems(source: "everyone", items: items)
            }
        let customListener = db.collection("itineraryItems").whereField("tourId", isEqualTo: tourID).whereField("visibleTo", arrayContains: currentUserID)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
                self.updateCombinedItems(source: "custom", items: items)
            }
        listeners.append(everyoneListener); listeners.append(customListener)
    }
    
    @State private var itemSources: [String: [ItineraryItem]] = ["everyone": [], "custom": []]

    private func updateCombinedItems(source: String, items: [ItineraryItem]) {
        self.itemSources[source] = items
        let combined = self.itemSources.values.flatMap { $0 }
        var uniqueItems = [String: ItineraryItem](); for item in combined { if let id = item.id { uniqueItems[id] = item } }
        self.allItems = Array(uniqueItems.values); processAndGroupItems(self.allItems)
    }

    private func fetchShowsForTour() {
        guard let tourID = tour.id else { return }
        Task {
            do { self.shows = try await FirebaseTourService.fetchShows(forTour: tourID) }
            catch { print("Error fetching shows for itinerary view: \(error.localizedDescription)") }
        }
    }

    private func toggleExpanded(_ item: ItineraryItem) { withAnimation { expandedItemID = (expandedItemID == item.id) ? nil : item.id } }
    private func deleteItem(_ item: ItineraryItem) { guard let itemID = item.id else { return }; Firestore.firestore().collection("itineraryItems").document(itemID).delete() }
}
