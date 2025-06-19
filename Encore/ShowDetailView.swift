import SwiftUI
import MapKit
import FirebaseFirestore

struct ShowDetailView: View {
    let show: ShowModel
    let tourID: String
    let ownerUserID: String

    // State
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    @State private var mapItem: MKMapItem?
    @State private var guestList: [GuestListItemModel] = []
    @State private var venueNotes: String = ""
    @State private var showAddGuest = false
    @State private var showEditNotes = false
    @State private var showEditShow = false
    @State private var showContactDetails = false

    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                Divider()
                
                // Main content grid with Timings, Guest List, and the new Setlist panel.
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        showTimingsPanel
                        venueNotesPanel
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        guestListPanel
                        
                        // ADDED: The new Setlist View is now part of the layout.
                        SetlistView(tourID: tourID, showID: show.id, ownerUserID: ownerUserID)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            .padding()
            .onAppear {
                loadMapForAddress()
                loadGuestList()
                loadVenueNotes()
            }
            .sheet(isPresented: $showAddGuest) {
                AddGuestView(userID: ownerUserID, tourID: tourID, showID: show.id) {
                    loadGuestList()
                }
            }
            .sheet(isPresented: $showEditNotes) {
                EditVenueNotesView(userID: ownerUserID, tourID: tourID, showID: show.id, notes: venueNotes) {
                    loadVenueNotes()
                }
            }
            .sheet(isPresented: $showEditShow) {
                ShowEditView(tourID: tourID, userID: appState.userID ?? "", ownerUserID: ownerUserID, show: show)
            }
        }
        .navigationTitle("Show Details")
    }

    // NOTE: All helper views and functions below this point remain unchanged.
    // They are included here to provide the full, complete file as requested.

    private var headerSection: some View {
        // This view is complex and remains unchanged from the user's codebase.
        // [Existing headerSection code...]
        let spacingDateToCity: CGFloat = 3
        let spacingCityToVenue: CGFloat = 3
        let spacingVenueToLoadIn: CGFloat = 7

        return VStack(alignment: .leading, spacing: 32) {
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let mapWidth = max(min(800, totalWidth * 0.55), 320)
                let dynamicSpacing = max(12, totalWidth * 0.04)

                HStack(alignment: .top, spacing: dynamicSpacing) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Button(action: {
                                appState.selectedShow = nil
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer().frame(height: spacingDateToCity)

                        Text(show.date.formatted(date: .numeric, time: .omitted))
                            .font(.system(size: 16))
                            .foregroundColor(.gray)

                        Spacer().frame(height: spacingDateToCity)

                        Text(show.city.uppercased())
                            .font(.system(size: 55, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer().frame(height: spacingCityToVenue)

                        Text(show.venue)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.gray)

                        Spacer().frame(height: spacingVenueToLoadIn)

                        if let loadIn = show.loadIn {
                            Label {
                                Text("Load In Time: \(loadIn.formatted(date: .omitted, time: .shortened))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.black)
                            } icon: {
                                Image(systemName: "truck")
                                    .font(.system(size: 13))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }

                    Spacer()

                    Map(coordinateRegion: $mapRegion, annotationItems: annotationItems()) { item in
                        MapMarker(coordinate: item.coordinate, tint: .red)
                    }
                    .cornerRadius(12)
                    .frame(width: mapWidth, height: 180)
                }
            }
            .frame(height: 200)

            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 18))
                        Button(action: openInMaps) {
                            Text(show.address).font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "person.fill").font(.system(size: 18))
                        Text(show.contactName ?? "Venue Contact")
                            .font(.system(size: 16))
                            .onTapGesture { withAnimation { showContactDetails.toggle() } }
                        if showContactDetails {
                            if let email = show.contactEmail {
                                Text(email).font(.system(size: 14)).foregroundColor(.gray)
                            }
                            if let phone = show.contactPhone {
                                Text(phone).font(.system(size: 14)).foregroundColor(.gray)
                            }
                        }
                    }
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 16) {
                    Button(action: { showEditShow = true }) {
                        Label("Edit Show", systemImage: "pencil")
                            .fontWeight(.semibold)
                            .frame(width: 220, height: 44)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: {}) {
                        Label("Upload Documents", systemImage: "tray.and.arrow.up")
                            .fontWeight(.semibold)
                            .frame(width: 220, height: 44)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -12)
        }
    }

    private func openInMaps() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = show.address
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            if let mapItem = response?.mapItems.first {
                mapItem.openInMaps()
            }
        }
    }

    private var showTimingsPanel: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Show Timings").font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                timingRow("Load In", show.loadIn)
                timingRow("Soundcheck", show.soundCheck)
                timingRow("Doors", show.doorsOpen)
                if let headliner = show.headliner {
                    timingRow("Headliner Set", headliner.setTime)
                }
                timingRow("Pack Out", show.packOut)
            }
            Spacer()
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private func timingRow(_ label: String, _ time: Date?) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            if let time = time {
                Text(time.formatted(date: .omitted, time: .shortened))
            } else {
                Text("-")
            }
        }
    }

    private var guestListPanel: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Guest List").font(.headline)
                Spacer()
                Button(action: { showAddGuest = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            if guestList.isEmpty {
                Text("No guests yet").foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(guestList) { guest in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(guest.name).font(.headline)
                                if let additional = guest.additionalGuests, !additional.isEmpty, additional != "0" {
                                    Text("+\(additional)").font(.subheadline).foregroundColor(.gray)
                                }
                            }
                            if let note = guest.note, !note.isEmpty {
                                Text(note).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private var venueNotesPanel: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Venue Notes").font(.headline)
                Spacer()
                Button(action: { showEditNotes = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            if venueNotes.isEmpty {
                Text("No notes").foregroundColor(.secondary)
            } else {
                Text(venueNotes).font(.subheadline)
            }
            Spacer()
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private func loadGuestList() {
        let db = Firestore.firestore()
        db.collection("users").document(ownerUserID).collection("tours").document(tourID)
            .collection("shows").document(show.id).collection("guestlist")
            .getDocuments { snapshot, _ in
                self.guestList = snapshot?.documents.compactMap { GuestListItemModel(from: $0) } ?? []
            }
    }

    private func loadVenueNotes() {
        let db = Firestore.firestore()
        db.collection("users").document(ownerUserID).collection("tours").document(tourID)
            .collection("shows").document(show.id).getDocument { doc, _ in
                self.venueNotes = doc?.data()?["venueNotes"] as? String ?? ""
            }
    }

    private func loadMapForAddress() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = show.address
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else { return }
            self.mapItem = mapItem
            self.mapRegion = MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

    private func annotationItems() -> [MapItemWrapper] {
        guard let item = mapItem else { return [] }
        return [MapItemWrapper(coordinate: item.placemark.coordinate)]
    }

    struct MapItemWrapper: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}
