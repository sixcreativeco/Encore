import SwiftUI
import MapKit
import FirebaseFirestore
import Kingfisher
import AppKit

fileprivate struct TicketSale: Identifiable {
    let id = UUID()
    let purchaseId: String?
    let ticketedEventId: String
    let showId: String
    let tourId: String
    let eventDescription: String
    let ticketTypeId: String
    let ticketTypeName: String
    let quantity: Int
    let totalPrice: Double
    let currency: String
    let buyerName: String
    let buyerEmail: String
    let buyerPhone: String
    let purchaseDate: Date
    let ticketNumbers: [String]
    let status: String
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.purchaseId = document.documentID
        self.ticketedEventId = data["ticketedEventId"] as? String ?? ""
        self.showId = data["showId"] as? String ?? ""
        self.tourId = data["tourId"] as? String ?? ""
        self.eventDescription = data["eventDescription"] as? String ?? ""
        self.ticketTypeId = data["ticketTypeId"] as? String ?? ""
        self.ticketTypeName = data["ticketTypeName"] as? String ?? ""
        self.quantity = data["quantity"] as? Int ?? 0
        self.totalPrice = data["totalPrice"] as? Double ?? 0.0
        self.currency = data["currency"] as? String ?? "NZD"
        self.buyerName = data["buyerName"] as? String ?? ""
        self.buyerEmail = data["buyerEmail"] as? String ?? ""
        self.buyerPhone = data["buyerPhone"] as? String ?? ""
        self.status = data["status"] as? String ?? "completed"
        self.ticketNumbers = data["ticketNumbers"] as? [String] ?? []
        
        if let timestamp = data["purchaseDate"] as? Timestamp {
            self.purchaseDate = timestamp.dateValue()
        } else {
            self.purchaseDate = Date()
        }
    }
}

fileprivate struct SummaryStats {
    var orderCount: Int = 0
    var ticketsIssued: Int = 0
    var totalRevenue: Double = 0.0
}


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

    // Ticketing State
    @State private var ticketedEvent: TicketedEvent?
    @State private var ticketSales: [TicketSale] = []
    @State private var ticketSummary = SummaryStats()
    @State private var isPublishingToWeb = false
    @State private var showingPublishAlert = false
    @State private var publishAlertTitle = ""
    @State private var publishAlertMessage = ""
    @State private var publishedURL = ""
    @State private var ticketListeners: [ListenerRegistration] = []


    // Sheet Presentation State
    @State private var showAddGuest = false
    @State private var showEditShow = false
    @State private var showContactDetails = false
    @State private var showLiveSetlist = false

    @EnvironmentObject var appState: AppState

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NZD" // This could be dynamic in the future
        return formatter
    }

    private let progressGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 216/255, green: 122/255, blue: 239/255),
            Color(red: 191/255, green: 93/255, blue: 93/255)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

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
                    showTimingsPanel
                    guestListPanel
                }
                
                if ticketedEvent != nil {
                    ticketSummarySection
                    ticketEventSection
                }
            }
            .padding()
        }
        .onAppear {
            loadAllShowDetails()
        }
        .onDisappear {
            ticketListeners.forEach { $0.remove() }
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
        .alert(publishAlertTitle, isPresented: $showingPublishAlert) {
            if !publishedURL.isEmpty {
                Button("Open Website") { openURL(publishedURL) }
                Button("Copy URL") { copyToClipboard(publishedURL) }
            }
            Button("OK") { }
        } message: {
            Text(publishAlertMessage)
        }
        .navigationTitle("Show Details")
    }

    private var headerSection: some View {
        return VStack(alignment: .leading, spacing: 32) {
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let mapWidth = max(min(800, totalWidth * 0.55), 320)
                let dynamicSpacing = max(12, totalWidth * 0.04)

                HStack(alignment: .top, spacing: dynamicSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            appState.selectedShow = nil
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                            .padding(.vertical, 4).padding(.horizontal, 10)
                            .background(Color.black.opacity(0.15)).cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(show.city.uppercased())
                            .font(.system(size: 55, weight: .bold)).lineLimit(1).minimumScaleFactor(0.5)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 12) {
                            Text(show.venueName)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(show.date.dateValue().formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        if let loadInDate = show.loadIn?.dateValue() {
                            Label {
                                Text("Load In Time: \(loadInDate.formatted(date: .omitted, time: .shortened))")
                                    .font(.system(size: 13, weight: .semibold))
                            } icon: {
                                Image(systemName: "truck")
                                    .font(.system(size: 13))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.black.opacity(0.15)).cornerRadius(6)
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
                            .fontWeight(.semibold).frame(width: 220, height: 44).background(Color.black.opacity(0.15)).cornerRadius(10)
                    }.buttonStyle(.plain)
                    
                    Button(action: { showEditShow = true }) {
                        Label("Edit Show", systemImage: "pencil")
                            .fontWeight(.semibold).frame(width: 220, height: 44).background(Color.black.opacity(0.15)).cornerRadius(10)
                    }.buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, -12)
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
        .background(Color.black.opacity(0.15))
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
        .frame(minHeight: 200).frame(maxWidth: .infinity).padding().background(Color.black.opacity(0.15)).cornerRadius(10)
    }

    // MARK: - Ticket Views
    
    private var ticketSummarySection: some View {
        HStack(spacing: 16) {
            summaryCard(title: "Orders", value: "\(ticketSummary.orderCount)")
            summaryCard(title: "Tickets Issued", value: "\(ticketSummary.ticketsIssued)")
            summaryCard(title: "Total Revenue", value: currencyFormatter.string(from: NSNumber(value: ticketSummary.totalRevenue)) ?? "$0.00")
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.title2).bold()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.15))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var ticketEventSection: some View {
        if let event = ticketedEvent {
            let originalAllocation = event.ticketTypes.reduce(0) { $0 + $1.allocation } + ticketSummary.ticketsIssued
            let ticketsSold = ticketSummary.ticketsIssued

            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 20) {
                    KFImage(URL(string: tour.posterURL ?? ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 180)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(tour.artist) - \(tour.tourName)")
                            .font(.caption).foregroundColor(.secondary)
                        Text(show.city).font(.system(size: 32, weight: .bold))
                        Text("Date: \(show.date.dateValue().formatted(date: .numeric, time: .omitted))")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer().frame(height: 10)
                        Text("Venue: \(show.venueName)").font(.caption).bold()
                        Text(show.venueAddress).font(.caption).foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 12) {
                        let isPublished = event.status == .published
                        ActionButton(
                            title: isPublished ? "Unpublish Tickets" : "Publish Tickets",
                            icon: isPublished ? "eye.slash" : "globe",
                            color: isPublished ? Color(red: 193/255, green: 94/255, blue: 94/255) : Color(red: 94/255, green: 149/255, blue: 73/255),
                            isLoading: isPublishingToWeb && !isPublished,
                            action: {
                                if isPublished {
                                    unpublishTickets(for: event)
                                } else {
                                    publishTicketsToWeb(for: event)
                                }
                            }
                        )
                        .disabled(isPublishingToWeb)
                    }
                    .frame(width: 180)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(height: 12)
                            let progress = originalAllocation > 0 ? Double(ticketsSold) / Double(originalAllocation) : 0.0
                            RoundedRectangle(cornerRadius: 6).fill(progressGradient)
                                .frame(width: geometry.size.width * progress, height: 12)
                                .animation(.easeInOut(duration: 0.8), value: progress)
                        }
                    }
                    .frame(height: 12)
                    Text("\(ticketsSold) of \(originalAllocation) Tickets Sold")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.15))
            .cornerRadius(16)
        }
    }

    // MARK: - Data Loading & Actions

    private func loadAllShowDetails() {
        loadMapForAddress()
        loadGuestList()
        buildTimeline()
        loadTicketDetails()
    }

    private func loadTicketDetails() {
        guard let showId = show.id else { return }
        let db = Firestore.firestore()
        
        let eventListener = db.collection("ticketedEvents").whereField("showId", isEqualTo: showId).limit(to: 1)
            .addSnapshotListener { querySnapshot, error in
                guard let document = querySnapshot?.documents.first else {
                    self.ticketedEvent = nil
                    return
                }
                self.ticketedEvent = try? document.data(as: TicketedEvent.self)
                
                if let eventId = self.ticketedEvent?.id {
                    let salesListener = db.collection("ticketSales").whereField("ticketedEventId", isEqualTo: eventId)
                        .addSnapshotListener { salesSnapshot, salesError in
                            guard let salesDocs = salesSnapshot?.documents else { return }
                            let sales = salesDocs.map { TicketSale(from: $0) }
                            self.ticketSales = sales
                            self.updateTicketSummary()
                            
                        }
                    self.ticketListeners.append(salesListener)
                }
            }
        self.ticketListeners.append(eventListener)
    }
    
    private func updateTicketSummary() {
        let totalTickets = ticketSales.reduce(0) { $0 + $1.quantity }
        let totalRevenue = ticketSales.reduce(0.0) { $0 + $1.totalPrice }
        self.ticketSummary = SummaryStats(orderCount: ticketSales.count, ticketsIssued: totalTickets, totalRevenue: totalRevenue)
    }

    private func buildTimeline() {
        Task {
            guard let showID = show.id else { return }
            let db = Firestore.firestore()
            var events: [ShowTimelineEvent] = []

            let itinerarySnapshot = try? await db.collection("itineraryItems")
                .whereField("showId", isEqualTo: showID)
                .getDocuments()

            let itineraryItems = itinerarySnapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
            
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
        guard let showID = show.id, let tourId = tour.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(tour.ownerId).collection("tours").document(tourId).collection("shows").document(showID).collection("guestlist")
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
    
    // MARK: - Helper Functions
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

    private func updateEventStatus(for event: TicketedEvent, to newStatus: TicketedEvent.Status) {
        guard let eventID = event.id else { return }
        Firestore.firestore().collection("ticketedEvents").document(eventID).updateData(["status": newStatus.rawValue])
    }

    private func publishTicketsToWeb(for event: TicketedEvent) {
        guard let eventID = event.id else {
            showPublishError(message: "Invalid event ID")
            return
        }
        isPublishingToWeb = true
        updateEventStatus(for: event, to: .published)
        TicketingAPI.shared.publishTickets(ticketedEventId: eventID) { result in
            DispatchQueue.main.async {
                self.isPublishingToWeb = false
                switch result {
                case .success(let response):
                    self.showPublishSuccess(url: response.ticketSaleUrl)
                case .failure(let error):
                    self.updateEventStatus(for: event, to: .draft)
                    self.showPublishError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func unpublishTickets(for event: TicketedEvent) {
        updateEventStatus(for: event, to: .unpublished)
    }

    private func showPublishSuccess(url: String) {
        publishedURL = url
        publishAlertTitle = "Tickets Published!"
        publishAlertMessage = "Your ticket sale website is ready and the URL has been copied to your clipboard."
        showingPublishAlert = true
        openURL(url)
    }
    
    private func showPublishError(message: String) {
        publishedURL = ""
        publishAlertTitle = "Publishing Failed"
        publishAlertMessage = "Failed to publish tickets to the web:\n\n\(message)"
        showingPublishAlert = true
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
