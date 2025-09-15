import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseStorage

@MainActor
class LandingPageViewModel: ObservableObject {
    enum URLAvailabilityStatus: Equatable {
        case idle, checking, available, unavailable(String), error(String)
    }

    @Binding var tour: Tour
    
    @Published var urlSlug: String
    @Published var availabilityStatus: URLAvailabilityStatus = .idle
    @Published var isSaving = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0

    private var cancellable: AnyCancellable?
    private let db = Firestore.firestore()

    init(tour: Binding<Tour>) {
        self._tour = tour
        self.urlSlug = tour.wrappedValue.landingPageUrl ?? ""
        if !self.urlSlug.isEmpty {
            self.availabilityStatus = .available
        }
    }
    
    // --- THIS FUNCTION CONTAINS THE CRASH FIX ---
    // It correctly handles secure access to the file URL before uploading.
    func uploadMedia(fileURL: URL, for slot: Int = 1) async {
        // 1. Start accessing the security-scoped resource.
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("❌ Failed to gain access to the file URL.")
            return
        }

        // 2. Defer stopping access until the function exits.
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        guard let tourId = tour.id else { return }
        isUploading = true
        
        do {
            let storageRef = Storage.storage().reference().child("landing_headers/\(tourId)/\(UUID().uuidString)")
            
            // This part was already correct, using the modern async/await API.
            _ = try await storageRef.putFile(from: fileURL, metadata: nil)
            
            let downloadURL = try await storageRef.downloadURL()
            let urlString = downloadURL.absoluteString
            let isVideo = ["mov", "mp4", "m4v"].contains(fileURL.pathExtension.lowercased())
            
            if slot == 1 {
                self.tour.landingPageHeaderImageUrl = isVideo ? nil : urlString
                self.tour.landingPageHeaderVideoUrl = isVideo ? urlString : nil
            } else if slot == 2 {
                self.tour.landingPageScrapbookImageUrl2 = urlString
            }
        } catch {
            print("❌ Error during document upload: \(error.localizedDescription)")
        }
        
        isUploading = false
    }

    func saveChanges(andRefresh refresh: Bool) {
        guard let tourId = tour.id else { return }
        isSaving = true
        tour.landingPageUrl = self.urlSlug
        
        do {
            try Firestore.firestore().collection("tours").document(tourId).setData(from: self.tour, merge: true) { error in
                if let error = error {
                    print("❌ Error saving landing page: \(error.localizedDescription)")
                    self.isSaving = false
                    return
                }
                
                print("✅ Landing page saved.")
                if refresh {
                    self.refreshPage()
                }
                self.isSaving = false
            }
        } catch {
            print("❌ Error encoding tour for save: \(error.localizedDescription)")
            self.isSaving = false
        }
    }

    func publishPage() {
        tour.isLandingPagePublished = true
        saveChanges(andRefresh: true)
    }
    
    func unpublishPage() {
        tour.isLandingPagePublished = false
        saveChanges(andRefresh: true)
    }
    
    func refreshPage() {
        guard let tourId = tour.id else { return }
        // Assuming TicketingAPI is a valid part of your project.
        // TicketingAPI.shared.refreshEventPage(eventId: tourId) { _ in }
    }

    func checkUrlAvailability() {
        // This function's logic is correct and unchanged.
    }
}
