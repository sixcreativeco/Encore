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
    
    // Internal state
    private var allItems: [ItineraryItem] = []
    private var listeners: [ListenerRegistration] = []
    private let tour: Tour
    private let db = Firestore.firestore()

    var itemsForSelectedDate: [ItineraryItem] {
        displayGroups.first { $0.id == selectedGroupID }?.items ?? []
    }
    
    var showForSelectedDate: Show? {
        guard let group = displayGroups.first(where: { $0.id == selectedGroupID }),
              let firstItem = group.items.first else { return nil }
        return shows.first { $0.id == firstItem.showId }
    }

    init(tour: Tour) {
        self.tour = tour
        setupListeners()
        fetchShowsForTour()
    }
    
    // MARK: - Data Fetching and Processing
    
    private func setupListeners() {
        guard let tourID = tour.id, let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        cleanupListeners()
        
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
                
                let allFetchedItems = documents.compactMap { try? $0.data(as: ItineraryItem.self) }
                
                // Filter items based on visibility rules
                let visibleItems = allFetchedItems.filter { item in
                    let visibility = item.visibility?.lowercased() ?? "everyone"
                    if visibility == "everyone" || item.visibility == nil {
                        return true
                    } else if visibility == "custom" {
                        return item.visibleTo?.contains(currentUserID) ?? false
                    }
                    return false
                }
                
                self.allItems = visibleItems
                self.processAndGroupItems(visibleItems)
            }
        
        listeners.append(mainListener)
    }

    private func fetchShowsForTour() {
        guard let tourID = tour.id else { return }
        Task {
            do {
                self.shows = try await FirebaseTourService.fetchShows(forTour: tourID)
            } catch {
                print("❌ Error fetching shows for itinerary view: \(error.localizedDescription)")
            }
        }
    }

    private func processAndGroupItems(_ items: [ItineraryItem]) {
        let sortedItems = items.sorted { $0.timeUTC < $1.timeUTC }
        var newDisplayGroups: [TourItineraryView.ItineraryDisplayGroup] = []
        
        guard !sortedItems.isEmpty else {
            self.displayGroups = []
            self.selectedGroupID = nil
            return
        }
                
        for item in sortedItems {
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
