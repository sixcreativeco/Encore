import SwiftUI
import MapKit
import FirebaseFirestore

struct ShowDetailView: View {
    let tour: Tour
    @State var show: Show

    // Map State
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    @State private var mapItem: MKMapItem?
    
    // Guest List State
    @State private var guestList: [GuestListItemModel] = []
    
    // Timeline State
    @State private var timelineEvents: [ShowTimelineEvent] = []

    // Sheet Presentation State
    @State private var showAddGuest = false
    @State private var showEditShow = false
    @State private var showContactDetails = false
    @State private var showLiveSetlist = false // State for the new sheet

    @EnvironmentObject var appState: AppState

    // A local struct to hold all timeline events for sorting
    struct ShowTimelineEvent: Identifiable, Comparable {
        let id = UUID()
        var time: Date
        var label: String

        static func < (lhs: ShowTimelineEvent, rhs: ShowTimelineEvent) -> Bool {
            lhs.time < rhs.time
        }
    }

    init(tour: Tour, show: Show) {
        self.tour = tour
        self._show = State(initialValue: show)
    }

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    headerSection
                    Divider()
                    
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            showTimingsPanel
                            // ADDED: The guest list panel is now in the left column
                            guestListPanel
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        
                        // The right column can now be used for other details
                        VStack(alignment: .leading, spacing: 16) {
                            // The old SetlistView is removed.
                            // This space is now available.
                            Spacer()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .onAppear {
                loadAllShowDetails()
            }
            .sheet(isPresented: $showAddGuest) {
                AddGuestView(userID: tour.ownerId, tourID: tour.id ?? "", showID: show.id ?? "") {
                    loadGuestList()
                }
            }
            .sheet(isPresented: $showEditShow) {
                ShowEditView(tour: tour, show: $show)
            }
            .sheet(isPresented: $showLiveSetlist) {
                LiveSetlistView(tour: tour, show: show)
            }
            .navigationTitle("Show Details")
        }

    private var headerSection: some View {
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
                                .font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                                .padding(.vertical, 4).padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.2)).cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer().frame(height: spacingDateToCity)
                        Text(show.date.dateValue().formatted(date: .numeric, time: .omitted))
                            .font(.system(size: 16)).foregroundColor(.gray)
                        Spacer().frame(height: spacingDateToCity)
                        Text(show.city.uppercased())
                            .font(.system(size: 55, weight: .bold)).lineLimit(1).minimumScaleFactor(0.5)
                        Spacer().frame(height: spacingCityToVenue)
                        Text(show.venueName)
                            .font(.system(size: 22, weight: .medium)).foregroundColor(.gray)
                        Spacer().frame(height: spacingVenueToLoadIn)
                        if let loadInDate = show.loadIn?.dateValue() {
                            Label {
                                Text("Load In Time: \(loadInDate.formatted(date: .omitted, time: .shortened))")
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.black)
                            } icon: {
                                Image(systemName: "truck")
                                    .font(.system(size: 13)).foregroundColor(.black)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15)).cornerRadius(6)
                        }
                    }
                    Spacer()
                    Map(coordinateRegion: $mapRegion, annotationItems: annotationItems()) { item in
                        MapMarker(coordinate: item.coordinate, tint: .red)
                    }
                    .cornerRadius(12).frame(width: mapWidth, height: 180)
                }
            }
            .frame(height: 200)

            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 18))
                        Button(action: openInMaps) {
                            Text(show.venueAddress).font(.system(size: 16))
                        }.buttonStyle(PlainButtonStyle())
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
                VStack(alignment: .trailing, spacing: 10) {
                     Button(action: { showLiveSetlist = true }) {
                        Label("Open Live Setlist", systemImage: "play.display")
                            .fontWeight(.semibold).frame(width: 220, height: 44).background(Color.accentColor.opacity(0.2)).foregroundColor(.accentColor).cornerRadius(10)
                    }.buttonStyle(.plain)
                    
                    Button(action: { showEditShow = true }) {
                        Label("Edit Show", systemImage: "pencil")
                            .fontWeight(.semibold).frame(width: 220, height: 44).background(Color.blue.opacity(0.15)).foregroundColor(.blue).cornerRadius(10)
                    }.buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -12)
        }
    }

    private func openInMaps() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = show.venueAddress
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
            }.padding(.bottom, 4)

            if timelineEvents.isEmpty {
                Text("No timings scheduled.")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(timelineEvents) { event in
                        timingRow(event.label, event.time)
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

    private func timingRow(_ label: String, _ time: Date?) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            if let time = time { Text(time.formatted(date: .omitted, time: .shortened)) }
            else { Text("-") }
        }
    }
    
    private var guestListPanel: some View {
        VStack(alignment: .leading) {
            HStack { Text("Guest List").font(.headline); Spacer(); Button(action: { showAddGuest = true }) { Image(systemName: "plus.circle.fill").font(.title3) }.buttonStyle(.plain) }
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
        .frame(minHeight: 200).frame(maxWidth: .infinity).padding().background(Color(nsColor: .controlBackgroundColor)).cornerRadius(10)
    }

    // MARK: - Data Loading

    private func loadAllShowDetails() {
        loadMapForAddress()
        loadGuestList()
        buildTimeline()
    }

    private func buildTimeline() {
        Task {
            guard let showID = show.id else { return }
            let db = Firestore.firestore()
            var events: [ShowTimelineEvent] = []

            let itinerarySnapshot = try? await db.collection("itineraryItems")
                .whereField("showId", isEqualTo: showID)
                .getDocuments()

            let itineraryItems = itinerarySnapshot?.documents.compactMap {
                try? $0.data(as: ItineraryItem.self)
            } ?? []
            
            for item in itineraryItems {
                events.append(ShowTimelineEvent(time: item.timeUTC.dateValue(), label: item.title))
            }

            if let time = show.venueAccess?.dateValue(), !events.contains(where: { $0.label == "Venue Access" }) {
                events.append(ShowTimelineEvent(time: time, label: "Venue Access"))
            }

            events.sort()

            await MainActor.run {
                self.timelineEvents = events
            }
        }
    }

    private func loadGuestList() {
        guard let showID = show.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(tour.ownerId).collection("tours").document(tour.id ?? "").collection("shows").document(showID).collection("guestlist")
            .getDocuments { snapshot, _ in
                self.guestList = snapshot?.documents.compactMap { GuestListItemModel(from: $0) } ?? []
            }
    }
    
    private func loadMapForAddress() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = show.venueAddress
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else { return }
            self.mapItem = mapItem
            self.mapRegion = MKCoordinateRegion(center: mapItem.placemark.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
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
