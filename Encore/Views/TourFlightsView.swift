import SwiftUI
import FirebaseFirestore

struct TourFlightsView: View {
    // FIX: The view now ONLY needs the tourID to fetch its data.
    // The unnecessary userID and ownerUserID have been removed.
    var tourID: String

    @State private var flights: [Flight] = []
    @State private var showAddFlight = false
    @State private var expandedFlightID: String? = nil
    @State private var flightListener: ListenerRegistration? = nil
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Flights", onAdd: { showAddFlight = true })

            if flights.isEmpty {
                placeholderView
            } else {
                flightList
            }
        }
        .onAppear { setupListener() }
        .onDisappear { flightListener?.remove() }
        .sheet(isPresented: $showAddFlight) {
            // To present the AddFlightView, we find the full Tour object from appState.
            if let tour = appState.tours.first(where: { $0.id == tourID }) {
                AddFlightView(tour: tour, onFlightAdded: {})
            }
        }
    }

    private var placeholderView: some View {
        Text("No flights yet.")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
    }

    private var flightList: some View {
        VStack(spacing: 12) {
            ForEach(flights) { flight in
                FlightItemCard(
                    flight: flight,
                    isExpanded: expandedFlightID == flight.id,
                    onExpandToggle: { toggleExpanded(flight) },
                    onEdit: { /* Placeholder */ },
                    onDelete: { deleteFlight(flight) }
                )
                .animation(.easeInOut, value: expandedFlightID)
            }
        }
    }

    private func toggleExpanded(_ flight: Flight) {
        withAnimation {
            if expandedFlightID == flight.id {
                expandedFlightID = nil
            } else {
                expandedFlightID = flight.id
            }
        }
    }

    private func setupListener() {
        flightListener?.remove()
        flightListener = FirebaseFlightService.addFlightsListener(forTour: tourID) { loadedFlights in
            self.flights = loadedFlights.sorted(by: { $0.departureTimeUTC.dateValue() < $1.departureTimeUTC.dateValue() })
        }
    }

    private func deleteFlight(_ flight: Flight) {
        guard let flightID = flight.id else { return }
        FirebaseFlightService.deleteFlight(flightID: flightID) { error in
            if let error = error {
                print("Error deleting flight: \(error.localizedDescription)")
            }
        }
    }
}
