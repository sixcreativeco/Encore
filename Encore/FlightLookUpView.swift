import SwiftUI

struct FlightLookupView: View {
    @State private var flightNumber: String = ""
    @State private var selectedDate: Date = Date()
    @State private var foundFlight: FlightLabsFlight? = nil
    @State private var isLoading: Bool = false
    @State private var noResults: Bool = false

    var body: some View {
        VStack {
            Form {
                TextField("Flight Number (e.g. QF140)", text: $flightNumber)
                    
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)

                Button("Search Flight") {
                    searchFlight()
                }
            }

            if isLoading {
                ProgressView("Searching...")
            }

            if let flight = foundFlight {
                VStack(spacing: 10) {
                    Text("\(flight.carrier.name) \(flight.carrier.fs)\(flight.carrier.flightNumber)")
                        .font(.title2).bold()

                    VStack {
                        Text("Departure: \(flight.departureTime?.timeAMPM ?? "N/A")")
                        Text("Arrival: \(flight.arrivalTime?.timeAMPM ?? "N/A")")
                        Text("Destination: \(flight.airport.city) (\(flight.airport.fs))")
                    }
                }
                .padding()
            }

            if noResults {
                Text("No flights found. Double-check flight number and date.")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Flight Lookup")
        .padding()
    }

    private func searchFlight() {
        guard !flightNumber.isEmpty else { return }

        isLoading = true
        foundFlight = nil
        noResults = false

        let airlineCode = flightNumber.prefix(while: { $0.isLetter })
        let flightNum = flightNumber.drop(while: { $0.isLetter })

        print("🔎 Looking for airlineCode: \(airlineCode), flightNum: \(flightNum)")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        let iataCode = "AKL"  // This will eventually be dynamic
        print("🗓 Searching flights departing \(iataCode) on \(dateString)")

        FlightLabsAPI.fetchFutureFlights(depIATA: iataCode, date: dateString) { result in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            switch result {
            case .success(let flights):
                print("✅ Retrieved \(flights.count) flights from API.")

                if let matchedFlight = flights.first(where: {
                    $0.carrier.fs.uppercased() == airlineCode.uppercased() &&
                    $0.carrier.flightNumber == flightNum
                }) {
                    print("🎯 Match found: \(matchedFlight)")
                    DispatchQueue.main.async {
                        self.foundFlight = matchedFlight
                    }
                } else {
                    print("⚠️ No matching flight found for \(airlineCode)\(flightNum)")
                    DispatchQueue.main.async {
                        self.noResults = true
                    }
                }

            case .failure(let error):
                print("❌ Failed to fetch flights: \(error.localizedDescription)")
            }
        }
    }
}
