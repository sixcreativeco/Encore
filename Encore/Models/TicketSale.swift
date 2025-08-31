import Foundation
import FirebaseFirestore

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
    var saleType: String? // --- THIS IS THE ADDITION ---
    
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
        self.saleType = data["saleType"] as? String // --- THIS IS THE ADDITION ---
        
        if let timestamp = data["purchaseDate"] as? Timestamp {
            self.purchaseDate = timestamp.dateValue()
        } else {
            self.purchaseDate = Date()
        }
    }
}

struct SummaryStats {
    var orderCount: Int = 0
    var ticketsIssued: Int = 0
    var totalRevenue: Double = 0.0
}
