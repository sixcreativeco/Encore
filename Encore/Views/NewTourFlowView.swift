import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AppKit
import UniformTypeIdentifiers

struct NewTourFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var tourName: String = ""
    @State private var artistName: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var tourScope: String = "national"
    @State private var posterImage: NSImage? = nil
    @State private var posterFileURL: URL? = nil
    
    // This now holds the complete new Tour object once saved
    @State private var newTour: Tour? = nil
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .top, spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Create New Tour").font(.system(size: 24, weight: .bold))
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
                        Button(action: { Task { await saveTour() } }) {
                            Text(isSaving ? "Saving..." : "Continue")
                                .fontWeight(.semibold)
                                .frame(width: 200, height: 44)
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.white)
                        .cornerRadius(8)
                        .disabled(tourName.isEmpty || artistName.isEmpty || isSaving)
                    }

                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.05))
                                .frame(width: 200, height: 240)
                            if let img = posterImage {
                                Image(nsImage: img)
                                    .resizable().scaledToFill().frame(width: 200, height: 240)
                                    .clipped().cornerRadius(10)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 28)).foregroundColor(.gray)
                                    Text("Upload Tour Poster")
                                        .foregroundColor(.gray).font(.subheadline)
                                }
                            }
                        }
                        .onTapGesture { selectPoster() }
                    }
                    .padding(.top, 40)
                }

                // FIX: These 'if let' statements now correctly check for the 'newTour' state object.
                if let tour = newTour, let tourID = tour.id {
                    AddCrewSectionView(tourID: tourID)
                    Divider()
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Shows").font(.headline)
                        ShowGridView(
                            tourID: tourID,
                            ownerUserID: tour.ownerId,
                            artistName: tour.artist,
                            onShowSelected: { selectedShow in
                                appState.selectedShow = selectedShow
                            }
                        )
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }
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

    private func saveTour() async {
        guard let userID = appState.userID else { return }
        isSaving = true
        
        var posterURLString: String? = nil
        if let fileURL = posterFileURL {
            do {
                let storageRef = Storage.storage().reference().child("posters/\(UUID().uuidString).jpg")
                _ = try await storageRef.putFileAsync(from: fileURL, metadata: nil)
                let downloadURL = try await storageRef.downloadURL()
                posterURLString = downloadURL.absoluteString
            } catch {
                print("❌ Error uploading poster: \(error.localizedDescription)")
            }
        }
        
        var newTourData = Tour(
            ownerId: userID,
            tourName: tourName,
            artist: artistName,
            startDate: Timestamp(date: startDate),
            endDate: Timestamp(date: endDate),
            posterURL: posterURLString
        )

        do {
            let ref = try Firestore.firestore().collection("tours").addDocument(from: newTourData)
            newTourData.id = ref.documentID
            // This sets the state object that unhides the rest of the view
            self.newTour = newTourData
        } catch {
            print("❌ Error saving tour: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
}
