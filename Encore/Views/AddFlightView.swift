import SwiftUI
import FirebaseFirestore
import Combine

fileprivate struct GuestInputView: View {
    @Binding var tourCrew: [TourCrew]
    @Binding var passengerEntries: [Passenger]
    @State private var guestSearchText: String = ""
    @State private var guestBaggage: String = ""
        
    private var totalBaggage: Int {
        passengerEntries.reduce(0) { total, passenger in
            total + (Int(passenger.baggage ?? "0") ?? 0)
        }
    }
        
    private var filteredCrewSuggestions: [TourCrew] {
        if guestSearchText.isEmpty { return [] }
        let assignedGuestIDs = Set(passengerEntries.map { $0.crewId })
        return tourCrew.filter { crew in
            let isAssigned = assignedGuestIDs.contains(crew.id ?? "")
            let matchesSearch = crew.name.lowercased().contains(guestSearchText.lowercased())
            return !isAssigned && matchesSearch
        }
    }
        
    var body: some View {
        VStack {
            if !passengerEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(passengerEntries) { entry in
                        HStack {
                            Text(tourCrew.first { $0.id == entry.crewId }?.name ?? "Unknown")
                            Spacer()
                            Text("\(entry.baggage ?? "0") kg").foregroundColor(.secondary)
                            Button(action: { passengerEntries.removeAll { $0.id == entry.id } }) {
                                Image(systemName: "xmark.circle")
                            }.buttonStyle(.plain)
                        }
                    }
                    Divider()
                    HStack {
                        Text("Total Baggage").fontWeight(.bold)
                        Spacer()
                        Text("\(totalBaggage) kg").fontWeight(.bold)
                    }
                }
                .padding(.bottom, 16)
            }
            
            HStack(alignment: .bottom) {
               VStack(alignment: .leading) {
                   Text("Name").font(.subheadline)
                   TextField("Search Crew", text: $guestSearchText).textFieldStyle(RoundedBorderTextFieldStyle())
               }
               VStack(alignment: .leading) {
                   Text("Baggage (kg)").font(.subheadline)
                   TextField("e.g. 23", text: $guestBaggage).textFieldStyle(RoundedBorderTextFieldStyle())
               }
               Button("Add") { addPassenger() }.disabled(guestSearchText.isEmpty)
           }
           
           if !filteredCrewSuggestions.isEmpty {
               ScrollView {
                   VStack(alignment: .leading, spacing: 0) {
                       ForEach(filteredCrewSuggestions) { crew in
                           Button(action: { guestSearchText = crew.name }) {
                               HStack { Text(crew.name); Spacer() }.padding(8)
                           }.buttonStyle(.plain)
                        }
                   }
               }.background(Color.gray.opacity(0.1)).cornerRadius(8).frame(maxHeight: 150)
           }
       }
    }
        
    private func addPassenger() {
        guard let crewMember = tourCrew.first(where: { $0.name == guestSearchText }), let crewID = crewMember.id else { return }
        let newEntry = Passenger(crewId: crewID, baggage: guestBaggage.isEmpty ? nil : guestBaggage)
        if !passengerEntries.contains(where: { $0.crewId == crewID }) { passengerEntries.append(newEntry) }
        guestSearchText = ""
        guestBaggage = ""
    }
}

struct AddFlightView: View {
    var tour: Tour
    var onFlightAdded: () -> Void
    @Environment(\.dismiss) var dismiss
        
    enum EntryMode: String, CaseIterable, Identifiable {
        case autoSearch = "Auto Search", manual = "Manual Entry"
        var id: String { self.rawValue }
    }
    
    @State private var entryMode: EntryMode = .autoSearch
    
    // State properties
    @State private var autoFlightNumber = ""
    @State private var autoFlightDate = Date()
    @State private var autoSelectedAirport: AirportEntry? = nil
    @State private var autoAirportSearchText = ""
    @FocusState private var isAirportSearchFocused: Bool
    @State private var fetchedFlight: Flight? = nil
    @State private var manualAirlineName = ""
    @State private var manualAirlineCode = ""
    @State private var manualFlightNumber = ""
    @State private var manualDepartureDate = Date()
    @State private var manualArrivalDate = Date()
    @State private var manualDepartureAirport = ""
    @State private var manualArrivalAirport = ""
    @State private var manualDepartureTime = Date()
    @State private var manualArrivalTime = Date()
    @State private var notes = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var tourCrew: [TourCrew] = []
    @State private var passengerEntries: [Passenger] = []
    
    private let allAirports = AirportService.shared.airports
        
    private var filteredAirports: [AirportEntry] {
        if autoAirportSearchText.isEmpty { return [] }
        return allAirports.filter {
            $0.name.lowercased().contains(autoAirportSearchText.lowercased()) ||
            $0.city.lowercased().contains(autoAirportSearchText.lowercased()) ||
            $0.iata.lowercased().contains(autoAirportSearchText.lowercased())
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                
                Picker("Entry Mode", selection: $entryMode) {
                    ForEach(EntryMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                }
                .pickerStyle(SegmentedPickerStyle()).padding(.bottom, 16)
                                
                if entryMode == .autoSearch {
                    autoSearchView
                } else {
                    manualEntryView
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear(perform: loadCrew)
    }
        
    private var header: some View {
        HStack {
            Text("Add Flight").font(.title.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
            }.buttonStyle(.plain)
        }
    }
    
    private var autoSearchView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Flight Number").font(.subheadline)
                    TextField("e.g. QF140", text: $autoFlightNumber).textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack(alignment: .leading) {
                    Text("Flight Date").font(.subheadline)
                    DatePicker("", selection: $autoFlightDate, displayedComponents: .date).labelsHidden()
                }
            }
            
            VStack(alignment: .leading) {
                Text("Departure Airport").font(.subheadline)
                if let selectedAirport = autoSelectedAirport {
                    HStack {
                        Text(selectedAirport.name).padding(.vertical, 8).padding(.leading, 12)
                        Spacer()
                        Button(action: {
                            self.autoSelectedAirport = nil
                            self.autoAirportSearchText = ""
                            self.isAirportSearchFocused = true
                        }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain).padding(.trailing, 8)
                    }
                    .background(Color.gray.opacity(0.2)).cornerRadius(8)
                } else {
                    TextField("Start typing airport or city...", text: $autoAirportSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isAirportSearchFocused)
                }
                
                if isAirportSearchFocused && !filteredAirports.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredAirports) { airport in
                                HStack {
                                    Text(airport.name).padding(8)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { selectAirport(airport) }
                                Divider()
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.1)).cornerRadius(8).frame(maxHeight: 200)
                }
            }
            
            if fetchedFlight == nil {
                Button(action: findFlight) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView().colorInvert()
                        } else {
                            Text("Search Flight")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(autoFlightNumber.isEmpty || autoSelectedAirport == nil || isLoading)
            } else {
                flightPreview(fetchedFlight)
                passengersSection
                
                Button(action: { saveFlight(fetchedFlight) }) {
                    HStack {
                        Spacer()
                        Text("Confirm & Add Flight")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption).padding(.top)
            }
        }
    }
    
    private var manualEntryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                StyledInputField(placeholder: "Airline Name", text: $manualAirlineName)
                StyledInputField(placeholder: "Code", text: $manualAirlineCode)
                    .onChange(of: manualAirlineCode) { _, v in
                        manualAirlineCode = String(v.uppercased().filter { "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }.prefix(2))
                    }
                StyledInputField(placeholder: "Flight No.", text: $manualFlightNumber)
                    .onChange(of: manualFlightNumber) { _, v in
                        manualFlightNumber = v.filter { "0123456789".contains($0) }
                    }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Departure").font(.subheadline)
                    StyledDateField(date: $manualDepartureDate)
                    StyledTimePicker(label: "", time: $manualDepartureTime)
                }
                VStack(alignment: .leading) {
                    Text("Arrival").font(.subheadline)
                    StyledDateField(date: $manualArrivalDate)
                    StyledTimePicker(label: "", time: $manualArrivalTime)
                }
            }
            
            HStack(spacing: 16) {
                StyledInputField(placeholder: "From (IATA)", text: $manualDepartureAirport)
                    .onChange(of: manualDepartureAirport) { _, v in
                        manualDepartureAirport = String(v.uppercased().prefix(3))
                    }
                StyledInputField(placeholder: "To (IATA)", text: $manualArrivalAirport)
                    .onChange(of: manualArrivalAirport) { _, v in
                        manualArrivalAirport = String(v.uppercased().prefix(3))
                    }
            }
            
            passengersSection
            
            Button(action: saveManualFlight) {
                HStack {
                    Spacer()
                    Text("Save Manual Flight")
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
        
    private var passengersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who's on this flight?").font(.headline)
            GuestInputView(tourCrew: $tourCrew, passengerEntries: $passengerEntries)
        }
    }
        
    @ViewBuilder
    private func flightPreview(_ flight: Flight?) -> some View {
        if let flight = flight {
            VStack(alignment: .leading, spacing: 8) {
                Text("Flight Found").font(.headline)
                HStack {
                    Text("\(flight.airline ?? "N/A") \(flight.flightNumber ?? "N/A")").font(.subheadline)
                    Spacer()
                }
                Text("\(flight.origin) → \(flight.destination)")
                Text("Departs: \(flight.departureTimeUTC.dateValue().formatted(date: .abbreviated, time: .shortened))")
                Text("Arrives: \(flight.arrivalTimeUTC.dateValue().formatted(date: .abbreviated, time: .shortened))")
            }
            .font(.caption)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
        }
    }
        
    func selectAirport(_ airport: AirportEntry) {
        self.autoSelectedAirport = airport
        self.autoAirportSearchText = ""
        self.isAirportSearchFocused = false
    }
        
    func loadCrew() {
        Task {
            do {
                self.tourCrew = try await FirebaseTourService.loadCrew(forTour: tour.id ?? "")
            }
            catch {
                print("❌ DEBUG: Error loading crew: \(error.localizedDescription)")
            }
        }
    }
       
    func findFlight() {
        guard let departureAirport = autoSelectedAirport else {
            self.errorMessage = "Please select a departure airport."
            return
        }
        
        isLoading = true
        errorMessage = nil
        fetchedFlight = nil
                
        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = apiDateFormatter.string(from: autoFlightDate)
                
        FlightLabsAPI.fetchFutureFlights(depIATA: departureAirport.iata, date: formattedDate) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let flights):
                    let airlineCode = String(self.autoFlightNumber.prefix { $0.isLetter })
                    let number = String(self.autoFlightNumber.drop { $0.isLetter })
                                        
                    if let match = flights.first(where: { $0.carrier.fs.uppercased() == airlineCode.uppercased() && $0.carrier.flightNumber == number }) {
                        guard let dep = self.allAirports.first(where: { $0.iata == departureAirport.iata }),
                              let arr = self.allAirports.first(where: { $0.iata == match.airport.fs }),
                              let depTZ = TimeZone(identifier: dep.tz),
                              let arrTZ = TimeZone(identifier: arr.tz) else {
                            self.errorMessage = "Could not determine timezone for airports."
                            return
                        }
                        
                        // Create departure time in departure timezone, then convert to UTC
                        let depDate = self.createDateInTimezone(date: self.autoFlightDate, timeString: match.departureTime?.time24 ?? "00:00", timezone: depTZ)
                        
                        // Create arrival time in arrival timezone, then convert to UTC
                        var arrDate = self.createDateInTimezone(date: self.autoFlightDate, timeString: match.arrivalTime?.time24 ?? "00:00", timezone: arrTZ)
                        
                        // Handle overnight flights - if arrival is before departure, add a day
                        if arrDate < depDate {
                            arrDate = Calendar.current.date(byAdding: .day, value: 1, to: arrDate) ?? arrDate
                        }
                        
                        // Convert both times to UTC for storage
                        let utcDepDate = self.convertToUTC(date: depDate, fromTimezone: depTZ)
                        let utcArrDate = self.convertToUTC(date: arrDate, fromTimezone: arrTZ)
                                                
                        self.fetchedFlight = Flight(
                            tourId: self.tour.id ?? "",
                            airline: match.carrier.name,
                            flightNumber: "\(match.carrier.fs)\(match.carrier.flightNumber)",
                            departureTimeUTC: Timestamp(date: utcDepDate),
                            arrivalTimeUTC: Timestamp(date: utcArrDate),
                            origin: dep.iata,
                            destination: arr.iata,
                            notes: self.notes,
                            passengers: []
                        )
                    } else {
                        self.errorMessage = "No matching flight found for this date."
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
        
    func saveManualFlight() {
        guard let tourID = tour.id, !manualAirlineName.isEmpty, !manualAirlineCode.isEmpty, !manualFlightNumber.isEmpty, !manualDepartureAirport.isEmpty, !manualArrivalAirport.isEmpty else {
            errorMessage = "Please fill all fields."
            return
        }
                
        let originAirport = allAirports.first(where: { $0.iata == manualDepartureAirport.uppercased() })
        let destinationAirport = allAirports.first(where: { $0.iata == manualArrivalAirport.uppercased() })
                
        guard let origin = originAirport, let destination = destinationAirport else {
            errorMessage = "Could not find airport for one of the IATA codes."
            return
        }
        
        let fullFlightNumber = manualAirlineCode.uppercased() + manualFlightNumber
        
        // For manual entry, we need to convert the local times to UTC properly
        guard let originTZ = TimeZone(identifier: origin.tz),
              let destTZ = TimeZone(identifier: destination.tz) else {
            errorMessage = "Could not determine timezone for airports."
            return
        }
        
        // Combine date and time in local timezone, then convert to UTC
        let localDepTime = combineDateAndTime(date: manualDepartureDate, time: manualDepartureTime)
        let localArrTime = combineDateAndTime(date: manualArrivalDate, time: manualArrivalTime)
        
        let utcDepTime = convertToUTC(date: localDepTime, fromTimezone: originTZ)
        let utcArrTime = convertToUTC(date: localArrTime, fromTimezone: destTZ)
        
        let depTimestamp = Timestamp(date: utcDepTime)
        let arrTimestamp = Timestamp(date: utcArrTime)
                
        let flightToSave = Flight(
            tourId: tourID,
            airline: manualAirlineName,
            flightNumber: fullFlightNumber,
            departureTimeUTC: depTimestamp,
            arrivalTimeUTC: arrTimestamp,
            origin: origin.iata,
            destination: destination.iata,
            notes: notes,
            passengers: passengerEntries
        )
                
        saveFlight(flightToSave, originAirport: origin, destinationAirport: destination)
    }
    
    func saveFlight(_ flight: Flight?) {
        guard let flight = flight else {
            errorMessage = "No flight data to save."
            return
        }
                
        let originAirport = allAirports.first(where: { $0.iata == flight.origin })
        let destinationAirport = allAirports.first(where: { $0.iata == flight.destination })
        
        guard let origin = originAirport, let destination = destinationAirport else {
            errorMessage = "Could not find airport details for this flight."
            return
        }
                
        saveFlight(flight, originAirport: origin, destinationAirport: destination)
    }
        
    func saveFlight(_ flight: Flight, originAirport: AirportEntry, destinationAirport: AirportEntry) {
        isLoading = true
        var flightToSave = flight
        flightToSave.passengers = self.passengerEntries
                
        FirebaseFlightService.saveFlight(flightToSave, originAirport: originAirport, destinationAirport: destinationAirport) { error, newFlightID in
            self.isLoading = false
            if let error = error {
                self.errorMessage = "Failed to save flight: \(error.localizedDescription)"
                return
            }
            self.onFlightAdded()
            self.dismiss()
        }
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
    
    // New helper function to convert local time to UTC
    func convertToUTC(date: Date, fromTimezone: TimeZone) -> Date {
        let utcCalendar = Calendar.current
        var localCalendar = Calendar.current
        localCalendar.timeZone = fromTimezone
        
        // Get the components in the local timezone
        let components = localCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Create the date in UTC
        return utcCalendar.date(from: components) ?? date
    }
        
    func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
                
        return calendar.date(from: combined) ?? Date()
    }
}
