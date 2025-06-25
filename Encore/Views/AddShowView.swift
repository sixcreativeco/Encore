import SwiftUI
import FirebaseFirestore

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    
    var tourID: String
    var userID: String // This is the ownerId
    var artistName: String
    var onSave: () -> Void

    @State private var city = ""
    @State private var country = ""
    @State private var venue = ""
    @State private var address = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var date = Date()
    @State private var venueAccess = defaultTime(hour: 12)
    @State private var loadIn = defaultTime(hour: 15)
    @State private var soundCheck = defaultTime(hour: 17)
    @State private var doorsOpen = defaultTime(hour: 19)

    @State private var supportActs: [SupportActInput] = [SupportActInput()]
    @State private var allSupportActs: [String] = []

    @State private var headlinerSetTime = defaultTime(hour: 20)
    @State private var headlinerSetDurationMinutes = 60

    @State private var packOut = defaultTime(hour: 23)
    @State private var packOutNextDay = false

    @StateObject private var venueSearch = VenueSearchService()
    @State private var venueQuery = ""
    @State private var showVenueSuggestions = false

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
                headerSection
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
        }
        .frame(minWidth: 600, maxWidth: .infinity)
    }

    private var headerSection: some View {
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
    }

    private var showDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date").font(.headline)
            HStack {
                StyledDateField(date: $date)
                    .frame(width: 200)
                    .padding(.leading, -40)
                Spacer()
            }
            .padding(.bottom, -8)
            Text("Venue").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                StyledInputField(placeholder: "Venue", text: $venueQuery)
                    .onChange(of: venueQuery) { _, newValue in
                        showVenueSuggestions = !newValue.isEmpty
                        venueSearch.searchVenues(query: newValue)
                    }
                if showVenueSuggestions && !venueSearch.results.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(venueSearch.results.prefix(5)) { result in
                            Button(action: {
                                venue = result.name; address = result.address; city = result.city
                                country = result.country; venueQuery = result.name; showVenueSuggestions = false
                                venueSearch.results = []
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
                Toggle(isOn: $packOutNextDay) {
                    Text("Next Day")
                }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #else
                .toggleStyle(.switch)
                #endif
            }
        }
    }

    private var saveButton: some View {
        StyledButtonV2(title: "Save Show", action: saveShow, fullWidth: true, showArrow: true)
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
                self.date = tour.startDate.dateValue()
            }
        }
    }
    
    private func createFullDate(for time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self.date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
    
    private func saveShow() {
        let finalVenueAccess = Timestamp(date: createFullDate(for: venueAccess))
        let finalLoadIn = Timestamp(date: createFullDate(for: loadIn))
        let finalSoundCheck = Timestamp(date: createFullDate(for: soundCheck))
        let finalDoorsOpen = Timestamp(date: createFullDate(for: doorsOpen))
        let finalHeadlinerSetTime = Timestamp(date: createFullDate(for: headlinerSetTime))
        
        var finalPackOutDate = createFullDate(for: packOut)
        if packOutNextDay {
            finalPackOutDate = Calendar.current.date(byAdding: .day, value: 1, to: finalPackOutDate) ?? finalPackOutDate
        }
        let finalPackOut = Timestamp(date: finalPackOutDate)
        
        let db = Firestore.firestore()
        var supportActIDsToSave: [String] = []
        let batch = db.batch()

        for sa in supportActs.filter({ !$0.name.isEmpty }) {
            let trimmedName = sa.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let newSupportAct = SupportAct(
                tourId: self.tourID,
                name: trimmedName,
                type: SupportAct.ActType(rawValue: sa.type) ?? .Touring,
                contactEmail: nil
            )
            let actRef = db.collection("supportActs").document()
            _ = try? batch.setData(from: newSupportAct, forDocument: actRef)
            supportActIDsToSave.append(actRef.documentID)
        }

        var newShow = Show(
            tourId: self.tourID,
            date: Timestamp(date: date),
            city: city,
            country: country.isEmpty ? nil : country,
            venueName: venueQuery,
            venueAddress: address,
            contactName: contactName.isEmpty ? nil : contactName,
            contactEmail: contactEmail.isEmpty ? nil : contactEmail,
            contactPhone: contactPhone.isEmpty ? nil : contactPhone,
            venueAccess: finalVenueAccess,
            loadIn: finalLoadIn,
            soundCheck: finalSoundCheck,
            doorsOpen: finalDoorsOpen,
            headlinerSetTime: finalHeadlinerSetTime,
            headlinerSetDurationMinutes: headlinerSetDurationMinutes,
            packOut: finalPackOut,
            packOutNextDay: packOutNextDay,
            supportActIds: supportActIDsToSave.isEmpty ? nil : supportActIDsToSave
        )

        let showRef = db.collection("shows").document()
        _ = try? batch.setData(from: newShow, forDocument: showRef)
        newShow.id = showRef.documentID
        
        createItineraryItems(for: newShow, batch: batch)
        
        batch.commit { error in
            if let error = error {
                print("❌ Error saving show: \(error.localizedDescription)")
            } else {
                print("✅ Show, Support Acts, and Itinerary Items saved successfully.")
                self.onSave()
                self.dismiss()
            }
        }
    }
    
    private func createItineraryItems(for show: Show, batch: WriteBatch) {
        guard let showId = show.id else { return }
        let db = Firestore.firestore()

        func createItineraryItem(forDate date: Timestamp?, type: ItineraryItemType, title: String) {
            guard let date = date else { return }
            let item = ItineraryItem(tourId: self.tourID, showId: showId, title: title, type: type.rawValue, timeUTC: date)
            let itemRef = db.collection("itineraryItems").document()
            _ = try? batch.setData(from: item, forDocument: itemRef)
        }
        
        createItineraryItem(forDate: show.loadIn, type: .loadIn, title: "Load In")
        createItineraryItem(forDate: show.soundCheck, type: .soundcheck, title: "Soundcheck")
        createItineraryItem(forDate: show.doorsOpen, type: .doors, title: "Doors Open")
        createItineraryItem(forDate: show.headlinerSetTime, type: .headline, title: "\(self.artistName) Set")
        
        for sa in supportActs.filter({ !$0.name.isEmpty }) {
            createItineraryItem(forDate: Timestamp(date: createFullDate(for: sa.soundCheck)), type: .soundcheck, title: "\(sa.name) Soundcheck")
            createItineraryItem(forDate: Timestamp(date: createFullDate(for: sa.setTime)), type: .custom, title: "\(sa.name) Set")
        }
    }

    private static func defaultTime(hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
