import SwiftUI
import Combine
import FirebaseFirestore

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
    
    // Auto-Search State
    @State private var autoFlightNumber = ""
    @State private var autoFlightDate = Date()
    @State private var autoSelectedAirport: AirportEntry? = nil
    @State private var autoAirportSearchText = ""
    @FocusState private var isAutoAirportSearchFocused: Bool
    @State private var fetchedFlight: Flight? = nil

    // Manual-Entry State
    @State private var manualAirlineName = ""
    @State private var manualAirlineCode = ""
    @State private var manualFlightNumber = ""
    @State private var manualDepartureDate = Date()
    @State private var manualArrivalDate = Date()
    @State private var manualDepartureTime = Date()
    @State private var manualArrivalTime = Date()
    
    // --- FIX: Replaced simple IATA strings with full AirportEntry models and search text state ---
    @State private var manualDepartureAirport: AirportEntry?
    @State private var manualArrivalAirport: AirportEntry?
    @State private var manualDepartureSearchText: String = ""
    @State private var manualArrivalSearchText: String = ""
    
    // Shared State
    @State private var notes = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var tourCrew: [TourCrew] = []
    @State private var passengerEntries: [Passenger] = []
    
    // Visa Checker State
    @State private var destinationForVisaCheck: AirportEntry?
    @State private var isVisaSectionExpanded: Bool = false
    
    private let allAirports = AirportService.shared.airports
        
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
                
                if let destination = destinationForVisaCheck {
                    CollapsibleSection(isExpanded: $isVisaSectionExpanded, title: "Travel & Visa Information") {
                        VisaCheckerView(destinationAirport: destination)
                    }
                    .padding(.top)
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
            
            // --- FIX: This reusable component replaces the previous hardcoded version ---
            AirportSearchView(
                title: "Departure Airport",
                selection: $autoSelectedAirport,
                searchText: $autoAirportSearchText
            )
            
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
            
            // --- FIX: Replaced IATA text fields with the flexible search component ---
            HStack(spacing: 16) {
                AirportSearchView(title: "Departure Airport", selection: $manualDepartureAirport, searchText: $manualDepartureSearchText)
                AirportSearchView(title: "Arrival Airport", selection: $manualArrivalAirport, searchText: $manualArrivalSearchText)
            }
            .onChange(of: manualArrivalAirport) { _, newAirport in
                destinationForVisaCheck = newAirport
                if newAirport != nil {
                    isVisaSectionExpanded = true
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
                        
                        self.destinationForVisaCheck = arr
                        self.isVisaSectionExpanded = true
                        
                        let depDate = self.createDateInTimezone(date: self.autoFlightDate, timeString: match.departureTime?.time24 ?? "00:00", timezone: depTZ)
                        var arrDate = self.createDateInTimezone(date: self.autoFlightDate, timeString: match.arrivalTime?.time24 ?? "00:00", timezone: arrTZ)
                        
                        if arrDate < depDate {
                            arrDate = Calendar.current.date(byAdding: .day, value: 1, to: arrDate) ?? arrDate
                        }
                        
                        let utcDepDate = self.convertToUTC(date: depDate, fromTimezone: depTZ)
                        let utcArrDate = self.convertToUTC(date: arrDate, fromTimezone: arrTZ)
                                       
                        self.fetchedFlight = Flight(
                            tourId: self.tour.id ?? "",
                            ownerId: self.tour.ownerId,
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
        guard let tourID = tour.id,
              !manualAirlineName.isEmpty,
              !manualAirlineCode.isEmpty,
              !manualFlightNumber.isEmpty,
              let originAirport = manualDepartureAirport,
              let destinationAirport = manualArrivalAirport else {
            errorMessage = "Please fill all required fields, including valid airports."
            return
        }
                
        let fullFlightNumber = manualAirlineCode.uppercased() + manualFlightNumber
        
        guard let originTZ = TimeZone(identifier: originAirport.tz),
              let destTZ = TimeZone(identifier: destinationAirport.tz) else {
            errorMessage = "Could not determine timezone for airports."
            return
        }
        
        let localDepTime = combineDateAndTime(date: manualDepartureDate, time: manualDepartureTime)
        let localArrTime = combineDateAndTime(date: manualArrivalDate, time: manualArrivalTime)
        
        let utcDepTime = convertToUTC(date: localDepTime, fromTimezone: originTZ)
        let utcArrTime = convertToUTC(date: localArrTime, fromTimezone: destTZ)
        
        let depTimestamp = Timestamp(date: utcDepTime)
        let arrTimestamp = Timestamp(date: utcArrTime)
                
        let flightToSave = Flight(
            tourId: tourID,
            ownerId: self.tour.ownerId,
            airline: manualAirlineName,
            flightNumber: fullFlightNumber,
            departureTimeUTC: depTimestamp,
            arrivalTimeUTC: arrTimestamp,
            origin: originAirport.iata,
            destination: destinationAirport.iata,
            notes: notes,
            passengers: passengerEntries
        )
                
        saveFlight(flightToSave, originAirport: originAirport, destinationAirport: destinationAirport)
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
    
    func convertToUTC(date: Date, fromTimezone: TimeZone) -> Date {
        let utcCalendar = Calendar.current
        var localCalendar = Calendar.current
        localCalendar.timeZone = fromTimezone
        
        let components = localCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
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
    
    // --- FIX: Reusable airport search component ---
    private struct AirportSearchView: View {
        let title: String
        @Binding var selection: AirportEntry?
        @Binding var searchText: String
        @FocusState private var isFocused: Bool
        
        private let allAirports = AirportService.shared.airports
        
        private var filteredAirports: [AirportEntry] {
            if searchText.isEmpty { return [] }
            return allAirports.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.city.lowercased().contains(searchText.lowercased()) ||
                $0.iata.lowercased().contains(searchText.lowercased())
            }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title).font(.subheadline)
                if let selected = selection {
                    HStack {
                        Text(selected.name).padding(.vertical, 8).padding(.leading, 12)
                        Spacer()
                        Button(action: {
                            self.selection = nil
                            self.searchText = ""
                            self.isFocused = true
                        }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain).padding(.trailing, 8)
                    }
                    .background(Color.gray.opacity(0.2)).cornerRadius(8)
                } else {
                    TextField("Start typing airport or city...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                }
                
                if isFocused && !filteredAirports.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredAirports) { airport in
                                HStack {
                                    Text(airport.name).padding(8)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.selection = airport
                                    self.searchText = ""
                                    self.isFocused = false
                                }
                                Divider()
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.1)).cornerRadius(8).frame(maxHeight: 200)
                }
            }
        }
    }
}

// Reusable Collapsible Section View
private struct CollapsibleSection<Content: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right").rotationEffect(.degrees(isExpanded ? 90 : 0))
                }.foregroundColor(.primary)
            }.buttonStyle(.plain)
            
            if isExpanded {
                content()
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
