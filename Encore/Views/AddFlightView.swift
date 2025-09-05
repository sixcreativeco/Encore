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
        VStack(alignment: .leading, spacing: 12) {
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
            
            HStack(alignment: .bottom, spacing: 12) {
                StyledInputField(placeholder: "Search Crew by Name...", text: $guestSearchText)
                StyledInputField(placeholder: "Baggage (kg)", text: $guestBaggage)
                    .frame(width: 120)
                
                // --- THIS IS THE FIX: Using smaller, white button ---
                ActionButton(title: "Add", icon: "plus", color: .white, textColor: .black, action: addPassenger)
                    .disabled(guestSearchText.isEmpty)
            }
           
           if !filteredCrewSuggestions.isEmpty {
               ScrollView {
                   VStack(alignment: .leading, spacing: 0) {
                       ForEach(filteredCrewSuggestions) { crew in
                           Button(action: {
                               guestSearchText = crew.name
                           }) {
                               HStack { Text(crew.name); Spacer() }.padding(8)
                           }.buttonStyle(.plain)
                       }
                   }
               }.background(Color.gray.opacity(0.1)).cornerRadius(8).frame(maxHeight: 150)
           }
        }
    }
        
    private func addPassenger() {
        // --- THIS IS THE FIX: Logic now correctly checks suggestions ---
        guard let crewMember = filteredCrewSuggestions.first(where: { $0.name.lowercased() == guestSearchText.lowercased() }) ?? tourCrew.first(where: { $0.name.lowercased() == guestSearchText.lowercased() }),
              let crewID = crewMember.id else {
            // Optional: Add user feedback here if the name is not found
            return
        }
        let newEntry = Passenger(crewId: crewID, baggage: guestBaggage.isEmpty ? nil : guestBaggage)
        if !passengerEntries.contains(where: { $0.crewId == crewID }) {
            passengerEntries.append(newEntry)
        }
        guestSearchText = ""
        guestBaggage = ""
    }
}

struct AddFlightView: View {
    var tour: Tour
    var onFlightAdded: () -> Void
    @Environment(\.dismiss) var dismiss
        
    enum EntryMode: String, CaseIterable, Identifiable {
        case autoSearch = "Search", manual = "Manual Entry"
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
    @State private var manualDepartureTime = defaultTime(hour: 9)
    @State private var manualArrivalTime = defaultTime(hour: 17)
    
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
        VStack(alignment: .leading, spacing: 0) {
            header
            
            modeSwitcher
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            footer
        }
        .onAppear(perform: loadCrew)
        .frame(minWidth: 700, minHeight: 800)
    }
    
    // MARK: - Main UI Sections
        
    private var header: some View {
        HStack {
            Text("Add Flight").font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
            }.buttonStyle(.plain)
        }
        .padding(32)
    }
    
    private var modeSwitcher: some View {
        HStack(spacing: 12) {
            ForEach(EntryMode.allCases) { mode in
                Button(action: { entryMode = mode }) {
                    Text(mode.rawValue)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(entryMode == mode ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(entryMode == mode ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                if entryMode == .autoSearch {
                    if fetchedFlight == nil {
                        ActionButton(title: "Search Flight", icon: "magnifyingglass", color: .accentColor, isLoading: isLoading, action: findFlight)
                            .disabled(autoFlightNumber.isEmpty || autoSelectedAirport == nil)
                    } else {
                        ActionButton(title: "Confirm & Add Flight", icon: "checkmark", color: .white, textColor: .black, isLoading: isLoading) {
                            saveFlight(fetchedFlight)
                        }
                    }
                } else {
                    ActionButton(title: "Save Manual Flight", icon: "plus", color: .accentColor, isLoading: isLoading, action: saveManualFlight)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical)
        .background(Material.bar)
    }
    
    // MARK: - Auto & Manual Views
    
    private var autoSearchView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Departure Airport").font(.subheadline.bold()).foregroundColor(.gray)
                    AirportSearchView(title: "", selection: $autoSelectedAirport, searchText: $autoAirportSearchText)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flight Date").font(.subheadline.bold()).foregroundColor(.gray)
                    CustomDateField(date: $autoFlightDate)
                }
            }
            StyledInputField(placeholder: "Flight Number (e.g. NZ102)", text: $autoFlightNumber)
            
            if fetchedFlight != nil {
                flightPreview(fetchedFlight)
                passengersSection
            }
        }
    }
    
    private var manualEntryView: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                StyledInputField(placeholder: "Airline Name", text: $manualAirlineName)
                StyledInputField(placeholder: "Code", text: $manualAirlineCode)
                    .frame(width: 80)
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
                    Text("Departure").font(.headline)
                    CustomDateField(date: $manualDepartureDate)
                    StyledTimePicker(label: "", time: $manualDepartureTime)
                }
                VStack(alignment: .leading) {
                    Text("Arrival").font(.headline)
                    CustomDateField(date: $manualArrivalDate)
                    StyledTimePicker(label: "", time: $manualArrivalTime)
                }
            }
            
            HStack(spacing: 16) {
                AirportSearchView(title: "Departure Airport", selection: $manualDepartureAirport, searchText: $manualDepartureSearchText)
                AirportSearchView(title: "Arrival Airport", selection: $manualArrivalAirport, searchText: $manualArrivalSearchText)
            }
            .onChange(of: manualArrivalAirport) { _, newAirport in
                destinationForVisaCheck = newAirport
                if newAirport != nil { isVisaSectionExpanded = true }
            }
         
            passengersSection
        }
    }
    
    // MARK: - Shared Subviews & Logic
        
    private var passengersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Passengers").font(.headline)
            GuestInputView(tourCrew: $tourCrew, passengerEntries: $passengerEntries)
        }
    }
        
    @ViewBuilder
    private func flightPreview(_ flight: Flight?) -> some View {
        if let flight = flight {
            VStack(alignment: .leading, spacing: 8) {
                Text("Flight Found").font(.headline)
                
                HStack {
                    AirlineLogoView(airlineCode: String(flight.flightNumber?.prefix(2) ?? ""), isIcon: true)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading) {
                        Text("\(flight.airline ?? "N/A") \(flight.flightNumber ?? "N/A")").font(.subheadline)
                        Text("\(flight.origin) → \(flight.destination)")
                    }
                    Spacer()
                }
                
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
    
    private static func defaultTime(hour: Int) -> Date { Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date() }
    func loadCrew() { Task { do { self.tourCrew = try await FirebaseTourService.loadCrew(forTour: tour.id ?? "") } catch { print("❌ DEBUG: Error loading crew: \(error.localizedDescription)") } } }
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
                        var depDate = self.createDateInTimezone(date: self.autoFlightDate, timeString: match.departureTime?.time24 ?? "00:00", timezone: depTZ)
                        var arrDate = self.createDateInTimezone(date: self.autoFlightDate, timeString: match.arrivalTime?.time24 ?? "00:00", timezone: arrTZ)
                        if arrDate < depDate {
                            arrDate = Calendar.current.date(byAdding: .day, value: 1, to: arrDate) ?? arrDate
                        }
                        self.fetchedFlight = Flight(
                            tourId: self.tour.id ?? "", ownerId: self.tour.ownerId, airline: match.carrier.name, flightNumber: "\(match.carrier.fs)\(match.carrier.flightNumber)",
                            departureTimeUTC: Timestamp(date: depDate), arrivalTimeUTC: Timestamp(date: arrDate),
                            origin: dep.iata, destination: arr.iata, notes: self.notes, passengers: []
                        )
                    } else {
                        self.errorMessage = "The automatic search couldn't find any flights for this date. Please double-check the details or use Manual Entry."
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    func saveManualFlight() {
        guard let tourID = tour.id, !manualAirlineName.isEmpty, !manualAirlineCode.isEmpty, !manualFlightNumber.isEmpty,
              let originAirport = manualDepartureAirport, let destinationAirport = manualArrivalAirport else {
            errorMessage = "Please fill all required fields, including valid airports."
            return
        }
        let fullFlightNumber = manualAirlineCode.uppercased() + manualFlightNumber
        guard let originTZ = TimeZone(identifier: originAirport.tz), let destTZ = TimeZone(identifier: destinationAirport.tz) else {
            errorMessage = "Could not determine timezone for airports."
            return
        }
        let localDepTime = combineDateAndTime(date: manualDepartureDate, time: manualDepartureTime, in: originTZ)
        let localArrTime = combineDateAndTime(date: manualArrivalDate, time: manualArrivalTime, in: destTZ)
        let depTimestamp = Timestamp(date: localDepTime)
        let arrTimestamp = Timestamp(date: localArrTime)
        let flightToSave = Flight(
            tourId: tourID, ownerId: self.tour.ownerId, airline: manualAirlineName, flightNumber: fullFlightNumber,
            departureTimeUTC: depTimestamp, arrivalTimeUTC: arrTimestamp,
            origin: originAirport.iata, destination: destinationAirport.iata, notes: notes, passengers: passengerEntries
        )
        saveFlight(flightToSave, originAirport: originAirport, destinationAirport: destinationAirport)
    }
    func saveFlight(_ flight: Flight?) {
        guard let flight = flight else { errorMessage = "No flight data to save."; return }
        let originAirport = allAirports.first(where: { $0.iata == flight.origin })
        let destinationAirport = allAirports.first(where: { $0.iata == flight.destination })
        guard let origin = originAirport, let destination = destinationAirport else { errorMessage = "Could not find airport details for this flight."; return }
        saveFlight(flight, originAirport: origin, destinationAirport: destination)
    }
    func saveFlight(_ flight: Flight, originAirport: AirportEntry, destinationAirport: AirportEntry) {
        isLoading = true; var flightToSave = flight; flightToSave.passengers = self.passengerEntries
        FirebaseFlightService.saveFlight(flightToSave, originAirport: originAirport, destinationAirport: destinationAirport) { error, newFlightID in
            self.isLoading = false
            if let error = error { self.errorMessage = "Failed to save flight: \(error.localizedDescription)"; return }
            self.onFlightAdded(); self.dismiss()
        }
    }
    func createDateInTimezone(date: Date, timeString: String, timezone: TimeZone) -> Date {
        var calendar = Calendar.current; calendar.timeZone = timezone
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = timeString.split(separator: ":")
        let hour = Int(timeComponents.first ?? "0") ?? 0
        let minute = Int(timeComponents.last ?? "0") ?? 0
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year; finalComponents.month = dateComponents.month; finalComponents.day = dateComponents.day
        finalComponents.hour = hour; finalComponents.minute = minute
        return calendar.date(from: finalComponents) ?? date
    }
    func combineDateAndTime(date: Date, time: Date, in timezone: TimeZone) -> Date {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        var combined = DateComponents(); combined.year = dateComponents.year; combined.month = dateComponents.month; combined.day = dateComponents.day
        combined.hour = timeComponents.hour; combined.minute = timeComponents.minute
        var calendar = Calendar.current; calendar.timeZone = timezone
        return calendar.date(from: combined) ?? Date()
    }
}


// MARK: - Reusable Helper Views (assumed to be available)

fileprivate struct AirportSearchView: View {
    let title: String
    @Binding var selection: AirportEntry?
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    // --- THIS IS THE FIX: Added debounce logic ---
    @State private var debouncedSearchText: String = ""
    private let textUpdatePublisher = PassthroughSubject<String, Never>()
    
    private let allAirports = AirportService.shared.airports
    
    private var filteredAirports: [AirportEntry] {
        if debouncedSearchText.isEmpty { return [] }
        let lowercasedSearch = debouncedSearchText.lowercased()
        return allAirports.filter {
            $0.name.lowercased().contains(lowercasedSearch) ||
            $0.city.lowercased().contains(lowercasedSearch) ||
            $0.iata.lowercased().contains(lowercasedSearch)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                Text(title).font(.subheadline.bold()).foregroundColor(.gray)
            }
            
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
                .background(Color.gray.opacity(0.1)).cornerRadius(10)
            } else {
                StyledInputField(placeholder: "Search airport or city...", text: $searchText)
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        textUpdatePublisher.send(newValue)
                    }
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
                .background(Color(nsColor: .controlBackgroundColor)).cornerRadius(8).frame(maxHeight: 150)
            }
        }
        .onReceive(textUpdatePublisher.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)) { newText in
            self.debouncedSearchText = newText
        }
    }
}

fileprivate struct CollapsibleSection<Content: View>: View {
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
