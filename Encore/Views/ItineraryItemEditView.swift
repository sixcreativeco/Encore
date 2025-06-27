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
    @State private var showCrewSelector: Bool
    @State private var tourCrew: [TourCrew] = []
    @State private var selectedCrewIDs: Set<String>

    // Grid Layout
    private let columns = [GridItem(.adaptive(minimum: 120))]
    
    init(item: Binding<ItineraryItem>, onSave: @escaping () -> Void) {
        self._item = item
        self.onSave = onSave
        
        // Initialize local state from the binding
        let initialDate = item.wrappedValue.timeUTC.dateValue()
        self._eventDate = State(initialValue: initialDate)
        self._time = State(initialValue: initialDate)
        self._notes = State(initialValue: item.wrappedValue.notes ?? "")
        
        let initialVisibility = item.wrappedValue.visibility ?? "Everyone"
        self._visibility = State(initialValue: initialVisibility)
        self._showCrewSelector = State(initialValue: initialVisibility == "Custom")
        self._selectedCrewIDs = State(initialValue: Set(item.wrappedValue.visibleTo ?? []))
    }

    var body: some View {
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
            
            Button("Save Changes", action: saveChanges)
                .frame(maxWidth: .infinity).padding().background(Color.accentColor)
                .foregroundColor(.white).cornerRadius(10)
        }
        .padding()
        .frame(minWidth: 550, minHeight: 650)
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
