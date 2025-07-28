import SwiftUI
import Kingfisher
import FirebaseAuth

struct TicketsDashboardView: View {
    @StateObject private var viewModel: TicketsViewModel
    @State private var showingAddTicketsSheet = false
    @EnvironmentObject var appState: AppState
    @State private var showingPayoutSheet = false

    // FIX: Removed state variables for the old sheet-based navigation
    // @State private var selectedShow: Show?
    // @State private var showingShowDetail = false

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
                    primaryEventView
                    bottomPanels
                }
                .padding(30)
            }
        }
        .sheet(isPresented: $showingAddTicketsSheet) {
            AddTicketsView(onSave: {
                Task { await viewModel.fetchData() }
            })
        }
        // FIX: Removed the old .sheet modifier for ShowDetailView
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
                Button(action: { showingAddTicketsSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.blue))
                .buttonStyle(.plain)
            }
        }

        private var summaryView: some View {
            HStack(spacing: 16) {
                summaryCard(title: "Orders", value: "\(viewModel.summaryStats.orderCount)")
                summaryCard(title: "Tickets Issued", value: "\(viewModel.summaryStats.ticketsIssued)")
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
                let originalAllocation = getOriginalAllocation(for: event)
                let ticketsSold = viewModel.getTicketsSoldForEvent(event.id ?? "")
                
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

                            if let scanCode = show.scanCode {
                                VStack(alignment: .leading, spacing: 2) {
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
                        
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button(action: { goToShow(show) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                    Text("Go To Show")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.vertical, 10)
                                .frame(width: 180)
                                .background(
                                    RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.tour == nil)
                            
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
                                .padding(.vertical, 10)
                                .frame(width: 180)
                                .background(RoundedRectangle(cornerRadius: 8).fill(isPublished ? Color.red : Color.green))
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isPublishingToWeb)
                            .opacity(viewModel.isPublishingToWeb ? 0.7 : 1.0)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(height: 12)
                                let progress = originalAllocation > 0 ? Double(ticketsSold) / Double(originalAllocation) : 0.0
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 216/255, green: 122/255, blue: 239/255), Color(red: 191/255, green: 93/255, blue: 93/255)]), startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geometry.size.width * progress, height: 12)
                                    .animation(.easeInOut(duration: 0.8), value: progress)
                            }
                        }
                        .frame(height: 12)
                        Text("\(ticketsSold) of \(originalAllocation) Tickets Sold (\(totalAllocation) remaining)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(20).background(Material.regular).cornerRadius(16)
            } else {
                Text("No upcoming ticketed events.").font(.headline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 220).background(Material.regular).cornerRadius(16)
            }
        }

        private var bottomPanels: some View {
            HStack(alignment: .top, spacing: 24) {
                recentActivityView
                publishedEventsView
            }
        }
        
        private var recentActivityView: some View {
            VStack {
                Text("Recent Activity").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                if viewModel.recentTicketSales.isEmpty {
                    VStack {
                        Image(systemName: "clock").font(.title2).foregroundColor(.secondary)
                        Text("No recent ticket sales").font(.subheadline).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    ForEach(Array(viewModel.recentTicketSales.prefix(5).enumerated()), id: \.element.id) { index, sale in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sale.buyerEmail).font(.subheadline).lineLimit(1)
                                    Text("\(getTourAndCityForSale(sale)) â€¢ \(sale.quantity) ticket\(sale.quantity > 1 ? "s" : "")").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(currencyFormatter.string(from: NSNumber(value: sale.totalPrice)) ?? "$0.00").font(.subheadline).bold()
                                    Text(sale.purchaseDate.formatted(.dateTime.hour().minute())).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }.padding(.vertical, 4)
                        if index < viewModel.recentTicketSales.prefix(5).count - 1 { Divider() }
                    }
                }
                Spacer()
            }.padding(20).background(Material.regular).cornerRadius(16)
        }

        private var publishedEventsView: some View {
            VStack {
                HStack {
                    Text("Published Events").font(.headline)
                    Spacer()
                    Button(action: {}) { Image(systemName: "plus").font(.caption) }.buttonStyle(.plain)
                }
                if viewModel.publishedEvents.isEmpty {
                    VStack {
                        Image(systemName: "ticket").font(.title2).foregroundColor(.secondary)
                        Text("No published events").font(.subheadline).foregroundColor(.secondary)
                    }.frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.publishedEvents) { event in
                                if let show = viewModel.allShows.first(where: { $0.id == event.showId }) {
                                    VStack {
                                        KFImage(URL(string: viewModel.tour?.posterURL ?? "")).resizable().aspectRatio(2/3, contentMode: .fit).frame(width: 100).cornerRadius(6)
                                        Text(show.city).font(.caption).bold().lineLimit(1)
                                        Text(show.date.dateValue().formatted(.dateTime.month().day())).font(.caption2).foregroundColor(.secondary)
                                    }.frame(width: 100)
                                }
                            }
                        }.padding(.horizontal, 4)
                    }
                }
                Spacer()
            }.padding(20).background(Material.regular).cornerRadius(16)
        }

        private var stripeBalanceView: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Stripe Balance & Payouts")
                        .font(.title2)
                        .bold()
                    
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
                    // Available Balance Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.green)
                            Text("Available Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(viewModel.stripeCurrency) \(String(format: "%.2f", viewModel.stripeBalance))")
                            .font(.title)
                            .bold()
                            .foregroundColor(viewModel.stripeBalance > 0 ? .green : .primary)
                        
                        if viewModel.hasStripeAccount {
                            Text("Connected to Stripe")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Setup account to receive payouts")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Material.regular)
                    .cornerRadius(12)
                    
                    // Pending Balance Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("Pending Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(viewModel.stripeCurrency) \(String(format: "%.2f", viewModel.stripePendingBalance))")
                            .font(.title)
                            .bold()
                            .foregroundColor(viewModel.stripePendingBalance > 0 ? .orange : .primary)
                        
                        Text(viewModel.stripePendingBalance > 0 ? "Processing - available soon" : "No pending funds")
                            .font(.caption)
                            .foregroundColor(viewModel.stripePendingBalance > 0 ? .orange : .secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Material.regular)
                    .cornerRadius(12)
                    
                    // Total Earnings Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.blue)
                            Text("Total Earnings")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        let totalEarnings = viewModel.stripeBalance + viewModel.stripePendingBalance
                        Text("\(viewModel.stripeCurrency) \(String(format: "%.2f", totalEarnings))")
                            .font(.title)
                            .bold()
                            .foregroundColor(.blue)
                        
                        Text(totalEarnings > 0 ? "Available + Pending" : "No earnings yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Material.regular)
                    .cornerRadius(12)
                }
                
                // Balance breakdown info
                if viewModel.hasStripeAccount && (viewModel.stripeBalance > 0 || viewModel.stripePendingBalance > 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance Information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .bold()
                        
                        if viewModel.stripePendingBalance > 0 {
                            Text("• Pending funds are being processed by Stripe and will become available within 2-7 business days")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if viewModel.stripeBalance > 0 {
                            Text("• Available funds can be withdrawn immediately to your bank account")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }

        // MARK: - Helper Functions

        private func getTourAndCityForSale(_ sale: TicketsViewModel.TicketSale) -> String {
            guard let event = viewModel.allTicketedEvents.first(where: { $0.id == sale.ticketedEventId }),
                  let show = viewModel.allShows.first(where: { $0.id == sale.showId }) else { return "Unknown Show" }
            let tourName = viewModel.tour?.tourName ?? "Tour"
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
        
        // MARK: - Navigation Functions
        
        private func goToShow(_ show: Show) {
            if let tour = viewModel.tour {
                appState.selectedTour = tour
                appState.selectedShow = show
            }
        }
    }
