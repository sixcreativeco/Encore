import SwiftUI
import FirebaseFirestore

struct AddFlightView: View {
    var tour: Tour
    var onFlightAdded: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    // Form State
    @State private var flightNumber = ""
    @State private var flightDate = Date()
    @State private var selectedAirport: AirportEntry? = nil
    @State private var airportSearchText = ""
    @State private var notes = ""

    // View State
    @State private var isLoading = false
    @State private var fetchedFlight: Flight? = nil
    @State private var errorMessage: String? = nil

    // Passenger State
    @State private var tourCrew: [TourCrew] = []
    @State private var crewSearchText = ""
    @State private var baggageInput = ""
    @State private var passengerEntries: [Passenger] = []
    
    // Computed property to calculate total baggage
    private var totalBaggage: Int {
        passengerEntries.reduce(0) { total, passenger in
            total + (Int(passenger.baggage ?? "0") ?? 0)
        }
    }
    
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
        let selectedIDs = Set(passengerEntries.map { $0.crewId })
        return tourCrew.filter { crew in
            guard let id = crew.id else { return false }
            return crew.name.lowercased().contains(crewSearchText.lowercased()) && !selectedIDs.contains(id)
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
                HStack(alignment: .bottom) {
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
                        Text("Baggage (kg)").font(.subheadline)
                        TextField("e.g. 23", text: $baggageInput)
                             .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: { addPassenger() }) {
                        Text("Add")
                    }
                    .disabled(crewSearchText.isEmpty)
                }

                if !passengerEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(passengerEntries) { entry in
                            HStack {
                                Text(tourCrew.first { $0.id == entry.crewId }?.name ?? "Unknown")
                                Spacer()
                                Text(entry.baggage ?? "N/A")
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    passengerEntries.removeAll { $0.id == entry.id }
                                }) {
                                    Image(systemName: "xmark.circle")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Divider()
                        HStack {
                            Text("Total Baggage").fontWeight(.bold)
                            Spacer()
                            Text("\(totalBaggage) kg").fontWeight(.bold)
                        }
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
        .onAppear(perform: loadCrew)
    }
    
    private func selectAirport(_ airport: AirportEntry) {
        selectedAirport = airport
        airportSearchText = "\(airport.name) (\(airport.iata))"
    }

    private func addPassenger() {
        guard let crewMember = tourCrew.first(where: { $0.name == crewSearchText }), let crewID = crewMember.id else { return }
        
        let newEntry = Passenger(crewId: crewID, baggage: baggageInput.isEmpty ? nil : baggageInput)
        
        if !passengerEntries.contains(where: { $0.crewId == crewID }) {
            passengerEntries.append(newEntry)
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
        Task {
            do {
                self.tourCrew = try await FirebaseTourService.loadCrew(forTour: tour.id ?? "")
            } catch {
                print("Error loading crew: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchFlightData() {
        guard let departureAirport = selectedAirport, let tourID = tour.id else {
            self.errorMessage = "Please select a departure airport."
            return
        }

        isLoading = true
        errorMessage = nil

        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = apiDateFormatter.string(from: flightDate)

        FlightLabsAPI.fetchFutureFlights(depIATA: departureAirport.iata, date: formattedDate) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let flights):
                    let airlineCode = String(self.flightNumber.prefix { $0.isLetter })
                    let number = String(self.flightNumber.drop { $0.isLetter })

                    if let match = flights.first(where: { $0.carrier.fs.uppercased() == airlineCode.uppercased() && $0.carrier.flightNumber == number }) {
                        
                        // Find full airport data for both departure and arrival to get timezones
                        guard let depAirportData = AirportService.shared.airports.first(where: { $0.iata == departureAirport.iata }),
                              let arrAirportData = AirportService.shared.airports.first(where: { $0.iata == match.airport.fs }),
                              let depTimeZone = TimeZone(identifier: depAirportData.tz),
                              let arrTimeZone = TimeZone(identifier: arrAirportData.tz) else {
                            self.errorMessage = "Could not determine timezone for airports."
                            return
                        }
                        
                        func createDateInTimezone(date: Date, timeString: String, timezone: TimeZone) -> Date {
                            var calendar = Calendar.current
                            calendar.timeZone = timezone
                            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                            let timeComponents = timeString.split(separator: ":")
                            let hour = Int(timeComponents.first ?? "0") ?? 0
                            let minute = Int(timeComponents.last ?? "0") ?? 0
                            
                            var finalComponents = DateComponents()
                            finalComponents.year = dateComponents.year
                            finalComponents.month = dateComponents.month
                            finalComponents.day = dateComponents.day
                            finalComponents.hour = hour
                            finalComponents.minute = minute
                            
                            return calendar.date(from: finalComponents) ?? date
                        }

                        // Create departure and arrival dates in their respective local timezones
                        let departureDateLocal = createDateInTimezone(date: self.flightDate, timeString: match.departureTime?.time24 ?? "00:00", timezone: depTimeZone)
                        var arrivalDateLocal = createDateInTimezone(date: self.flightDate, timeString: match.arrivalTime?.time24 ?? "00:00", timezone: arrTimeZone)

                        // If local arrival time is before local departure time, it's an overnight or date line-crossing flight.
                        if arrivalDateLocal < departureDateLocal {
                             arrivalDateLocal = Calendar.current.date(byAdding: .day, value: 1, to: arrivalDateLocal) ?? arrivalDateLocal
                        }
                        
                        let flight = Flight(
                            tourId: tourID,
                            airline: match.carrier.name,
                            flightNumber: "\(match.carrier.fs)\(match.carrier.flightNumber)",
                            departureTimeUTC: Timestamp(date: departureDateLocal),
                            arrivalTimeUTC: Timestamp(date: arrivalDateLocal),
                            origin: departureAirport.iata,
                            destination: match.airport.fs,
                            notes: self.notes,
                            passengers: self.passengerEntries
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
        var finalFlight = flight
        finalFlight.passengers = self.passengerEntries
        
        FirebaseFlightService.saveFlight(finalFlight) { error, newFlightID  in
            if let error = error {
                print("❌ Error saving flight: \(error.localizedDescription)")
                self.errorMessage = "Failed to save flight. Please try again."
                return
            }
            
            guard let flightID = newFlightID else {
                self.errorMessage = "Failed to get new flight ID."
                return
            }
            
            let itineraryItem = ItineraryItem(
                 id: "flight-\(flightID)",
                tourId: flight.tourId,
                showId: nil,
                title: "\(flight.airline ?? "") \(flight.flightNumber ?? ""): \(flight.origin) → \(flight.destination)",
                type: ItineraryItemType.flight.rawValue,
                 timeUTC: flight.departureTimeUTC, // Itinerary item is based on departure
                notes: flight.notes,
                timezone: AirportService.shared.airports.first { $0.iata == flight.origin }?.tz,
                visibility: "Everyone",
                visibleTo: nil
            )
            
            do {
                try db.collection("itineraryItems").document(itineraryItem.id!).setData(from: itineraryItem)
                self.onFlightAdded()
                self.dismiss()
            } catch {
                print("❌ Error saving itinerary item: \(error.localizedDescription)")
                self.errorMessage = "Failed to save itinerary item for flight."
            }
        }
    }
}
