import SwiftUI
import FirebaseFirestore
import Kingfisher

struct AddTicketsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void
    
    // Form State
    @State private var selectedShowID: String = ""
    @State private var ticketTypes: [TicketType] = [TicketType(name: "General Admission", allocation: 0, price: 0.0, currency: "NZD")]
    @State private var description: String = ""
    @State private var restriction: TicketedEvent.Restriction = .allAges
    
    // Data for Picker
    @State private var availableShows: [Show] = []
    @State private var userTours: [Tour] = []
    
    @State private var isSaving = false
    
    private var selectedShow: Show? {
        availableShows.first { $0.id == selectedShowID }
    }
    
    private var selectedTour: Tour? {
        guard let show = selectedShow else { return nil }
        return userTours.first { $0.id == show.tourId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                headerView
                
                showSelector
                
                if selectedShow != nil {
                    showPreview
                }
                
                ticketTypesSection
                
                descriptionSection
                
                restrictionsSection
                
                Spacer()
            }
            .padding(30)
        }
        .frame(minWidth: 550, idealWidth: 600, minHeight: 700)
        .onAppear(perform: loadPrerequisites)
        .safeAreaInset(edge: .bottom) {
            saveButton.padding()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Add Tickets").font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark").font(.title2)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var showSelector: some View {
        Menu {
            ForEach(availableShows) { show in
                let tour = userTours.first { $0.id == show.tourId }
                Button("\(tour?.artist ?? "N/A") - \(show.city)") {
                    selectedShowID = show.id ?? ""
                }
            }
        } label: {
            HStack {
                if let show = selectedShow, let tour = selectedTour {
                    Text("\(tour.artist) - \(show.city)")
                } else {
                    Text(availableShows.isEmpty ? "No available shows" : "Select a show...").foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .pickerStyle(.menu)
        .disabled(availableShows.isEmpty)
    }
    
    @ViewBuilder
    private var showPreview: some View {
        if let show = selectedShow, let tour = selectedTour {
            HStack(spacing: 16) {
                KFImage(URL(string: tour.posterURL ?? ""))
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 150).cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(tour.artist) - \(tour.tourName)").font(.caption).foregroundColor(.secondary)
                    Text(show.city).font(.system(size: 28, weight: .bold))
                    Text(show.date.dateValue(), style: .date).font(.subheadline)
                    Spacer().frame(height: 8)
                    Text(show.venueName).font(.caption).bold()
                    Text(show.venueAddress).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Material.regular)
            .cornerRadius(12)
        }
    }
    
    private var ticketTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ticket Types").font(.headline)
            
            ForEach($ticketTypes) { $ticketType in
                HStack {
                    StyledInputField(placeholder: "Type Name (e.g. GA)", text: $ticketType.name)
                    StyledInputField(placeholder: "Allocation", text: Binding(
                        get: { ticketType.allocation > 0 ? "\(ticketType.allocation)" : "" },
                        set: { ticketType.allocation = Int($0) ?? 0 }
                    ))
                    StyledInputField(placeholder: "Price", text: Binding(
                        get: { ticketType.price > 0 ? "\(ticketType.price)" : "" },
                        set: { ticketType.price = Double($0) ?? 0.0 }
                    ))
                    StyledInputField(placeholder: "NZD", text: $ticketType.currency).frame(width: 70)
                }
            }
            
            Button {
                ticketTypes.append(TicketType(name: "", allocation: 0, price: 0.0, currency: "NZD"))
            } label: {
                HStack { Image(systemName: "plus"); Text("Add Type") }
            }.buttonStyle(.borderless)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description").font(.headline)
            CustomTextEditor(placeholder: "Enter details about the event...", text: $description)
                .frame(minHeight: 100)
        }
    }
    
    private var restrictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Restrictions").font(.headline)
            CustomSegmentedPicker(selected: $restriction, options: TicketedEvent.Restriction.allCases)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveTicketedEvent) {
            Text("Save Tickets")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(selectedShowID.isEmpty || isSaving)
    }
    
    // MARK: - Functions
    
    private func loadPrerequisites() {
        guard let ownerId = appState.userID else { return }
        let db = Firestore.firestore()
        let today = Timestamp(date: Date())
        let group = DispatchGroup()
        
        var allUpcomingShows: [Show] = []
        var existingEventShowIDs = Set<String>()
        var fetchedTours: [Tour] = []

        // 1. Fetch all tours owned by the user
        group.enter()
        db.collection("tours")
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments { tourSnapshot, error in
                defer { group.leave() }
                if let tourDocs = tourSnapshot?.documents {
                    fetchedTours = tourDocs.compactMap { try? $0.data(as: Tour.self) }
                    self.userTours = fetchedTours
                }
            }

        // 2. Fetch all ticketed events for the user to find which shows are already used
        group.enter()
        db.collection("ticketedEvents")
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments { eventSnapshot, error in
                defer { group.leave() }
                if let eventDocs = eventSnapshot?.documents {
                    existingEventShowIDs = Set(eventDocs.compactMap { $0["showId"] as? String })
                }
            }
        
        // 3. After fetching tours, fetch all shows associated with those tours
        group.notify(queue: .main) {
            let tourIDs = fetchedTours.compactMap { $0.id }
            if tourIDs.isEmpty {
                self.availableShows = []
                return
            }
            
            db.collection("shows")
                .whereField("tourId", in: tourIDs)
                .whereField("date", isGreaterThanOrEqualTo: today)
                .getDocuments { showSnapshot, error in
                    if let showDocs = showSnapshot?.documents {
                        allUpcomingShows = showDocs.compactMap { try? $0.data(as: Show.self) }
                        
                        // Now filter out the shows that already have ticketed events
                        self.availableShows = allUpcomingShows.filter { show in
                            !existingEventShowIDs.contains(show.id ?? "")
                        }
                    }
                }
        }
    }
    
    private func saveTicketedEvent() {
        guard let ownerId = appState.userID,
              let show = selectedShow,
              let tour = selectedTour else {
            print("Error: Missing required data to save event.")
            return
        }
        
        isSaving = true
        
        let validTicketTypes = ticketTypes.filter { !$0.name.isEmpty && $0.allocation > 0 }
        
        let newEvent = TicketedEvent(
            ownerId: ownerId,
            tourId: tour.id!,
            showId: show.id!,
            status: .draft,
            description: description,
            restrictions: restriction,
            ticketTypes: validTicketTypes
        )
        
        do {
            try Firestore.firestore().collection("ticketedEvents").addDocument(from: newEvent) { error in
                if let error = error {
                    print("Error saving ticketed event: \(error.localizedDescription)")
                } else {
                    self.onSave()
                    dismiss()
                }
                isSaving = false
            }
        } catch {
            print("Error encoding TicketedEvent: \(error)")
            isSaving = false
        }
    }
}
