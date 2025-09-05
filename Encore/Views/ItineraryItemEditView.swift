import SwiftUI
import FirebaseFirestore

struct ItineraryItemEditView: View {
    // --- THIS IS THE FIX (Part 1): The view now depends on the ViewModel ---
    @ObservedObject var viewModel: ItineraryViewModel
    @Binding var item: ItineraryItem
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    // Local state for the form
    @State private var eventDate: Date
    @State private var time: Date
    @State private var notes: String
    @State private var subtitle: String
    @State private var isShowTiming: Bool
    @State private var visibility: String
    @State private var selectedTimezoneIdentifier: String
    @State private var assumedTimezoneName: String
    @State private var tourCrew: [TourCrew] = []
    @State private var selectedCrewIDs: Set<String>
    @State private var isSaving = false
    
    private let columns = [GridItem(.adaptive(minimum: 120))]
        
    init(viewModel: ItineraryViewModel, item: Binding<ItineraryItem>, onSave: @escaping () -> Void) {
        self.viewModel = viewModel
        self._item = item
        self.onSave = onSave
                
        let boundItem = item.wrappedValue
        let originalUTCDate = boundItem.timeUTC.dateValue()
        let initialTimezoneIdentifier = boundItem.timezone ?? TimeZone.current.identifier
        let eventTimeZone = TimeZone(identifier: initialTimezoneIdentifier) ?? .current
                
        var eventCalendar = Calendar.current
        eventCalendar.timeZone = eventTimeZone
        let eventComponents = eventCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: originalUTCDate)
                
        var localCalendar = Calendar.current
        let displayDate = localCalendar.date(from: eventComponents) ?? originalUTCDate
        
        self._eventDate = State(initialValue: displayDate)
        self._time = State(initialValue: displayDate)
        self._notes = State(initialValue: boundItem.notes ?? "")
        self._subtitle = State(initialValue: boundItem.subtitle ?? "")
        self._isShowTiming = State(initialValue: boundItem.isShowTiming ?? false)
        self._visibility = State(initialValue: boundItem.visibility ?? "Everyone")
        self._selectedCrewIDs = State(initialValue: Set(boundItem.visibleTo ?? []))
        self._selectedTimezoneIdentifier = State(initialValue: initialTimezoneIdentifier)
        self._assumedTimezoneName = State(initialValue: initialTimezoneIdentifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? initialTimezoneIdentifier)
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
        .padding()
        .frame(minWidth: 550, minHeight: 750)
        .onAppear(perform: fetchCrew)
        .onChange(of: eventDate) { _, newDate in
            let newAssumed = viewModel.getAssumedTimezone(for: newDate)
            self.selectedTimezoneIdentifier = newAssumed.identifier
            self.assumedTimezoneName = newAssumed.name
        }
    }
    
    @ViewBuilder
    private var iOSBody: some View {
        NavigationView {
            Text("Edit Item (iOS)") // Placeholder for iOS implementation
        }
        .onAppear(perform: fetchCrew)
    }
    
    private var header: some View {
        HStack {
            Text("Edit Itinerary Item").font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark").font(.system(size: 24, weight: .medium)).padding(10)
            }.buttonStyle(.plain)
        }
    }
    
    private var formBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "calendar")
                    .font(.title2).foregroundColor(.accentColor).frame(width: 30)
                StyledInputField(placeholder: "Title", text: $item.title)
                    .onChange(of: item.title) { _, newValue in updateType(from: newValue) }
            }
            StyledInputField(placeholder: "Subtitle (e.g. 'Confirmation #123')", text: $subtitle)
            
            HStack {
                StyledDateField(date: $eventDate)
                StyledTimePicker(label: "", time: $time)
            }
            
            timezonePicker
                            
            CustomTextEditor(placeholder: "Notes", text: $notes)
            Toggle("Add to Show Timings", isOn: $isShowTiming).toggleStyle(.checkbox)
            visibilitySection
        }
    }
    
    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visibility").font(.headline)
            HStack {
                Button("Everyone") { visibility = "Everyone" }
                    .buttonStyle(PrimaryButtonStyle(color: visibility == "Everyone" ? .accentColor : .gray.opacity(0.3)))
                Button("Choose Crew") { visibility = "Custom" }
                    .buttonStyle(PrimaryButtonStyle(color: visibility == "Custom" ? .accentColor : .gray.opacity(0.3)))
            }
            if visibility == "Custom" {
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
                Text("Timezone: \(assumedTimezoneName)")
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
        Button(action: saveChanges) {
            HStack {
                if isSaving { ProgressView().scaleEffect(0.8).padding(.trailing, 8) }
                Text(isSaving ? "Saving..." : "Save Changes")
            }
            .frame(maxWidth: .infinity).padding().background(isSaving ? Color.gray : Color.accentColor)
            .foregroundColor(.white).cornerRadius(10)
        }
        .disabled(isSaving)
    }
        
    private func saveChanges() {
        guard !isSaving else { return }
        
        isSaving = true
        let db = Firestore.firestore()
        guard let itemId = item.id else {
            isSaving = false
            return
        }
        
        let eventTimeZone = TimeZone(identifier: selectedTimezoneIdentifier) ?? .current
                
        let localCalendar = Calendar.current
        let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: eventDate)
        let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
                
        var eventCalendar = Calendar.current
        eventCalendar.timeZone = eventTimeZone
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year; finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day; finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute; finalComponents.timeZone = eventTimeZone
                
        guard let finalDate = eventCalendar.date(from: finalComponents) else {
            print("Error: Could not construct final date from components.")
            isSaving = false
            return
        }
                
        item.timeUTC = Timestamp(date: finalDate)
        item.notes = notes.isEmpty ? nil : notes
        item.subtitle = subtitle.isEmpty ? nil : subtitle
        item.isShowTiming = self.isShowTiming
        item.visibility = visibility
        item.visibleTo = visibility == "Custom" ? Array(selectedCrewIDs) : nil
        item.timezone = eventTimeZone.identifier
        
        do {
            try db.collection("itineraryItems").document(itemId).setData(from: item, merge: true) { error in
                DispatchQueue.main.async {
                    self.isSaving = false
                    if let error = error {
                        print("Error saving itinerary item: \(error)")
                    } else {
                        self.onSave()
                        self.dismiss()
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isSaving = false
                print("Error saving itinerary item: \(error)")
            }
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
    private func fetchCrew() { Task { do { self.tourCrew = try await FirebaseTourService.loadCrew(forTour: item.tourId); if item.visibleTo == nil && visibility == "Custom" { self.selectedCrewIDs = Set(self.tourCrew.compactMap { $0.id }) } } catch { print("Error fetching crew: \(error.localizedDescription)") } } }
    private func updateType(from eventTitle: String) {
        let lowercasedTitle = eventTitle.lowercased()
        var newType: ItineraryItemType = .custom
        if ["hotel", "check in", "check out"].contains(where: lowercasedTitle.contains) { newType = .hotel }
        else if ["drive", "transport", "bus", "van"].contains(where: lowercasedTitle.contains) { newType = .travel }
        else if ["flight", "airport"].contains(where: lowercasedTitle.contains) { newType = .flight }
        else if ["content", "photo", "video"].contains(where: lowercasedTitle.contains) { newType = .content }
        else if ["food", "lunch", "dinner"].contains(where: lowercasedTitle.contains) { newType = .catering }
        else if ["lounge"].contains(where: lowercasedTitle.contains) { newType = .lounge }
        self.item.type = newType.rawValue
    }
}
