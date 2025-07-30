import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ConfigureTicketsViewModel: ObservableObject {
    @Published var tour: Tour
    @Published var shows: [Show] = []
    @Published var eventMap: [String: TicketedEvent] = [:]
    @Published var isLoading = true
    @Published var isSaving = false
    
    // State for handling API call status and alerts
    @Published var isPublishing: [String: Bool] = [:]
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private let db = Firestore.firestore()

    init(tour: Tour) {
        self.tour = tour
    }

    func fetchData() async {
        self.isLoading = true
        guard let tourId = tour.id else {
            print("Error: Tour is missing ID")
            self.isLoading = false
            return
        }
        let ownerId = tour.ownerId
        
        do {
            let showsSnapshot = try await db.collection("shows").whereField("tourId", isEqualTo: tourId).getDocuments()
            self.shows = showsSnapshot.documents.compactMap { try? $0.data(as: Show.self) }.sorted { $0.date.dateValue() < $1.date.dateValue() }

            let eventsSnapshot = try await db.collection("ticketedEvents").whereField("tourId", isEqualTo: tourId).getDocuments()
            let existingEvents = eventsSnapshot.documents.compactMap { try? $0.data(as: TicketedEvent.self) }
            
            var tempMap: [String: TicketedEvent] = [:]
            for show in self.shows {
                guard let showId = show.id else { continue }
                if let existingEvent = existingEvents.first(where: { $0.showId == showId }) {
                    tempMap[showId] = existingEvent
                } else {
                    tempMap[showId] = TicketedEvent(
                        ownerId: ownerId, tourId: tourId, showId: showId, status: .draft,
                        importantInfo: nil, complimentaryTickets: nil, externalTicketsUrl: nil,
                        ticketTypes: [TicketType(name: "General Admission", allocation: 100, price: 0.0, currency: "NZD", availability: .init(type: .always))]
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
    
    func copySettings(from sourceShowId: String, to destinationShowId: String) {
        guard let sourceEvent = eventMap[sourceShowId] else { return }
        var destinationEvent = eventMap[destinationShowId]
        destinationEvent?.ticketTypes = sourceEvent.ticketTypes
        destinationEvent?.importantInfo = sourceEvent.importantInfo
        destinationEvent?.complimentaryTickets = sourceEvent.complimentaryTickets
        eventMap[destinationShowId] = destinationEvent
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
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
    
    func saveAllChanges() async {
        isSaving = true
        let batch = db.batch()
        
        for (_, var event) in eventMap {
            do {
                if let eventId = event.id {
                    let docRef = db.collection("ticketedEvents").document(eventId)
                    try batch.setData(from: event, forDocument: docRef, merge: true)
                } else {
                    let docRef = db.collection("ticketedEvents").document()
                    event.id = docRef.documentID // Assign the new ID back
                    try batch.setData(from: event, forDocument: docRef)
                }
            } catch {
                print("Error encoding event for save: \(error.localizedDescription)")
            }
        }
        
        do {
            try await batch.commit()
            print("✅ All ticket configurations saved.")
        } catch {
            print("❌ Error committing ticket configuration batch: \(error.localizedDescription)")
        }
        isSaving = false
        await fetchData()
    }
}
