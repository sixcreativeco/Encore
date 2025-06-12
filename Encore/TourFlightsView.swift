import SwiftUI

struct TourFlightsView: View {
    var tourID: String
    @State private var flights: [FlightModel] = []
    @State private var showAddFlight = false

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

    private func loadFlights() {
        FirebaseFlightService.loadFlights(tourID: tourID) { loadedFlights in
            self.flights = loadedFlights
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
                FlightCardView(
                    airlineName: flight.airline,
                    flightCode: flight.flightNumber,
                    departureIATA: flight.departureAirport,
                    arrivalIATA: flight.arrivalAirport,
                    departureTime: formattedTime(flight.departureTime),
                    arrivalTime: "N/A",
                    duration: "N/A",
                    airlineLogo: Image(systemName: "airplane"),
                    isDarkMode: true
                )
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
