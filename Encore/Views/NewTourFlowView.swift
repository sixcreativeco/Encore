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
    @State private var posterImage: NSImage? = nil
    @State private var posterFileURL: URL? = nil
    
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
                                Text("Start Date").font(.subheadline).foregroundColor(.secondary)
                                CustomDateField(date: $startDate)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("End Date").font(.subheadline).foregroundColor(.secondary)
                                CustomDateField(date: $endDate)
                            }
                        }
                        Text("Including Travel/Extra Days").font(.footnote).foregroundColor(.secondary)
                        
                        if newTour == nil {
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
                            .padding(.top, 8)
                        }
                    }

                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.15))
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

                if let tour = newTour {
                    // Pass the entire Tour object instead of just the ID
                    AddCrewSectionView(tour: tour)
                    Divider()
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Shows").font(.headline)
                        ShowGridView(
                            tourID: tour.id ?? "",
                            ownerUserID: tour.ownerId,
                            artistName: tour.artist,
                            onShowSelected: { selectedShow in
                                appState.selectedShow = selectedShow
                            }
                        )
                        Spacer()
                    }
                }
            }
            .padding(30)
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
            
            // Add the new tour to the global state so other views are aware of it
            appState.tours.append(newTourData)
            
            self.newTour = newTourData
        } catch {
            print("❌ Error saving tour: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
}
