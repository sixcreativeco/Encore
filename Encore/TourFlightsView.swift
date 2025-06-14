import SwiftUI

struct TourFlightsView: View {
    var tourID: String

    @State private var flights: [FlightModel] = []
    @State private var showAddFlight = false
    @State private var expandedFlightID: String? = nil
    @State private var selectedFlightForEdit: FlightModel? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Flights", onAdd: { showAddFlight = true })

            if flights.isEmpty {
                placeholderView
            } else {
                flightList
            }
        }
        .onAppear { loadFlights() }
        .sheet(isPresented: $showAddFlight) {
            AddFlightView(tourID: tourID, onFlightAdded: { loadFlights() })
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
                    onEdit: { /* Leave empty for now */ },
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

    private func loadFlights() {
        FirebaseFlightService.loadFlights(tourID: tourID) { loadedFlights in
            self.flights = loadedFlights
        }
    }

    private func deleteFlight(_ flight: FlightModel) {
        let db = FirebaseFlightService.db
        db.collection("tours")
            .document(tourID)
            .collection("flights")
            .document(flight.id)
            .delete { _ in
                loadFlights()
            }
    }
}
