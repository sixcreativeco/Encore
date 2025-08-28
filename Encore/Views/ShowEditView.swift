import SwiftUI
import FirebaseFirestore

struct ShowEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let tour: Tour
    
    @Binding var show: Show

    @State private var date: Date
    @State private var venueAccess: Date?
    @State private var loadIn: Date?
    @State private var soundCheck: Date?
    @State private var doorsOpen: Date?
    @State private var headline: Date?
    @State private var packOut: Date?
    
    @State private var isShowingDeleteAlert = false

    init(tour: Tour, show: Binding<Show>) {
        self.tour = tour
        self._show = show
        
        func dateInUserLocale(from eventTimestamp: Timestamp?) -> Date? {
            guard let eventTimestamp = eventTimestamp else { return nil }
            let eventDate = eventTimestamp.dateValue()
            var eventCalendar = Calendar.current
            eventCalendar.timeZone = TimeZone(identifier: show.wrappedValue.timezone ?? "UTC") ?? .current
            let components = eventCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: eventDate)
            return Calendar.current.date(from: components)
        }
        
        self._date = State(initialValue: dateInUserLocale(from: show.wrappedValue.date) ?? Date())
        self._venueAccess = State(initialValue: dateInUserLocale(from: show.wrappedValue.venueAccess))
        self._loadIn = State(initialValue: dateInUserLocale(from: show.wrappedValue.loadIn))
        self._soundCheck = State(initialValue: dateInUserLocale(from: show.wrappedValue.soundCheck))
        self._doorsOpen = State(initialValue: dateInUserLocale(from: show.wrappedValue.doorsOpen))
        self._headline = State(initialValue: dateInUserLocale(from: show.wrappedValue.headlinerSetTime))
        self._packOut = State(initialValue: dateInUserLocale(from: show.wrappedValue.packOut))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                showDetailsSection
                timingSection
                headlinerDetailsSection
                packOutSection
                actionButtons
            }
            .padding()
        }
        .frame(minWidth: 700, maxWidth: .infinity)
        .alert("Delete Show?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await deleteShow() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to permanently delete this show? This action cannot be undone.")
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Edit Show").font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .medium)).padding(10)
            }.buttonStyle(.plain)
        }
    }
    
    private var showDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date").font(.headline)
            StyledDateField(date: $date).padding(.bottom, -8)
            Text("Venue").font(.headline)
            StyledInputField(placeholder: "Venue", text: $show.venueName)
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
            Text("Headliner: \(tour.artist)").font(.headline)
            HStack(alignment: .top, spacing: 0) {
                timingCell(label: "Headliner Set", selection: $headline)
                    .frame(width: 100)
                durationCell(label: "Set Duration",
                             minutes: optionalIntBinding(for: $show.headlinerSetDurationMinutes, defaultValue: 60))
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
    
    // --- FIX IS HERE ---
    // The logic inside this component has been rewritten to be more robust and avoid the crash.
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

            if selection.wrappedValue != nil {
                // This binding is now guaranteed to be non-nil, preventing the crash.
                let dateBinding = Binding<Date>(
                    get: { selection.wrappedValue ?? Date() },
                    set: { selection.wrappedValue = $0 }
                )
                
                DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden().datePickerStyle(.compact)
                    .padding(.horizontal, 8).padding(.vertical, 7)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10).frame(height: 44)
            } else {
                Button(action: {
                    withAnimation {
                        selection.wrappedValue = Self.defaultTime(for: self.date, hour: 12)
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
    }
    // --- END OF FIX ---

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

    private var actionButtons: some View {
        VStack(spacing: 12) {
            StyledButtonV2(title: "Save Changes", action: saveChanges, fullWidth: true, showArrow: true)
            Button(action: { isShowingDeleteAlert = true }) {
                Text("Delete Show").foregroundColor(.red).font(.subheadline)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
        }
    }
    
    private func optionalStringBinding(for binding: Binding<String?>) -> Binding<String> {
        Binding<String>(get: { binding.wrappedValue ?? "" }, set: { $0.isEmpty ? nil : $0 })
    }
    
    private func optionalIntBinding(for binding: Binding<Int?>, defaultValue: Int) -> Binding<Int> {
        Binding<Int>(get: { binding.wrappedValue ?? defaultValue }, set: { binding.wrappedValue = $0 })
    }
    
    private func saveChanges() {
        guard let showID = show.id else { return }
        let eventTimeZone = TimeZone(identifier: show.timezone ?? "UTC") ?? .current
        func createOptionalTimestamp(for time: Date?, on day: Date, in timezone: TimeZone) -> Timestamp? {
            guard let time = time else { return nil }
            let localCalendar = Calendar.current
            let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: day)
            let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
            var eventCalendar = Calendar(identifier: .gregorian); eventCalendar.timeZone = timezone
            var finalComponents = DateComponents()
            finalComponents.year = dateComponents.year
            finalComponents.month = dateComponents.month
            finalComponents.day = dateComponents.day
            finalComponents.hour = timeComponents.hour
            finalComponents.minute = timeComponents.minute
            finalComponents.timeZone = timezone
            guard let finalDate = eventCalendar.date(from: finalComponents) else { return nil }
            return Timestamp(date: finalDate)
        }
        
        show.date = createOptionalTimestamp(for: date, on: date, in: eventTimeZone)!
        show.venueAccess = createOptionalTimestamp(for: venueAccess, on: date, in: eventTimeZone)
        show.loadIn = createOptionalTimestamp(for: loadIn, on: date, in: eventTimeZone)
        show.soundCheck = createOptionalTimestamp(for: soundCheck, on: date, in: eventTimeZone)
        show.doorsOpen = createOptionalTimestamp(for: doorsOpen, on: date, in: eventTimeZone)
        show.headlinerSetTime = createOptionalTimestamp(for: headline, on: date, in: eventTimeZone)
        show.packOut = createOptionalTimestamp(for: packOut, on: date, in: eventTimeZone)

        let db = Firestore.firestore()
        let showRef = db.collection("shows").document(showID)
        Task {
            do {
                let oldItemsSnapshot = try await db.collection("itineraryItems")
                    .whereField("showId", isEqualTo: showID)
                    .whereField("isShowTiming", isEqualTo: true)
                    .getDocuments()
                let batch = db.batch()
                oldItemsSnapshot.documents.forEach { batch.deleteDocument($0.reference) }
                try batch.setData(from: self.show, forDocument: showRef, merge: true)
                let allTimings: [ItineraryItemType: Date?] = [
                    .venueAccess: venueAccess,
                    .loadIn: loadIn,
                    .soundcheck: soundCheck,
                    .doors: doorsOpen,
                    .headline: headline,
                    .packOut: packOut
                ]
                for (type, time) in allTimings {
                    guard let date = time,
                          let timestamp = createOptionalTimestamp(for: date, on: self.date, in: eventTimeZone) else { continue }
                    let item = ItineraryItem(
                        ownerId: self.tour.ownerId,
                        tourId: self.tour.id!,
                        showId: showID,
                        title: type.displayName,
                        type: type.rawValue,
                        timeUTC: timestamp,
                        isShowTiming: true
                    )
                    let itemRef = db.collection("itineraryItems").document()
                    try batch.setData(from: item, forDocument: itemRef)
                }
                try await batch.commit()
                print("✅ Transaction successfully committed!")
                dismiss()
            } catch {
                print("Transaction failed: \(error)")
            }
        }
    }
    
    private func deleteShow() async {
        guard let showID = show.id else { return }
        let db = Firestore.firestore()
        let batch = db.batch()
        let showRef = db.collection("shows").document(showID)
        batch.deleteDocument(showRef)
        do {
            let itinerarySnapshot = try await db.collection("itineraryItems").whereField("showId", isEqualTo: showID).getDocuments()
            itinerarySnapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
            await MainActor.run {
                appState.selectedShow = nil
                dismiss()
            }
        } catch {
            print("❌ Error deleting show: \(error.localizedDescription)")
        }
    }
    
    static func defaultTime(for date: Date, hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }
}
