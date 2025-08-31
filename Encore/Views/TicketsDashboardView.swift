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
    @State private var isHoveringMainEvent: Bool = false // New state for hover effect

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
                    publishedEventsGrid
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
           let show = viewModel.allShows.first(where: { $0.id == event.showId }) {
            
            let originalAllocation = getOriginalAllocation(for: event)
            let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")
            let tourForEvent = viewModel.getTour(for: event.tourId)
            
            VStack(spacing: 16) {
                // --- Major changes to this ZStack for layout and cycling buttons ---
                ZStack(alignment: .leading) { // Align content to leading
                    HStack(alignment: .top, spacing: 20) {
                        if let posterURL = tourForEvent?.posterURL, let url = URL(string: posterURL) {
                             KFImage(url)
                                .resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 180).cornerRadius(8)
                        }

                         VStack(alignment: .leading, spacing: 4) {
                            Text("\(tourForEvent?.artist ?? "") - \(tourForEvent?.tourName ?? "")")
                                .font(.caption).foregroundColor(.secondary)
                             Text(show.city).font(.system(size: 32, weight: .bold))
                            Text("Date: \(show.date.dateValue().formatted(date: .numeric, time: .omitted))")
                                .font(.subheadline).foregroundColor(.secondary)
                            Spacer().frame(height: 10)
                            Text("Venue: \(show.venueName)").font(.caption).bold()
                            Text(show.venueAddress).font(.caption).foregroundColor(.secondary)
                             
                            if event.status == .published, let eventId = event.id {
                                VStack(alignment: .leading, spacing: 2) {
                                     Text("TICKET LINK")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                     HStack {
                                        let urlString = "https://en-co.re/event/\(eventId)"
                                        Link("View Page", destination: URL(string: urlString)!)
                                             .font(.caption)
                                            .foregroundColor(.blue)
                                         Button(action: {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(urlString, forType: .string)
                                         }) { Image(systemName: "doc.on.doc") }.buttonStyle(.plain)
                                    }
                                }.padding(.top, 8)
                            }
                        }
                         Spacer()
                    }
                    
                    // Cycling Buttons now overlaying, with visibility on hover
                    if !viewModel.upcomingEvents.isEmpty && viewModel.upcomingEvents.count > 1 {
                        HStack {
                            cycleButton(icon: "chevron.left") { cycleShow(forward: false) }
                            Spacer()
                            cycleButton(icon: "chevron.right") { cycleShow(forward: true) }
                        }
                        .padding(.horizontal, 8) // Adjust padding to fit within the card visually
                        .opacity(isHoveringMainEvent ? 1 : 0) // Visible only on hover
                        .animation(.easeInOut(duration: 0.2), value: isHoveringMainEvent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure buttons span the ZStack
                    }
                }
                .onHover { hovering in
                    isHoveringMainEvent = hovering
                }
                .overlay(alignment: .topTrailing) {
                    topRightButtons(for: event, show: show)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    GradientProgressView(value: Double(ticketsSold), total: Double(originalAllocation))
                    Text("\(ticketsSold) of \(originalAllocation) Tickets Sold")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Material.regular)
            .cornerRadius(16)
        } else {
            noEventsPlaceholder
        }
    }
    
    private var noEventsPlaceholder: some View {
        Text("No upcoming ticketed events to feature.")
            .font(.headline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Material.regular)
            .cornerRadius(16)
    }

    private func topRightButtons(for event: TicketedEvent, show: Show) -> some View {
        VStack(alignment: .trailing, spacing: 12) {
            Button(action: { goToShow(show) }) {
                 HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text("Go To Show")
                 }
                .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(SecondaryButtonStyle())
            
            let isPublished = event.status == .published
            Button(action: {
                if isPublished { viewModel.unpublishTickets(for: event) }
                else { viewModel.publishTicketsToWeb(for: event) }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isPublishingToWeb && !isPublished {
                         ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                    } else {
                        Image(systemName: isPublished ? "eye.slash" : "globe").font(.system(size: 14, weight: .medium))
                    }
                    Text(getPublishButtonText(isPublished: isPublished))
                }
                 .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            }
            .buttonStyle(PrimaryButtonStyle(color: isPublished ? Color.red : Color.green))
            .disabled(viewModel.isPublishingToWeb)
            .opacity(viewModel.isPublishingToWeb ? 0.7 : 1.0)
            
            if event.status == .published, let scanCode = show.scanCode {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("SCAN CODE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                     Text(scanCode)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                 }
                .padding(.top, 8)
            }
        }
    }

    private func cycleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.light))
                .foregroundColor(.secondary)
                .padding()
                .background(Circle().fill(Color.clear)) // Make background clear for hit testing
                .contentShape(Circle()) // Define tappable area
        }
        .buttonStyle(.plain)
    }

    private var publishedEventsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Events")
                .font(.title2.bold())

            if viewModel.publishedEvents.isEmpty {
                Text("No other events are currently on sale.")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.publishedEvents) { event in
                        Button(action: {
                            withAnimation { selectedEventForDisplay = event }
                        }) {
                            EventSummaryCard(viewModel: viewModel, event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recentActivityView: some View {
        VStack(alignment: .leading) {
             Text("Recent Activity").font(.headline)
            
            if viewModel.recentTicketSales.isEmpty {
                VStack {
                    Image(systemName: "clock").font(.title2).foregroundColor(.secondary)
                    Text("No recent ticket sales").font(.subheadline).foregroundColor(.secondary)
                 }.frame(maxWidth: .infinity, minHeight: 100)
                 .padding()
                 .background(Material.regular)
                 .cornerRadius(16)
            } else {
                VStack {
                    ForEach(Array(viewModel.recentTicketSales.prefix(5).enumerated()), id: \.element.id) { index, sale in
                        VStack(alignment: .leading, spacing: 4) {
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
                        }.padding(.vertical, 8)
                        if index < viewModel.recentTicketSales.prefix(5).count - 1 { Divider() }
                    }
                }
                .padding()
                .background(Material.regular)
                .cornerRadius(16)
            }
        }
    }

    private var stripeBalanceView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stripe Balance & Payouts")
                    .font(.title2.bold())
                Spacer()
                
                if viewModel.hasStripeAccount {
                     Button("Request Payout") {
                        showingPayoutSheet = true
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .green))
                    .disabled(viewModel.stripeBalance <= 0)
                 } else {
                    Button("Setup Stripe Account") {
                        viewModel.setupStripeAccount()
                    }
                     .buttonStyle(PrimaryButtonStyle(color: .blue))
                }
            }
            
            HStack(spacing: 16) {
                summaryCard(title: "Available Balance", value: "\(viewModel.stripeCurrency) \(String(format: "%.2f", viewModel.stripeBalance))")
                summaryCard(title: "Pending Balance", value: "\(viewModel.stripeCurrency) \(String(format: "%.2f", viewModel.stripePendingBalance))")
            }
        }
    }

    // MARK: - Helper Functions & Logic

    private func cycleShow(forward: Bool) {
        let upcoming = viewModel.upcomingEvents
        guard !upcoming.isEmpty else { return }
        
        // Use eventToDisplay to determine the current event for cycling
        let currentEvent = selectedEventForDisplay ?? viewModel.primaryEvent! // Fallback to primary if none selected
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
    
    private func getPublishButtonText(isPublished: Bool) -> String {
        if viewModel.isPublishingToWeb && !isPublished {
            return "Publishing..."
        }
        return isPublished ? "Unpublish Tickets" : "Publish Tickets"
    }
    
    private func goToShow(_ show: Show) {
        if let tour = viewModel.tour {
            appState.selectedTour = tour
            appState.selectedShow = show
        }
    }
}

// MARK: - EventSummaryCard

fileprivate struct EventSummaryCard: View {
    @ObservedObject var viewModel: TicketsViewModel
    let event: TicketedEvent

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NZD"
        return formatter
    }

    var body: some View {
        // --- Revised layout for EventSummaryCard ---
        VStack(alignment: .leading, spacing: 12) {
            if let show = viewModel.allShows.first(where: { $0.id == event.showId }) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(show.city).font(.headline.bold()).lineLimit(1)
                        Text(show.venueName).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    }
                    Spacer() // Pushes the status badge to the right
                    Text(event.status.rawValue.uppercased())
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(statusColor(for: event.status).opacity(0.2))
                        .foregroundColor(statusColor(for: event.status))
                        .cornerRadius(6)
                }

                let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")
                let totalAllocation = (event.ticketTypes.reduce(0) { $0 + $1.allocation }) + ticketsSold
                
                VStack(alignment: .leading, spacing: 4) {
                    GradientProgressView(value: Double(ticketsSold), total: Double(totalAllocation > 0 ? totalAllocation : 1))
                    Text("\(ticketsSold) of \(totalAllocation) sold")
                        .font(.caption).foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Revenue:")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text(currencyFormatter.string(from: NSNumber(value: viewModel.getRevenueForEvent(event.id ?? ""))) ?? "$0.00")
                        .font(.subheadline).bold()
                    Spacer()
                }
            } else {
                Text("Event details not available").foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure it fills its grid cell
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
