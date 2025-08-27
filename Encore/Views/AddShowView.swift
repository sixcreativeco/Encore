import SwiftUI
import FirebaseFirestore
import CoreLocation

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    
    var tourID: String
    var userID: String
    var artistName: String
    var onSave: () -> Void

    // Network & Search Services
    @StateObject private var syncManager = OfflineSyncManager.shared
    @StateObject private var venueSearch = VenueSearchService()

    // Form State
    @State private var venueQuery = ""
    @State private var showVenueSuggestions = false
    @State private var selectedVenue: VenueResult?
    @State private var selectedTimezoneIdentifier: String = TimeZone.current.identifier
    
    @State private var city = ""
    @State private var country = ""
    @State private var venueName = ""
    @State private var address = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var showDate = Date()
    
    @State private var venueAccess: Date? = defaultTime(hour: 12)
    @State private var loadIn: Date? = defaultTime(hour: 15)
    @State private var soundCheck: Date? = defaultTime(hour: 17)
    @State private var doorsOpen: Date? = defaultTime(hour: 19)
    @State private var headline: Date? = defaultTime(hour: 20)
    @State private var packOut: Date? = defaultTime(hour: 23)
    
    @State private var supportActs: [SupportActInput] = []
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
        var soundCheck: Date? = defaultTime(hour: 16)
        var setTime: Date? = defaultTime(hour: 18)
        var changeoverMinutes = 15
        var suggestion = ""
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                showDetailsSection
                timingSection
                headlinerDetailsSection
                packOutSection
                supportActSection
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
        .frame(minWidth: 700, maxWidth: .infinity)
    }

    private var header: some View {
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
            StyledDateField(date: $showDate).frame(maxWidth: .infinity, alignment: .leading)
            Text("Venue").font(.headline)
            StyledInputField(placeholder: "Search for Venue...", text: $venueQuery)
                .onChange(of: venueQuery) { _, newValue in
                    if newValue != selectedVenue?.name {
                        self.selectedVenue = nil
                        showVenueSuggestions = !newValue.isEmpty
                        if syncManager.isOnline { venueSearch.searchVenues(query: newValue) }
                    }
                }
            if showVenueSuggestions && !venueSearch.results.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(venueSearch.results.prefix(5)) { result in
                        Button(action: { selectVenue(result) }) {
                            VStack(alignment: .leading) {
                                Text(result.name).font(.body)
                                Text(result.address).font(.caption).foregroundColor(.gray)
                            }.padding(8)
                        }.buttonStyle(.plain)
                    }
                }.background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
            }
            HStack(spacing: 16) {
                StyledInputField(placeholder: "Address", text: $address)
                timezonePicker.frame(width: 200)
            }
            HStack(spacing: 16) {
                StyledInputField(placeholder: "City", text: $city)
                StyledInputField(placeholder: "Country (optional)", text: $country)
            }
            HStack(spacing: 16) {
                StyledInputField(placeholder: "Venue Contact Name", text: $contactName)
                StyledInputField(placeholder: "Email", text: $contactEmail)
                StyledInputField(placeholder: "Phone Number", text: $contactPhone)
            }
        }
    }
    
    private var timezonePicker: some View {
        Menu {
            ForEach(TimezoneHelper.regions) { region in
                Section(header: Text(region.name)) {
                    ForEach(region.timezones) { timezone in
                        Button(timezone.name) { self.selectedTimezoneIdentifier = timezone.identifier }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedTimezoneIdentifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? "Select")
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding(10).background(Color.black.opacity(0.15)).cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timings").font(.headline)
            HStack(spacing: 8) {
                timingCell(label: "Venue Access", selection: $venueAccess)
                timingCell(label: "Load In", selection: $loadIn)
                timingCell(label: "Soundcheck", selection: $soundCheck)
                timingCell(label: "Doors Open", selection: $doorsOpen)
                Spacer()
            }
        }
    }

    private var headlinerDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Headliner: \(artistName)").font(.headline)
            HStack(alignment: .top, spacing: 0) { // ← Adjust this spacing to control the gap between Headliner Set and Set Duration
                timingCell(label: "Headliner Set", selection: $headline)
                    .frame(width: 100)

                durationCell(label: "Set Duration", minutes: $headlinerSetDurationMinutes)
                    .frame(width: 100)
            }
        }
    }
    
    private var packOutSection: some View {
        HStack {
            timingCell(label: "Pack Out", selection: $packOut)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func timingCell(label: String, selection: Binding<Date?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.gray)
                if selection.wrappedValue != nil {
                    Button(action: {
                        withAnimation { selection.wrappedValue = nil }
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(height: 16)

            if let dateBinding = Binding(selection) {
                DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden().datePickerStyle(.compact)
                    .padding(.horizontal, 8).padding(.vertical, 7)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10).frame(height: 44)
            } else {
                Button(action: {
                    withAnimation {
                        selection.wrappedValue = Self.defaultTime(hour: 12)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .foregroundColor(Color.gray.opacity(0.3))
                )
            }
        }
        // --- FIX: The expanding frame modifier has been removed ---
    }

    @ViewBuilder
    private func durationCell(label: String, minutes: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(.gray)
                .frame(height: 16)
            Stepper("\(minutes.wrappedValue) min", value: minutes, in: 0...300, step: 5)
                .padding(.leading, 8)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .frame(height: 44)
        }
    }
    
    private var supportActSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Acts").font(.headline)
            ForEach($supportActs) { $sa in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        StyledInputField(placeholder: "Name", text: $sa.name)
                        StyledDropdown(label: "Type", selection: $sa.type, options: ["Touring", "Local"])
                            .frame(width: 160)
                    }
                    HStack(spacing: 16) {
                        timingCell(label: "Soundcheck", selection: $sa.soundCheck)
                        timingCell(label: "Set Time", selection: $sa.setTime)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Changeover")
                                .font(.subheadline.bold())
                                .foregroundColor(.gray)
                                .frame(height: 16)
                            Stepper("\(sa.changeoverMinutes) min", value: $sa.changeoverMinutes, in: 0...60, step: 5)
                                .padding(.leading, 8).padding(.vertical, 7)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(10).frame(height: 44)
                        }
                    }
                }
                Divider()
            }
            StyledButtonV2(title: "+ Add Support Act", action: { supportActs.append(SupportActInput()) }, showArrow: false, width: 200)
        }
    }

    private var saveButton: some View {
        Button(action: { Task { await saveShow() } }) {
            HStack {
                Spacer()
                if isSaving { ProgressView().colorInvert() } else { Text("Save Show").fontWeight(.semibold) }
                Spacer()
            }
            .padding().background(isSaving ? Color.gray : Color.accentColor).foregroundColor(.white).cornerRadius(12)
        }
        .buttonStyle(.plain).disabled(isSaving)
    }
    
    private func selectVenue(_ result: VenueResult) {
        self.selectedVenue = result; self.venueName = result.name; self.address = result.address; self.city = result.city; self.country = result.country; self.venueQuery = result.name; self.showVenueSuggestions = false
        if let timezone = result.timeZone { self.selectedTimezoneIdentifier = timezone.identifier }
    }

    private func saveShow() async {
        isSaving = true
        let eventTimeZone = TimeZone(identifier: selectedTimezoneIdentifier) ?? .current
        func createOptionalTimestamp(for time: Date?, on day: Date, in timezone: TimeZone) -> Timestamp? {
            guard let time = time else { return nil }
            let localCalendar = Calendar.current
            let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: day)
            let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
            var eventCalendar = Calendar(identifier: .gregorian); eventCalendar.timeZone = timezone
            var finalComponents = DateComponents();
            finalComponents.year = dateComponents.year; finalComponents.month = dateComponents.month; finalComponents.day = dateComponents.day; finalComponents.hour = timeComponents.hour; finalComponents.minute = timeComponents.minute;
            finalComponents.timeZone = timezone
            guard let finalDate = eventCalendar.date(from: finalComponents) else { return nil }
            return Timestamp(date: finalDate)
        }
        do {
            let db = Firestore.firestore()
            let batch = db.batch()
            var supportActIDsToSave: [String] = []
            for sa in supportActs.filter({ !$0.name.isEmpty }) {
                let actRef = db.collection("supportActs").document()
                let newSupportAct = SupportAct(tourId: self.tourID, name: sa.name.trimmingCharacters(in: .whitespacesAndNewlines), type: SupportAct.ActType(rawValue: sa.type) ?? .Touring, contactEmail: nil)
                try batch.setData(from: newSupportAct, forDocument: actRef)
                supportActIDsToSave.append(actRef.documentID)
            }
            
            let newShow = Show(tourId: self.tourID, date: createOptionalTimestamp(for: showDate, on: showDate, in: eventTimeZone)!, city: city, country: country.isEmpty ? nil : country, venueName: venueName, venueAddress: address, timezone: eventTimeZone.identifier, contactName: contactName.isEmpty ? nil : contactName, contactEmail: contactEmail.isEmpty ? nil : contactEmail, contactPhone: contactPhone.isEmpty ? nil : contactPhone, venueAccess: createOptionalTimestamp(for: venueAccess, on: showDate, in: eventTimeZone), loadIn: createOptionalTimestamp(for: loadIn, on: showDate, in: eventTimeZone), soundCheck: createOptionalTimestamp(for: soundCheck, on: showDate, in: eventTimeZone), doorsOpen: createOptionalTimestamp(for: doorsOpen, on: showDate, in: eventTimeZone), headlinerSetTime: createOptionalTimestamp(for: headline, on: showDate, in: eventTimeZone), headlinerSetDurationMinutes: headlinerSetDurationMinutes, packOut: createOptionalTimestamp(for: packOut, on: showDate, in: eventTimeZone), supportActIds: supportActIDsToSave.isEmpty ? nil : supportActIDsToSave)
            
            let showRef = db.collection("shows").document()
            try batch.setData(from: newShow, forDocument: showRef)
            
            let allTimings: [ItineraryItemType: Date?] = [.venueAccess: venueAccess, .loadIn: loadIn, .soundcheck: soundCheck, .doors: doorsOpen, .headline: headline, .packOut: packOut]
            for (type, time) in allTimings {
                guard let date = time, let timestamp = createOptionalTimestamp(for: date, on: self.showDate, in: eventTimeZone) else { continue }
                let item = ItineraryItem(ownerId: self.userID, tourId: self.tourID, showId: showRef.documentID, title: type.displayName, type: type.rawValue, timeUTC: timestamp, isShowTiming: true)
                let itemRef = db.collection("itineraryItems").document()
                try batch.setData(from: item, forDocument: itemRef)
            }
            
            try await batch.commit()
            await MainActor.run { self.onSave(); self.dismiss() }
        } catch {
            await MainActor.run { self.alertMessage = error.localizedDescription; self.showingAlert = true; self.isSaving = false }
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
        components.hour = hour; components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
