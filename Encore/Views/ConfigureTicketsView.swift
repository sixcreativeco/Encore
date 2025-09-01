import SwiftUI
import FirebaseFirestore
import Kingfisher

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
             LandingPageConfigView(tour: viewModel.tour)
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

            ForEach(viewModel.shows) { show in
                 if let showId = show.id, let showIndex = viewModel.shows.firstIndex(where: { $0.id == showId }) {
                    ShowConfigurationCard(
                        show: $viewModel.shows[showIndex],
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
                        getTicketsSold: {
                            viewModel.getTicketsSold(for: viewModel.eventMap[showId]?.id ?? "")
                        },
                        isPublishing: viewModel.isPublishing[viewModel.eventMap[showId]?.id ?? ""] ?? false,
                        isFirstShow: showIndex == 0
                    )
                 }
            }
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
                    dismiss()
                }
            }) {
                Text(viewModel.isSaving ? "Saving..." : "Save & Close")
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
    let getTicketsSold: () -> Int
    let isPublishing: Bool
    let isFirstShow: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                     Text(show.venueName).font(.title2.bold())
                    // --- THIS IS THE FIX (Part 1) ---
                    // Replaced the default DatePicker with your custom styled one.
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
                            StyledInputField(placeholder: "External Ticket URL (optional)", text: Binding(
                                get: { event.externalTicketsUrl ?? "" },
                                set: { event.externalTicketsUrl = $0.isEmpty ? nil : $0 }
                            ))

                            Button(action: onCopy) {
                                Label("Copy settings from previous show", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isFirstShow)
                        }
                    }

                    ticketTypesSection
                    descriptionSection
                    importantInfoSection
                    
                    // --- THIS IS THE FIX (Part 2) ---
                    // The complimentary tickets section has been removed.
                    
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
        let totalAllocation = event.ticketTypes.reduce(0) { $0 + $1.allocation } + ticketsSold

        VStack(alignment: .leading, spacing: 12) {
            if totalAllocation > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    GradientProgressView(value: Double(ticketsSold), total: Double(totalAllocation))
                    Text("\(ticketsSold) of \(totalAllocation) tickets sold")
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
                        
                        Spacer()
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(urlString, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var ticketTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ticket Types").font(.headline)
            ForEach($event.ticketTypes) { $ticketType in
                ticketTypeRow(ticketType: $ticketType)
                Divider().padding(.vertical, 4)
            }
            Button(action: { event.ticketTypes.append(TicketType(name: "", allocation: 0, price: 0.0, currency: "NZD", availability: .init(type: .always))) }) {
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
    
    private func ticketTypeRow(ticketType: Binding<TicketType>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
             HStack(spacing: 8) {
                StyledInputField(placeholder: "Name (e.g., GA)", text: ticketType.name)
                StyledInputField(placeholder: "Allocation", text: Binding(
                    get: { ticketType.wrappedValue.allocation > 0 ? "\(ticketType.wrappedValue.allocation)" : "" },
                    set: { ticketType.wrappedValue.allocation = Int($0) ?? 0 }
                 ))
                StyledInputField(placeholder: "Price", text: Binding(
                    get: { ticketType.wrappedValue.price > 0 ? String(format: "%.2f", ticketType.wrappedValue.price) : "" },
                    set: { ticketType.wrappedValue.price = Double($0) ?? 0.0 }
                 ))
                StyledInputField(placeholder: "NZD", text: ticketType.currency).frame(width: 60)
            }

            Menu {
                ForEach(TicketAvailability.AvailabilityType.allCases, id: \.self) { type in
                     Button(action: {
                        if ticketType.wrappedValue.availability == nil {
                            ticketType.wrappedValue.availability = .init(type: type)
                       } else {
                            ticketType.wrappedValue.availability?.type = type
                        }
                    }) {
                         Text(type.description)
                    }
                }
            } label: {
                HStack {
                    Text("Availability:")
                         .foregroundColor(.secondary)
                    Text(ticketType.wrappedValue.availability?.type.description ?? "Not Set")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                         .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.15))
                .cornerRadius(10)
             }
            .buttonStyle(.plain)

            if ticketType.wrappedValue.availability?.type == .custom {
                HStack {
                     CustomDateField(date: Binding(
                        get: { ticketType.wrappedValue.availability?.startDate?.dateValue() ?? Date() },
                        set: { ticketType.wrappedValue.availability?.startDate = FirebaseFirestore.Timestamp(date: $0) }
                     ))
                     CustomDateField(date: Binding(
                         get: { ticketType.wrappedValue.availability?.endDate?.dateValue() ?? Date() },
                        set: { ticketType.wrappedValue.availability?.endDate = FirebaseFirestore.Timestamp(date: $0) }
                     ))
                }
            }
        }
    }
}
