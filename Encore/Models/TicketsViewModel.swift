import Foundation
import Combine
import FirebaseFirestore
import AppKit

class TicketsViewModel: ObservableObject {
    
    // MARK: - Published Properties for the View
    
    @Published var summaryStats = SummaryStats()
    @Published var primaryEvent: TicketedEvent?
    @Published var recentTicketSales: [TicketSale] = []
    @Published var allTicketSales: [TicketSale] = []
    @Published var publishedEvents: [TicketedEvent] = []
    @Published var allShows: [Show] = []
    @Published var tour: Tour?
    @Published var userTours: [Tour] = []
    @Published var isLoading = true
    @Published var selectedTimeframe: Timeframe = .thisYear {
        didSet {
            processFetchedData()
        }
    }
    
    // MARK: - Alert Properties
    @Published var showingPublishAlert = false
    @Published var publishAlertTitle = ""
    @Published var publishAlertMessage = ""
    @Published var publishedURL = ""
    @Published var isPublishingToWeb = false
    
    // MARK: - Properties
    
    var allTicketedEvents: [TicketedEvent] = []
    
    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()
    private let currentUserID: String?
    
    // MARK: - Structs and Enums
    
    struct SummaryStats {
        var orderCount: Int = 0
        var ticketsIssued: Int = 0
        var totalRevenue: Double = 0.0
    }
    
    struct TicketSale: Identifiable {
        let id = UUID()
        let purchaseId: String?
        let ticketedEventId: String
        let showId: String
        let tourId: String
        let eventDescription: String
        let ticketTypeId: String
        let ticketTypeName: String
        let quantity: Int
        let totalPrice: Double
        let currency: String
        let buyerName: String
        let buyerEmail: String
        let buyerPhone: String
        let purchaseDate: Date
        let ticketNumbers: [String]
        let status: String
        
        init(from document: DocumentSnapshot) {
            let data = document.data() ?? [:]
            self.purchaseId = document.documentID
            self.ticketedEventId = data["ticketedEventId"] as? String ?? ""
            self.showId = data["showId"] as? String ?? ""
            self.tourId = data["tourId"] as? String ?? ""
            self.eventDescription = data["eventDescription"] as? String ?? ""
            self.ticketTypeId = data["ticketTypeId"] as? String ?? ""
            self.ticketTypeName = data["ticketTypeName"] as? String ?? ""
            self.quantity = data["quantity"] as? Int ?? 0
            self.totalPrice = data["totalPrice"] as? Double ?? 0.0
            self.currency = data["currency"] as? String ?? "NZD"
            self.buyerName = data["buyerName"] as? String ?? ""
            self.buyerEmail = data["buyerEmail"] as? String ?? ""
            self.buyerPhone = data["buyerPhone"] as? String ?? ""
            self.status = data["status"] as? String ?? "completed"
            self.ticketNumbers = data["ticketNumbers"] as? [String] ?? []
            
            if let timestamp = data["purchaseDate"] as? Timestamp {
                self.purchaseDate = timestamp.dateValue()
            } else {
                self.purchaseDate = Date()
            }
        }
    }
    
    enum Timeframe: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case allTime = "All Time"
        var id: String { self.rawValue }
    }
    
    // MARK: - Lifecycle
    
    init(userID: String?) {
        self.currentUserID = userID
        fetchData()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    // MARK: - Data Fetching and Processing
    
    func fetchData() {
        guard let userID = currentUserID else {
            isLoading = false
            return
        }
        
        isLoading = true
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        let group = DispatchGroup()

        // 1. Fetch user's tours first
        group.enter()
        db.collection("tours")
            .whereField("ownerId", isEqualTo: userID)
            .getDocuments { tourSnapshot, error in
                defer { group.leave() }
                guard let tourDocs = tourSnapshot?.documents else { return }
                self.userTours = tourDocs.compactMap { try? $0.data(as: Tour.self) }
            }

        // 2. Once tours are fetched, fetch their corresponding shows
        group.notify(queue: .main) {
            let tourIDs = self.userTours.compactMap { $0.id }
            if tourIDs.isEmpty {
                // If the user has no tours, they can't have shows or events
                self.allShows = []
                self.attachListeners(for: userID)
                self.isLoading = false
                return
            }

            self.db.collection("shows")
                .whereField("tourId", in: tourIDs)
                .getDocuments { showSnapshot, error in
                    if let showDocs = showSnapshot?.documents {
                        self.allShows = showDocs.compactMap { try? $0.data(as: Show.self) }
                    }
                    // 3. Now that we have all necessary data, attach listeners
                    self.attachListeners(for: userID)
                    self.isLoading = false
                }
        }
    }
    
    private func attachListeners(for userID: String) {
        // Listen to ticketed events owned by this user
        let eventListener = self.db.collection("ticketedEvents")
            .whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.allTicketedEvents = documents.compactMap { try? $0.data(as: TicketedEvent.self) }
                self.processFetchedData()
            }
        self.listeners.append(eventListener)
        
        // Listen to ALL ticket sales, then filter by user's events
        let salesListener = self.db.collection("ticketSales")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let allSales = documents.map { TicketSale(from: $0) }
                
                // Filter sales to only include tickets for this user's events
                let userEventIds = Set(self.allTicketedEvents.compactMap { $0.id })
                self.allTicketSales = allSales.filter { userEventIds.contains($0.ticketedEventId) }
                self.recentTicketSales = Array(self.allTicketSales.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(10))
                
                self.processFetchedData()
            }
        self.listeners.append(salesListener)
    }
    
    private func processFetchedData() {
        let filteredSales = filterSalesByTimeframe()
        
        let totalTickets = filteredSales.reduce(0) { $0 + $1.quantity }
        let totalRevenue = filteredSales.reduce(0.0) { $0 + $1.totalPrice }
        
        DispatchQueue.main.async {
            self.summaryStats = SummaryStats(
                orderCount: filteredSales.count,
                ticketsIssued: totalTickets,
                totalRevenue: totalRevenue
            )
            
            // Set primary event only if it's not already set by user interaction
            if self.primaryEvent == nil {
                self.primaryEvent = self.findPrimaryEvent()
            }

            if let primaryEvent = self.primaryEvent {
                self.tour = self.userTours.first { $0.id == primaryEvent.tourId }
            } else {
                self.tour = nil
            }
            
            self.publishedEvents = self.allTicketedEvents.filter { $0.status == .published }
        }
    }
    
    private func findPrimaryEvent() -> TicketedEvent? {
        let upcomingEvents = allTicketedEvents.filter { event in
            guard let show = allShows.first(where: { $0.id == event.showId }) else { return false }
            return show.date.dateValue() >= Date()
        }
        
        return upcomingEvents.sorted(by: { event1, event2 in
            guard let show1 = allShows.first(where: { $0.id == event1.showId }),
                  let show2 = allShows.first(where: { $0.id == event2.showId }) else {
                return false
            }
            return show1.date.dateValue() < show2.date.dateValue()
        }).first
    }
    
    private func filterSalesByTimeframe() -> [TicketSale] {
        let now = Date()
        let calendar = Calendar.current
        
        return allTicketSales.filter { sale in
            switch selectedTimeframe {
            case .thisMonth:
                return calendar.isDate(sale.purchaseDate, equalTo: now, toGranularity: .month)
            case .thisYear:
                return calendar.isDate(sale.purchaseDate, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            }
        }
    }
    
    func setPrimaryEvent(to event: TicketedEvent) {
        self.primaryEvent = event
        self.tour = self.userTours.first { $0.id == event.tourId }
    }
    
    // Helper function to get tickets sold for a specific event
    func getTicketsSoldForEvent(_ eventId: String) -> Int {
        return allTicketSales
            .filter { $0.ticketedEventId == eventId }
            .reduce(0) { $0 + $1.quantity }
    }
    
    func updateEventStatus(for event: TicketedEvent, to newStatus: TicketedEvent.Status) {
        guard let eventID = event.id else { return }
        db.collection("ticketedEvents").document(eventID).updateData(["status": newStatus.rawValue])
    }
    
    // MARK: - Web Publishing Functions
    
    func publishTicketsToWeb(for event: TicketedEvent) {
        guard let eventID = event.id else {
            showPublishError(message: "Invalid event ID")
            return
        }
        
        isPublishingToWeb = true
        
        updateEventStatus(for: event, to: .published)
        
        TicketingAPI.shared.publishTickets(ticketedEventId: eventID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPublishingToWeb = false
                
                switch result {
                case .success(let response):
                    self?.showPublishSuccess(url: response.ticketSaleUrl)
                case .failure(let error):
                    self?.updateEventStatus(for: event, to: .draft)
                    self?.showPublishError(message: error.localizedDescription)
                }
            }
        }
    }
    
    func unpublishTickets(for event: TicketedEvent) {
        updateEventStatus(for: event, to: .unpublished)
    }
    
    // MARK: - Alert Helper Functions
    
    private func showPublishSuccess(url: String) {
        publishedURL = url
        publishAlertTitle = "Tickets Published!"
        publishAlertMessage = "Your ticket sale website is ready and the URL has been copied to your clipboard."
        showingPublishAlert = true
        TicketingAPI.shared.openURL(url)
    }
    
    private func showPublishError(message: String) {
        publishedURL = ""
        publishAlertTitle = "Publishing Failed"
        publishAlertMessage = "Failed to publish tickets to the web:\n\n\(message)"
        showingPublishAlert = true
    }
    
    // MARK: - Helper Functions for Alert Actions
    
    func openPublishedWebsite() {
        if !publishedURL.isEmpty {
            TicketingAPI.shared.openURL(publishedURL)
        }
    }
    
    func copyPublishedURL() {
        if !publishedURL.isEmpty {
            TicketingAPI.shared.copyToClipboard(publishedURL)
        }
    }
}
