import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AppKit
import UniformTypeIdentifiers
import Kingfisher

struct ConfigureTicketsView: View {
    @StateObject private var viewModel: ConfigureTicketsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showLandingPageConfig = false

    init(tour: Tour) {
        _viewModel = StateObject(wrappedValue: ConfigureTicketsViewModel(tour: tour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

             if viewModel.isLoading {
                ProgressView("Loading Show Information...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.shows.indices, id: \.self) { index in
                            let show = viewModel.shows[index]
                            if let showId = show.id {
                                 ShowConfigurationCard(
                                    show: show,
                                     tour: viewModel.tour,
                                    event: Binding(
                                        get: { viewModel.eventMap[showId] ?? placeholderEvent(for: showId) },
                                        set: { viewModel.eventMap[showId] = $0 }
                                    ),
                                     onCopy: {
                                        if index > 0, let sourceShowId = viewModel.shows[index-1].id {
                                            viewModel.copySettings(from: sourceShowId, to: showId)
                                        }
                                    },
                                     onTogglePublish: {
                                        viewModel.handlePublishToggle(for: showId)
                                     },
                                    isPublishing: viewModel.isPublishing[show.id ?? ""] ?? false,
                                    isFirst: index == 0
                                )
                             }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                 }
            }
            
            footer
        }
        .frame(minWidth: 800, minHeight: 800)
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

            Text("Set up ticket types, pricing, and availability for each show on the tour. You can also provide a link to an external ticketing provider.")
                .foregroundColor(.secondary)
        }
        .padding(30)
    }

    private var footer: some View {
        HStack {
            Button("Landing Page") {
                showLandingPageConfig = true
             }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            Button(action: {
                Task { await viewModel.saveAllChanges() }
            }) {
                Text(viewModel.isSaving ? "Saving..." : "Save All Configurations")
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
            ticketTypes: []
        )
    }
}

fileprivate struct ShowConfigurationCard: View {
    let show: Show
    let tour: Tour
    @Binding var event: TicketedEvent
     let onCopy: () -> Void
    let onTogglePublish: () -> Void
    let isPublishing: Bool
    let isFirst: Bool
    
    @State private var isCollapsed = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                     Text(show.venueName).font(.title2.bold())
                    Text("\(show.city) - \(show.date.dateValue().formatted(date: .long, time: .omitted))")
                        .foregroundColor(.secondary)
                }
                Spacer()
                 Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { isCollapsed.toggle() }
            }

            if !isCollapsed {
                VStack(alignment: .leading, spacing: 24) {
                    Divider()

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
                            
 .onTapGesture {
                                // Add file selection logic here
                            }

                        VStack(alignment: .leading, spacing: 12) {
                             StyledInputField(placeholder: "External Ticket URL (optional)", text: Binding(
                                get: { event.externalTicketsUrl ?? "" },
                                set: { event.externalTicketsUrl = $0.isEmpty ? nil : $0 }
                            ))

                            Button(action: onCopy) {
                                Label("Copy settings from previous show", systemImage: "doc.on.doc")
                             }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isFirst)
                         }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ticket Types").font(.headline)
                        
 ForEach($event.ticketTypes) { $ticketType in
                            ticketTypeRow(ticketType: $ticketType)
                            Divider().padding(.vertical, 4)
                        }
                         Button(action: { event.ticketTypes.append(TicketType(name: "", allocation: 0, price: 0.0, currency: "NZD", availability: .init(type: .always))) }) {
                            Label("Add Ticket Type", systemImage: "plus")
                        }
                         .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description (About This Event)").font(.headline)
                        CustomTextEditor(placeholder: "Enter details about the event for the ticket page...", text: Binding(
                            get: { event.description ?? "" },
                            set: { event.description = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Info").font(.headline)
                         CustomTextEditor(placeholder: "e.g., Age restrictions, what to bring...", text: Binding(
                            get: { event.importantInfo ?? "" },
                            set: { event.importantInfo = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                         Text("Complimentary Tickets").font(.headline)
                        StyledInputField(placeholder: "Number of comps", text: Binding(
                            get: { event.complimentaryTickets.map(String.init) ?? "" },
                             set: { event.complimentaryTickets = Int($0) }
                        ))
                    }
                    
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
