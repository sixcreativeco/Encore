import SwiftUI
import FirebaseFirestore
import Kingfisher

struct AddTicketsView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void // Completion handler to trigger a refresh
    
    // Form State
    @State private var selectedShowID: String = ""
    @State private var ticketTypes: [TicketType] = [TicketType(name: "General Admission", allocation: 0, price: 0.0, currency: "NZD")]
    @State private var description: String = ""
    @State private var restriction: TicketedEvent.Restriction = .allAges
    
    // Data for Picker
    @State private var upcomingShows: [Show] = []
    @State private var allTours: [Tour] = []
    
    @State private var isSaving = false
    
    private var selectedShow: Show? {
        upcomingShows.first { $0.id == selectedShowID }
    }
    
    private var selectedTour: Tour? {
        guard let show = selectedShow else { return nil }
        return allTours.first { $0.id == show.tourId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) { // Increased spacing
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
        // FIX: Replaced standard Picker with a custom styled Menu
        Menu {
            ForEach(upcomingShows) { show in
                let tour = allTours.first { $0.id == show.tourId }
                Button("\(tour?.artist ?? "N/A") - \(show.city)") {
                    selectedShowID = show.id ?? ""
                }
            }
        } label: {
            HStack {
                if let show = selectedShow, let tour = selectedTour {
                    Text("\(tour.artist) - \(show.city)")
                } else {
                    Text("Select a show...").foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .pickerStyle(.menu)
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
                Spacer() // Ensures content is aligned left
            }
            .padding()
            .frame(maxWidth: .infinity) // FIX: Makes container full-width
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
            // FIX: Using the updated CustomSegmentedPicker which now handles this styling
            CustomSegmentedPicker(selected: $restriction, options: TicketedEvent.Restriction.allCases)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveTicketedEvent) {
            Text("Save Tickets")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                // FIX: Updated button style
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(selectedShowID.isEmpty || isSaving)
    }
    
    // MARK: - Functions
    
    private func loadPrerequisites() {
        let db = Firestore.firestore()
        let today = Timestamp(date: Date())

        db.collection("shows").whereField("date", isGreaterThanOrEqualTo: today).getDocuments { showSnapshot, error in
            guard let showDocs = showSnapshot?.documents else { return }
            self.upcomingShows = showDocs.compactMap { try? $0.data(as: Show.self) }
        }
        
        db.collection("tours").getDocuments { tourSnapshot, error in
            guard let tourDocs = tourSnapshot?.documents else { return }
            self.allTours = tourDocs.compactMap { try? $0.data(as: Tour.self) }
        }
    }
    
    private func saveTicketedEvent() {
        guard let show = selectedShow, let tour = selectedTour else { return }
        isSaving = true
        
        let validTicketTypes = ticketTypes.filter { !$0.name.isEmpty && $0.allocation > 0 }
        
        let newEvent = TicketedEvent(
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
                    self.onSave() // Call the completion handler to trigger refresh
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
