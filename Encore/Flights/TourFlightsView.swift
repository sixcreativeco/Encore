import SwiftUI
import FirebaseFirestore

struct TourFlightsView: View {
    var tourID: String
    var userID: String
    var ownerUserID: String

    @State private var flights: [FlightModel] = []
    @State private var showAddFlight = false
    @State private var expandedFlightID: String? = nil
    @State private var flightListener: ListenerRegistration? = nil

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
            AddFlightView(userID: ownerUserID, tourID: tourID, onFlightAdded: {})
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

    private func toggleExpanded(_ flight: FlightModel) {
        withAnimation {
            if expandedFlightID == flight.id {
                expandedFlightID = nil
            } else {
                expandedFlightID = flight.id
            }
        }
    }

    private func setupListener() {
        // Remove any existing listener to prevent duplicates
        flightListener?.remove()
        
        // Set up the new real-time listener
        flightListener = FirebaseFlightService.addFlightsListener(userID: ownerUserID, tourID: tourID) { loadedFlights in
            self.flights = loadedFlights.sorted(by: { $0.departureTime < $1.departureTime })
        }
    }

    private func deleteFlight(_ flight: FlightModel) {
        // This delete logic remains unchanged as per your instruction.
        FirebaseFlightService.deleteFlight(userID: ownerUserID, tourID: tourID, flightID: flight.id) {
            // UI will update automatically from the listener, so no local removal is needed.
        }
    }
}
