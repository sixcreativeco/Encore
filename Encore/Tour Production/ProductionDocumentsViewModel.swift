import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ProductionDocumentsViewModel: ObservableObject {
    let tour: Tour
    @Published var documents: [ProductionDocument] = []
    @Published var isLoading = true
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init(tour: Tour) {
        self.tour = tour
        setupListener()
    }
    
    deinit {
        listener?.remove()
    }

    private func setupListener() {
        guard let tourId = tour.id else {
            self.isLoading = false
            return
        }
        listener = db.collection("productionDocuments")
            .whereField("tourId", isEqualTo: tourId)
            .order(by: "uploadedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching production documents: \(error?.localizedDescription ?? "Unknown")")
                    self.isLoading = false
                    return
                }
                self.documents = documents.compactMap { try? $0.data(as: ProductionDocument.self) }
                self.isLoading = false
            }
    }

    func uploadDocument(fileURL: URL, documentName: String, documentType: String) async {
        guard let tourId = tour.id else { return }
        let ownerId = tour.ownerId
        
        isUploading = true
        uploadProgress = 0.0
        
        do {
            let storageRef = storage.reference().child("production_documents/\(tourId)/\(UUID().uuidString)_\(fileURL.lastPathComponent)")
            
            let uploadTask = storageRef.putFile(from: fileURL, metadata: nil)
            
            // Set up the progress observer
            let observer = uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    DispatchQueue.main.async {
                        self.uploadProgress = progress.fractionCompleted
                    }
                }
            }
            
            // Await the completion of the upload
            _ = try await uploadTask
            
            // The observer is tied to the task and is cleaned up automatically.
            // The line causing the error is now correctly removed.
            
            let downloadURL = try await storageRef.downloadURL()
            
            let newDocument = ProductionDocument(
                tourId: tourId,
                ownerId: ownerId,
                name: documentName,
                type: documentType,
                fileURL: downloadURL.absoluteString,
                fileType: fileURL.pathExtension.lowercased()
            )
            
            try db.collection("productionDocuments").addDocument(from: newDocument)
            
        } catch {
            print("Error during document upload: \(error.localizedDescription)")
        }
        
        isUploading = false
    }

    func deleteDocument(_ document: ProductionDocument) async {
        guard let docId = document.id else { return }
        
        do {
            // Delete file from Storage first
            let storageRef = storage.reference(forURL: document.fileURL)
            try await storageRef.delete()
            
            // Then delete Firestore record
            try await db.collection("productionDocuments").document(docId).delete()
        } catch {
            print("Error deleting document: \(error.localizedDescription)")
        }
    }
}
