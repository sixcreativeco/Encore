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
    @Published var tour: Tour? // Represents the primary tour for context
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
    private var allTicketSales: [TicketSale] = []
    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()
    private let currentUserID: String?
    
    // MARK: - Structs
    struct SummaryStats {
        var orderCount: Int = 0; var ticketsIssued: Int = 0; var totalRevenue: Double = 0.0
    }
    
    struct TicketSale: Identifiable {
        let id = UUID(); let purchaseId: String?; let ticketedEventId: String; let showId: String; let tourId: String; let quantity: Int; let totalPrice: Double; let buyerEmail: String; let purchaseDate: Date
        init(from document: DocumentSnapshot) {
            let data = document.data() ?? [:]; self.purchaseId = document.documentID; self.ticketedEventId = data["ticketedEventId"] as? String ?? ""; self.showId = data["showId"] as? String ?? ""; self.tourId = data["tourId"] as? String ?? ""; self.quantity = data["quantity"] as? Int ?? 0; self.totalPrice = data["totalPrice"] as? Double ?? 0.0; self.buyerEmail = data["buyerEmail"] as? String ?? ""; self.purchaseDate = (data["purchaseDate"] as? Timestamp)?.dateValue() ?? Date()
        }
    }
    
    // MARK: - Lifecycle
    init(userID: String?) {
        self.currentUserID = userID
        Task { await fetchData() }
    }
    
    deinit { listeners.forEach { $0.remove() } }
    
    // MARK: - Data Fetching
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
            // --- FIX: Query for ticketedEvents directly using ownerId ---
            print("➡️ DEBUG: Step 1 - Fetching ticketedEvents for ownerId: \(userID)...")
            let eventsSnapshot = try await db.collection("ticketedEvents").whereField("ownerId", isEqualTo: userID).getDocuments()
            self.allTicketedEvents = eventsSnapshot.documents.compactMap { try? $0.data(as: TicketedEvent.self) }
            print("✅ DEBUG: Found \(self.allTicketedEvents.count) ticketed events.")
            
            guard !self.allTicketedEvents.isEmpty else {
                print("⚠️ INFO: No ticketed events found for this user. Dashboard will be empty.")
                self.allShows = []; self.allTicketSales = []; self.tour = nil
                processAllData()
                self.isLoading = false
                return
            }

            // Step 2: Get related data based on the events we found
            let showIDs = Array(Set(self.allTicketedEvents.compactMap { $0.showId }))
            let tourIDs = Array(Set(self.allTicketedEvents.compactMap { $0.tourId }))
            
            print("➡️ DEBUG: Step 2 - Fetching related shows, tours, and sales...")
            print("✅ DEBUG: Unique Show IDs: \(showIDs)")
            print("✅ DEBUG: Unique Tour IDs: \(tourIDs)")

            if !showIDs.isEmpty {
                async let showsTask: [Show] = self.fetchCollectionByIds(collectionName: "shows", ids: showIDs)
                async let salesTask: [TicketSale] = self.fetchSalesCollection(where: "showId", in: showIDs)
                let (shows, sales) = try await (showsTask, salesTask)
                self.allShows = shows
                self.allTicketSales = sales
                print("✅ DEBUG: Found \(self.allShows.count) shows and \(self.allTicketSales.count) sales.")
            }
            
            if !tourIDs.isEmpty {
                let tours: [Tour] = try await self.fetchCollectionByIds(collectionName: "tours", ids: tourIDs)
                self.tour = tours.first // Assign the first tour for display purposes
                print("✅ DEBUG: Found \(tours.count) related tours.")
            }
            
            self.processAllData()
            self.attachListeners(for: userID)
            await fetchStripeBalance()
            
        } catch {
            print("❌ CRITICAL ERROR during initial data fetch: \(error.localizedDescription)")
        }
        
        print("--- TicketsDashboard: Data Fetch Complete ---")
        self.isLoading = false
    }
    
    private func fetchCollectionByIds<T: Decodable>(collectionName: String, ids: [String]) async throws -> [T] {
        guard !ids.isEmpty else { return [] }
        let snapshot = try await db.collection(collectionName).whereField(FieldPath.documentID(), in: ids).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    private func fetchSalesCollection(where field: String, in values: [Any]) async throws -> [TicketSale] {
        guard !values.isEmpty else { return [] }
        let snapshot = try await db.collection("ticketSales").whereField(field, in: values).getDocuments()
        return snapshot.documents.map { TicketSale(from: $0) }
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
            }
        
        self.listeners = [eventsListener, salesListener]
    }

    // MARK: - Data Processing
    private func processAllData() {
        // ... (This function remains the same, it will now just work with the correct data)
        let totalTickets = self.allTicketSales.reduce(0) { $0 + $1.quantity }
        let totalRevenue = self.allTicketSales.reduce(0.0) { $0 + $1.totalPrice }
        self.summaryStats = SummaryStats(orderCount: self.allTicketSales.count, ticketsIssued: totalTickets, totalRevenue: totalRevenue)
        self.primaryEvent = self.findPrimaryEvent()
        self.publishedEvents = self.allTicketedEvents.filter { $0.status == .published }
        self.recentTicketSales = Array(self.allTicketSales.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5))
        print("🔄 Processed Data: \(summaryStats.ticketsIssued) tickets sold. Primary event is '\(primaryEvent?.id ?? "None")'.")
    }
    
    private func findPrimaryEvent() -> TicketedEvent? {
        // ... (This function remains the same)
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
        // ... (This function remains the same)
        return allTicketSales.filter { $0.ticketedEventId == eventId }.reduce(0) { $0 + $1.quantity }
    }
    
    // MARK: - Stripe & Publishing Functions (Unchanged)
    
    func fetchStripeBalance() async {
        // Unchanged
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
        // Unchanged
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
        // Unchanged
        guard let userID = currentUserID else { return }
        let setupURL = "https://encoretickets.vercel.app/dashboard/stripe/setup?userId=\(userID)"
        if let url = URL(string: setupURL) { NSWorkspace.shared.open(url) }
    }
    
    func publishTicketsToWeb(for event: TicketedEvent) {
        // Unchanged
        guard let eventID = event.id else { return }
        isPublishingToWeb = true
        TicketingAPI.shared.publishTickets(ticketedEventId: eventID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPublishingToWeb = false
                switch result {
                case .success(let response):
                    self?.publishedURL = response.ticketSaleUrl
                    self?.showAlert(title: "Tickets Published!", message: "Your ticket sale website is ready.")
                    self?.updateEventStatus(for: event, to: .published)
                case .failure(let error):
                    self?.showAlert(title: "Publish Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    func unpublishTickets(for event: TicketedEvent) {
        // Unchanged
        updateEventStatus(for: event, to: .unpublished)
    }
    
    private func updateEventStatus(for event: TicketedEvent, to newStatus: TicketedEvent.Status) {
        guard let eventID = event.id else { return }
        db.collection("ticketedEvents").document(eventID).updateData(["status": newStatus.rawValue])
    }
    
    private func showAlert(title: String, message: String) {
        // Unchanged
        self.alertTitle = title; self.alertMessage = message; self.showingAlert = true
    }
    
    func openPublishedWebsite() {
        // Unchanged
        if !publishedURL.isEmpty, let url = URL(string: publishedURL) { NSWorkspace.shared.open(url) }
    }
    
    func copyPublishedURL() {
        // Unchanged
        if !publishedURL.isEmpty {
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(publishedURL, forType: .string)
        }
    }
}
