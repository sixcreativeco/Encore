import Foundation
import Combine
import FirebaseFirestore

class TicketsViewModel: ObservableObject {
    
    // MARK: - Published Properties for the View
    
    @Published var summaryStats = SummaryStats()
    @Published var primaryEvent: TicketedEvent?
    @Published var recentActivity: [TicketOrder] = []
    @Published var recentTicketSales: [TicketSale] = []
    @Published var allTicketSales: [TicketSale] = []
    @Published var publishedEvents: [TicketedEvent] = []
    @Published var allShows: [Show] = []
    @Published var tour: Tour?
    
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
    var allOrders: [TicketOrder] = []
    
    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()
    
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
    
    init() {
        fetchData()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    // MARK: - Data Fetching and Processing
    
    func fetchData() {
        isLoading = true
        listeners.forEach { $0.remove() }
        listeners.removeAll()

        let group = DispatchGroup()
        
        group.enter()
        db.collection("shows").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                self.allShows = documents.compactMap { try? $0.data(as: Show.self) }
            }
            group.leave()
        }
        
        group.enter()
        db.collection("tours").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                self.tour = documents.compactMap { try? $0.data(as: Tour.self) }.first
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.attachListeners()
            self.isLoading = false
        }
    }
    
    private func attachListeners() {
        let eventListener = self.db.collection("ticketedEvents").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            self.allTicketedEvents = documents.compactMap { try? $0.data(as: TicketedEvent.self) }
            self.processFetchedData()
        }
        self.listeners.append(eventListener)
        
        let orderListener = self.db.collection("ticketOrders").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            self.allOrders = documents.compactMap { try? $0.data(as: TicketOrder.self) }
            self.processFetchedData()
        }
        self.listeners.append(orderListener)
        
        // NEW: Listen to ticket sales
        let salesListener = self.db.collection("ticketSales").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            self.allTicketSales = documents.map { TicketSale(from: $0) }
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
            self.primaryEvent = self.findPrimaryEvent()
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
        
        // Update local Firebase status first for immediate UI feedback
        updateEventStatus(for: event, to: .published)
        
        // Then call the web API
        TicketingAPI.shared.publishTickets(ticketedEventId: eventID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPublishingToWeb = false
                
                switch result {
                case .success(let response):
                    print("✅ Tickets published successfully!")
                    print("🎫 Ticket sale URL: \(response.ticketSaleUrl)")
                    
                    // Copy URL to clipboard
                    TicketingAPI.shared.copyToClipboard(response.ticketSaleUrl)
                    
                    // Show success alert
                    self?.showPublishSuccess(url: response.ticketSaleUrl)
                    
                case .failure(let error):
                    print("❌ Failed to publish tickets: \(error.localizedDescription)")
                    
                    // Revert the status change if API call failed
                    self?.updateEventStatus(for: event, to: .unpublished)
                    
                    // Show error alert
                    self?.showPublishError(message: error.localizedDescription)
                }
            }
        }
    }
    
    func unpublishTickets(for event: TicketedEvent) {
        // For unpublishing, just update the local Firebase status
        updateEventStatus(for: event, to: .unpublished)
        
        // Optionally, you could also call an API to unpublish from web
        // but for now, we'll just update the local status
        print("🔒 Tickets unpublished locally")
    }
    
    // MARK: - Alert Helper Functions
    
    private func showPublishSuccess(url: String) {
        publishedURL = url
        publishAlertTitle = "Tickets Published!"
        publishAlertMessage = "Your ticket sale website is ready and has been copied to your clipboard.\n\n\(url)"
        showingPublishAlert = true
        
        // Automatically open the website
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
