import SwiftUI
import FirebaseFirestore

struct ShowEditView: View {
    @Environment(\.dismiss) var dismiss
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

    init(tour: Tour, show: Binding<Show>) {
        self.tour = tour
        self._show = show
        
        self._date = State(initialValue: show.wrappedValue.date.dateValue())
        self._venueAccess = State(initialValue: show.wrappedValue.venueAccess?.dateValue() ?? ShowEditView.defaultTime(hour: 12))
        self._loadIn = State(initialValue: show.wrappedValue.loadIn?.dateValue() ?? ShowEditView.defaultTime(hour: 15))
        self._soundCheck = State(initialValue: show.wrappedValue.soundCheck?.dateValue() ?? ShowEditView.defaultTime(hour: 17))
        self._doorsOpen = State(initialValue: show.wrappedValue.doorsOpen?.dateValue() ?? ShowEditView.defaultTime(hour: 19))
        self._headlinerSetTime = State(initialValue: show.wrappedValue.headlinerSetTime?.dateValue() ?? ShowEditView.defaultTime(hour: 20))
        self._packOut = State(initialValue: show.wrappedValue.packOut?.dateValue() ?? ShowEditView.defaultTime(hour: 23))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                showDetailsSection
                timingSection
                headlinerSection
                packOutSection
                saveButton
            }
            .padding()
        }
        .frame(minWidth: 600, maxWidth: .infinity)
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
                .toggleStyle(.checkbox)
            }
        }
    }

    private var saveButton: some View {
        StyledButtonV2(title: "Save Changes", action: saveChanges, fullWidth: true, showArrow: true)
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

    // This helper function correctly combines the selected show date with a specific time.
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

    private func saveChanges() {
        guard let showID = show.id else {
            print("Error: Show ID is missing, cannot save.")
            return
        }
        
        // 1. Update the main 'show' binding with the corrected timestamps
        show.date = Timestamp(date: date)
        show.venueAccess = Timestamp(date: createFullDate(for: venueAccess))
        show.loadIn = Timestamp(date: createFullDate(for: loadIn))
        show.soundCheck = Timestamp(date: createFullDate(for: soundCheck))
        show.doorsOpen = Timestamp(date: createFullDate(for: doorsOpen))
        show.headlinerSetTime = Timestamp(date: createFullDate(for: headlinerSetTime))
        
        var finalPackOutDate = createFullDate(for: packOut)
        if show.packOutNextDay == true {
            finalPackOutDate = Calendar.current.date(byAdding: .day, value: 1, to: finalPackOutDate) ?? finalPackOutDate
        }
        show.packOut = Timestamp(date: finalPackOutDate)

        let db = Firestore.firestore()
        let showRef = db.collection("shows").document(showID)
        let itineraryQuery = db.collection("itineraryItems").whereField("showId", isEqualTo: showID)

        // 2. Fetch the itinerary documents that need to be updated first.
        itineraryQuery.getDocuments { (itinerarySnapshot, error) in
            if let error = error {
                print("Error fetching itinerary items to update: \(error.localizedDescription)")
                return
            }
            
            // 3. Now that we have the documents, run the transaction.
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                // A. Update the main Show document within the transaction.
                do {
                    try transaction.setData(from: self.show, forDocument: showRef, merge: true)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                // B. Loop through the itinerary documents we fetched and update their times.
                itinerarySnapshot?.documents.forEach { doc in
                    guard let itemType = ItineraryItemType(rawValue: doc["type"] as? String ?? "") else { return }
                    
                    var newTime: Timestamp?
                    switch itemType {
                    case .loadIn:           newTime = self.show.loadIn
                    case .soundcheck:       newTime = self.show.soundCheck
                    case .doors:            newTime = self.show.doorsOpen
                    case .headline:         newTime = self.show.headlinerSetTime
                    case .packOut:          newTime = self.show.packOut
                    default:                return
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
    
    private static func defaultTime(hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
