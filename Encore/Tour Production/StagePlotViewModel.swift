import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class StagePlotViewModel: ObservableObject {
    @Binding var tour: Tour
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init(tour: Binding<Tour>) {
        self._tour = tour
    }

    func uploadStagePlot(fileURL: URL) async {
        guard let tourId = tour.id else { return }
        
        isUploading = true
        uploadProgress = 0.0
        
        do {
            let storageRef = storage.reference().child("stage_plots/\(tourId)/\(UUID().uuidString)")
            
            let uploadTask = storageRef.putFile(from: fileURL, metadata: nil)
            
            let observer = uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    self.uploadProgress = progress.fractionCompleted
                }
            }
            
            _ = try await uploadTask
            
            // The observer is automatically cleaned up when the task completes.
            // The line causing the error has been removed.
            
            let downloadURL = try await storageRef.downloadURL()
            
            let newURL = downloadURL.absoluteString
            try await db.collection("tours").document(tourId).updateData(["stagePlotImageURL": newURL])
            
            self.tour.stagePlotImageURL = newURL
            
        } catch {
            print("Error uploading stage plot: \(error.localizedDescription)")
        }
        
        isUploading = false
    }

    func deleteStagePlot() async {
        guard let tourId = tour.id, let urlString = tour.stagePlotImageURL else { return }
        
        do {
            let storageRef = storage.reference(forURL: urlString)
            try await storageRef.delete()
            
            try await db.collection("tours").document(tourId).updateData(["stagePlotImageURL": FieldValue.delete()])
            
            self.tour.stagePlotImageURL = nil
        } catch {
            print("Error deleting stage plot: \(error.localizedDescription)")
        }
    }
}
