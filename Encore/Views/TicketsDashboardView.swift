import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import AppKit

struct TicketsDashboardView: View {
    @StateObject private var viewModel: TicketsViewModel
    @State private var showingAddTicketsSheet = false
    @State private var selectedShow: Show?
    @State private var showingShowDetail = false
    @EnvironmentObject var appState: AppState

    init() {
        _viewModel = StateObject(wrappedValue: TicketsViewModel(userID: Auth.auth().currentUser?.uid))
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NZD"
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
        .sheet(isPresented: $showingShowDetail) {
            if let show = selectedShow, let tour = viewModel.tour {
                ShowDetailView(tour: tour, show: show)
            }
        }
        .alert(viewModel.publishAlertTitle, isPresented: $viewModel.showingPublishAlert) {
            if !viewModel.publishedURL.isEmpty {
                Button("Open Website") { viewModel.openPublishedWebsite() }
                Button("Copy URL") { viewModel.copyPublishedURL() }
            }
            Button("OK") { }
        } message: {
            Text(viewModel.publishAlertMessage)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Tickets")
                .font(.system(size: 40, weight: .bold))
            Spacer()
            Button(action: { showingAddTicketsSheet = true }) {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(width: 40, height: 40)
            .background(Color.black.opacity(0.15))
            .clipShape(Circle())
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
        .background(Color.black.opacity(0.15))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var primaryEventView: some View {
        if let event = viewModel.primaryEvent,
           let show = viewModel.allShows.first(where: { $0.id == event.showId }) {

            let originalAllocation = getOriginalAllocation(for: event)
            let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")

            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 20) {
                    if let posterURL = viewModel.tour?.posterURL, let url = URL(string: posterURL) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 180)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.tour?.artist ?? "") - \(viewModel.tour?.tourName ?? "")")
                            .font(.caption).foregroundColor(.secondary)
                        Text(show.city).font(.system(size: 32, weight: .bold))
                        Text("Date: \(show.date.dateValue().formatted(date: .numeric, time: .omitted))")
                            .font(.subheadline).foregroundColor(.secondary)

                        Spacer().frame(height: 10)

                        Text("Venue: \(show.venueName)").font(.caption).bold()
                        Text(show.venueAddress).font(.caption).foregroundColor(.secondary)

                        if event.status == .published, let eventId = event.id {
                            Button(action: {
                                if let url = URL(string: "https://en-co.re/event/\(eventId)") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "ticket")
                                    Text("View Ticket Page")
                                }
                                .font(.caption.bold())
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 12) {
                        let isPublished = event.status == .published

                        ActionButton(title: "Go To Show", icon: "arrow.right.square", color: Color.white.opacity(0.15), textColor: .white) {
                            if let tour = viewModel.tour {
                                self.selectedShow = show
                                self.showingShowDetail = true
                            }
                        }
                        
                        ActionButton(
                            title: getPublishButtonText(isPublished: isPublished),
                            icon: isPublished ? "eye.slash" : "globe",
                            color: isPublished ? Color(red: 193/255, green: 94/255, blue: 94/255) : Color(red: 94/255, green: 149/255, blue: 73/255),
                            isLoading: viewModel.isPublishingToWeb && !isPublished
                        ) {
                            if isPublished {
                                viewModel.unpublishTickets(for: event)
                            } else {
                                viewModel.publishTicketsToWeb(for: event)
                            }
                        }
                        .disabled(viewModel.isPublishingToWeb)
                        .opacity(viewModel.isPublishingToWeb ? 0.7 : 1.0)
                    }
                    .frame(width: 180)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)

                            let progress = originalAllocation > 0 ? Double(ticketsSold) / Double(originalAllocation) : 0.0

                            RoundedRectangle(cornerRadius: 6)
                                .fill(progressGradient)
                                .frame(width: geometry.size.width * progress, height: 12)
                                .animation(.easeInOut(duration: 0.8), value: progress)
                        }
                    }
                    .frame(height: 12)

                    Text("\(ticketsSold) of \(originalAllocation) Tickets Sold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.15))
            .cornerRadius(16)
        } else {
            Text("No upcoming ticketed events.")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Color.black.opacity(0.15))
                .cornerRadius(16)
        }
    }

    private var bottomPanels: some View {
        HStack(alignment: .top, spacing: 24) {
            recentActivityView
            eventsView
        }
    }

    private var recentActivityView: some View {
        VStack {
            Text("Recent Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.recentTicketSales.isEmpty {
                VStack {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No recent ticket sales")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(Array(viewModel.recentTicketSales.prefix(5).enumerated()), id: \.element.id) { index, sale in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sale.buyerEmail)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                let ticketWord = sale.quantity == 1 ? "ticket" : "tickets"
                                let quantityText = "\(sale.quantity) \(ticketWord)"
                                let tourAndCity = getTourAndCityForSale(sale)

                                Text(tourAndCity + " • " + quantityText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currencyFormatter.string(from: NSNumber(value: sale.totalPrice)) ?? "$0.00")
                                    .font(.subheadline)
                                    .bold()
                                Text(sale.purchaseDate.formatted(.dateTime.hour().minute()))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if index < viewModel.recentTicketSales.prefix(5).count - 1 {
                        Divider()
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.15))
        .cornerRadius(16)
    }

    private var eventsView: some View {
        VStack {
            HStack {
                Text("Events").font(.headline)
                Spacer()
                Button(action: { showingAddTicketsSheet = true }) {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            let sortedEvents = viewModel.allTicketedEvents.sorted { event1, event2 in
                guard let show1 = viewModel.allShows.first(where: { $0.id == event1.showId }),
                      let show2 = viewModel.allShows.first(where: { $0.id == event2.showId }) else {
                    return false
                }
                return show1.date.dateValue() < show2.date.dateValue()
            }

            if sortedEvents.isEmpty {
                VStack {
                    Image(systemName: "ticket")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No ticketed events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sortedEvents) { event in
                            if let show = viewModel.allShows.first(where: { $0.id == event.showId }),
                               let tour = viewModel.userTours.first(where: { $0.id == show.tourId }) {
                                Button(action: {
                                    viewModel.setPrimaryEvent(to: event)
                                }) {
                                    VStack {
                                        ZStack(alignment: .bottomTrailing) {
                                            KFImage(URL(string: tour.posterURL ?? ""))
                                                .resizable()
                                                .aspectRatio(2/3, contentMode: .fit)
                                                .frame(width: 100)
                                                .cornerRadius(6)
                                            
                                            if event.status == .published {
                                                Image(systemName: "globe")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(4)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                                    .padding(4)
                                            }
                                        }
                                        Text(show.city)
                                            .font(.caption)
                                            .bold()
                                            .lineLimit(1)
                                        Text(show.date.dateValue().formatted(.dateTime.month().day()))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 100)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.15))
        .cornerRadius(16)
    }

    private func getTourAndCityForSale(_ sale: TicketsViewModel.TicketSale) -> String {
        guard let event = viewModel.allTicketedEvents.first(where: { $0.id == sale.ticketedEventId }),
              let show = viewModel.allShows.first(where: { $0.id == event.showId }),
              let tour = viewModel.userTours.first(where: { $0.id == show.tourId }) else {
            return "Unknown Show"
        }
        
        return "\(tour.tourName) - \(show.city)"
    }
    
    private func getOriginalAllocation(for event: TicketedEvent) -> Int {
        let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")
        let currentAllocation = event.ticketTypes.reduce(0) { $0 + $1.allocation }
        return ticketsSold + currentAllocation
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
