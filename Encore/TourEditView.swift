import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AppKit
import UniformTypeIdentifiers

struct TourEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    var tour: TourModel

    @State private var tourName: String
    @State private var artistName: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tourScope: String
    @State private var posterImage: NSImage? = nil
    @State private var isPickingPoster = false
    @State private var posterFileURL: URL? = nil
    @State private var isSaving = false
    @State private var isLoadingImage = false

    init(tour: TourModel) {
        self.tour = tour
        _tourName = State(initialValue: tour.name)
        _artistName = State(initialValue: tour.artist)
        _startDate = State(initialValue: tour.startDate)
        _endDate = State(initialValue: tour.endDate)
        _tourScope = State(initialValue: "national")
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
                    CustomTextField(placeholder: "Tour Name", text: $tourName)
                    CustomTextField(placeholder: "Artist Name", text: $artistName)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Date").font(.subheadline).foregroundColor(.gray)
                            CustomDateField(date: $startDate)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Date").font(.subheadline).foregroundColor(.gray)
                            CustomDateField(date: $endDate)
                        }
                    }
                    Text("Including Travel/Extra Days").font(.footnote).foregroundColor(.gray)
                    Picker("", selection: $tourScope) {
                        Text("National").tag("national")
                        Text("International").tag("international")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(height: 44)
                }

                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                            .frame(width: 220, height: 280)
                        if let img = posterImage {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 220, height: 280)
                                .clipped()
                                .cornerRadius(10)
                        } else if isLoadingImage {
                            ProgressView().frame(width: 220, height: 280)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray)
                                Text("Upload Tour Poster")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .onTapGesture { selectPoster() }
                }
                .padding(.top, 20)
            }

            Button(action: { Task { await saveEdits() } }) {
                Text(isSaving ? "Saving..." : "Save Changes")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .disabled(tourName.isEmpty || artistName.isEmpty || isSaving)

            HStack(spacing: 16) {
                Button(action: { Task { await cancelTour() } }) {
                    Text("Cancel Tour")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.clear)

                Button(action: { Task { await deleteTour() } }) {
                    Text("Delete Tour")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.clear)
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
        guard let urlStr = tour.posterURL, let url = URL(string: urlStr) else { return }
        isLoadingImage = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = NSImage(data: data) {
                self.posterImage = img
            }
        } catch {
            print("Failed to load image async: \(error)")
        }
        isLoadingImage = false
    }

    private func selectPoster() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            if let url = panel.url, let img = NSImage(contentsOf: url) {
                posterImage = img
                posterFileURL = url
            }
        }
    }

    private func saveEdits() async {
        guard let userID = appState.userID else { return }
        isSaving = true
        let db = Firestore.firestore()

        var tourData: [String: Any] = [
            "tourName": tourName,
            "artist": artistName,
            "startDate": startDate,
            "endDate": endDate,
            "tourScope": tourScope,
            "createdAt": tour.createdAt
        ]

        do {
            if let fileURL = posterFileURL {
                let storageRef = Storage.storage().reference().child("posters/\(UUID().uuidString).jpg")
                let _ = try await storageRef.putFileAsync(from: fileURL, metadata: nil)
                let downloadURL = try await storageRef.downloadURL()
                tourData["posterURL"] = downloadURL.absoluteString
            }

            try await db.collection("users").document(userID).collection("tours").document(tour.id).setData(tourData, merge: true)
        } catch {
            print("❌ Error saving edits: \(error.localizedDescription)")
        }

        isSaving = false
        presentationMode.wrappedValue.dismiss()
    }

    private func deleteTour() async {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(userID).collection("tours").document(tour.id).delete()
            DispatchQueue.main.async {
                appState.removeTour(tourID: tour.id)
                appState.selectedTour = nil
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            print("❌ Error deleting tour: \(error.localizedDescription)")
        }
    }

    private func cancelTour() async {
        // placeholder cancel logic
    }
}
