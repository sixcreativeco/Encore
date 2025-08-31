import Foundation
import Combine
import FirebaseFirestore
import AppKit
import SwiftUI
import Kingfisher
import FirebaseAuth

@MainActor
class TicketsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var summaryStats = SummaryStats()
    @Published var primaryEvent: TicketedEvent?
    @Published var recentTicketSales: [TicketSale] = []
    @Published var publishedEvents: [TicketedEvent] = []
    @Published var upcomingEvents: [TicketedEvent] = []
    @Published var ticketedTours: [Tour] = []
    @Published var isLoading = true
    
    @Published var allShows: [Show] = []
    @Published var eventMap: [String: TicketedEvent] = [:]
    @Published var allUserTours: [Tour] = []
    
    var tour: Tour?
    
    // Alert Properties
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var publishedURL = ""
    @Published var isPublishingToWeb = false
    
    // Stripe Properties
    @Published var stripeBalance: Double = 0.0
    @Published var stripePendingBalance: Double = 0.0
    @Published var stripeCurrency: String = "NZD"
    @Published var hasStripeAccount: Bool = false
    @Published var isRequestingPayout: Bool = false
    
    // MARK: - Private Properties
    private var allTicketedEvents: [TicketedEvent] = []
    private var allTicketSales: [TicketSale] = []
    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()
    private let currentUserID: String?
    
    init(userID: String?) {
        self.currentUserID = userID
        Task { await fetchData() }
    }
    
    deinit { listeners.forEach { $0.remove() } }
    
    func fetchData() async {
        self.isLoading = true
        guard let userID = currentUserID else {
            self.isLoading = false
            return
        }

        do {
            async let toursTask: [Tour] = self.fetchCollection(collectionName: "tours", field: "ownerId", value: userID)
            let tours = try await toursTask
            self.allUserTours = tours.sorted { $0.startDate.dateValue() > $1.startDate.dateValue() }
            
            let tourIDs = self.allUserTours.compactMap { $0.id }
            if !tourIDs.isEmpty {
                let shows: [Show] = try await fetchCollectionByIds(collectionName: "shows", ids: tourIDs, idField: "tourId")
                self.allShows = shows
            } else {
                self.allShows = []
            }
            
            self.attachListeners(for: userID)
            await self.fetchStripeBalance()
            
        } catch {
            self.isLoading = false
        }
    }

    private func fetchCollection<T: Decodable>(collectionName: String, field: String, value: Any) async throws -> [T] {
        let snapshot = try await db.collection(collectionName).whereField(field, isEqualTo: value).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    private func fetchCollectionByIds<T: Decodable>(collectionName: String, ids: [String], idField: String = FieldPath.documentID().description) async throws -> [T] {
        guard !ids.isEmpty else { return [] }
        let snapshot = try await db.collection(collectionName).whereField(idField, in: ids).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    private func attachListeners(for userID: String) {
        listeners.forEach { $0.remove() }
        
        let eventsListener = db.collection("ticketedEvents").whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }
                self.allTicketedEvents = documents.compactMap { try? $0.data(as: TicketedEvent.self) }
                self.processAllData()
            }
        
        let salesListener = db.collection("ticketSales").whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }
                self.allTicketSales = documents.map { TicketSale(from: $0) }
                self.processAllData()
                
                if self.isLoading {
                     self.isLoading = false
                }
            }
        
        self.listeners = [eventsListener, salesListener]
    }

    private func processAllData() {
        let totalTickets = self.allTicketSales.reduce(0) { $0 + $1.quantity }
        let totalRevenue = self.allTicketSales.reduce(0.0) { $0 + $1.totalPrice }
        self.summaryStats = SummaryStats(orderCount: self.allTicketSales.count, ticketsIssued: totalTickets, totalRevenue: totalRevenue)
        
        self.publishedEvents = self.allTicketedEvents.filter { $0.status == .published }
        self.recentTicketSales = Array(self.allTicketSales.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5))

        let tourIDsWithTickets = Set(self.allTicketedEvents.map { $0.tourId })
        self.ticketedTours = self.allUserTours.filter { tourIDsWithTickets.contains($0.id ?? "") }
        
        var tempEventMap: [String: TicketedEvent] = [:]
        for event in allTicketedEvents {
            tempEventMap[event.showId] = event
        }
        self.eventMap = tempEventMap

        self.primaryEvent = self.findPrimaryEvent()

        if let primaryEventTourID = self.primaryEvent?.tourId {
            self.tour = self.allUserTours.first { $0.id == primaryEventTourID }
        } else if !self.ticketedTours.isEmpty {
            self.tour = self.ticketedTours.first
        } else {
            self.tour = self.allUserTours.first
        }
    }
    
    private func findPrimaryEvent() -> TicketedEvent? {
        let upcoming = self.allTicketedEvents.filter { event in
            guard let show = self.allShows.first(where: { $0.id == event.showId }) else { return false }
            return show.date.dateValue() >= Date() && (event.status == .published || event.status == .scheduled)
        }
        
        self.upcomingEvents = upcoming.sorted { e1, e2 in
            let show1 = self.allShows.first(where: { $0.id == e1.showId })
            let show2 = self.allShows.first(where: { $0.id == e2.showId })
            return (show1?.date.dateValue() ?? .distantFuture) < (show2?.date.dateValue() ?? .distantFuture)
        }
        
        if let nextUpcoming = self.upcomingEvents.first {
            return nextUpcoming
        }
        
        let pastEvents = self.allTicketedEvents.filter { event in
            guard let show = allShows.first(where: { $0.id == event.showId }) else { return false }
            return show.date.dateValue() < Date()
        }
        
        return pastEvents.sorted { e1, e2 in
            let show1 = self.allShows.first(where: { $0.id == e1.showId })
            let show2 = self.allShows.first(where: { $0.id == e2.showId })
            return (show1?.date.dateValue() ?? .distantPast) > (show2?.date.dateValue() ?? .distantPast)
        }.first
    }
    
    func getTicketsSoldForEvent(_ eventId: String) -> Int {
        return allTicketSales.filter { $0.ticketedEventId == eventId && $0.saleType != "comp" }.reduce(0) { $0 + $1.quantity }
    }
    
    func getCompTicketsIssued(for eventId: String) -> Int {
        return allTicketSales.filter { $0.ticketedEventId == eventId && $0.saleType == "comp" }.reduce(0) { $0 + $1.quantity }
    }

    func getRevenueForEvent(_ eventId: String) -> Double {
        return allTicketSales
            .filter { $0.ticketedEventId == eventId }
            .reduce(0.0) { $0 + $1.totalPrice }
    }
    
    func getTour(for tourId: String) -> Tour? {
        return allUserTours.first { $0.id == tourId }
    }
    
    func fetchStripeBalance() async {
        guard let userID = currentUserID else { return }
        do {
            let userDoc = try await db.collection("users").document(userID).getDocument()
            let stripeId = userDoc.data()?["stripeAccountId"] as? String ?? userDoc.data()?["stripeLiveAccountId"] as? String
            
            guard stripeId != nil else {
                self.hasStripeAccount = false
                return
            }
            
            self.hasStripeAccount = true
            let url = URL(string: "https://en-co.re/api/get-balance")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["userId": userID])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
            let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let available = responseDict?["available"] as? [[String: Any]], let nzdBalance = available.first(where: { ($0["currency"] as? String)?.uppercased() == "NZD" }) {
                self.stripeBalance = Double(nzdBalance["amount"] as? Int ?? 0) / 100.0
            } else { self.stripeBalance = 0.0 }
            if let pending = responseDict?["pending"] as? [[String: Any]], let nzdPending = pending.first(where: { ($0["currency"] as? String)?.uppercased() == "NZD" }) {
                self.stripePendingBalance = Double(nzdPending["amount"] as? Int ?? 0) / 100.0
            } else { self.stripePendingBalance = 0.0 }
        } catch {
            self.hasStripeAccount = false; self.stripeBalance = 0.0; self.stripePendingBalance = 0.0
        }
    }

    func requestStripePayout(amount: Double) {
        guard let userID = currentUserID, amount > 0 else { return }
        isRequestingPayout = true
        Task {
            do {
                let url = URL(string: "https://en-co.re/api/create-payout")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: Any] = ["userId": userID, "amount": amount, "currency": stripeCurrency.lowercased()]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                 let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    throw NSError(domain: "PayoutError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: responseDict?["error"] as? String ?? "Payout request failed."])
                }
                self.showAlert(title: "Payout Requested", message: "Your payout of \(self.stripeCurrency) \(String(format: "%.2f", amount)) has been requested.")
                 self.isRequestingPayout = false
                await self.fetchStripeBalance()
            } catch {
                self.showAlert(title: "Payout Failed", message: error.localizedDescription)
                self.isRequestingPayout = false
            }
        }
    }

     func setupStripeAccount() {
        guard let userID = currentUserID else { return }
        let setupURL = "https://en-co.re/dashboard/stripe/setup?userId=\(userID)"
        if let url = URL(string: setupURL) { NSWorkspace.shared.open(url) }
    }
    
    func publishTicketsToWeb(for event: TicketedEvent) {
        guard let eventID = event.id else {
            showPublishError(message: "Invalid event ID")
            return
        }
        isPublishingToWeb = true
        
        TicketingAPI.shared.publishTickets(ticketedEventId: eventID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPublishingToWeb = false
                switch result {
                 case .success(let response):
                    self?.showPublishSuccess(url: response.ticketSaleUrl)
                case .failure(let error):
                    self?.showPublishError(message: error.localizedDescription)
                }
            }
         }
    }
    
    func unpublishTickets(for event: TicketedEvent) {
        updateEventStatus(for: event, to: .unpublished)
    }
    
    private func updateEventStatus(for event: TicketedEvent, to newStatus: TicketedEvent.Status) {
        guard let eventID = event.id else { return }
        db.collection("ticketedEvents").document(eventID).updateData(["status": newStatus.rawValue])
    }
    
    private func showAlert(title: String, message: String) {
         self.alertTitle = title; self.alertMessage = message;
        self.showingAlert = true
    }
    
    private func showPublishSuccess(url: String) {
        self.publishedURL = url
        self.alertTitle = "Tickets Published!"
        self.alertMessage = "Your ticket sale website is ready."
        self.showingAlert = true
    }
    
    private func showPublishError(message: String) {
        self.publishedURL = ""
        self.alertTitle = "Publishing Failed"
        self.alertMessage = "Failed to publish tickets to the web:\n\n\(message)"
        self.showingAlert = true
    }
    
    func openPublishedWebsite() {
        if !publishedURL.isEmpty, let url = URL(string: publishedURL) { NSWorkspace.shared.open(url) }
    }
    
    func copyPublishedURL() {
        if !publishedURL.isEmpty {
            NSPasteboard.general.clearContents();
            NSPasteboard.general.setString(publishedURL, forType: .string)
        }
    }
}
