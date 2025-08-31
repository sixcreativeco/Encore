import SwiftUI
import FirebaseFirestore

@MainActor
class BulkTicketEditViewModel: ObservableObject {
    let tour: Tour
    let showIDs: Set<String>
    private let db = Firestore.firestore()

    @Published var ticketTypes: [TicketType] = [TicketType(name: "General Admission", allocation: 100, price: 0.0, currency: "NZD", availability: .init(type: .always))]
    @Published var description: String = ""
    @Published var importantInfo: String = ""
    @Published var complimentaryTickets: String = ""
    
    @Published var isSaving = false
    
    init(tour: Tour, showIDs: Set<String>) {
        self.tour = tour
        self.showIDs = showIDs
    }
    
    func saveChanges() async throws {
        isSaving = true
        
        let batch = db.batch()
        let validTicketTypes = ticketTypes.filter { !$0.name.isEmpty && $0.allocation > 0 }
        
        // Fetch existing TicketedEvents for the selected shows in one query
        let eventsSnapshot = try await db.collection("ticketedEvents").whereField("showId", in: Array(showIDs)).getDocuments()
        let existingEventsMap = Dictionary(uniqueKeysWithValues: eventsSnapshot.documents.compactMap { doc -> (String, DocumentReference)? in
            guard let showId = doc.data()["showId"] as? String else { return nil }
            return (showId, doc.reference)
        })

        for showId in showIDs {
            let data: [String: Any] = [
                "ticketTypes": validTicketTypes.map { try? Firestore.Encoder().encode($0) }.compactMap { $0 },
                "description": description.isEmpty ? NSNull() : description,
                "importantInfo": importantInfo.isEmpty ? NSNull() : importantInfo,
                "complimentaryTickets": Int(complimentaryTickets) ?? NSNull(),
                "lastUpdatedAt": FieldValue.serverTimestamp()
            ]

            if let eventRef = existingEventsMap[showId] {
                // Update existing document
                batch.updateData(data, forDocument: eventRef)
            } else {
                // Create new document for a show that didn't have tickets configured yet
                let eventRef = db.collection("ticketedEvents").document()
                var newData = data
                newData["ownerId"] = tour.ownerId
                newData["tourId"] = tour.id ?? ""
                newData["showId"] = showId
                newData["status"] = TicketedEvent.Status.draft.rawValue
                newData["createdAt"] = FieldValue.serverTimestamp()
                batch.setData(newData, forDocument: eventRef)
            }
        }
        
        try await batch.commit()
        
        await MainActor.run {
            isSaving = false
        }
    }
}
