import SwiftUI
import FirebaseFirestore

struct ItineraryItemAddView: View {
    // --- THIS IS THE FIX (Part 1): The view now depends on the ViewModel ---
    @ObservedObject var viewModel: ItineraryViewModel
    var onSave: () -> Void
    
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var type: ItineraryItemType = .custom
    @State private var title = ""
    @State private var subtitle = ""
    @State private var note = ""
    @State private var eventDate: Date
    @State private var time: Date
    @State private var isShowTiming = false
    @State private var selectedTimezoneIdentifier: String
    @State private var assumedTimezoneName: String
    
    // Visibility State
    @State private var visibility: String = "Everyone"
    @State private var showCrewSelector = false
    @State private var tourCrew: [TourCrew] = []
    @State private var selectedCrewIDs: Set<String> = []

    private let columns = [GridItem(.adaptive(minimum: 120))]

    init(viewModel: ItineraryViewModel, onSave: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSave = onSave
        
        // Determine the date to default to
        let baseDate: Date
        if let selectedGroup = viewModel.displayGroups.first(where: { $0.id == viewModel.selectedGroupID }) {
            baseDate = Calendar.current.date(from: selectedGroup.dateComponents) ?? Date()
        } else {
            baseDate = Date()
        }
        
        // Get the assumed timezone from the ViewModel
        let assumedTimezone = viewModel.getAssumedTimezone(for: baseDate)
        
        self._eventDate = State(initialValue: baseDate)
        self._selectedTimezoneIdentifier = State(initialValue: assumedTimezone.identifier)
        self._assumedTimezoneName = State(initialValue: assumedTimezone.name)

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: assumedTimezone.identifier) ?? .current
        
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = 12
        components.minute = 0
        self._time = State(initialValue: calendar.date(from: components) ?? baseDate)
    }

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }
        
    @ViewBuilder
    private var macOSBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            formBody
            Spacer()
            saveButton
        }
        .padding(32)
        .frame(width: 550, height: 750)
        .onAppear(perform: fetchCrew)
        .onChange(of: eventDate) { _, newDate in
            // When the date changes, re-calculate the assumed timezone
            let newAssumed = viewModel.getAssumedTimezone(for: newDate)
            self.selectedTimezoneIdentifier = newAssumed.identifier
            self.assumedTimezoneName = newAssumed.name
        }
    }
     
    @ViewBuilder
    private var iOSBody: some View {
        NavigationView {
            // This view would need to be adapted for iOS if required
            Text("Add Item (iOS)")
        }
    }
    
    private var header: some View {
        HStack {
            Text("Add Itinerary Item")
                .font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
            }.buttonStyle(.plain)
        }
    }
    
    private var formBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: type.iconName).font(.title2).foregroundColor(.accentColor).frame(width: 30)
                StyledInputField(placeholder: "Event Title (e.g. 'Dinner reservation')", text: $title)
                    .onChange(of: title) { _, newValue in updateType(from: newValue) }
            }
            StyledInputField(placeholder: "Subtitle (e.g. 'Confirmation #123')", text: $subtitle)

            HStack {
                StyledDateField(date: $eventDate)
                StyledTimePicker(label: "", time: $time)
            }
            
            // --- THIS IS THE NEW TIMEZONE UI ---
            timezonePicker
            
            CustomTextEditor(placeholder: "Notes (optional)", text: $note)
            Toggle("Add to Show Timings", isOn: $isShowTiming).toggleStyle(.checkbox)
            visibilitySection
        }
    }
    
    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visibility").font(.headline)
            HStack {
                Button("Everyone") { visibility = "Everyone"; showCrewSelector = false }
                    .buttonStyle(PrimaryButtonStyle(color: visibility == "Everyone" ? .accentColor : .gray.opacity(0.3)))
                Button("Choose Crew") { visibility = "Custom"; showCrewSelector = true }
                    .buttonStyle(PrimaryButtonStyle(color: visibility == "Custom" ? .accentColor : .gray.opacity(0.3)))
            }
            if showCrewSelector {
                crewGrid.padding(.top, 8)
            }
        }
    }
    
    private var timezonePicker: some View {
        Menu {
            ForEach(TimezoneHelper.regions) { region in
                Section(header: Text(region.name)) {
                    ForEach(region.timezones) { timezone in
                        Button(timezone.name) {
                            self.selectedTimezoneIdentifier = timezone.identifier
                            self.assumedTimezoneName = timezone.name
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "globe").foregroundColor(.secondary)
                Text("Assuming \(assumedTimezoneName)")
                    .font(.subheadline)
                Spacer()
                Text("Change")
                    .font(.subheadline.bold())
            }
            .padding(10)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var saveButton: some View {
        Button("Save Item", action: saveItem)
            .frame(maxWidth: .infinity)
            .padding()
            .background(title.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(title.isEmpty)
    }
    
    private func saveItem() {
        let eventTimeZone = TimeZone(identifier: selectedTimezoneIdentifier) ?? .current
        
        let localCalendar = Calendar.current
        let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
        
        var eventCalendar = Calendar.current
        eventCalendar.timeZone = eventTimeZone

        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year
        finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        finalComponents.timeZone = eventTimeZone
        
        guard let finalDate = eventCalendar.date(from: finalComponents) else {
            print("Error: Could not construct final date from components.")
            return
        }

        let newItem = ItineraryItem(
            ownerId: viewModel.tour.ownerId,
            tourId: viewModel.tour.id ?? "",
            showId: viewModel.showForSelectedDate?.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: self.type.rawValue,
            timeUTC: Timestamp(date: finalDate),
            subtitle: subtitle.isEmpty ? nil : subtitle,
            notes: note.isEmpty ? nil : note,
            timezone: eventTimeZone.identifier,
            isShowTiming: self.isShowTiming,
            visibility: visibility,
            visibleTo: visibility == "Custom" ? Array(selectedCrewIDs) : nil
        )
        
        do {
            _ = try Firestore.firestore().collection("itineraryItems").addDocument(from: newItem)
            onSave()
            dismiss()
        } catch {
            print("Error adding itinerary item: \(error.localizedDescription)")
        }
    }
    
    // Unchanged helper functions
    private var crewGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tourCrew) { crew in
                    Button(action: { toggleCrewSelection(crew.id!) }) {
                        Text(crew.name)
                            .font(.caption).lineLimit(1).padding(8).frame(maxWidth: .infinity)
                            .background(selectedCrewIDs.contains(crew.id!) ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2))
                            .cornerRadius(8).foregroundColor(.primary)
                    }.buttonStyle(.plain)
                }
            }
        }.frame(maxHeight: 150)
    }
    private var crewList: some View {
        List(tourCrew) { crew in
            Button(action: { toggleCrewSelection(crew.id!) }) {
                HStack { Text(crew.name); Spacer(); if selectedCrewIDs.contains(crew.id!) { Image(systemName: "checkmark") } }
            }
        }
    }
    private func toggleCrewSelection(_ crewID: String) { if selectedCrewIDs.contains(crewID) { selectedCrewIDs.remove(crewID) } else { selectedCrewIDs.insert(crewID) } }
    private func fetchCrew() { Task { do { self.tourCrew = try await FirebaseTourService.loadCrew(forTour: viewModel.tour.id ?? ""); self.selectedCrewIDs = Set(self.tourCrew.compactMap { $0.id }) } catch { print("Error fetching crew: \(error.localizedDescription)") } } }
    private func updateType(from eventTitle: String) {
        let lowercasedTitle = eventTitle.lowercased()
        var newType: ItineraryItemType = .custom
        if ["hotel", "check in", "check out", "lobby", "acommodation", "resort", "hotel room", "apartment", "airbnb", "acom", "accom"].contains(where: lowercasedTitle.contains) { newType = .hotel }
        else if ["drive", "transport", "bus", "van", "pick up", "drop off", "car", "taxi", "shuttle", "rideshare", "pickup", "dropoff", "uber", "lyft"].contains(where: lowercasedTitle.contains) { newType = .travel }
        else if ["flight", "airport", "takeoff", "landing", "fly", "airplane", "plane", "departures", "arrivals", "terminal", "gate"].contains(where: lowercasedTitle.contains) { newType = .flight }
        else if ["shoot", "film", "content", "tiktok", "reel", "reels", "video", "photo", "photoshoot", "press", "vlog"].contains(where: lowercasedTitle.contains) { newType = .content }
        else if ["food", "lunch", "breakfast", "dinner", "tea", "kai", "restaurant", "eat", "catering", "snack"].contains(where: lowercasedTitle.contains) { newType = .catering }
        else if ["lounge", "airport lounge"].contains(where: lowercasedTitle.contains) { newType = .lounge }
        self.type = newType
    }
}
