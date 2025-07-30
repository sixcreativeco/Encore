import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    let tour: Tour
    @EnvironmentObject var appState: AppState
    
    struct ItineraryDisplayGroup: Identifiable, Hashable {
        var id: DateComponents { dateComponents }
        let dateComponents: DateComponents
        var items: [ItineraryItem]
        var representativeDate: Date { items.first?.timeUTC.dateValue() ?? Date.distantPast }
        
        static func == (lhs: ItineraryDisplayGroup, rhs: ItineraryDisplayGroup) -> Bool {
            lhs.dateComponents == rhs.dateComponents
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(dateComponents)
        }
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
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0/255, green: 58/255, blue: 83/255),
                    Color(red: 23/255, green: 17/255, blue: 17/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
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
                SectionHeader(title: "Itinerary", onAdd: { isAddingItem = true })
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                #if os(iOS)
                    .padding(.top, 8)
                #endif
                
                if !displayGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(displayGroups) { group in
                                DateButtonView(
                                    group: group,
                                    shows: shows,
                                    selectedGroupID: $selectedGroupID
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
                    if itemsForSelectedDate.isEmpty && !displayGroups.isEmpty {
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
                            .id(item.id)
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
            cleanupListeners()
        }
        .sheet(item: $itemToEdit) { item in
            if let index = allItems.firstIndex(where: { $0.id == item.id }) {
                ItineraryItemEditView(
                    item: $allItems[index],
                    onSave: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.refreshData()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $isAddingItem) {
            ItineraryItemAddView(
                tourID: tour.id ?? "",
                userID: tour.ownerId,
                onSave: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.refreshData()
                    }
                },
                showForTimezone: showForSelectedDate
            )
        }
    }
        
    private struct DateButtonView: View {
        let group: ItineraryDisplayGroup
        let shows: [Show]
        @Binding var selectedGroupID: DateComponents?
        
        private var isSelected: Bool {
            selectedGroupID == group.id
        }
        
        private var city: String? {
            for item in group.items {
                if let showId = item.showId, let show = shows.first(where: { $0.id == showId }) {
                    return show.city
                }
            }
            return nil
        }
        
        var body: some View {
            VStack(spacing: 2) {
                Text(formattedDate(from: group.dateComponents))
                    .font(.system(size: 14, weight: .semibold))
                
                if let city = city, !city.isEmpty {
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
                selectedGroupID = group.id
            }
        }
        
        private func formattedDate(from components: DateComponents) -> String {
            let calendar = Calendar.current
            guard let date = calendar.date(from: components) else { return "Invalid Date" }
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter.string(from: date)
        }
    }
        
    private func processAndGroupItems(_ items: [ItineraryItem]) {
        let sortedItems = items.sorted { $0.timeUTC < $1.timeUTC }
        var newDisplayGroups: [ItineraryDisplayGroup] = []
        
        guard !sortedItems.isEmpty else {
            DispatchQueue.main.async {
                self.displayGroups = []
                self.selectedGroupID = nil
            }
            return
        }
                
        for item in sortedItems {
            let itemDateComponents = dateComponents(for: item)
                        
            if let lastGroupIndex = newDisplayGroups.indices.last,
               newDisplayGroups[lastGroupIndex].id == itemDateComponents {
                newDisplayGroups[lastGroupIndex].items.append(item)
            } else {
                let newGroup = ItineraryDisplayGroup(
                    dateComponents: itemDateComponents,
                    items: [item]
                )
                newDisplayGroups.append(newGroup)
            }
        }
                
        DispatchQueue.main.async {
            let previousSelectedGroupID = self.selectedGroupID
            self.displayGroups = newDisplayGroups
            
            if let previousID = previousSelectedGroupID {
                if self.displayGroups.contains(where: { $0.id == previousID }) {
                    self.selectedGroupID = previousID
                } else {
                    self.selectedGroupID = self.displayGroups.first?.id
                }
            } else {
                self.selectedGroupID = self.displayGroups.first?.id
            }
            
            if let expandedID = self.expandedItemID {
                let itemStillExists = self.allItems.contains { $0.id == expandedID }
                if !itemStillExists {
                    self.expandedItemID = nil
                }
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
        
        cleanupListeners()
        
        let db = Firestore.firestore()
        
        let mainListener = db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error in itinerary listener: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No documents in snapshot")
                    return
                }
                
                let allItems = documents.compactMap { document -> ItineraryItem? in
                    do {
                        return try document.data(as: ItineraryItem.self)
                    } catch {
                        print("❌ Error decoding itinerary item: \(error)")
                        return nil
                    }
                }
                
                let visibleItems = allItems.filter { item in
                    let visibility = item.visibility?.lowercased() ?? "everyone"
                    
                    if visibility == "everyone" || visibility == "Everyone" || item.visibility == nil {
                        return true
                    } else if visibility == "custom" {
                        return item.visibleTo?.contains(currentUserID) ?? false
                    }
                    return false
                }
                
                print("📋 Listener found \(allItems.count) total items, \(visibleItems.count) visible to user")
                
                DispatchQueue.main.async {
                    self.allItems = visibleItems
                    self.processAndGroupItems(visibleItems)
                }
            }
        
        listeners.append(mainListener)
        print("🎧 Set up listener for tour: \(tourID)")
    }
    
    private func cleanupListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    private func refreshData() {
        setupListeners()
    }
    
    private func fetchShowsForTour() {
        guard let tourID = tour.id else { return }
        Task {
            do {
                self.shows = try await FirebaseTourService.fetchShows(forTour: tourID)
                print("🎭 Loaded \(self.shows.count) shows for tour")
            }
            catch {
                print("❌ Error fetching shows for itinerary view: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleExpanded(_ item: ItineraryItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }
    
    private func deleteItem(_ item: ItineraryItem) {
        guard let itemID = item.id else {
            print("❌ Cannot delete item - no ID")
            return
        }
        
        print("🗑️ Deleting itinerary item: \(item.title)")
        
        if expandedItemID == itemID {
            withAnimation {
                expandedItemID = nil
            }
        }
        
        Firestore.firestore().collection("itineraryItems").document(itemID).delete { error in
            if let error = error {
                print("❌ Error deleting itinerary item: \(error.localizedDescription)")
            } else {
                print("✅ Successfully deleted itinerary item")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.refreshData()
                }
            }
        }
    }
}
