import SwiftUI
import Kingfisher

// A new custom button style for this view
struct ActionButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .fontWeight(.semibold)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(color == .white ? .black : .white)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}


struct TicketsDashboardView: View {
    @StateObject private var viewModel = TicketsViewModel()
    @State private var showingAddTicketsSheet = false
    @EnvironmentObject var appState: AppState

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
                    primaryEventView
                    bottomPanels
                }
                .padding(30)
            }
        }
        .sheet(isPresented: $showingAddTicketsSheet) {
            AddTicketsView(onSave: {
                viewModel.fetchData()
            })
        }
        .alert(viewModel.publishAlertTitle, isPresented: $viewModel.showingPublishAlert) {
            if !viewModel.publishedURL.isEmpty {
                Button("Open Website") {
                    viewModel.openPublishedWebsite()
                }
                Button("Copy URL") {
                    viewModel.copyPublishedURL()
                }
            }
            Button("OK") { }
        } message: {
            Text(viewModel.publishAlertMessage)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text("Tickets")
                .font(.system(size: 48, weight: .bold)) // FIX: Bigger Title
            Spacer()
            Button(action: { showingAddTicketsSheet = true }) {
                Image(systemName: "plus")
                    // FIX: Larger, circular plus button
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, -10) // FIX: Reduced padding
    }

    private var summaryView: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // FIX: Replaced Picker with a custom Menu
            Menu {
                ForEach(TicketsViewModel.Timeframe.allCases) { timeframe in
                    Button(timeframe.rawValue) {
                        viewModel.selectedTimeframe = timeframe
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedTimeframe.rawValue)
                    Image(systemName: "chevron.down")
                }
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Material.regular)
                .cornerRadius(8)
            }
            .frame(width: 300) // FIX: Occupy more horizontal space
            .menuStyle(.borderlessButton)
            
            HStack(spacing: 16) {
                summaryCard(title: "Orders", value: "\(viewModel.summaryStats.orderCount)")
                summaryCard(title: "Tickets Issued", value: "\(viewModel.summaryStats.ticketsIssued)")
                summaryCard(title: "Total Revenue", value: currencyFormatter.string(from: NSNumber(value: viewModel.summaryStats.totalRevenue)) ?? "$0.00")
            }
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
    private var primaryEventView: some View {
        if let event = viewModel.primaryEvent,
           let show = viewModel.allShows.first(where: { $0.id == event.showId }) {
            
            let totalAllocation = event.ticketTypes.reduce(0) { $0 + $1.allocation }
            let ticketsSold = getTicketsSoldForEvent(event.id ?? "")
            
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 20) {
                    if let posterURL = viewModel.tour?.posterURL, let url = URL(string: posterURL) {
                        KFImage(url)
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 180).cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.tour?.artist ?? "") - \(viewModel.tour?.tourName ?? "")")
                            .font(.caption).foregroundColor(.secondary)
                        Text(show.city).font(.system(size: 32, weight: .bold))
                        Text("Date: \(show.date.dateValue().formatted(date: .numeric, time: .omitted))")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer().frame(height: 10)
                        Text("Venue: \(show.venueName)").font(.caption)
                        Text(show.venueAddress).font(.caption).foregroundColor(.secondary)
                        if event.status == .published, let eventId = event.id {
                            Link("🎫 View Ticket Sales Page", destination: URL(string: "https://en-co.re/event/\(eventId)")!)
                                .font(.caption).foregroundColor(.blue).padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        // FIX: Replaced with custom button and added navigation action
                        ActionButton(title: "Go To Show", icon: nil, color: .white.opacity(0.1)) {
                            appState.selectedTour = viewModel.tour
                            appState.selectedShow = show
                        }
                        
                        let isPublished = event.status == .published
                        
                        // FIX: Replaced with custom button
                        ActionButton(title: isPublished ? "Unpublish Tickets" : "Publish Tickets",
                                     icon: isPublished ? "xmark.octagon.fill" : "arrow.up.circle.fill",
                                     color: isPublished ? .red : .green) {
                            if isPublished {
                                viewModel.unpublishTickets(for: event)
                            } else {
                                viewModel.publishTicketsToWeb(for: event)
                            }
                        }
                        .disabled(viewModel.isPublishingToWeb)
                    }
                    .frame(width: 180)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: Double(ticketsSold), total: Double(totalAllocation))
                        .tint(.pink)
                    Text("\(ticketsSold) of \(totalAllocation) Tickets Sold")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Material.regular)
            .cornerRadius(16)
        } else {
            Text("No upcoming ticketed events.")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Material.regular)
                .cornerRadius(16)
        }
    }

    private var bottomPanels: some View {
        HStack(alignment: .top, spacing: 24) {
            recentActivityView
            publishedEventsView
        }
    }
    
    private var recentActivityView: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.recentTicketSales.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "clock").font(.title2).foregroundColor(.secondary)
                    Text("No recent ticket sales").font(.subheadline).foregroundColor(.secondary)
                }.frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(Array(viewModel.recentTicketSales.prefix(5).enumerated()), id: \.element.id) { index, sale in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sale.buyerEmail).font(.subheadline).lineLimit(1)
                            Text(getCityNameForSale(sale)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currencyFormatter.string(from: NSNumber(value: sale.totalPrice)) ?? "$0.00").font(.subheadline).bold()
                            Text(sale.purchaseDate.formatted(.dateTime.hour().minute())).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if index < viewModel.recentTicketSales.prefix(5).count - 1 {
                        Divider().padding(.vertical, 4)
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Material.regular)
        .cornerRadius(16)
    }

    private var publishedEventsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Published Events").font(.headline)
                Spacer()
                Button(action: {}) { Image(systemName: "plus").font(.caption) }.buttonStyle(.plain)
            }
            
            if viewModel.publishedEvents.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "ticket").font(.title2).foregroundColor(.secondary)
                    Text("No published events").font(.subheadline).foregroundColor(.secondary)
                }.frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.publishedEvents) { event in
                            if let show = viewModel.allShows.first(where: { $0.id == event.showId }) {
                                VStack {
                                    KFImage(URL(string: viewModel.tour?.posterURL ?? ""))
                                        .resizable().aspectRatio(2/3, contentMode: .fit)
                                        .frame(width: 100).cornerRadius(6)
                                    Text(show.city).font(.caption).bold().lineLimit(1)
                                    Text(show.date.dateValue().formatted(.dateTime.month().day())).font(.caption2).foregroundColor(.secondary)
                                }
                                .frame(width: 100)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(Material.regular)
        .cornerRadius(16)
    }

    // MARK: - Helper Functions

    private func getCityNameForSale(_ sale: TicketsViewModel.TicketSale) -> String {
        guard let event = viewModel.allTicketedEvents.first(where: { $0.id == sale.ticketedEventId }),
              let show = viewModel.allShows.first(where: { $0.id == event.showId })
        else { return "Unknown Show" }
        return show.city
    }
    
    private func getTicketsSoldForEvent(_ eventId: String) -> Int {
        return viewModel.allTicketSales.filter { $0.ticketedEventId == eventId }.reduce(0) { $0 + $1.quantity }
    }
    
    private func getPublishButtonText(isPublished: Bool) -> String {
        if viewModel.isPublishingToWeb && !isPublished {
            return "Publishing..."
        }
        return isPublished ? "Unpublish Tickets" : "Publish Tickets"
    }
}
