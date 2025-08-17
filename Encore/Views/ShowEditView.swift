import SwiftUI
import FirebaseFirestore

struct ShowEditView: View {
    @Environment(\.dismiss) var dismiss
    // --- THIS IS THE FIX: Part 1 ---
    // We need access to the app's state to clear the selected show after deletion.
    @EnvironmentObject var appState: AppState
    let tour: Tour
    
    @Binding var show: Show

    // We use local @State variables ONLY for the DatePickers
    @State private var date: Date
    @State private var venueAccess: Date
    @State private var loadIn: Date
    @State private var soundCheck: Date
    @State private var doorsOpen: Date
    @State private var headlinerSetTime: Date
    @State private var packOut: Date
    
    // State for the delete confirmation alert
    @State private var isShowingDeleteAlert = false

    init(tour: Tour, show: Binding<Show>) {
        self.tour = tour
        self._show = show
        
        // Helper function to translate a date from the event's timezone to the user's local timezone for display
        func dateInUserLocale(from eventTimestamp: Timestamp?) -> Date? {
            guard let eventTimestamp = eventTimestamp else { return nil }
            let eventDate = eventTimestamp.dateValue()

            // Get components from the date in its local timezone
            var eventCalendar = Calendar.current
            eventCalendar.timeZone = TimeZone(identifier: show.wrappedValue.timezone ?? "UTC") ?? .current
            let components = eventCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: eventDate)

            // Create a new date from those same components, but in the user's local calendar
            let userCalendar = Calendar.current // This uses the device's timezone
            return userCalendar.date(from: components)
        }
        
        let showDateForPicker = dateInUserLocale(from: show.wrappedValue.date) ?? Date()

        // Initialize local state from the binding, adjusted for display
        self._date = State(initialValue: showDateForPicker)
        self._venueAccess = State(initialValue: dateInUserLocale(from: show.wrappedValue.venueAccess) ?? ShowEditView.defaultTime(for: showDateForPicker, hour: 12))
        self._loadIn = State(initialValue: dateInUserLocale(from: show.wrappedValue.loadIn) ?? ShowEditView.defaultTime(for: showDateForPicker, hour: 15))
        self._soundCheck = State(initialValue: dateInUserLocale(from: show.wrappedValue.soundCheck) ?? ShowEditView.defaultTime(for: showDateForPicker, hour: 17))
        self._doorsOpen = State(initialValue: dateInUserLocale(from: show.wrappedValue.doorsOpen) ?? ShowEditView.defaultTime(for: showDateForPicker, hour: 19))
        self._headlinerSetTime = State(initialValue: dateInUserLocale(from: show.wrappedValue.headlinerSetTime) ?? ShowEditView.defaultTime(for: showDateForPicker, hour: 20))
        self._packOut = State(initialValue: dateInUserLocale(from: show.wrappedValue.packOut) ?? ShowEditView.defaultTime(for: showDateForPicker, hour: 23))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                showDetailsSection
                timingSection
                headlinerSection
                packOutSection
                actionButtons
            }
            .padding()
        }
        .frame(minWidth: 600, maxWidth: .infinity)
        .alert("Delete Show?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteShow()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to permanently delete this show and its associated itinerary items? This action cannot be undone.")
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Edit Show").font(.largeTitle.bold())
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
                StyledInputField(placeholder: "Venue", text: $show.venueName)
            }

            HStack(spacing: 16) {
                StyledInputField(placeholder: "City", text: $show.city)
                StyledInputField(placeholder: "Country (optional)", text: optionalStringBinding(for: $show.country))
            }

            StyledInputField(placeholder: "Address", text: $show.venueAddress)

            HStack(spacing: 16) {
                StyledInputField(placeholder: "Venue Contact Name", text: optionalStringBinding(for: $show.contactName))
                StyledInputField(placeholder: "Email", text: optionalStringBinding(for: $show.contactEmail))
                StyledInputField(placeholder: "Phone Number", text: optionalStringBinding(for: $show.contactPhone))
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

    private var headlinerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Headliner: \(tour.artist)").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Set Time", time: $headlinerSetTime)
                Stepper("Set Duration: \(show.headlinerSetDurationMinutes ?? 60) min",
                        value: optionalIntBinding(for: $show.headlinerSetDurationMinutes, defaultValue: 60),
                        in: 0...300, step: 5)
            }
        }
    }

    private var packOutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pack Out").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Time", time: $packOut)
                Toggle(isOn: optionalBoolBinding(for: $show.packOutNextDay)) {
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

    private var actionButtons: some View {
        VStack(spacing: 12) {
            StyledButtonV2(title: "Save Changes", action: saveChanges, fullWidth: true, showArrow: true)
            
            Button(action: {
                isShowingDeleteAlert = true
            }) {
                Text("Delete Show")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
        }
    }
    
    private func optionalStringBinding(for binding: Binding<String?>) -> Binding<String> {
        Binding<String>(get: { binding.wrappedValue ?? "" }, set: { binding.wrappedValue = $0.isEmpty ? nil : $0 })
    }
    
    private func optionalIntBinding(for binding: Binding<Int?>, defaultValue: Int) -> Binding<Int> {
        Binding<Int>(get: { binding.wrappedValue ?? defaultValue }, set: { binding.wrappedValue = $0 })
    }
    
    private func optionalBoolBinding(for binding: Binding<Bool?>) -> Binding<Bool> {
        Binding<Bool>(get: { binding.wrappedValue ?? false }, set: { binding.wrappedValue = $0 })
    }
    
    private func saveChanges() {
        guard let showID = show.id else {
            print("Error: Show ID is missing, cannot save.")
            return
        }

        let eventTimeZone = TimeZone(identifier: show.timezone ?? "UTC") ?? .current
        
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
        
        show.date = createTimestampInEventZone(for: date, on: date, in: eventTimeZone)
        show.venueAccess = createTimestampInEventZone(for: venueAccess, on: date, in: eventTimeZone)
        show.loadIn = createTimestampInEventZone(for: loadIn, on: date, in: eventTimeZone)
        show.soundCheck = createTimestampInEventZone(for: soundCheck, on: date, in: eventTimeZone)
        show.doorsOpen = createTimestampInEventZone(for: doorsOpen, on: date, in: eventTimeZone)
        show.headlinerSetTime = createTimestampInEventZone(for: headlinerSetTime, on: date, in: eventTimeZone)
        
        var finalPackOutDate = createTimestampInEventZone(for: packOut, on: date, in: eventTimeZone).dateValue()
        if show.packOutNextDay == true {
            finalPackOutDate = Calendar.current.date(byAdding: .day, value: 1, to: finalPackOutDate) ?? finalPackOutDate
        }
        show.packOut = Timestamp(date: finalPackOutDate)

        let db = Firestore.firestore()
        let showRef = db.collection("shows").document(showID)
        let itineraryQuery = db.collection("itineraryItems").whereField("showId", isEqualTo: showID)

        itineraryQuery.getDocuments { (itinerarySnapshot, error) in
            if let error = error {
                print("Error fetching itinerary items to update: \(error.localizedDescription)")
                return
            }
            
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    try transaction.setData(from: self.show, forDocument: showRef, merge: true)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                itinerarySnapshot?.documents.forEach { doc in
                    guard let itemType = ItineraryItemType(rawValue: doc["type"] as? String ?? "") else { return }
                    
                    var newTime: Timestamp?
                    switch itemType {
                    case .loadIn:          newTime = self.show.loadIn
                    case .soundcheck:      newTime = self.show.soundCheck
                    case .doors:           newTime = self.show.doorsOpen
                    case .headline:        newTime = self.show.headlinerSetTime
                    case .packOut:         newTime = self.show.packOut
                    default:               return
                    }
                    
                    if let newTime = newTime {
                        transaction.updateData(["timeUTC": newTime], forDocument: doc.reference)
                    }
                }
                return nil
                
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    print("✅ Transaction successfully committed! Show and itinerary items are in sync.")
                    self.dismiss()
                }
            }
        }
    }
    
    private func deleteShow() async {
        guard let showID = show.id else {
            print("Error: Show ID is missing, cannot delete.")
            return
        }

        let db = Firestore.firestore()
        let batch = db.batch()

        // 1. Delete the Show document itself
        let showRef = db.collection("shows").document(showID)
        batch.deleteDocument(showRef)

        // 2. Find and delete all itinerary items associated with this show
        do {
            let itinerarySnapshot = try await db.collection("itineraryItems").whereField("showId", isEqualTo: showID).getDocuments()
            for document in itinerarySnapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            // 3. Commit the batch
            try await batch.commit()
            print("✅ Show and associated itinerary items deleted successfully.")

            // --- THIS IS THE FIX: Part 2 ---
            // On the main thread, clear the selected show from the app state and then dismiss the view.
            // This ensures the app navigates back to the TourDetailView correctly.
            await MainActor.run {
                appState.selectedShow = nil
                dismiss()
            }
            // --- END OF FIX ---

        } catch {
            print("❌ Error deleting show: \(error.localizedDescription)")
            // Optionally, show an error alert to the user
        }
    }
    
    private static func defaultTime(for date: Date, hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? date
    }
}
