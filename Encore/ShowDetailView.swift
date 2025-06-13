import SwiftUI
import MapKit
import FirebaseFirestore

struct ShowDetailView: View {
    let show: ShowModel
    let userID: String
    let tourID: String

    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    @State private var mapItem: MKMapItem?

    @State private var guestList: [GuestListItemModel] = []
    @State private var venueNotes: String = ""
    @State private var showAddGuest = false
    @State private var showEditNotes = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                headerSection

                Divider()

                HStack(alignment: .top, spacing: 16) {
                    showTimingsPanel
                    guestListPanel
                    venueNotesPanel
                }
            }
            .padding()
            .onAppear {
                loadMapForAddress()
                loadGuestList()
                loadVenueNotes()
            }
            .sheet(isPresented: $showAddGuest) {
                AddGuestView(userID: userID, tourID: tourID, showID: show.id) {
                    loadGuestList()
                }
            }
            .sheet(isPresented: $showEditNotes) {
                EditVenueNotesView(userID: userID, tourID: tourID, showID: show.id, notes: venueNotes) {
                    loadVenueNotes()
                }
            }
        }
        .navigationTitle("Show Details")
    }

    // MARK: HEADER SECTION

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 32) {

            // City, Venue, Date block
            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(show.date.formatted(date: .numeric, time: .omitted))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    Text(show.city.uppercased())
                        .font(.system(size: 42, weight: .bold))

                    Text(show.venue)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.gray)

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
                .frame(width: 500, height: 180)
            }

            // Contact Info + Buttons (2x1 layout)
            HStack(alignment: .top, spacing: 40) {

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 18))
                        Text(show.address).font(.system(size: 16))
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "phone").font(.system(size: 18))
                        Text("09 358 1250").font(.system(size: 16))
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "person.fill").font(.system(size: 18))
                        Text("Venue Contact").font(.system(size: 16))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 16) {
                    StyledActionButton(title: "Edit Show", icon: "pencil", color: .blue)
                    StyledActionButton(title: "Upload Documents", icon: "tray.and.arrow.up", color: .green)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: PANELS

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
        .background(Color.gray.opacity(0.10))
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
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
            }

            if guestList.isEmpty {
                Text("No guests yet").foregroundColor(.gray)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(guestList) { guest in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(guest.name).font(.headline)
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
        .background(Color.gray.opacity(0.10))
        .cornerRadius(10)
    }

    private var venueNotesPanel: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Venue Notes").font(.headline)
                Spacer()
                Button(action: { showEditNotes = true }) {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
            }

            if venueNotes.isEmpty {
                Text("No notes").foregroundColor(.gray)
            } else {
                Text(venueNotes).font(.subheadline)
            }
            Spacer()
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.10))
        .cornerRadius(10)
    }

    // MARK: DATA LOADERS

    private func loadGuestList() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID)
            .collection("shows").document(show.id).collection("guestlist")
            .getDocuments { snapshot, _ in
                self.guestList = snapshot?.documents.compactMap { GuestListItemModel(from: $0) } ?? []
            }
    }

    private func loadVenueNotes() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID)
            .collection("shows").document(show.id).getDocument { doc, _ in
                self.venueNotes = doc?.data()?["venueNotes"] as? String ?? ""
            }
    }

    // MARK: MAP

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

// MARK: StyledActionButton component
struct StyledActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button(action: { }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(width: 220, height: 44)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
