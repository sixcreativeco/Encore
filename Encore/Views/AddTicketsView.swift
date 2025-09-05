import SwiftUI
import FirebaseFirestore
import Kingfisher

struct AddTicketsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void
    
    // Form State
    @State private var selectedShowID: String = ""
    @State private var ticketTypes: [TicketType] = []
    @State private var description: String = ""
    @State private var importantInfo: String = ""
    
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
                
                importantInfoSection
                
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
                TicketTypeCardView(ticketType: $ticketType, show: selectedShow ?? Show(tourId: "", date: Timestamp(), city: "", venueName: "", venueAddress: ""))
            }
            
            Button(action: {
                let newRelease = TicketRelease(name: "Early Bird", allocation: 50, price: 25.0, availability: .init(type: .scheduled, startDate: Timestamp(date: selectedShow?.date.dateValue() ?? Date())))
                ticketTypes.append(TicketType(name: "General Admission", releases: [newRelease]))
            }) {
                Label("Add Ticket Type", systemImage: "plus")
            }.buttonStyle(SecondaryButtonStyle())
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description").font(.headline)
            CustomTextEditor(placeholder: "Enter details about the event...", text: $description)
                .frame(minHeight: 100)
        }
    }
    
    private var importantInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Important Info").font(.headline)
            CustomTextEditor(placeholder: "Enter age restrictions or other important info for buyers...", text: $importantInfo)
                .frame(minHeight: 100)
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

        group.enter()
        db.collection("ticketedEvents")
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments { eventSnapshot, error in
                defer { group.leave() }
                if let eventDocs = eventSnapshot?.documents {
                    existingEventShowIDs = Set(eventDocs.compactMap { $0["showId"] as? String })
                }
            }
        
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
        
        let validTicketTypes = ticketTypes.filter { !$0.name.isEmpty && !$0.releases.isEmpty }
        
        let newEvent = TicketedEvent(
            ownerId: ownerId,
            tourId: tour.id!,
            showId: show.id!,
            status: .draft,
            description: description.isEmpty ? nil : description,
            importantInfo: importantInfo.isEmpty ? nil : importantInfo,
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

// --- THIS IS THE FIX: The missing helper views are now included in this file ---

fileprivate struct TicketTypeCardView: View {
    @Binding var ticketType: TicketType
    let show: Show

    var body: some View {
        VStack(alignment: .leading) {
            StyledInputField(placeholder: "Ticket Category (e.g., General Admission)", text: $ticketType.name)
            
            VStack {
                ForEach($ticketType.releases) { $release in
                    TicketReleaseRowView(release: $release, allReleases: ticketType.releases)
                    if release.id != ticketType.releases.last?.id {
                        Divider().padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
            
            Button(action: {
                let newRelease = TicketRelease(name: "New Release", allocation: 100, price: ticketType.releases.last?.price ?? 35.0, availability: .init(type: .onSaleImmediately))
                ticketType.releases.append(newRelease)
            }) {
                Label("Add Release", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .font(.caption)
            .padding(.top, 4)
        }
    }
}

fileprivate struct TicketReleaseRowView: View {
    @Binding var release: TicketRelease
    let allReleases: [TicketRelease]

    var otherReleases: [TicketRelease] {
        allReleases.filter { $0.id != release.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StyledInputField(placeholder: "Release Name", text: $release.name)
                StyledInputField(placeholder: "Qty", text: Binding(
                    get: { release.allocation > 0 ? "\(release.allocation)" : "" },
                    set: { release.allocation = Int($0) ?? 0 }
                 ))
                StyledInputField(placeholder: "Price", text: Binding(
                    get: { release.price > 0 ? String(format: "%.2f", release.price) : "" },
                    set: { release.price = Double($0) ?? 0.0 }
                 ))
            }

            Menu {
                ForEach(TicketAvailability.AvailabilityType.allCases, id: \.self) { type in
                     Button(type.description) { release.availability.type = type }
                }
            } label: {
                HStack {
                    Text("Availability:").foregroundColor(.secondary)
                    Text(release.availability.type.description).fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal, 12).padding(.vertical, 10).background(Color.black.opacity(0.15)).cornerRadius(10)
            }.buttonStyle(.plain)
            
            Text(release.availability.type.helperText)
                .font(.caption).foregroundColor(.secondary).padding(.leading, 4)

            if release.availability.type == .scheduled {
                HStack {
                    CustomDateField(date: Binding(
                        get: { release.availability.startDate?.dateValue() ?? Date() },
                        set: { release.availability.startDate = FirebaseFirestore.Timestamp(date: $0) }
                    ))
                    
                    if release.availability.endDate != nil {
                        CustomDateField(date: Binding(
                            get: { release.availability.endDate?.dateValue() ?? Date() },
                            set: { release.availability.endDate = FirebaseFirestore.Timestamp(date: $0) }
                        ))
                        Button(action: { release.availability.endDate = nil }) {
                            Image(systemName: "xmark.circle.fill")
                        }.buttonStyle(.plain)
                    } else {
                        Button("Add End Date") {
                            let startDate = release.availability.startDate?.dateValue() ?? Date()
                            release.availability.endDate = Timestamp(date: Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate)
                        }.buttonStyle(.plain)
                    }
                }
            }
            
            if release.availability.type == .afterPreviousSellsOut {
                Menu {
                    ForEach(otherReleases) { other in
                        Button(other.name) { release.availability.dependsOnReleaseID = other.id }
                    }
                } label: {
                    HStack {
                        Text("On sale after:").foregroundColor(.secondary)
                        Text(allReleases.first { $0.id == release.availability.dependsOnReleaseID }?.name ?? "Select a release")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }.buttonStyle(.plain)
            }
        }
    }
}
