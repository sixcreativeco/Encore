import SwiftUI
import FirebaseFirestore
import MapKit

struct AddHotelView: View {
    var tour: Tour
    var onHotelAdded: () -> Void

    @Environment(\.dismiss) var dismiss
    
    // Search Service
    @StateObject private var venueSearch = VenueSearchService()

    // Form State
    @State private var hotelName: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var venueQuery: String = ""
    
    @State private var checkInDate = Date()
    @State private var checkOutDate = Date()
    @State private var checkInTime = defaultTime(hour: 15) // Default 3 PM
    @State private var checkOutTime = defaultTime(hour: 11) // Default 11 AM
    @State private var bookingReference: String = ""
    
    @State private var rooms: [HotelRoom] = [HotelRoom(guests: [])]
    
    // Crew & Guest State
    @State private var tourCrew: [TourCrew] = []
    
    // View State
    @State private var showVenueSuggestions = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var selectedVenueTimeZone: TimeZone?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                searchAndDetailsSection
                bookingDetailsSection
                roomsSection
                Spacer()
                saveButton
            }
            .padding(32)
        }
        .frame(minWidth: 600)
        .onAppear(perform: loadTourCrew)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private var header: some View {
        HStack {
            Text("Add Hotel Stay").font(.largeTitle.bold()); Spacer()
            Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray) }.buttonStyle(.plain)
        }
    }
    
    private var searchAndDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            StyledInputField(placeholder: "Search for Hotel...", text: $venueQuery)
                .onChange(of: venueQuery) { _, newValue in
                    showVenueSuggestions = !newValue.isEmpty
                    venueSearch.searchVenues(query: newValue)
                }
            if showVenueSuggestions && !venueSearch.results.isEmpty {
                venueSuggestionsList
            }
            HStack { StyledInputField(placeholder: "Hotel Name", text: $hotelName); StyledInputField(placeholder: "City", text: $city) }
            StyledInputField(placeholder: "Address", text: $address)
        }
    }
    
    private var venueSuggestionsList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(venueSearch.results.prefix(5)) { result in
                Button(action: { selectVenue(result) }) {
                    VStack(alignment: .leading) { Text(result.name).font(.body); Text(result.address).font(.caption).foregroundColor(.gray) }
                    .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain)
            }
        }.background(Color.gray.opacity(0.1)).cornerRadius(8)
    }
    
    private var bookingDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Check In").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                Text("Check Out").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading) { Text("Date").font(.caption).foregroundColor(.secondary); StyledDateField(date: $checkInDate) }
                VStack(alignment: .leading) { Text("Time").font(.caption).foregroundColor(.secondary); StyledTimePicker(label: "", time: $checkInTime) }
                VStack(alignment: .leading) { Text("Date").font(.caption).foregroundColor(.secondary); StyledDateField(date: $checkOutDate) }
                VStack(alignment: .leading) { Text("Time").font(.caption).foregroundColor(.secondary); StyledTimePicker(label: "", time: $checkOutTime) }
            }
            StyledInputField(placeholder: "Booking Reference / Confirmation #", text: $bookingReference)
        }
    }

    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rooms & Guests").font(.headline)
            ForEach($rooms) { $room in
                RoomInputView(room: $room, tourCrew: tourCrew, onDelete: { rooms.removeAll { $0.id == room.id } })
                Divider()
            }
            Button(action: { rooms.append(HotelRoom(guests: [])) }) { HStack { Image(systemName: "plus"); Text("Add Room") } }.buttonStyle(.borderless)
        }
    }
    
    private var saveButton: some View {
        Button(action: { Task { await saveHotel() } }) {
            HStack {
                Spacer()
                if isSaving { ProgressView().colorInvert() }
                else { Text("Save Hotel Stay").fontWeight(.semibold) }
                Spacer()
            }
            .padding().background(isFormValid ? Color.accentColor : Color.gray).foregroundColor(.white).cornerRadius(12)
        }
        .buttonStyle(.plain).disabled(!isFormValid || isSaving)
    }
    
    struct RoomInputView: View {
        @Binding var room: HotelRoom; let tourCrew: [TourCrew]; let onDelete: () -> Void
        @State private var guestSearchText: String = ""
        private var availableCrew: [TourCrew] { let assignedGuestIDs = Set(room.guests.map { $0.crewId }); return tourCrew.filter { !assignedGuestIDs.contains($0.id ?? "") } }
        private var filteredCrewSuggestions: [TourCrew] { if guestSearchText.isEmpty { return [] }; return availableCrew.filter { $0.name.lowercased().contains(guestSearchText.lowercased()) } }
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StyledInputField(placeholder: "Room Number (optional)", text: optionalStringBinding(for: $room.roomNumber)); Spacer()
                    Button(action: onDelete) { Image(systemName: "trash").foregroundColor(.red) }.buttonStyle(.plain)
                }
                if !room.guests.isEmpty {
                    WrapView(items: room.guests) { guest in
                        HStack(spacing: 4) {
                            Text(guest.name).font(.caption).padding(.horizontal, 8).padding(.vertical, 4).background(Color.blue.opacity(0.2)).cornerRadius(6)
                            Button(action: { room.guests.removeAll { $0.id == guest.id } }) { Image(systemName: "xmark.circle.fill").font(.caption) }.buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                HStack { TextField("Add Guest...", text: $guestSearchText).textFieldStyle(RoundedBorderTextFieldStyle()); Button("Add") { addGuest(name: guestSearchText) }.disabled(guestSearchText.isEmpty) }
                if !filteredCrewSuggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading) { ForEach(filteredCrewSuggestions.prefix(5)) { crew in Button(action: { addGuest(crew: crew) }) { Text(crew.name).padding(8).frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.plain) } }
                    }.background(Color.gray.opacity(0.1)).cornerRadius(8).frame(maxHeight: 150)
                }
            }
        }
        private func addGuest(crew: TourCrew) { guard let crewId = crew.id else { return }; let newGuest = HotelGuest(crewId: crewId, name: crew.name); if !room.guests.contains(where: { $0.id == newGuest.id }) { room.guests.append(newGuest) }; guestSearchText = "" }
        private func addGuest(name: String) { let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines); guard !trimmedName.isEmpty else { return }; if let existingCrew = tourCrew.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) { addGuest(crew: existingCrew) } else { let tempGuest = HotelGuest(crewId: "temp_\(UUID().uuidString)", name: trimmedName); if !room.guests.contains(where: { $0.name == tempGuest.name }) { room.guests.append(tempGuest) }; guestSearchText = "" } }
        private func optionalStringBinding(for binding: Binding<String?>) -> Binding<String> { Binding<String>(get: { binding.wrappedValue ?? "" }, set: { binding.wrappedValue = $0.isEmpty ? nil : $0 }) }
    }
    
    private var isFormValid: Bool { !hotelName.isEmpty && !address.isEmpty }
    private static func defaultTime(hour: Int) -> Date { Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date() }
    
    private func loadTourCrew() {
        Task {
            guard let tourID = tour.id else { return }
            self.tourCrew = (try? await FirebaseTourService.loadCrew(forTour: tourID)) ?? []
        }
    }
    
    private func selectVenue(_ result: VenueResult) {
        self.hotelName = result.name; self.address = result.address; self.city = result.city; self.country = result.country; self.venueQuery = result.name;
        self.showVenueSuggestions = false
        self.selectedVenueTimeZone = result.timeZone
    }

    private func saveHotel() async {
        guard isFormValid, let tourID = tour.id else { errorMessage = "Please fill in all required fields."; return }
        isSaving = true
        
        // --- THIS IS THE FIX ---
        // This logic now guarantees a timezone, falling back to the user's current timezone if needed.
        let eventTimeZone: TimeZone
        if let selectedTZ = selectedVenueTimeZone {
            eventTimeZone = selectedTZ
        } else {
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.geocodeAddressString(address).first, let tz = placemark.timeZone {
                eventTimeZone = tz
            } else {
                // Safe fallback to the user's current timezone
                eventTimeZone = .current
            }
        }
        // --- END OF FIX ---
        
        func combine(date: Date, time: Date, in timezone: TimeZone) -> Timestamp {
            let localCalendar = Calendar.current
            let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
            var eventCalendar = Calendar.current; eventCalendar.timeZone = timezone
            var finalComponents = DateComponents(); finalComponents.year = dateComponents.year; finalComponents.month = dateComponents.month; finalComponents.day = dateComponents.day; finalComponents.hour = timeComponents.hour; finalComponents.minute = timeComponents.minute;
            finalComponents.timeZone = timezone
            guard let finalDate = eventCalendar.date(from: finalComponents) else { return Timestamp(date: Date()) }
            return Timestamp(date: finalDate)
        }
        
        let newHotel = Hotel(
            tourId: tourID,
            ownerId: tour.ownerId,
            name: hotelName,
            address: address,
            city: city,
            country: country,
            timezone: eventTimeZone.identifier,
            checkInDate: combine(date: checkInDate, time: checkInTime, in: eventTimeZone),
            checkOutDate: combine(date: checkOutDate, time: checkOutTime, in: eventTimeZone),
            bookingReference: bookingReference.isEmpty ? nil : bookingReference,
            rooms: rooms
        )
        
        FirebaseHotelService.shared.saveHotel(newHotel) { error in
            isSaving = false
            if let error = error { errorMessage = "Failed to save hotel: \(error.localizedDescription)" }
            else { onHotelAdded(); dismiss() }
        }
    }
}
