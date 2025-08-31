import SwiftUI
import Kingfisher
import FirebaseAuth

struct TicketsDashboardView: View {
    @StateObject private var viewModel: TicketsViewModel
    @EnvironmentObject var appState: AppState

    @State private var showingSelectTourSheet = false
    @State private var tourToConfigure: Tour?
    @State private var showingPayoutSheet = false
    @State private var selectedEventForDisplay: TicketedEvent?
    @State private var isHoveringMainEvent: Bool = false
    @State private var eventToManage: TicketedEvent?
    @State private var showAllLiveEvents = false
    @State private var selectedTourFilterID: String? = nil

    private var eventToDisplay: TicketedEvent? {
        selectedEventForDisplay ?? viewModel.primaryEvent
    }

    init() {
        _viewModel = StateObject(wrappedValue: TicketsViewModel(userID: Auth.auth().currentUser?.uid))
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NZD"
        return formatter
    }

    var body: some View {
        ScrollView {
             if viewModel.isLoading {
                ProgressView("Loading Ticket Data...")
                    .frame(maxWidth: .infinity, minHeight: 500)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                     headerView
                    summaryView
                    stripeBalanceView
                    mainEventDisplayView
                    liveEventsGrid
                    recentActivityView
                }
                .padding(30)
            }
        }
        .sheet(isPresented: $showingSelectTourSheet) {
            SelectTourForTicketingView { selectedTour in
                self.tourToConfigure = selectedTour
            }
        }
        .sheet(item: $tourToConfigure) { tour in
            ConfigureTicketsView(tour: tour)
        }
        .sheet(item: $eventToManage) { event in
            if let tour = viewModel.getTour(for: event.tourId), let show = viewModel.allShows.first(where: { $0.id == event.showId }) {
                ConfigureTicketsView(tour: tour, show: show)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            if !viewModel.publishedURL.isEmpty {
                 Button("Open Website") { viewModel.openPublishedWebsite() }
                Button("Copy URL") { viewModel.copyPublishedURL() }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
         .sheet(isPresented: $showingPayoutSheet) {
            StripePayoutRequestView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchData()
        }
        .refreshable {
            await viewModel.fetchData()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text("Tickets")
                .font(.system(size: 48, weight: .bold))
            Spacer()
            Button(action: { showingSelectTourSheet = true }) {
                Image(systemName: "plus")
                     .font(.title3.weight(.medium))
                    .foregroundColor(.black)
            }
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.white))
            .buttonStyle(.plain)
        }
    }
    
    private var summaryView: some View {
        HStack(spacing: 16) {
            summaryCard(title: "Orders", value: "\(viewModel.summaryStats.orderCount)")
            summaryCard(title: "Tickets Issued", value: "\(viewModel.summaryStats.ticketsIssued)")
            summaryCard(title: "Total Revenue", value: currencyFormatter.string(from: NSNumber(value: viewModel.summaryStats.totalRevenue)) ?? "$0.00")
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

    @ViewBuilder
    private var mainEventDisplayView: some View {
        if let event = eventToDisplay,
           let show = viewModel.allShows.first(where: { $0.id == event.showId }),
           let tour = viewModel.getTour(for: event.tourId) {
            
            MainEventCardView(
                viewModel: viewModel,
                event: event,
                show: show,
                tour: tour,
                isHovering: $isHoveringMainEvent,
                onManageTickets: { self.eventToManage = event },
                onGoToShow: { goToShow(show) },
                onCycle: { forward in cycleShow(forward: forward) }
            )
            .onHover { hovering in isHoveringMainEvent = hovering }

        } else {
            noEventsPlaceholder
        }
    }
    
    private var noEventsPlaceholder: some View {
        VStack(spacing: 8) {
            Text("No Ticketed Events")
                .font(.headline)
            Text("Once you configure tickets for a show, your next upcoming event will be featured here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Material.regular)
        .cornerRadius(16)
    }

    private var liveEventsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                tourFilterDropdown
                Spacer()
                if filteredShows.count > 6 {
                    Button(showAllLiveEvents ? "Show Less" : "Show All") {
                        withAnimation(.easeInOut) {
                            showAllLiveEvents.toggle()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                }
            }
            
            let showsToDisplay = showAllLiveEvents ? filteredShows : Array(filteredShows.prefix(6))

            if showsToDisplay.isEmpty {
                Text(selectedTourFilterID == nil ? "No shows found for your tours." : "No shows found for this tour.")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                    ForEach(showsToDisplay) { show in
                        LiveEventGridItemView(
                            viewModel: viewModel,
                            show: show,
                            onSelect: { event in
                                withAnimation { selectedEventForDisplay = event }
                            },
                            onManage: {
                                if let tour = viewModel.getTour(for: show.tourId) {
                                    let newEvent = TicketedEvent(ownerId: tour.ownerId, tourId: show.tourId, showId: show.id ?? "", status: .draft, ticketTypes: [])
                                    self.eventToManage = newEvent
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var filteredShows: [Show] {
        let allSortedShows = viewModel.allShows.sorted { $0.date.dateValue() < $1.date.dateValue() }
        if let tourID = selectedTourFilterID {
            return allSortedShows.filter { $0.tourId == tourID }
        }
        return allSortedShows
    }
    
    private var tourFilterDropdown: some View {
        Menu {
            Button("All Shows") {
                selectedTourFilterID = nil
            }
            Divider()
            ForEach(viewModel.allUserTours) { tour in
                Button(tour.tourName) {
                    selectedTourFilterID = tour.id
                }
            }
        } label: {
            HStack {
                Text(viewModel.allUserTours.first(where: { $0.id == selectedTourFilterID })?.tourName ?? "All Shows")
                    .font(.title2.bold())
                Image(systemName: "chevron.down")
                    .font(.body)
            }
            .foregroundColor(.primary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var recentActivityView: some View {
        VStack(alignment: .leading) {
             Text("Recent Activity").font(.headline)
            
            if viewModel.recentTicketSales.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock").font(.title2)
                    Text("No recent ticket sales").font(.subheadline)
                 }
                 .foregroundColor(.secondary)
                 .frame(maxWidth: .infinity, minHeight: 100)
                 .padding()
                 .background(Material.regular)
                 .cornerRadius(16)
            } else {
                VStack {
                    ForEach(Array(viewModel.recentTicketSales.prefix(5).enumerated()), id: \.element.id) { index, sale in
                        HStack {
                             VStack(alignment: .leading, spacing: 2) {
                                Text(sale.buyerEmail).font(.subheadline).lineLimit(1)
                                Text("\(getTourAndCityForSale(sale)) • \(sale.quantity) ticket\(sale.quantity > 1 ? "s" : "")").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                 Text(currencyFormatter.string(from: NSNumber(value: sale.totalPrice)) ?? "$0.00").font(.subheadline).bold()
                                Text(sale.purchaseDate.formatted(.relative(presentation: .named))).font(.caption).foregroundColor(.secondary)
                            }
                         }
                        if index < viewModel.recentTicketSales.prefix(5).count - 1 { Divider().padding(.vertical, 4) }
                    }
                }
                .padding()
                .background(Material.regular)
                .cornerRadius(16)
            }
        }
    }

    private var stripeBalanceView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            balanceCard(
                title: "Pending Balance",
                amount: viewModel.stripePendingBalance,
                currency: viewModel.stripeCurrency,
                icon: "clock",
                iconColor: .orange
            )
            
            balanceCard(
                title: "Available Balance",
                amount: viewModel.stripeBalance,
                currency: viewModel.stripeCurrency,
                icon: "creditcard",
                iconColor: .green
            ) {
                if viewModel.hasStripeAccount {
                     Button("Request Payout") {
                        showingPayoutSheet = true
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .white, textColor: .black))
                    .disabled(viewModel.stripeBalance <= 0)
                 } else {
                    Button("Setup Stripe Account") {
                        viewModel.setupStripeAccount()
                    }
                     .buttonStyle(PrimaryButtonStyle(color: .blue))
                }
            }
        }
    }
    
    @ViewBuilder
    private func balanceCard<Footer: View>(title: String, amount: Double, currency: String, icon: String, iconColor: Color, @ViewBuilder footer: () -> Footer = { EmptyView() }) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom) {
                Text("\(currency) \(String(format: "%.2f", amount))")
                    .font(.title.bold())
                    .foregroundColor(amount > 0 ? iconColor : .primary)
                Spacer()
                footer()
            }
        }
        .padding(16)
        // --- THIS IS THE FIX ---
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(Material.regular)
        .cornerRadius(12)
    }

    private func cycleShow(forward: Bool) {
        let upcoming = viewModel.upcomingEvents
        guard !upcoming.isEmpty else { return }
        
        let currentEvent = eventToDisplay ?? upcoming.first!
        guard let currentIndex = upcoming.firstIndex(of: currentEvent) else { return }
        
        let newIndex: Int
        if forward {
            newIndex = (currentIndex + 1) % upcoming.count
        } else {
            newIndex = (currentIndex - 1 + upcoming.count) % upcoming.count
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedEventForDisplay = upcoming[newIndex]
        }
    }

    private func getTourAndCityForSale(_ sale: TicketSale) -> String {
        guard let show = viewModel.allShows.first(where: { $0.id == sale.showId }) else { return "Unknown Show" }
        let tourName = viewModel.getTour(for: show.tourId)?.tourName ?? "Tour"
        return "\(tourName) - \(show.city)"
    }
    
    private func getOriginalAllocation(for event: TicketedEvent) -> Int {
        let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")
        let currentAllocation = event.ticketTypes.reduce(0) { $0 + $1.allocation }
        return ticketsSold + currentAllocation
    }
    
    private func goToShow(_ show: Show) {
        if let tour = viewModel.getTour(for: show.tourId) {
            appState.selectedTour = tour
            appState.selectedShow = show
        }
    }
}

// MARK: - Grid Item View

fileprivate struct LiveEventGridItemView: View {
    @ObservedObject var viewModel: TicketsViewModel
    let show: Show
    let onSelect: (TicketedEvent) -> Void
    let onManage: () -> Void
    
    var body: some View {
        let event = viewModel.eventMap[show.id ?? ""]
        
        Button(action: {
            if let validEvent = event {
                onSelect(validEvent)
            } else {
                onManage()
            }
        }) {
            EventSummaryCard(
                viewModel: viewModel,
                show: show,
                event: event
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - MainEventCardView

fileprivate struct MainEventCardView: View {
    @ObservedObject var viewModel: TicketsViewModel
    let event: TicketedEvent
    let show: Show
    let tour: Tour
    @Binding var isHovering: Bool
    
    let onManageTickets: () -> Void
    let onGoToShow: () -> Void
    let onCycle: (Bool) -> Void

    @State private var animatedTicketsSold: Double = 0.0

    private var ticketsSold: Int { viewModel.getTicketsSoldForEvent(event.id ?? "") }
    private var compsIssued: Int { viewModel.getCompTicketsIssued(for: event.id ?? "") }
    private var originalAllocation: Int {
        let sold = viewModel.getTicketsSoldForEvent(event.id ?? "")
        let allocation = event.ticketTypes.reduce(0) { $0 + $1.allocation }
        return sold + allocation
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack(alignment: .top, spacing: 20) {
                    if let posterURL = tour.posterURL, let url = URL(string: posterURL) {
                         KFImage(url)
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 180).cornerRadius(8)
                    }

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
                }
                
                if viewModel.upcomingEvents.count > 1 {
                    HStack {
                        cycleButton(icon: "chevron.left") { onCycle(false) }
                        Spacer()
                        cycleButton(icon: "chevron.right") { onCycle(true) }
                    }
                    .opacity(isHovering ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                }
            }
            .overlay(alignment: .topTrailing) {
                topRightButtons()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                GradientProgressView(value: animatedTicketsSold, total: Double(originalAllocation > 0 ? originalAllocation : 1))
                
                HStack {
                    Text("\(ticketsSold) of \(originalAllocation) Tickets Sold")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    if compsIssued > 0 {
                        Text("\(compsIssued) Comps Issued")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                animatedTicketsSold = 0
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedTicketsSold = Double(ticketsSold)
                }
            }
            .onChange(of: ticketsSold) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedTicketsSold = Double(ticketsSold)
                }
            }
        }
        .padding(20).background(Material.regular).cornerRadius(16)
    }

    private func topRightButtons() -> some View {
        VStack(alignment: .trailing, spacing: 12) {
            Button(action: onGoToShow) {
                 HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text("Go To Show")
                 }
                .frame(width: 150)
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button(action: onManageTickets) {
                HStack(spacing: 8) {
                    Image(systemName: "ticket")
                    Text("Manage Tickets")
                }
                .frame(width: 150)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func cycleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
                .padding()
                .background(.thinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .shadow(radius: 5)
    }
}


// MARK: - EventSummaryCard

fileprivate struct EventSummaryCard: View {
    @ObservedObject var viewModel: TicketsViewModel
    let show: Show
    let event: TicketedEvent?

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NZD"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(show.city).font(.headline.bold()).lineLimit(1)
                    Text(show.venueName).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                
                let status = event?.status ?? .draft
                Text(status.rawValue.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(statusColor(for: status).opacity(0.2))
                    .foregroundColor(statusColor(for: status))
                    .cornerRadius(6)
            }

            Spacer(minLength: 0)

            if let event = event {
                let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")
                let totalAllocation = (event.ticketTypes.reduce(0) { $0 + $1.allocation }) + ticketsSold
                let revenue = viewModel.getRevenueForEvent(event.id ?? "")

                VStack(alignment: .leading, spacing: 4) {
                    GradientProgressView(value: Double(ticketsSold), total: Double(totalAllocation > 0 ? totalAllocation : 1))
                    Text("\(ticketsSold) of \(totalAllocation) sold")
                        .font(.caption).foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Revenue:")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text(currencyFormatter.string(from: NSNumber(value: revenue)) ?? "$0.00")
                        .font(.subheadline).bold()
                    Spacer()
                }
            } else {
                Text("No tickets configured for this show.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minHeight: 120)
        .background(Material.regular)
        .cornerRadius(12)
    }

    private func statusColor(for status: TicketedEvent.Status) -> Color {
        switch status {
        case .published: return .green
        case .scheduled: return .orange
        case .draft, .unpublished: return .gray
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}
