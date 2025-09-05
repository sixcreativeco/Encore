import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ItineraryViewModel: ObservableObject {
    // Published properties that the View will observe
    @Published var displayGroups: [TourItineraryView.ItineraryDisplayGroup] = []
    @Published var selectedGroupID: DateComponents?
    @Published var itemToEdit: ItineraryItem?
    @Published var expandedItemID: String? = nil
    @Published var isAddingItem = false
    @Published var shows: [Show] = []
    @Published var flights: [Flight] = []
    @Published var hotels: [Hotel] = []
    
    // Internal state
    private var allItems: [ItineraryItem] = []
    private var listeners: [ListenerRegistration] = []
    let tour: Tour // --- THIS IS THE FIX: 'private' keyword removed ---
    private let db = Firestore.firestore()

    var itemsForSelectedDate: [ItineraryItem] {
        displayGroups.first { $0.id == selectedGroupID }?.items ?? []
    }
    
    var showForSelectedDate: Show? {
        guard let group = displayGroups.first(where: { $0.id == selectedGroupID }) else { return nil }
        
        // Find a showId from any item in the selected day's group
        let showIdForDay = group.items.compactMap { $0.showId }.first
        
        guard let showId = showIdForDay else { return nil }
        return shows.first { $0.id == showId }
    }

    init(tour: Tour) {
        self.tour = tour
        setupListeners()
    }
    
    // MARK: - Data Fetching and Processing
    
    private func setupListeners() {
        guard let tourID = tour.id, let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        cleanupListeners()
        
        let itineraryListener = db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "timeUTC")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                let allFetchedItems = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
                let visibleItems = allFetchedItems.filter { item in
                    let visibility = item.visibility?.lowercased() ?? "everyone"
                    if visibility == "everyone" || item.visibility == nil { return true }
                    return item.visibleTo?.contains(currentUserID) ?? false
                }
                self.allItems = visibleItems
                self.processAndGroupItems(visibleItems)
            }
        
        let showsListener = db.collection("shows").whereField("tourId", isEqualTo: tourID).addSnapshotListener { [weak self] snapshot, _ in
            self?.shows = snapshot?.documents.compactMap { try? $0.data(as: Show.self) } ?? []
        }
        
        let flightsListener = db.collection("flights").whereField("tourId", isEqualTo: tourID).addSnapshotListener { [weak self] snapshot, _ in
            self?.flights = snapshot?.documents.compactMap { try? $0.data(as: Flight.self) } ?? []
        }
        
        let hotelsListener = db.collection("hotels").whereField("tourId", isEqualTo: tourID).addSnapshotListener { [weak self] snapshot, _ in
            self?.hotels = snapshot?.documents.compactMap { try? $0.data(as: Hotel.self) } ?? []
        }
        
        listeners = [itineraryListener, showsListener, flightsListener, hotelsListener]
    }

    private func processAndGroupItems(_ items: [ItineraryItem]) {
        var newDisplayGroups: [TourItineraryView.ItineraryDisplayGroup] = []
        
        guard !items.isEmpty else {
            self.displayGroups = []
            self.selectedGroupID = nil
            return
        }
                
        for item in items {
            let itemDateComponents = dateComponents(for: item)
                        
            if let lastGroupIndex = newDisplayGroups.indices.last,
               newDisplayGroups[lastGroupIndex].id == itemDateComponents {
                newDisplayGroups[lastGroupIndex].items.append(item)
            } else {
                let newGroup = TourItineraryView.ItineraryDisplayGroup(
                    dateComponents: itemDateComponents,
                    items: [item]
                )
                newDisplayGroups.append(newGroup)
            }
        }
        
        for i in 0..<newDisplayGroups.count {
            newDisplayGroups[i].items.sort { $0.timeUTC < $1.timeUTC }
        }
                
        let previousSelectedGroupID = self.selectedGroupID
        self.displayGroups = newDisplayGroups
        
        if let previousID = previousSelectedGroupID, self.displayGroups.contains(where: { $0.id == previousID }) {
            self.selectedGroupID = previousID
        } else {
            self.selectedGroupID = self.displayGroups.first?.id
        }
        
        if let expandedID = self.expandedItemID, !self.allItems.contains(where: { $0.id == expandedID }) {
            self.expandedItemID = nil
        }
    }

    private func dateComponents(for item: ItineraryItem) -> DateComponents {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: item.timezone ?? "UTC") ?? .current
        return calendar.dateComponents([.year, .month, .day], from: item.timeUTC.dateValue())
    }

    func cleanupListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    func getAssumedTimezone(for date: Date) -> (identifier: String, name: String) {
        
        // 1. Check if there's a show on the selected date.
        let calendar = Calendar.current
        if let showOnDate = shows.first(where: { calendar.isDate(date, inSameDayAs: $0.date.dateValue()) }) {
            if let tzIdentifier = showOnDate.timezone {
                _ = tzIdentifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? tzIdentifier
                return (tzIdentifier, "\(showOnDate.city) Time")
            }
        }
        
        // 2. If not, find the most recent "anchor" event before this date.
        
        // Create a list of all possible anchors with their times and timezones
        var anchors: [(date: Date, timezone: String, name: String)] = []
        
        for show in shows {
            if let timezone = show.timezone {
                anchors.append((show.date.dateValue(), timezone, "\(show.city) Time"))
            }
        }
        for flight in flights {
            if let destAirport = AirportService.shared.airports.first(where: { $0.iata == flight.destination }) {
                anchors.append((flight.arrivalTimeUTC.dateValue(), destAirport.tz, "\(destAirport.city) Time"))
            }
        }
        for hotel in hotels {
            anchors.append((hotel.checkInDate.dateValue(), hotel.timezone, "\(hotel.city) Time"))
        }

        // Find the most recent anchor that happened on or before the target date
        let mostRecentAnchor = anchors
            .filter { $0.date <= date }
            .sorted { $0.date > $1.date }
            .first

        if let anchor = mostRecentAnchor {
            return (anchor.timezone, anchor.name)
        }

        // 3. As a final fallback, use the user's current timezone.
        let currentID = TimeZone.current.identifier
        let currentName = TimeZone.current.localizedName(for: .generic, locale: .current) ?? "Local Time"
        return (currentID, currentName)
    }
    
    // MARK: - User Actions

    func toggleExpanded(_ item: ItineraryItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }
    
    func deleteItem(_ item: ItineraryItem) {
        guard let itemID = item.id else { return }
        
        if expandedItemID == itemID {
            withAnimation { expandedItemID = nil }
        }
        
        db.collection("itineraryItems").document(itemID).delete { error in
            if let error = error {
                print("❌ Error deleting itinerary item: \(error.localizedDescription)")
            }
        }
    }
}
