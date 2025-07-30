import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseStorage

@MainActor
class LandingPageViewModel: ObservableObject {
    enum URLAvailabilityStatus: Equatable {
        case idle
        case checking
        case available
        case unavailable(String)
        case error(String)
    }

    @Published var tour: Tour
    @Published var urlSlug: String
    @Published var availabilityStatus: URLAvailabilityStatus = .idle
    @Published var isSaving = false

    private var cancellable: AnyCancellable?
    private let db = Firestore.firestore()

    init(tour: Tour) {
        self.tour = tour
        self.urlSlug = tour.landingPageUrl ?? ""
        if !self.urlSlug.isEmpty {
            self.availabilityStatus = .available
        }
    }

    func checkUrlAvailability() {
        let cleanSlug = urlSlug
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        
        guard !cleanSlug.isEmpty else {
            availabilityStatus = .idle
            return
        }
        
        // If the user types back their original URL, show it as available.
        if cleanSlug == tour.landingPageUrl {
            availabilityStatus = .available
            return
        }

        availabilityStatus = .checking
        cancellable?.cancel()

        cancellable = Just(cleanSlug)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .flatMap { slug -> AnyPublisher<Bool, Error> in
                // This is a placeholder for the API call. In a real scenario,
                // this would call the TicketingAPI service.
                Future<Bool, Error> { promise in
                    self.db.collection("tours").whereField("landingPageUrl", isEqualTo: slug).getDocuments { snapshot, error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            promise(.success(snapshot?.isEmpty ?? true))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.availabilityStatus = .error(error.localizedDescription)
                }
            }, receiveValue: { isAvailable in
                if isAvailable {
                    self.availabilityStatus = .available
                } else {
                    self.availabilityStatus = .unavailable("URL is already taken.")
                }
            })
    }

    func saveAndPublish(headerImageUrl: URL?, publishNow: Bool) async {
        guard let tourId = tour.id else {
            print("❌ Error: Tour ID is missing.")
            return
        }
        
        isSaving = true
        var updatedTour = self.tour
        updatedTour.landingPageUrl = self.urlSlug

        // 1. Upload new header image if one was selected
        if let fileURL = headerImageUrl {
            do {
                let storageRef = Storage.storage().reference().child("landing_headers/\(UUID().uuidString).jpg")
                _ = try await storageRef.putFileAsync(from: fileURL)
                let downloadURL = try await storageRef.downloadURL()
                updatedTour.landingPageHeaderImageUrl = downloadURL.absoluteString
            } catch {
                print("❌ Error uploading header image: \(error.localizedDescription)")
            }
        }

        let batch = db.batch()

        // 2. Update the tour document
        do {
            let tourRef = db.collection("tours").document(tourId)
            try batch.setData(from: updatedTour, forDocument: tourRef, merge: true)
        } catch {
            print("❌ Error encoding tour for update: \(error.localizedDescription)")
            isSaving = false
            return
        }

        // 3. Update status of all ticketed events for this tour
        if publishNow {
            do {
                let eventsSnapshot = try await db.collection("ticketedEvents").whereField("tourId", isEqualTo: tourId).getDocuments()
                for doc in eventsSnapshot.documents {
                    batch.updateData(["status": TicketedEvent.Status.published.rawValue], forDocument: doc.reference)
                }
            } catch {
                print("❌ Error fetching ticketed events for publishing: \(error.localizedDescription)")
            }
        }

        // 4. Commit all changes
        do {
            try await batch.commit()
            print("✅ Landing page saved and events status updated.")
            self.tour = updatedTour // Update local state
        } catch {
            print("❌ Error saving landing page batch: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
}
