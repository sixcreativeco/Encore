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
    @Published var allShows: [Show] = []
    @Published var tour: Tour?
    @Published var ticketedTours: [Tour] = []
    @Published var isLoading = true
    
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
    var allTicketedEvents: [TicketedEvent] = []
    private var allUserTours: [Tour] = []
    private var allTicketSales: [TicketSale] = []
    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()
    private let currentUserID: String?

    struct SummaryStats {
        var orderCount: Int = 0; var ticketsIssued: Int = 0; var totalRevenue: Double = 0.0
    }
    
    struct TicketSale: Identifiable {
        let id = UUID(); let purchaseId: String?; let ticketedEventId: String; let showId: String; let tourId: String; let quantity: Int; let totalPrice: Double; let buyerEmail: String; let purchaseDate: Date
        init(from document: DocumentSnapshot) {
            let data = document.data() ?? [:]; self.purchaseId = document.documentID; self.ticketedEventId = data["ticketedEventId"] as? String ?? ""; self.showId = data["showId"] as? String ?? ""; self.tourId = data["tourId"] as? String ?? ""; self.quantity = data["quantity"] as? Int ?? 0; self.totalPrice = data["totalPrice"] as? Double ?? 0.0; self.buyerEmail = data["buyerEmail"] as? String ?? ""; self.purchaseDate = (data["purchaseDate"] as? Timestamp)?.dateValue() ?? Date()
        }
    }
    
    init(userID: String?) {
        self.currentUserID = userID
        Task { await fetchData() }
    }
    
    deinit { listeners.forEach { $0.remove() } }
    
    func fetchData() async {
        self.isLoading = true
        print("--- TicketsDashboard: Starting Data Fetch ---")
        guard let userID = currentUserID else {
            print("❌ ERROR: User ID is nil. Halting fetch.")
            self.isLoading = false
            return
        }
        print("✅ DEBUG: Current User ID: \(userID)")

        do {
            async let toursTask: [Tour] = self.fetchCollection(collectionName: "tours", field: "ownerId", value: userID)
            let tours = try await toursTask
            self.allUserTours = tours
            
            let tourIDs = self.allUserTours.compactMap { $0.id }
            if !tourIDs.isEmpty {
                let shows: [Show] = try await fetchCollectionByIds(collectionName: "shows", ids: tourIDs, idField: "tourId")
                self.allShows = shows
            } else {
                self.allShows = []
            }
            
            print("✅ DEBUG: Fetched \(self.allUserTours.count) tours and \(self.allShows.count) shows.")
            
            self.attachListeners(for: userID)
            await self.fetchStripeBalance()
            
        } catch {
            print("❌ CRITICAL ERROR during initial data fetch: \(error.localizedDescription)")
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
        print("🎧 Attaching real-time listeners for ownerId: \(userID)...")
        
        let eventsListener = db.collection("ticketedEvents").whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }
                print("🎧 Firestore REAL-TIME update: Got \(documents.count) ticketed events.")
                self.allTicketedEvents = documents.compactMap { try? $0.data(as: TicketedEvent.self) }
                self.processAllData()
            }
        
        let salesListener = db.collection("ticketSales").whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }
                print("🎧 Firestore REAL-TIME update: Got \(documents.count) ticket sales.")
                self.allTicketSales = documents.map { TicketSale(from: $0) }
                self.processAllData()
                
                if self.isLoading {
                    self.isLoading = false
                    print("--- TicketsDashboard: Initial Load Complete ---")
                }
            }
        
        self.listeners = [eventsListener, salesListener]
    }

    private func processAllData() {
        let totalTickets = self.allTicketSales.reduce(0) { $0 + $1.quantity }
        let totalRevenue = self.allTicketSales.reduce(0.0) { $0 + $1.totalPrice }
        self.summaryStats = SummaryStats(orderCount: self.allTicketSales.count, ticketsIssued: totalTickets, totalRevenue: totalRevenue)
        
        self.primaryEvent = self.findPrimaryEvent()
        self.publishedEvents = self.allTicketedEvents.filter { $0.status == .published }
        self.recentTicketSales = Array(self.allTicketSales.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5))

        let tourIDsWithTickets = Set(self.allTicketedEvents.map { $0.tourId })
        self.ticketedTours = self.allUserTours.filter { tourIDsWithTickets.contains($0.id ?? "") }

        if let primaryEventTourID = self.primaryEvent?.tourId {
            self.tour = self.allUserTours.first { $0.id == primaryEventTourID }
        } else if !self.ticketedTours.isEmpty {
            self.tour = self.ticketedTours.first
        } else {
            self.tour = self.allUserTours.first
        }
        
        print("🔄 Processed Data: \(summaryStats.ticketsIssued) tickets sold. Primary event is '\(primaryEvent?.id ?? "None")'. Found \(ticketedTours.count) ticketed tours.")
    }
    
    private func findPrimaryEvent() -> TicketedEvent? {
        let upcomingEvents = allTicketedEvents.filter { event in
            guard let show = allShows.first(where: { $0.id == event.showId }) else { return false }
            return show.date.dateValue() >= Date()
        }
        return upcomingEvents.sorted { event1, event2 in
            guard let show1 = allShows.first(where: { $0.id == event1.showId }),
                  let show2 = allShows.first(where: { $0.id == event2.showId }) else { return false }
            return show1.date.dateValue() < show2.date.dateValue()
        }.first
    }
    
    func getTicketsSoldForEvent(_ eventId: String) -> Int {
        return allTicketSales.filter { $0.ticketedEventId == eventId }.reduce(0) { $0 + $1.quantity }
    }
    
    func getTour(for tourId: String) -> Tour? {
        return allUserTours.first { $0.id == tourId }
    }
    
    func fetchStripeBalance() async {
        guard let userID = currentUserID else { return }
        do {
            let userDoc = try await db.collection("users").document(userID).getDocument()
            guard userDoc.data()?["stripeAccountId"] as? String != nil else {
                self.hasStripeAccount = false; return
            }
            self.hasStripeAccount = true
            let url = URL(string: "https://encoretickets.vercel.app/api/get-balance")!
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
                let url = URL(string: "https://encoretickets.vercel.app/api/create-payout")!
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
        let setupURL = "https://encoretickets.vercel.app/dashboard/stripe/setup?userId=\(userID)"
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
        self.alertTitle = title; self.alertMessage = message; self.showingAlert = true
    }
    
    // FIX: Added 'self' to access class properties
    private func showPublishSuccess(url: String) {
        self.publishedURL = url
        self.alertTitle = "Tickets Published!"
        self.alertMessage = "Your ticket sale website is ready."
        self.showingAlert = true
    }
    
    // FIX: Added 'self' to access class properties
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
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(publishedURL, forType: .string)
        }
    }
}
