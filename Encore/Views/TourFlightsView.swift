import SwiftUI
import FirebaseFirestore

struct TourFlightsView: View {
    var tourID: String

    @State private var flights: [Flight] = []
    @State private var tourCrew: [TourCrew] = []
    @State private var showAddFlight = false
    @State private var expandedFlightID: String? = nil
    @State private var flightListener: ListenerRegistration? = nil
    @EnvironmentObject var appState: AppState
    
    private let airports = AirportService.shared.airports

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Flights", onAdd: { showAddFlight = true })

            if flights.isEmpty {
                placeholderView
            } else {
                 flightList
            }
        }
        .onAppear(perform: loadData)
        .onDisappear { flightListener?.remove() }
        .sheet(isPresented: $showAddFlight) {
            if let tour = appState.tours.first(where: { $0.id == tourID }) {
                AddFlightView(tour: tour, onFlightAdded: {})
            }
        }
    }

    private var placeholderView: some View {
        Text("No flights yet.")
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding()
             .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }

    private var flightList: some View {
        VStack(spacing: 12) {
            ForEach(flights) { flight in
                FlightItemCard(
                    flight: flight,
                    crew: tourCrew,
                    airports: airports,
                     isExpanded: expandedFlightID == flight.id,
                    onExpandToggle: { toggleExpanded(flight) },
                    onEdit: { /* Placeholder */ },
                    onDelete: { deleteFlight(flight) }
                )
                .animation(.easeInOut, value: expandedFlightID)
            }
        }
    }
    
    private func loadData() {
        flightListener?.remove()
        flightListener = FirebaseFlightService.addFlightsListener(forTour: tourID) { loadedFlights in
            self.flights = loadedFlights.sorted(by: { $0.departureTimeUTC.dateValue() < $1.departureTimeUTC.dateValue() })
        }
        fetchCrew()
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
    
    private func fetchCrew() {
        Task {
            do {
                self.tourCrew = try await FirebaseTourService.loadCrew(forTour: tourID)
            } catch {
                print("Error fetching crew for flights view: \(error.localizedDescription)")
            }
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
