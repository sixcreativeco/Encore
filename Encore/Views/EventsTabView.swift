import SwiftUI
import Kingfisher
import FirebaseFirestore
import FirebaseAuth

// MARK: - Main View

struct EventsTabView: View {
    @StateObject private var viewModel = EventsTabViewModel()
    @State private var eventToManage: TicketedEvent?

    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]

    var body: some View {
        // --- THIS IS THE FIX (Part 1) ---
        // The main VStack now has no spacing to allow for precise control.
        VStack(alignment: .leading, spacing: 0) {
            
            // The filter/sort bar has its own padding now.
            HStack(spacing: 12) {
                tourFilterDropdown
                Spacer(minLength: 0)
                sortOrderDropdown
            }
            .padding(.vertical, 12) // Adds padding above and below the bar

            // The content area is now structured to prevent the layout jump.
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading Events...")
                    Spacer()
                }
            } else if viewModel.filteredEvents.isEmpty {
                VStack {
                    Spacer()
                    emptyStateView
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.filteredEvents) { displayEvent in
                            EventGridCardView(event: displayEvent) {
                                self.eventToManage = displayEvent.event
                            }
                        }
                    }
                    .padding(.top, 8) // Reduced top padding for the grid
                }
            }
        }
        .sheet(item: $eventToManage) { event in
            if let displayEvent = viewModel.filteredEvents.first(where: { $0.event.id == event.id }) {
                ConfigureTicketsView(tour: displayEvent.tour, show: displayEvent.show)
            }
        }
    }

    private var tourFilterDropdown: some View {
        Menu {
            Button("All Tours") { viewModel.selectedTourFilterID = nil }
            Divider()
            ForEach(viewModel.allTours) { tour in
                Button(tour.tourName) { viewModel.selectedTourFilterID = tour.id }
            }
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.allTours.first { $0.id == viewModel.selectedTourFilterID }?.tourName ?? "All Tours")
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var sortOrderDropdown: some View {
        Menu {
            ForEach(EventsTabViewModel.SortOption.allCases) { option in
                Button(option.rawValue) { viewModel.selectedSortOption = option }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                Text(viewModel.selectedSortOption.rawValue)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("No Events Found")
                .font(.headline)
            Text("There are no ticketed events matching your selected filters.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Event Grid Card View

fileprivate struct EventGridCardView: View {
    let event: EventsTabViewModel.DisplayEvent
    var onManage: () -> Void

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = event.event.ticketTypes.first?.currency ?? "NZD"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(event.show.city).font(.headline.bold()).lineLimit(1)
                    Text(event.show.venueName).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()

                Text(event.event.status.rawValue.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(statusColor(for: event.event.status).opacity(0.2))
                    .foregroundColor(statusColor(for: event.event.status))
                    .cornerRadius(6)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                GradientProgressView(
                    value: Double(event.ticketsSold),
                    total: Double(event.totalAllocation > 0 ? event.totalAllocation : 1)
                )
                Text("\(event.ticketsSold) of \(event.totalAllocation) sold")
                    .font(.caption).foregroundColor(.secondary)
            }

            HStack {
                Text("Revenue:")
                    .font(.subheadline).foregroundColor(.secondary)
                Text(currencyFormatter.string(from: NSNumber(value: event.totalRevenue)) ?? "$0.00")
                    .font(.subheadline).bold()
                Spacer()
                Button("Manage", action: onManage)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .frame(minHeight: 150)
        .background(Material.regular)
        .cornerRadius(12)
    }

    private func statusColor(for status: TicketedEvent.Status) -> Color {
        switch status {
        case .published, .scheduled: return .green
        case .draft, .unpublished: return .gray
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}
