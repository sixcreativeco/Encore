import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class EventsTabViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var filteredEvents: [DisplayEvent] = []
    @Published var isLoading = true
    @Published var allTours: [Tour] = []
    
    @Published var selectedTourFilterID: String? = nil {
        didSet { processData() }
    }
    @Published var selectedSortOption: SortOption = .dateDescending {
        didSet { processData() }
    }

    // MARK: - Private Properties
    private var allEvents: [TicketedEvent] = []
    private var allShows: [Show] = []
    private var allSales: [TicketSale] = []
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let userID: String?

    // MARK: - Enums and Structs
    enum SortOption: String, CaseIterable, Identifiable {
        case dateDescending = "Date (Newest First)"
        case dateAscending = "Date (Oldest First)"
        case mostTickets = "Most Tickets Sold"
        case leastTickets = "Least Tickets Sold"
        var id: String { self.rawValue }
    }

    struct DisplayEvent: Identifiable {
        let id: String
        let event: TicketedEvent
        let show: Show
        let tour: Tour
        let ticketsSold: Int
        let totalAllocation: Int
        let totalRevenue: Double
    }

    // MARK: - Lifecycle
    init() {
        self.userID = Auth.auth().currentUser?.uid
        Task {
            await setupListeners()
        }
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }

    // MARK: - Data Handling
    private func setupListeners() async {
        guard let userID = self.userID else {
            self.isLoading = false
            return
        }

        do {
            self.allTours = try await db.collection("tours").whereField("ownerId", isEqualTo: userID).getDocuments().documents.compactMap { try? $0.data(as: Tour.self) }
            let tourIDs = self.allTours.compactMap { $0.id }
            if !tourIDs.isEmpty {
                self.allShows = try await db.collection("shows").whereField("tourId", in: tourIDs).getDocuments().documents.compactMap { try? $0.data(as: Show.self) }
            }
        } catch {
            print("Error fetching initial tour/show data: \(error)")
            self.isLoading = false
            return
        }

        let eventsListener = db.collection("ticketedEvents").whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.allEvents = snapshot?.documents.compactMap { try? $0.data(as: TicketedEvent.self) } ?? []
                self?.processData()
            }

        let salesListener = db.collection("ticketSales").whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.allSales = snapshot?.documents.map { TicketSale(from: $0) } ?? []
                self?.processData()
            }

        self.listeners = [eventsListener, salesListener]
    }

    private func processData() {
        var processedEvents: [DisplayEvent] = []

        let sourceEvents = allEvents.filter {
            guard let tourId = selectedTourFilterID else { return true }
            return $0.tourId == tourId
        }

        for event in sourceEvents {
            guard let show = allShows.first(where: { $0.id == event.showId }),
                  let tour = allTours.first(where: { $0.id == event.tourId }) else { continue }
            
            let salesForEvent = allSales.filter { $0.ticketedEventId == event.id }
            let ticketsSold = salesForEvent.reduce(0) { $0 + $1.quantity }
            let totalRevenue = salesForEvent.reduce(0.0) { $0 + $1.totalPrice }
            
            // --- THIS IS THE FIX ---
            // The logic now correctly sums the allocation from all releases within all ticket types.
            let currentAllocation = event.ticketTypes.flatMap { $0.releases }.reduce(0) { $0 + $1.allocation }
            let totalAllocation = currentAllocation + ticketsSold
            // --- END OF FIX ---

            processedEvents.append(DisplayEvent(
                id: event.id ?? UUID().uuidString, event: event, show: show, tour: tour,
                ticketsSold: ticketsSold, totalAllocation: totalAllocation, totalRevenue: totalRevenue
            ))
        }
        
        processedEvents.sort { lhs, rhs in
            switch selectedSortOption {
            case .dateDescending:
                return lhs.show.date.dateValue() > rhs.show.date.dateValue()
            case .dateAscending:
                return lhs.show.date.dateValue() < rhs.show.date.dateValue()
            case .mostTickets:
                return lhs.ticketsSold > rhs.ticketsSold
            case .leastTickets:
                return lhs.ticketsSold < rhs.ticketsSold
            }
        }
        
        self.filteredEvents = processedEvents
        if self.isLoading {
            self.isLoading = false
        }
    }
}
