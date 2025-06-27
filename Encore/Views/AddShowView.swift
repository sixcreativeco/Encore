import SwiftUI
import FirebaseFirestore
import CoreLocation

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    
    var tourID: String
    var userID: String
    var artistName: String
    var onSave: () -> Void

    // Venue state
    @StateObject private var venueSearch = VenueSearchService()
    @State private var venueQuery = ""
    @State private var showVenueSuggestions = false
    @State private var selectedVenue: VenueResult?
    
    // Show details state
    @State private var city = ""
    @State private var country = ""
    @State private var venueName = ""
    @State private var address = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    
    // Date and time state
    @State private var showDate = Date()
    @State private var venueAccess = defaultTime(hour: 12)
    @State private var loadIn = defaultTime(hour: 15)
    @State private var soundCheck = defaultTime(hour: 17)
    @State private var doorsOpen = defaultTime(hour: 19)
    @State private var headlinerSetTime = defaultTime(hour: 20)
    @State private var packOut = defaultTime(hour: 23)
    @State private var packOutNextDay = false
    
    // Support Act State
    @State private var supportActs: [SupportActInput] = [SupportActInput()]
    @State private var allSupportActs: [String] = []
    
    @State private var headlinerSetDurationMinutes = 60

    // View State
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    struct SupportActInput: Identifiable {
        var id = UUID().uuidString
        var name = ""
        var type = "Touring"
        var soundCheck = defaultTime(hour: 16)
        var setTime = defaultTime(hour: 18)
        var changeoverMinutes = 15
        var suggestion = ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Text("Add Show").font(.largeTitle.bold())
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                }
                
                showDetailsSection
                timingSection
                supportActSection
                headlinerSection
                packOutSection
                saveButton
            }
            .padding()
            .onAppear {
                loadSupportActs()
                loadDefaultShowDate()
            }
            .alert("Save Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .frame(minWidth: 600, maxWidth: .infinity)
    }

    private var showDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date").font(.headline)
            StyledDateField(date: $showDate)
                 .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Venue").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                StyledInputField(placeholder: "Search for Venue...", text: $venueQuery)
                    .onChange(of: venueQuery) { _, newValue in
                        if newValue != selectedVenue?.name {
                            self.selectedVenue = nil
                            showVenueSuggestions = !newValue.isEmpty
                            venueSearch.searchVenues(query: newValue)
                        }
                    }
                
                if showVenueSuggestions && !venueSearch.results.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(venueSearch.results) { result in
                            Button(action: {
                                self.selectedVenue = result
                                self.venueName = result.name
                                self.address = result.address
                                self.city = result.city
                                self.country = result.country
                                self.venueQuery = result.name
                                self.showVenueSuggestions = false
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.name).font(.body)
                                    Text(result.address).font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding(8)
                        }
                    }
                    .background(Color.gray.opacity(0.1)).cornerRadius(8)
                }
            }
            HStack(spacing: 16) {
                StyledInputField(placeholder: "City", text: $city)
                StyledInputField(placeholder: "Country (optional)", text: $country)
            }
            StyledInputField(placeholder: "Address", text: $address)
            HStack(spacing: 16) {
                StyledInputField(placeholder: "Venue Contact Name", text: $contactName)
                StyledInputField(placeholder: "Email", text: $contactEmail)
                StyledInputField(placeholder: "Phone Number", text: $contactPhone)
            }
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timings").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Venue Access", time: $venueAccess)
                StyledTimePicker(label: "Load In", time: $loadIn)
                StyledTimePicker(label: "Soundcheck", time: $soundCheck)
                StyledTimePicker(label: "Doors", time: $doorsOpen)
            }
        }
    }
    
    private var supportActSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Acts").font(.headline)
            ForEach($supportActs) { $sa in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            ZStack(alignment: .leading) {
                                TextField("Name", text: $sa.name)
                                    .textFieldStyle(PlainTextFieldStyle()).padding(12)
                                    .background(Color.gray.opacity(0.06)).cornerRadius(10)
                                    .font(.body)
                                    .onChange(of: sa.name) { _, newValue in
                                        if let match = allSupportActs.first(where: { $0.lowercased().hasPrefix(newValue.lowercased()) }) {
                                            sa.suggestion = match
                                        } else {
                                            sa.suggestion = ""
                                        }
                                    }
                                    .onSubmit {
                                        if !sa.suggestion.isEmpty { sa.name = sa.suggestion }
                                    }
                                if !sa.suggestion.isEmpty && sa.suggestion.lowercased().hasPrefix(sa.name.lowercased()) && sa.name != sa.suggestion {
                                    let remaining = String(sa.suggestion.dropFirst(sa.name.count))
                                    HStack(spacing: 0) {
                                        Text(sa.name)
                                        Text(remaining).foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding(12).allowsHitTesting(false)
                                }
                            }
                        }
                        StyledDropdown(label: "Type", selection: $sa.type, options: ["Touring", "Local"])
                            .frame(width: 160)
                    }
                    HStack(spacing: 16) {
                        StyledTimePicker(label: "Soundcheck", time: $sa.soundCheck)
                        StyledTimePicker(label: "Set Time", time: $sa.setTime)
                        Stepper("Changeover: \(sa.changeoverMinutes) min", value: $sa.changeoverMinutes, in: 0...60, step: 5)
                    }
                }
                Divider()
            }
            StyledButtonV2(title: "+ Add Support Act", action: { supportActs.append(SupportActInput()) }, showArrow: false, width: 200)
        }
    }

    private var headlinerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Headliner: \(artistName)").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Set Time", time: $headlinerSetTime)
                Stepper("Set Duration: \(headlinerSetDurationMinutes) min", value: $headlinerSetDurationMinutes, in: 0...300, step: 5)
            }
        }
    }

    private var packOutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pack Out").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Time", time: $packOut)
                Toggle(isOn: $packOutNextDay) { Text("Next Day") }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #else
                .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var saveButton: some View {
        Button(action: { Task { await saveShow() } }) {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().colorInvert()
                } else {
                    Text("Save Show").fontWeight(.semibold)
                }
                Spacer()
            }
            .padding()
            .background(isSaving ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func getEventTimezone() async throws -> TimeZone {
        if let timeZone = selectedVenue?.timeZone { return timeZone }
        
        guard !address.isEmpty else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please select a venue from the search results or enter a full address to determine the timezone."])
        }
        
        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.geocodeAddressString(address)
        
        if let timeZone = placemarks?.first?.timeZone {
            return timeZone
        } else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine a timezone for the address entered. Please check the address is complete."])
        }
    }
    
    // --- THIS FUNCTION CONTAINS THE CORE FIX ---
    private func saveShow() async {
        isSaving = true
        do {
            let eventTimeZone = try await getEventTimezone()
            
            // This helper function now correctly creates a Timestamp based on the venue's timezone.
            func createTimestampInEventZone(for time: Date, on day: Date, in timezone: TimeZone) -> Timestamp {
                let localCalendar = Calendar.current
                let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: day)
                let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
                
                var eventCalendar = Calendar(identifier: .gregorian)
                eventCalendar.timeZone = timezone

                var finalComponents = DateComponents()
                finalComponents.year = dateComponents.year
                finalComponents.month = dateComponents.month
                finalComponents.day = dateComponents.day
                finalComponents.hour = timeComponents.hour
                finalComponents.minute = timeComponents.minute
                finalComponents.timeZone = timezone
                
                let finalDate = eventCalendar.date(from: finalComponents) ?? Date()
                return Timestamp(date: finalDate)
            }
            
            let db = Firestore.firestore()
            let batch = db.batch()
            var supportActIDsToSave: [String] = []

            for sa in supportActs.filter({ !$0.name.isEmpty }) {
                let actRef = db.collection("supportActs").document()
                let newSupportAct = SupportAct(tourId: self.tourID, name: sa.name.trimmingCharacters(in: .whitespacesAndNewlines), type: SupportAct.ActType(rawValue: sa.type) ?? .Touring, contactEmail: nil)
                try batch.setData(from: newSupportAct, forDocument: actRef)
                supportActIDsToSave.append(actRef.documentID)
            }
            
            var packOutDate = createTimestampInEventZone(for: packOut, on: showDate, in: eventTimeZone).dateValue()
            if packOutNextDay {
                packOutDate = Calendar.current.date(byAdding: .day, value: 1, to: packOutDate) ?? packOutDate
            }

            var newShow = Show(
                tourId: self.tourID,
                date: createTimestampInEventZone(for: showDate, on: showDate, in: eventTimeZone),
                city: city, country: country.isEmpty ? nil : country,
                venueName: venueName, venueAddress: address,
                timezone: eventTimeZone.identifier,
                contactName: contactName.isEmpty ? nil : contactName,
                contactEmail: contactEmail.isEmpty ? nil : contactEmail,
                contactPhone: contactPhone.isEmpty ? nil : contactPhone,
                venueAccess: createTimestampInEventZone(for: venueAccess, on: showDate, in: eventTimeZone),
                loadIn: createTimestampInEventZone(for: loadIn, on: showDate, in: eventTimeZone),
                soundCheck: createTimestampInEventZone(for: soundCheck, on: showDate, in: eventTimeZone),
                doorsOpen: createTimestampInEventZone(for: doorsOpen, on: showDate, in: eventTimeZone),
                headlinerSetTime: createTimestampInEventZone(for: headlinerSetTime, on: showDate, in: eventTimeZone),
                headlinerSetDurationMinutes: headlinerSetDurationMinutes,
                packOut: Timestamp(date: packOutDate),
                packOutNextDay: packOutNextDay,
                supportActIds: supportActIDsToSave.isEmpty ? nil : supportActIDsToSave
            )
            
            let showRef = db.collection("shows").document()
            try batch.setData(from: newShow, forDocument: showRef)
            newShow.id = showRef.documentID
            
            createItineraryItems(for: newShow, batch: batch, eventTimeZone: eventTimeZone)
            
            try await batch.commit()
            
            await MainActor.run {
                self.onSave()
                self.dismiss()
            }
        } catch {
            await MainActor.run {
                self.alertMessage = error.localizedDescription
                self.showingAlert = true
                self.isSaving = false
            }
        }
    }

    private func createItineraryItems(for show: Show, batch: WriteBatch, eventTimeZone: TimeZone) {
        guard let showId = show.id else { return }
        
        func createItineraryItem(forDate date: Timestamp?, type: ItineraryItemType, title: String) {
            guard let date = date else { return }
            let item = ItineraryItem(
                tourId: self.tourID, showId: showId, title: title, type: type.rawValue, timeUTC: date,
                subtitle: nil, notes: nil, timezone: eventTimeZone.identifier,
                visibility: "Everyone", visibleTo: nil
            )
            let itemRef = Firestore.firestore().collection("itineraryItems").document()
            try? batch.setData(from: item, forDocument: itemRef)
        }
        
        createItineraryItem(forDate: show.venueAccess, type: .custom, title: "Venue Access")
        createItineraryItem(forDate: show.loadIn, type: .loadIn, title: "Load In")
        createItineraryItem(forDate: show.soundCheck, type: .soundcheck, title: "Soundcheck")
        createItineraryItem(forDate: show.doorsOpen, type: .doors, title: "Doors Open")
        createItineraryItem(forDate: show.headlinerSetTime, type: .headline, title: "\(self.artistName) Set")
        createItineraryItem(forDate: show.packOut, type: .packOut, title: "Pack Out")

        for sa in supportActs.filter({ !$0.name.isEmpty }) {
            // This logic needs to be timezone-aware as well
            var calendar = Calendar.current
            calendar.timeZone = eventTimeZone
            let showDayComponents = calendar.dateComponents([.year, .month, .day], from: show.date.dateValue())

            var soundcheckComponents = calendar.dateComponents([.hour, .minute], from: sa.soundCheck)
            soundcheckComponents.year = showDayComponents.year
            soundcheckComponents.month = showDayComponents.month
            soundcheckComponents.day = showDayComponents.day
            let soundcheckDate = calendar.date(from: soundcheckComponents) ?? Date()

            var setTimeComponents = calendar.dateComponents([.hour, .minute], from: sa.setTime)
            setTimeComponents.year = showDayComponents.year
            setTimeComponents.month = showDayComponents.month
            setTimeComponents.day = showDayComponents.day
            let setTimeDate = calendar.date(from: setTimeComponents) ?? Date()

            createItineraryItem(forDate: Timestamp(date: soundcheckDate), type: .soundcheck, title: "\(sa.name) Soundcheck")
            createItineraryItem(forDate: Timestamp(date: setTimeDate), type: .custom, title: "\(sa.name) Set")
        }
    }

    private func loadSupportActs() {
        let db = Firestore.firestore()
        db.collection("supportActs").whereField("tourId", isEqualTo: tourID)
            .getDocuments { snapshot, _ in
                self.allSupportActs = snapshot?.documents.compactMap { try? $0.data(as: SupportAct.self).name } ?? []
            }
    }
    
    private func loadDefaultShowDate() {
        let db = Firestore.firestore()
        db.collection("tours").document(tourID).getDocument { snapshot, _ in
            if let tour = try? snapshot?.data(as: Tour.self) {
                self.showDate = tour.startDate.dateValue()
            }
        }
    }

    private static func defaultTime(hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
