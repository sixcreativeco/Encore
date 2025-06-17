import SwiftUI

struct AddFlightView: View {
    var userID: String
    var tourID: String
    var onFlightAdded: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var flightNumber = ""
    @State private var flightDate = Date()
    @State private var selectedAirport: AirportEntry? = nil
    @State private var airportSearchText = ""

    @State private var isLoading = false
    @State private var fetchedFlight: FlightModel? = nil
    @State private var errorMessage: String? = nil

    @State private var crewSearchText = ""
    @State private var selectedCrew: [PassengerEntry] = []
    @State private var baggageInput = ""
    @State private var crewSuggestions: [CrewMember] = []

    private let airports = AirportService.shared.airports

    private var filteredAirports: [AirportEntry] {
        if airportSearchText.isEmpty { return [] }
        return airports.filter {
            $0.name.lowercased().contains(airportSearchText.lowercased()) ||
            $0.city.lowercased().contains(airportSearchText.lowercased()) ||
            $0.iata.lowercased().contains(airportSearchText.lowercased())
        }
    }

    private var filteredCrew: [CrewMember] {
        if crewSearchText.isEmpty { return [] }
        return crewSuggestions.filter {
            $0.name.lowercased().contains(crewSearchText.lowercased())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Add Flight").font(.title.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Flight Number").font(.subheadline)
                        TextField("e.g. QF140", text: $flightNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Flight Date").font(.subheadline)
                        DatePicker("", selection: $flightDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Departure Airport").font(.subheadline)
                    TextField("Start typing airport...", text: $airportSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if !filteredAirports.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredAirports) { airport in
                                    Button {
                                        selectAirport(airport)
                                    } label: {
                                        HStack {
                                            Text("\(airport.name) (\(airport.iata))")
                                            Spacer()
                                        }
                                        .padding(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxHeight: 200)
                    }

                    if let selected = selectedAirport {
                        Text("Selected: \(selected.name)").font(.caption).foregroundColor(.gray)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Who's on this flight?").font(.headline)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Name").font(.subheadline)
                        TextField("Search Crew", text: $crewSearchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        if !filteredCrew.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(filteredCrew, id: \.id) { crew in
                                        Button {
                                            crewSearchText = crew.name
                                        } label: {
                                            HStack {
                                                Text(crew.name)
                                                Spacer()
                                            }
                                            .padding(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .frame(maxHeight: 150)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Total Baggage (kg)").font(.subheadline)
                        TextField("kg", text: $baggageInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                Button(action: { addPassenger() }) {
                    Text("+ Add Passenger")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                if !selectedCrew.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(selectedCrew, id: \.id) { passenger in
                            HStack {
                                Text(passenger.name)
                                Spacer()
                                Text("\(passenger.baggage) kg")
                            }
                        }
                        let totalBaggage = selectedCrew.reduce(0) { $0 + (Int($1.baggage) ?? 0) }
                        Text("Total Baggage: \(totalBaggage) KG").font(.subheadline).fontWeight(.bold)
                    }
                }
            }

            if isLoading { ProgressView() }

            if let fetched = fetchedFlight {
                flightPreview(fetched)
                Button("Confirm & Add") {
                    saveFlight(fetched)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: { fetchFlightData() }) {
                    Text("Search Flight")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(flightNumber.isEmpty || selectedAirport == nil)
            }

            if let error = errorMessage {
                Text(error).foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .onAppear { loadCrew() }
    }

    private func selectAirport(_ airport: AirportEntry) {
        selectedAirport = airport
        airportSearchText = "\(airport.name) (\(airport.iata))"
    }

    private func addPassenger() {
        let name = crewSearchText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let baggage = baggageInput.isEmpty ? "0" : baggageInput
        selectedCrew.append(PassengerEntry(name: name, baggage: baggage))
        crewSearchText = ""
        baggageInput = ""
    }

    private func loadCrew() {
        FirebaseTourService.loadCrew(userID: userID, tourID: tourID) { crew in
            self.crewSuggestions = crew
        }
    }

    private func fetchFlightData() {
        guard let selectedAirport = selectedAirport else {
            self.errorMessage = "Please select a departure airport."
            return
        }

        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = formatter.string(from: flightDate)

        FlightLabsAPI.fetchFutureFlights(depIATA: selectedAirport.iata, date: formattedDate) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let flights):
                    let airlineCode = String(flightNumber.prefix { $0.isLetter })
                    let number = String(flightNumber.drop { $0.isLetter })

                    if let match = flights.first(where: { $0.carrier.fs.uppercased() == airlineCode.uppercased() && $0.carrier.flightNumber == number }) {
                        let scheduledDate = ISO8601DateFormatter().date(from: match.sortTime) ?? Date()

                        let flight = FlightModel(
                            airline: match.carrier.name,
                            flightNumber: "\(match.carrier.fs)\(match.carrier.flightNumber)",
                            departureAirport: selectedAirport.iata,
                            arrivalAirport: match.airport.fs,
                            departureTime: scheduledDate
                        )

                        self.fetchedFlight = flight
                    } else {
                        self.errorMessage = "No matching flight found."
                    }

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveFlight(_ flight: FlightModel) {
        FirebaseFlightService.saveFlight(userID: userID, tourID: tourID, flight: flight, passengers: selectedCrew.map { $0.name }) {
            self.onFlightAdded()
            self.dismiss()
        }
    }

    private func flightPreview(_ flight: FlightModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(flight.airline) \(flight.flightNumber)").font(.headline)
                Spacer()
                airlineIconView(for: flight)
            }
            Text("\(flight.departureAirport) → \(flight.arrivalAirport)").font(.subheadline)
            Text("Departs: \(formattedDate(flight.departureTime))").font(.caption)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private func airlineIconView(for flight: FlightModel) -> some View {
        let airlineCode = extractAirlineCode(from: flight.flightNumber).uppercased()
        let imageName: String

        if airlineCode == "NZ" {
            imageName = colorScheme == .dark ? "\(airlineCode)_icon_light" : "\(airlineCode)_icon"
        } else {
            imageName = "\(airlineCode)_icon"
        }

        return Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
    }

    private func extractAirlineCode(from flightNumber: String) -> String {
        let prefix = flightNumber.prefix { $0.isLetter }
        return String(prefix)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PassengerEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var baggage: String
}
