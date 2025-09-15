import SwiftUI
import Kingfisher
import FirebaseFirestore

struct ConfigureTicketsView: View {
    @StateObject private var viewModel: ConfigureTicketsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showLandingPageConfig = false
    @State private var expandedShowID: String?

    init(tour: Tour, show: Show? = nil) {
        _viewModel = StateObject(wrappedValue: ConfigureTicketsViewModel(tour: tour, showToExpand: show))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            contentView
            footer
        }
        .frame(minWidth: 800, minHeight: 800)
        .onAppear {
            self.expandedShowID = viewModel.showToExpandId
        }
        .task {
            await viewModel.fetchData()
        }
        .sheet(isPresented: $showLandingPageConfig) {
             LandingPageConfigView(tour: $viewModel.tour)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
             HStack {
                 Text("Configure Tickets")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                     Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            Text("Set up ticket types, pricing, and availability for each show on the tour.")
                 .foregroundColor(.secondary)
        }
        .padding(30)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
           ProgressView("Loading Show Information...")
               .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
           ScrollView {
               showList
           }
        }
    }
    
    private var showList: some View {
        VStack(alignment: .leading, spacing: 20) {
            TourDefaultsSection(tour: $viewModel.tour)

            // --- FIX START: Iterate over indices to allow for bindings ---
            ForEach($viewModel.shows.indices, id: \.self) { showIndex in
                let show = viewModel.shows[showIndex]
                if let showId = show.id {
                    ShowConfigurationCard(
                        show: $viewModel.shows[showIndex], // This binding is now valid
                        tour: viewModel.tour,
                        event: Binding(
                            get: { viewModel.eventMap[showId] ?? placeholderEvent(for: showId) },
                            set: { viewModel.eventMap[showId] = $0 }
                        ),
                        isExpanded: Binding(
                            get: { expandedShowID == showId },
                            set: { isExpanded in
                                withAnimation(.easeInOut) {
                                    expandedShowID = isExpanded ? showId : nil
                                }
                            }
                        ),
                        onCopy: {
                            if showIndex > 0 {
                                let previousShowID = viewModel.shows[showIndex - 1].id!
                                viewModel.copySettings(from: previousShowID, to: showId)
                            }
                        },
                        onTogglePublish: {
                            viewModel.handlePublishToggle(for: showId)
                        },
                        onRefresh: {
                            if let event = viewModel.eventMap[showId] {
                                viewModel.refreshPublishedPage(for: event)
                            }
                        },
                        getTicketsSold: {
                            viewModel.getTicketsSold(for: viewModel.eventMap[showId]?.id ?? "")
                        },
                        isPublishing: viewModel.isPublishing[viewModel.eventMap[showId]?.id ?? ""] ?? false,
                        isRefreshing: viewModel.isRefreshing[viewModel.eventMap[showId]?.id ?? ""] ?? false,
                        isFirstShow: showIndex == 0
                    )
                }
            }
            // --- FIX END ---
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }

    private var footer: some View {
        HStack {
            Button("Landing Page") {
                showLandingPageConfig = true
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            Button(action: {
                Task {
                    await viewModel.saveAllChanges()
                }
            }) {
                Text(viewModel.isSaving ? "Saving..." : "Save Changes")
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue, isLoading: viewModel.isSaving))
            .disabled(viewModel.isSaving)
        }
        .padding()
        .background(Material.bar)
    }
    
    private func placeholderEvent(for showId: String) -> TicketedEvent {
        return TicketedEvent(
            ownerId: viewModel.tour.ownerId,
            tourId: viewModel.tour.id ?? "",
            showId: showId,
            status: .draft,
            onSaleDate: nil,
            ticketTypes: []
        )
    }
}

// MARK: - Tour Defaults Section

fileprivate struct TourDefaultsSection: View {
    @Binding var tour: Tour
    @State private var isCollapsed = true
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tour Ticketing Defaults").font(.title2.bold())
                Spacer()
                 Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { isCollapsed.toggle() } }
            
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 24) {
                    Divider()
                    Text("These settings can be used as a template for all shows on this tour. Your server will automatically apply them to any new show you create.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Description").font(.headline)
                        CustomTextEditor(placeholder: "Default 'About This Event' info...", text: Binding(
                            get: { tour.defaultEventDescription ?? "" },
                            set: { tour.defaultEventDescription = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Important Info").font(.headline)
                        CustomTextEditor(placeholder: "Default policies (e.g., Age restrictions)...", text: Binding(
                            get: { tour.defaultImportantInfo ?? "" },
                            set: { tour.defaultImportantInfo = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }
                .padding(.top)
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
}


// MARK: - Show Configuration Card

fileprivate struct ShowConfigurationCard: View {
    @Binding var show: Show
    let tour: Tour
    @Binding var event: TicketedEvent
    @Binding var isExpanded: Bool
    
    let onCopy: () -> Void
    let onTogglePublish: () -> Void
    let onRefresh: () -> Void
    let getTicketsSold: () -> Int
    let isPublishing: Bool
    let isRefreshing: Bool
    let isFirstShow: Bool
    
    private let currencyOptions = ["NZD", "AUD", "USD", "EUR", "GBP"]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                     Text(show.venueName).font(.title2.bold())
                    CustomDateField(date: Binding(
                        get: { show.date.dateValue() },
                        set: { newDate in show.date = Timestamp(date: newDate) }
                    ))
                }
                Spacer()
                 Image(systemName: "chevron.right")
                   .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 24) {
                    Divider()
                    salesAndURLSection
                    
                    HStack(alignment: .top, spacing: 16) {
                        KFImage(URL(string: show.showSpecificPosterUrl ?? tour.posterURL ?? ""))
                             .placeholder {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                     Image(systemName: "photo.on.rectangle.angled")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120).cornerRadius(6)

                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: onCopy) {
                                Label("Copy settings from previous show", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isFirstShow)
                        }
                    }
                    
                    currencySection
                    ticketTypesSection
                    descriptionSection
                    importantInfoSection
                    externalURLSection
                    
                    Button(action: onTogglePublish) {
                        Text(event.status == .published ? "Unpublish Tickets" : "Publish Tickets")
                    }
                    .buttonStyle(PrimaryButtonStyle(
                        color: event.status == .published ? .red.opacity(0.8) : .green.opacity(0.8),
                        isLoading: isPublishing
                    ))
                    .disabled(isPublishing)
                }
                .padding(.top)
            }
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var salesAndURLSection: some View {
        let ticketsSold = getTicketsSold()
        let totalAllocation = event.ticketTypes.flatMap { $0.releases }.reduce(0) { $0 + $1.allocation } + ticketsSold

        VStack(alignment: .leading, spacing: 12) {
            if totalAllocation > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    GradientProgressView(value: Double(ticketsSold), total: Double(totalAllocation))
                    Text("\(ticketsSold) of \(totalAllocation) sold")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            if event.status == .published, let eventId = event.id {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TICKET LINK").font(.caption).foregroundColor(.secondary)
                    HStack {
                        let urlString = "https://en-co.re/event/\(eventId)"
                        Link(urlString, destination: URL(string: urlString)!)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(urlString, forType: .string)
                        }) { Image(systemName: "doc.on.doc") }.buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: onRefresh) {
                            if isRefreshing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Label("Refresh Site", systemImage: "arrow.clockwise")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isRefreshing)
                    }
                }
            }
        }
    }
    
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Currency").font(.headline)
            Text("Select the currency for all ticket sales for this show.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(currencyOptions, id: \.self) { currency in
                    Button(currency) { event.currency = currency }
                }
            } label: {
                HStack {
                    Text(event.currency ?? "Select Currency...")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(12)
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var ticketTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ticket Types").font(.headline)
            Text("You can add multiple releases for a single ticket type. Eg, Early Bird, Second Release.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach($event.ticketTypes) { $ticketType in
                TicketTypeCardView(ticketType: $ticketType, show: show)
            }
            
            Button(action: {
                let newRelease = TicketRelease(name: "Early Bird", allocation: 50, price: 25.0, availability: .init(type: .scheduled, startDate: Timestamp(date: show.date.dateValue())))
                event.ticketTypes.append(TicketType(name: "General Admission", releases: [newRelease]))
            }) {
                Label("Add Ticket Type", systemImage: "plus")
            }.buttonStyle(SecondaryButtonStyle())
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description (About This Event)").font(.headline)
            CustomTextEditor(placeholder: "Enter details about the event for the ticket page...", text: Binding(
                 get: { event.description ?? "" },
                set: { event.description = $0.isEmpty ? nil : $0 }
            ))
        }
    }
    
    private var importantInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Important Info").font(.headline)
             CustomTextEditor(placeholder: "e.g., Age restrictions, what to bring...", text: Binding(
                get: { event.importantInfo ?? "" },
                set: { event.importantInfo = $0.isEmpty ? nil : $0 }
            ))
        }
    }
    
    private var externalURLSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("External Ticket Link").font(.headline)
            Text("If you're using another provider for this show, paste the URL here. This will override Encore's ticketing.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            StyledInputField(placeholder: "https://...", text: Binding(
                get: { event.externalTicketsUrl ?? "" },
                set: { event.externalTicketsUrl = $0.isEmpty ? nil : $0 }
            ))
        }
    }
}

fileprivate struct TicketTypeCardView: View {
    @Binding var ticketType: TicketType
    let show: Show

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StyledInputField(placeholder: "Ticket Category (e.g., General Admission)", text: $ticketType.name)
                .font(.title2)
            
            VStack(spacing: 12) {
                ForEach($ticketType.releases) { $release in
                    TicketReleaseRowView(
                        release: $release,
                        allReleasesInType: ticketType.releases
                    )
                    if release.id != ticketType.releases.last?.id {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.1))
            .cornerRadius(12)
            
            ActionButton(title: "Add Release for \(ticketType.name.isEmpty ? "Ticket" : ticketType.name)", icon: "plus", color: .accentColor.opacity(0.3)) {
                let newRelease = TicketRelease(name: "New Release", allocation: 100, price: ticketType.releases.last?.price ?? 35.0, availability: .init(type: .onSaleImmediately))
                ticketType.releases.append(newRelease)
            }
        }
        .padding()
        .background(Material.ultraThin)
        .cornerRadius(16)
    }
}

fileprivate struct TicketReleaseRowView: View {
    @Binding var release: TicketRelease
    let allReleasesInType: [TicketRelease]

    private var previousRelease: TicketRelease? {
        guard let currentIndex = allReleasesInType.firstIndex(where: { $0.id == release.id }), currentIndex > 0 else {
            return nil
        }
        return allReleasesInType[currentIndex - 1]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StyledInputField(placeholder: "Release Name", text: $release.name)
                .font(.headline)
            
            HStack(spacing: 8) {
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
                     Button(type.description) {
                         release.availability.type = type
                         if type == .afterPreviousSellsOut, let prev = previousRelease {
                             release.availability.dependsOnReleaseID = prev.id
                         }
                     }
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
                VStack(alignment: .leading, spacing: 8) {
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
                            }.buttonStyle(.plain).font(.caption)
                        }
                    }
                    if release.availability.endDate != nil {
                        Toggle("End sale when allocation runs out (whichever comes first)", isOn: Binding(
                            get: { release.availability.endWhenSoldOut ?? false },
                            set: { release.availability.endWhenSoldOut = $0 }
                        )).toggleStyle(.checkbox).font(.caption)
                    }
                }
            }
            
            if release.availability.type == .afterPreviousSellsOut {
                if let prev = previousRelease {
                    Text("On sale after **'\(prev.name)'** sells out.")
                        .font(.caption)
                } else {
                    Text("Warning: No previous release to depend on. Add a release before this one.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
