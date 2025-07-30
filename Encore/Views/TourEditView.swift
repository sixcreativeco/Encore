import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AppKit
import UniformTypeIdentifiers

struct TourEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    @State private var editableTour: Tour
    
    // State for UI controls
    @State private var startDate: Date
    @State private var endDate: Date

    // State for poster image handling
    @State private var posterImage: NSImage? = nil
    @State private var posterFileURL: URL? = nil
    @State private var isSaving = false
    @State private var isLoadingImage = false

    init(tour: Tour) {
        _editableTour = State(initialValue: tour)
        // Initialize local Date state from the tour's Timestamps
        _startDate = State(initialValue: tour.startDate.dateValue())
        _endDate = State(initialValue: tour.endDate.dateValue())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit Tour").font(.system(size: 28, weight: .bold))
                    
                    CustomTextField(placeholder: "Tour Name", text: $editableTour.tourName)
                    CustomTextField(placeholder: "Artist Name", text: $editableTour.artist)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Date").font(.subheadline).foregroundColor(.gray)
                            // Bind directly to the local Date state
                            CustomDateField(date: $startDate)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Date").font(.subheadline).foregroundColor(.gray)
                            // Bind directly to the local Date state
                            CustomDateField(date: $endDate)
                        }
                    }
                }

                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.clear).frame(width: 220, height: 280)
                        if let img = posterImage {
                            Image(nsImage: img).resizable().scaledToFill().frame(width: 220, height: 280).clipped().cornerRadius(10)
                        } else if isLoadingImage {
                            ProgressView().frame(width: 220, height: 280)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled").font(.system(size: 28)).foregroundColor(.gray)
                                Text("Upload Tour Poster").foregroundColor(.gray).font(.subheadline)
                            }
                        }
                    }
                    .onTapGesture { selectPoster() }
                }
                .padding(.top, 20)
            }

            Button(action: { Task { await saveEdits() } }) {
                Text(isSaving ? "Saving..." : "Save Changes")
                    .fontWeight(.semibold).frame(maxWidth: .infinity).frame(height: 48)
                    .background(Color.white).foregroundColor(.black).cornerRadius(8)
            }
            .disabled(editableTour.tourName.isEmpty || editableTour.artist.isEmpty || isSaving)

            HStack(spacing: 16) {
                Button(action: { /* cancel logic */ }) {
                    Text("Cancel Tour").font(.subheadline).foregroundColor(.orange).frame(maxWidth: .infinity)
                }.buttonStyle(PlainButtonStyle()).background(Color.clear)

                Button(action: { Task { await deleteTour() } }) {
                    Text("Delete Tour").font(.subheadline).foregroundColor(.red).frame(maxWidth: .infinity)
                }.buttonStyle(PlainButtonStyle()).background(Color.clear)
            }
            Spacer()
        }
        .padding(30)
        .frame(minWidth: 750, minHeight: 720)
        .onAppear {
            Task { await loadPosterAsync() }
        }
    }

    private func loadPosterAsync() async {
        guard let urlStr = editableTour.posterURL, let url = URL(string: urlStr) else { return }
        isLoadingImage = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = NSImage(data: data) { self.posterImage = img }
        } catch { print("Failed to load image async: \(error)") }
        isLoadingImage = false
    }

    private func selectPoster() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            posterImage = img
            posterFileURL = url
        }
    }

    private func saveEdits() async {
        isSaving = true
        
        // Update the tour object's timestamps from our local Date state before saving
        editableTour.startDate = Timestamp(date: startDate)
        editableTour.endDate = Timestamp(date: endDate)
        
        if let fileURL = posterFileURL {
            do {
                let storageRef = Storage.storage().reference().child("posters/\(UUID().uuidString).jpg")
                _ = try await storageRef.putFileAsync(from: fileURL, metadata: nil)
                let downloadURL = try await storageRef.downloadURL()
                editableTour.posterURL = downloadURL.absoluteString
            } catch { print("❌ Error uploading poster: \(error.localizedDescription)") }
        }
        
        do {
            guard let tourID = editableTour.id else { throw URLError(.badServerResponse) }
            try Firestore.firestore().collection("tours").document(tourID).setData(from: editableTour, merge: true)
        } catch {
            print("❌ Error saving edits: \(error.localizedDescription)")
        }

        isSaving = false
        presentationMode.wrappedValue.dismiss()
    }

    private func deleteTour() async {
        guard let tourID = editableTour.id else { return }
        
        do {
            try await Firestore.firestore().collection("tours").document(tourID).delete()
            DispatchQueue.main.async {
                appState.removeTour(tourID: tourID)
                appState.selectedTour = nil
                presentationMode.wrappedValue.dismiss()
            }
        } catch { print("❌ Error deleting tour: \(error.localizedDescription)") }
    }
}
