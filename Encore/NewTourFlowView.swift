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
    @State private var isPickingPoster = false
    @State private var posterFileURL: URL? = nil
    @State private var newTourID: String? = nil
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
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 240)
                                    .clipped()
                                    .cornerRadius(10)
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
                    .padding(.top, 40)
                }

                Divider()

                if let tourID = newTourID, let userID = appState.userID {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Shows").font(.headline)
                        ShowGridView(tourID: tourID, userID: userID, artistName: tourName)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    func selectPoster() {
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

    func saveTour() async {
        guard let userID = appState.userID else { return }
        isSaving = true
        let db = Firestore.firestore()

        var tourData: [String: Any] = [
            "tourName": tourName,
            "artist": artistName,
            "startDate": startDate,
            "endDate": endDate,
            "tourScope": tourScope,
            "createdAt": Date()
        ]

        do {
            var posterURL: String? = nil
            if let fileURL = posterFileURL {
                let storageRef = Storage.storage().reference().child("posters/\(UUID().uuidString).jpg")
                let _ = try await storageRef.putFileAsync(from: fileURL, metadata: nil)
                let downloadURL = try await storageRef.downloadURL()
                posterURL = downloadURL.absoluteString
                tourData["posterURL"] = posterURL
            }

            let ref = try await db.collection("users").document(userID).collection("tours").addDocument(data: tourData)
            newTourID = ref.documentID

        } catch {
            print("❌ Error saving tour: \(error.localizedDescription)")
        }

        isSaving = false
    }
}
