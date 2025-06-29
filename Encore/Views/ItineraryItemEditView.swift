import SwiftUI
import FirebaseFirestore

struct ItineraryItemEditView: View {
    @Binding var item: ItineraryItem
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var eventDate: Date
    @State private var time: Date
    @State private var notes: String
    
    // Visibility State
    @State private var visibility: String
    @State private var tourCrew: [TourCrew] = []
    @State private var selectedCrewIDs: Set<String>

    // Grid Layout (macOS)
    private let columns = [GridItem(.adaptive(minimum: 120))]
    
    init(item: Binding<ItineraryItem>, onSave: @escaping () -> Void) {
        self._item = item
        self.onSave = onSave
        
        let initialDate = item.wrappedValue.timeUTC.dateValue()
        self._eventDate = State(initialValue: initialDate)
        self._time = State(initialValue: initialDate)
        self._notes = State(initialValue: item.wrappedValue.notes ?? "")
        
        let initialVisibility = item.wrappedValue.visibility ?? "Everyone"
        self._visibility = State(initialValue: initialVisibility)
        self._selectedCrewIDs = State(initialValue: Set(item.wrappedValue.visibleTo ?? []))
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
                Text("Edit Itinerary Item").font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").font(.system(size: 24, weight: .medium)).padding(10)
                }.buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "calendar")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)

                    StyledInputField(placeholder: "Title", text: $item.title)
                        .onChange(of: item.title) { _, newValue in updateType(from: newValue) }
                }
                
                HStack {
                    StyledDateField(date: $eventDate)
                    StyledTimePicker(label: "", time: $time)
                }
                
                CustomTextEditor(placeholder: "Notes", text: $notes)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Visibility").font(.headline)
                    HStack {
                        Button("Everyone") {
                            visibility = "Everyone"
                        }
                        .buttonStyle(PrimaryButtonStyle(color: visibility == "Everyone" ? .accentColor : .gray.opacity(0.3)))
                        
                        Button("Choose Crew") {
                            visibility = "Custom"
                        }
                        .buttonStyle(PrimaryButtonStyle(color: visibility == "Custom" ? .accentColor : .gray.opacity(0.3)))
                    }
                
                    if visibility == "Custom" {
                        crewGrid
                            .padding(.top, 8)
                    }
                }
            }

            Spacer()
            
            Button("Save Changes", action: saveChanges)
                .frame(maxWidth: .infinity).padding().background(Color.accentColor)
                .foregroundColor(.white).cornerRadius(10)
        }
        .padding()
        .frame(minWidth: 550, minHeight: 650)
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
                             Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "calendar")
                                .foregroundColor(.accentColor)
                            TextField("Event Title", text: $item.title)
                                .onChange(of: item.title) { _, newValue in updateType(from: newValue) }
                        }
                        DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $notes)
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
                }
                // These modifiers are now correctly wrapped for iOS only
                #if os(iOS)
                .navigationTitle("Edit Itinerary Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save", action: saveChanges)
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
                self.tourCrew = try await FirebaseTourService.loadCrew(forTour: item.tourId)
                if item.visibleTo == nil && visibility == "Custom" {
                    self.selectedCrewIDs = Set(self.tourCrew.compactMap { $0.id })
                }
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
        
        self.item.type = newType.rawValue
    }

    private func saveChanges() {
        let db = Firestore.firestore()
        guard let itemId = item.id else { return }

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combinedComponents = dateComponents
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let finalDate = calendar.date(from: combinedComponents) ?? Date()
        
        item.timeUTC = Timestamp(date: finalDate)
        item.notes = notes.isEmpty ? nil : notes
        item.visibility = visibility
        item.visibleTo = visibility == "Custom" ? Array(selectedCrewIDs) : nil

        do {
            try db.collection("itineraryItems").document(itemId).setData(from: item, merge: true)
            onSave()
            dismiss()
        } catch {
            print("Error saving itinerary item: \(error)")
        }
    }
}
