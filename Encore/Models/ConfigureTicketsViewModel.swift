import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AppKit

@MainActor
class ConfigureTicketsViewModel: ObservableObject {
    
    @Published var tour: Tour
    @Published var show: Show?
    @Published var shows: [Show] = []
    @Published var eventMap: [String: TicketedEvent] = [:]
    @Published var ticketSales: [TicketSale] = []
    @Published var isLoading = true
    @Published var isSaving = false
    
    @Published var showToExpandId: String?
    
    @Published var isPublishing: [String: Bool] = [:]
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private let db = Firestore.firestore()

    init(tour: Tour, showToExpand: Show? = nil) {
        self.tour = tour
        self.show = showToExpand
        self.showToExpandId = showToExpand?.id
    }

    func fetchData() async {
        self.isLoading = true
        guard let tourId = tour.id else {
            self.isLoading = false
            return
        }
        
        do {
            let showsSnapshot = try await db.collection("shows").whereField("tourId", isEqualTo: tourId).getDocuments()
            self.shows = showsSnapshot.documents.compactMap { try? $0.data(as: Show.self) }.sorted { $0.date.dateValue() < $1.date.dateValue() }
            
            let showIDs = self.shows.compactMap { $0.id }
            if showIDs.isEmpty {
                self.isLoading = false
                return
            }
            
            let eventsSnapshot = try await db.collection("ticketedEvents").whereField("showId", in: showIDs).getDocuments()
            let existingEvents = eventsSnapshot.documents.compactMap { try? $0.data(as: TicketedEvent.self) }
            
            let salesSnapshot = try await db.collection("ticketSales").whereField("tourId", isEqualTo: tourId).getDocuments()
            self.ticketSales = salesSnapshot.documents.map { TicketSale(from: $0) }
            
            var tempMap: [String: TicketedEvent] = [:]
            for show in self.shows {
                guard let showId = show.id else { continue }
                if let existingEvent = existingEvents.first(where: { $0.showId == showId }) {
                    tempMap[showId] = existingEvent
                } else {
                    tempMap[showId] = TicketedEvent(
                        ownerId: tour.ownerId, tourId: tourId, showId: showId, status: .draft,
                        onSaleDate: nil, description: nil, importantInfo: nil, complimentaryTickets: nil, externalTicketsUrl: nil,
                        ticketTypes: tour.defaultTicketTypes ?? [TicketType(name: "General Admission", allocation: 100, price: 0.0, currency: "NZD", availability: .init(type: .always))]
                    )
                }
            }
            self.eventMap = tempMap
            self.isLoading = false
        } catch {
            print("Error fetching data for ticket configuration: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
    
    func getTicketsSold(for eventId: String) -> Int {
        return ticketSales.filter { $0.ticketedEventId == eventId }.reduce(0) { $0 + $1.quantity }
    }
    
    func copySettings(from sourceShowId: String, to destinationShowId: String) {
        guard let sourceEvent = eventMap[sourceShowId], var destEvent = eventMap[destinationShowId] else { return }
        destEvent.ticketTypes = sourceEvent.ticketTypes
        destEvent.description = sourceEvent.description
        destEvent.importantInfo = sourceEvent.importantInfo
        destEvent.complimentaryTickets = sourceEvent.complimentaryTickets
        eventMap[destinationShowId] = destEvent
    }
    
    func handlePublishToggle(for showId: String) {
        guard let event = eventMap[showId] else { return }
        
        if event.status == .published {
            unpublishTickets(for: event)
        } else {
            publishTicketsToWeb(for: event)
        }
    }
    
    private func publishTicketsToWeb(for event: TicketedEvent) {
        guard let eventId = event.id else {
            showAlert(title: "Save Required", message: "Please save all configurations before publishing.")
            return
        }
        isPublishing[eventId] = true
        
        TicketingAPI.shared.publishTickets(ticketedEventId: eventId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPublishing[eventId] = false
                switch result {
                case .success:
                    self?.showAlert(title: "Tickets Published", message: "The ticket sales page is now live.")
                    Task { await self?.fetchData() }
                case .failure(let error):
                    self?.showAlert(title: "Publish Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func unpublishTickets(for event: TicketedEvent) {
        guard let eventId = event.id else { return }
        isPublishing[eventId] = true
        db.collection("ticketedEvents").document(eventId).updateData(["status": TicketedEvent.Status.unpublished.rawValue]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isPublishing[eventId] = false
                if let error = error {
                    self?.showAlert(title: "Error", message: "Could not unpublish tickets: \(error.localizedDescription)")
                } else {
                    Task { await self?.fetchData() }
                }
            }
        }
    }
    
    func saveAllChanges() async {
        isSaving = true
        let batch = db.batch()
        
        if let tourId = tour.id {
            do {
                let tourRef = db.collection("tours").document(tourId)
                try batch.setData(from: tour, forDocument: tourRef, merge: true)
            } catch {
                 print("Error encoding tour defaults for save: \(error.localizedDescription)")
            }
        }
        
        // --- THIS IS THE FIX ---
        // Save any changes made to the show objects (like their dates).
        for show in self.shows {
            guard let showId = show.id else { continue }
            let showRef = db.collection("shows").document(showId)
            do {
                try batch.setData(from: show, forDocument: showRef, merge: true)
            } catch {
                print("Error encoding show \(showId) for save: \(error.localizedDescription)")
            }
        }
        // --- END OF FIX ---
         
        for (_, var event) in eventMap {
            do {
                if let eventId = event.id {
                    let docRef = db.collection("ticketedEvents").document(eventId)
                    try batch.setData(from: event, forDocument: docRef, merge: true)
                 } else {
                    let docRef = db.collection("ticketedEvents").document()
                    event.id = docRef.documentID
                    try batch.setData(from: event, forDocument: docRef)
                 }
            } catch {
                print("Error encoding event for save: \(error.localizedDescription)")
            }
        }
        
        do {
            try await batch.commit()
        } catch {
            print("❌ Error committing batch: \(error.localizedDescription)")
        }
        isSaving = false
        await fetchData()
    }

    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
