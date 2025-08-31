import SwiftUI
import FirebaseFirestore

fileprivate enum TourDetailTab: String, CaseIterable, Identifiable {
    case schedule = "Schedule"
    case tickets = "Tickets"
    case production = "Production"
    var id: String { self.rawValue }
}

struct TourDetailView: View {
    let tourID: String
    
    @EnvironmentObject var appState: AppState
    
    @State private var tour: Tour?
    @State private var listener: ListenerRegistration?
    @State private var selectedTab: TourDetailTab = .schedule
    
    @State private var showToConfigureTicketsFor: Show? = nil
    
    @Namespace private var animation

    var body: some View {
        Group {
            if let tour = tour {
                VStack(alignment: .leading, spacing: 0) {
                    TourHeaderView(tour: tour)
                        .padding(.horizontal, 24)
                        .padding(.top)

                    TourSummaryCardsView(tourID: tour.id ?? "", ownerUserID: tour.ownerId)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    
                    // Tab Picker
                    HStack(spacing: 28) {
                        ForEach(TourDetailTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.easeInOut) { selectedTab = tab }
                            }) {
                                HStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                                    
                                    if tab == .production {
                                        Text("Coming Soon")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.secondary)
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.bottom, 12)
                                .overlay(alignment: .bottom) {
                                    if selectedTab == tab {
                                        Rectangle()
                                            .frame(height: 3)
                                            .foregroundColor(.accentColor)
                                            .matchedGeometryEffect(id: "underline", in: animation)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(tab == .production)
                            .opacity(tab == .production ? 0.5 : 1.0)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    Divider().padding(.horizontal, 24).padding(.top, -1)
                    
                    // Tab Content
                    VStack {
                        switch selectedTab {
                        case .schedule:
                            ScheduleTabView(tour: tour)
                                .transition(.opacity)
                        case .tickets:
                            TicketsTabView(tour: tour, showToConfigureTicketsFor: $showToConfigureTicketsFor)
                                .transition(.opacity)
                        case .production:
                            ProductionTabView(tour: tour)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
                .ignoresSafeArea(edges: .bottom)
                .sheet(item: $showToConfigureTicketsFor) { show in
                    ConfigureTicketsView(tour: tour, show: show)
                }

            } else {
                ProgressView("Loading Tour...")
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: setupListener)
        .onDisappear(perform: {
            listener?.remove()
        })
    }

    private func setupListener() {
        listener?.remove()
        
        let db = Firestore.firestore()
        listener = db.collection("tours").document(tourID)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching tour document: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    self.tour = try document.data(as: Tour.self)
                 } catch {
                    print("Error decoding tour: \(error.localizedDescription)")
                    self.tour = nil
                }
            }
    }
}

// MARK: - Tab Content Subviews

fileprivate struct ScheduleTabView: View {
    let tour: Tour
    @EnvironmentObject var appState: AppState
    @State private var isShowingCrewEditView = false
    
    @State private var isSelectionModeActive = false
    @State private var selectedShowIDs = Set<String>()
    @State private var showBulkEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .top, spacing: 24) {
                    TourItineraryView(tour: tour)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Crew") { isShowingCrewEditView = true }
                                Button(action: { isShowingCrewEditView = true }) {
                                    TourCrewView(tourID: tour.id ?? "", ownerUserID: tour.ownerId)
                                }.buttonStyle(.plain)
                            }
                            TourFlightsView(tour: tour)
                            TourHotelsView(tourID: tour.id ?? "")
                        }
                    }
                    .frame(width: 380)
                }
                .frame(minHeight: 500)

                if let tourID = tour.id {
                    showsSection(tour: tour, tourID: tourID)
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $isShowingCrewEditView) {
            CrewEditView(tour: tour)
        }
        .sheet(isPresented: $showBulkEditView) {
            BulkTicketEditView(tour: tour, selectedShowIDs: selectedShowIDs) {}
        }
    }
    
    private func showsSection(tour: Tour, tourID: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shows").font(.headline)
                Spacer()
                Button(isSelectionModeActive ? "Done" : "Select") {
                    withAnimation {
                        isSelectionModeActive.toggle()
                        selectedShowIDs.removeAll()
                    }
                }
                .buttonStyle(.plain)
            }
            
            if !selectedShowIDs.isEmpty {
                Button(action: { showBulkEditView = true }) {
                    Text("Bulk Edit Tickets for \(selectedShowIDs.count) Shows")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            
            ShowGridView(
                tourID: tourID,
                ownerUserID: tour.ownerId,
                artistName: tour.artist,
                onShowSelected: { selectedShow in
                    appState.selectedShow = selectedShow
                },
                isSelectionModeActive: $isSelectionModeActive,
                selectedShowIDs: $selectedShowIDs
            )
        }
    }
}

fileprivate struct TicketsTabView: View {
    let tour: Tour
    @Binding var showToConfigureTicketsFor: Show?
    
    @State private var ticketedEvents: [TicketedEvent] = []
    @State private var allShows: [Show] = []
    // --- THIS IS THE FIX ---
    @State private var allSales: [TicketSale] = []
    @State private var isLoading = true
    
    private var totalRevenue: Double {
        allSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    private var totalTicketsSold: Int {
        allSales.reduce(0) { $0 + $1.quantity }
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NZD"
        return formatter
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if ticketedEvents.isEmpty {
                Text("No tickets have been configured for this tour yet.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 16) {
                        summaryCard(title: "Total Revenue", value: currencyFormatter.string(from: NSNumber(value: totalRevenue)) ?? "$0.00")
                        summaryCard(title: "Total Tickets Sold", value: "\(totalTicketsSold)")
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Events").font(.headline)
                        ForEach(ticketedEvents) { event in
                            if let show = allShows.first(where: { $0.id == event.showId }) {
                                showTicketSummaryRow(event: event, show: show)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .task {
            await loadTicketData()
        }
    }
    
    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.title2).bold()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.regular)
        .cornerRadius(12)
    }
    
    private func showTicketSummaryRow(event: TicketedEvent, show: Show) -> some View {
        let salesForEvent = allSales.filter { $0.ticketedEventId == event.id }
        let ticketsSold = salesForEvent.reduce(0) { $0 + $1.quantity }
        let totalAllocation = event.ticketTypes.reduce(0) { $0 + $1.allocation } + ticketsSold
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(show.city).font(.headline.bold())
                    Text(show.venueName).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Button("Manage") {
                    showToConfigureTicketsFor = show
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            ProgressView(value: Double(ticketsSold), total: Double(totalAllocation > 0 ? totalAllocation : 1))
            Text("\(ticketsSold) of \(totalAllocation) tickets sold")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Material.regular.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func loadTicketData() async {
        guard let tourId = tour.id else {
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        do {
            let eventsSnapshot = try await db.collection("ticketedEvents").whereField("tourId", isEqualTo: tourId).getDocuments()
            self.ticketedEvents = eventsSnapshot.documents.compactMap { try? $0.data(as: TicketedEvent.self) }
            
            let showIDs = self.ticketedEvents.map { $0.showId }
            if !showIDs.isEmpty {
                let showsSnapshot = try await db.collection("shows").whereField(FieldPath.documentID(), in: showIDs).getDocuments()
                self.allShows = showsSnapshot.documents.compactMap { try? $0.data(as: Show.self) }
            }
            
            let salesSnapshot = try await db.collection("ticketSales").whereField("tourId", isEqualTo: tourId).getDocuments()
            // --- THIS IS THE FIX ---
            self.allSales = salesSnapshot.documents.map { TicketSale(from: $0) }
            
            self.isLoading = false
        } catch {
            print("Error loading ticketing data for tour: \(error)")
            self.isLoading = false
        }
    }
}

fileprivate struct ProductionTabView: View {
    let tour: Tour
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.and.arrow.backward")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Production")
                .font(.title2.bold())
            Text("Advanced production features are coming soon.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
