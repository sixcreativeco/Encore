import SwiftUI
import FirebaseFirestore

struct AddFlightView: View {
    var tour: Tour
    var onFlightAdded: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    // Form State
    @State private var flightNumber = ""
    @State private var flightDate = Date() // This is the date the user selects
    @State private var selectedAirport: AirportEntry? = nil
    @State private var airportSearchText = ""
    @State private var notes = ""

    // View State
    @State private var isLoading = false
    @State private var fetchedFlight: Flight? = nil
    @State private var errorMessage: String? = nil

    // Passenger State
    @State private var crewSearchText = ""
    @State private var selectedPassengers: [String] = []
    @State private var baggageInput = ""
    @State private var crewSuggestions: [TourCrew] = []

    private let airports = AirportService.shared.airports

    private var filteredAirports: [AirportEntry] {
        if airportSearchText.isEmpty { return [] }
        return airports.filter {
            $0.name.lowercased().contains(airportSearchText.lowercased()) ||
            $0.city.lowercased().contains(airportSearchText.lowercased()) ||
            $0.iata.lowercased().contains(airportSearchText.lowercased())
        }
    }
    
    private var filteredCrew: [TourCrew] {
        if crewSearchText.isEmpty { return [] }
        return crewSuggestions.filter {
            $0.name.lowercased().contains(crewSearchText.lowercased()) &&
            !selectedPassengers.contains($0.id ?? "")
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
                                    ForEach(filteredCrew) { crew in
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
                }
                .buttonStyle(.bordered)

                if !selectedPassengers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(selectedPassengers.count) passenger(s) added.")
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
                        .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
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
        .onAppear {
            // loadCrew() // This will be refactored later
        }
    }
    
    private func selectAirport(_ airport: AirportEntry) {
        selectedAirport = airport
        airportSearchText = "\(airport.name) (\(airport.iata))"
    }

    private func addPassenger() {
        guard let crewMember = crewSuggestions.first(where: { $0.name == crewSearchText }), let crewID = crewMember.id else { return }
        if !selectedPassengers.contains(crewID) {
            selectedPassengers.append(crewID)
        }
        crewSearchText = ""
        baggageInput = ""
    }

    private func flightPreview(_ flight: Flight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(flight.airline ?? "N/A") \(flight.flightNumber ?? "N/A")").font(.headline)
                Spacer()
            }
            Text("\(flight.origin) → \(flight.destination)").font(.subheadline)
            Text("Departs: \(flight.departureTimeUTC.dateValue().formatted(date: .long, time: .shortened))").font(.caption)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func loadCrew() {
        // This function will be refactored when we address the Crew feature.
    }

    // --- FIX IS HERE ---
    private func fetchFlightData() {
        guard let selectedAirport = selectedAirport, let tourID = tour.id else {
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
                    let airlineCode = String(self.flightNumber.prefix { $0.isLetter })
                    let number = String(self.flightNumber.drop { $0.isLetter })

                    if let match = flights.first(where: { $0.carrier.fs.uppercased() == airlineCode.uppercased() && $0.carrier.flightNumber == number }) {
                        
                        // This new helper function ensures the correct date is combined with the time from the API.
                        func createFullDate(from timeString24: String, on selectedDate: Date) -> Date {
                            let calendar = Calendar.current
                            let timeComponents = timeString24.split(separator: ":")
                            let hour = Int(timeComponents.first ?? "0") ?? 0
                            let minute = Int(timeComponents.last ?? "0") ?? 0
                            
                            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate) ?? selectedDate
                        }

                        // Use the user's selected date as the base for both departure and arrival.
                        var departureDate = createFullDate(from: match.departureTime?.time24 ?? "00:00", on: self.flightDate)
                        var arrivalDate = createFullDate(from: match.arrivalTime?.time24 ?? "00:00", on: self.flightDate)
                        
                        // Handle overnight flights where arrival is on the next day
                        if arrivalDate < departureDate {
                            arrivalDate = Calendar.current.date(byAdding: .day, value: 1, to: arrivalDate) ?? arrivalDate
                        }
                        
                        let flight = Flight(
                            id: UUID().uuidString,
                            tourId: tourID,
                            airline: match.carrier.name,
                            flightNumber: "\(match.carrier.fs)\(match.carrier.flightNumber)",
                            departureTimeUTC: Timestamp(date: departureDate),
                            arrivalTimeUTC: Timestamp(date: arrivalDate),
                            origin: selectedAirport.iata,
                            destination: match.airport.fs,
                            notes: self.notes,
                            passengers: self.selectedPassengers
                        )
                        self.fetchedFlight = flight
                    } else {
                        self.errorMessage = "No matching flight found for this date."
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveFlight(_ flight: Flight) {
        let db = Firestore.firestore()
        
        do {
            // Save the Flight document
            let flightRef = try db.collection("flights").addDocument(from: flight)
            
            // Create and save the corresponding ItineraryItem document
            let itineraryItem = ItineraryItem(
                id: "flight-\(flightRef.documentID)", // Create a unique but related ID
                tourId: flight.tourId,
                showId: nil,
                title: "\(flight.airline ?? "") \(flight.flightNumber ?? ""): \(flight.origin) → \(flight.destination)",
                type: ItineraryItemType.flight.rawValue,
                timeUTC: flight.departureTimeUTC,
                notes: flight.notes
            )
            try db.collection("itineraryItems").document(itineraryItem.id!).setData(from: itineraryItem)
            
            self.onFlightAdded()
            self.dismiss()
            
        } catch {
            print("❌ Error saving flight and itinerary item: \(error.localizedDescription)")
            self.errorMessage = "Failed to save flight. Please try again."
        }
    }
}
