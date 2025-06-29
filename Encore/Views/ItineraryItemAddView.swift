import SwiftUI
import FirebaseFirestore

struct ItineraryItemAddView: View {
    var tourID: String
    var userID: String
    var onSave: () -> Void
    var showForTimezone: Show?
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var type: ItineraryItemType = .custom
    @State private var title = ""
    @State private var note = ""
    @State private var eventDate: Date
    @State private var time: Date
    
    // Visibility State
    @State private var visibility: String = "Everyone"
    @State private var showCrewSelector = false
    @State private var tourCrew: [TourCrew] = []
    @State private var selectedCrewIDs: Set<String> = []

    // Grid Layout (for macOS)
    private let columns = [GridItem(.adaptive(minimum: 120))]

    init(tourID: String, userID: String, onSave: @escaping () -> Void, showForTimezone: Show?) {
        self.tourID = tourID
        self.userID = userID
        self.onSave = onSave
        self.showForTimezone = showForTimezone
        
        let baseDate = showForTimezone?.date.dateValue() ?? Date()
        self._eventDate = State(initialValue: baseDate)

        let calendar = Calendar.current
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
    
    // MARK: - macOS Body
    @ViewBuilder
    private var macOSBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Add Itinerary Item").font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: type.iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    StyledInputField(placeholder: "Event (e.g. 'Dinner reservation')", text: $title)
                        .onChange(of: title) { _, newValue in updateType(from: newValue) }
                }

                HStack {
                    StyledDateField(date: $eventDate)
                    StyledTimePicker(label: "", time: $time)
                }
                
                CustomTextEditor(placeholder: "Notes (optional)", text: $note)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Visibility").font(.headline)
                    HStack {
                        Button("Everyone") {
                            visibility = "Everyone"
                            showCrewSelector = false
                        }
                        .buttonStyle(PrimaryButtonStyle(color: visibility == "Everyone" ? .accentColor : .gray.opacity(0.3)))
                        
                        Button("Choose Crew") {
                            visibility = "Custom"
                            showCrewSelector = true
                        }
                        .buttonStyle(PrimaryButtonStyle(color: visibility == "Custom" ? .accentColor : .gray.opacity(0.3)))
                    }
                    
                    if showCrewSelector {
                        crewGrid
                            .padding(.top, 8)
                    }
                }
            }

            Spacer()
            
            Button("Save Item", action: saveItem)
                .frame(maxWidth: .infinity).padding().background(title.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor)
                .foregroundColor(.white).cornerRadius(10)
                .disabled(title.isEmpty)
        }
        .padding(32)
        .frame(width: 550, height: 650)
        .onAppear(perform: fetchCrew)
    }
    
    // MARK: - iOS Body
    @ViewBuilder
    private var iOSBody: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section(header: Text("Event Details")) {
                        HStack {
                             Image(systemName: type.iconName)
                                .foregroundColor(.accentColor)
                            TextField("Event Title", text: $title)
                                .onChange(of: title) { _, newValue in updateType(from: newValue) }
                        }
                        DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $note)
                            .frame(minHeight: 100)
                    }
                    
                    Section(header: Text("Visibility")) {
                        Picker("Visible To", selection: $visibility) {
                            Text("Everyone").tag("Everyone")
                            Text("Custom").tag("Custom")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if visibility == "Custom" {
                            crewList
                        }
                    }
                    
                    Section {
                         Button(action: saveItem) {
                            Text("Save Item")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(title.isEmpty)
                    }
                }
                // These modifiers are now correctly wrapped for iOS only
                #if os(iOS)
                .navigationTitle("Add Itinerary Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
                #endif
            }
        }
        .onAppear(perform: fetchCrew)
    }

    private var crewGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tourCrew) { crew in
                    Button(action: {
                        toggleCrewSelection(crew.id!)
                    }) {
                        Text(crew.name)
                            .font(.caption)
                            .lineLimit(1)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(selectedCrewIDs.contains(crew.id!) ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 150)
    }
    
    private var crewList: some View {
        List(tourCrew) { crew in
            Button(action: { toggleCrewSelection(crew.id!) }) {
                HStack {
                    Text(crew.name)
                    Spacer()
                    if selectedCrewIDs.contains(crew.id!) {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    private func toggleCrewSelection(_ crewID: String) {
        if selectedCrewIDs.contains(crewID) {
            selectedCrewIDs.remove(crewID)
        } else {
            selectedCrewIDs.insert(crewID)
        }
    }

    private func fetchCrew() {
        Task {
            do {
                self.tourCrew = try await FirebaseTourService.loadCrew(forTour: tourID)
                self.selectedCrewIDs = Set(self.tourCrew.compactMap { $0.id })
            } catch {
                print("Error fetching crew: \(error.localizedDescription)")
            }
        }
    }
    
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
    
    private func saveItem() {
        let eventTimeZone = TimeZone(identifier: showForTimezone?.timezone ?? "UTC") ?? .current
        
        var calendar = Calendar.current
        calendar.timeZone = eventTimeZone

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let finalDate = calendar.date(from: combinedComponents) ?? Date()

        let newItem = ItineraryItem(
            tourId: self.tourID,
            showId: showForTimezone?.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: self.type.rawValue,
            timeUTC: Timestamp(date: finalDate),
            subtitle: nil,
            notes: note.isEmpty ? nil : note,
            timezone: eventTimeZone.identifier,
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
}
