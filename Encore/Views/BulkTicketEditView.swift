import SwiftUI
import FirebaseFirestore

struct BulkTicketEditView: View {
    @StateObject private var viewModel: BulkTicketEditViewModel
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    init(tour: Tour, selectedShowIDs: Set<String>, onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: BulkTicketEditViewModel(tour: tour, showIDs: selectedShowIDs))
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ticketTypesSection
                    descriptionSection
                    importantInfoSection
                    complimentaryTicketsSection
                }
                .padding(30)
            }
            
            footer
        }
        .frame(minWidth: 700, minHeight: 700)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
             HStack {
                Text("Bulk Edit Tickets")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                     Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            Text("These settings will be applied to all \(viewModel.showIDs.count) selected shows.")
                .foregroundColor(.secondary)
        }
        .padding(30)
    }
    
    private var footer: some View {
        HStack {
            Spacer()
            Button(action: {
                Task {
                    do {
                        try await viewModel.saveChanges()
                        onSave()
                        dismiss()
                    } catch {
                        print("Error saving bulk changes: \(error)")
                    }
                }
            }) {
                Text(viewModel.isSaving ? "Saving..." : "Apply to \(viewModel.showIDs.count) Shows")
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue, isLoading: viewModel.isSaving))
            .disabled(viewModel.isSaving)
        }
        .padding()
        .background(Material.bar)
    }

    // --- THIS IS THE FIX: UI refactored for new models ---
    private var ticketTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ticket Types").font(.headline)
            Text("These ticket types will replace any existing types on the selected shows.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach($viewModel.ticketTypes) { $ticketType in
                // In a real app, we would build a reusable card view here.
                // For simplicity, we'll embed the logic.
                VStack(alignment: .leading) {
                    StyledInputField(placeholder: "Category Name (e.g., GA)", text: $ticketType.name)
                    ForEach($ticketType.releases) { $release in
                        HStack {
                            StyledInputField(placeholder: "Release Name", text: $release.name)
                            StyledInputField(placeholder: "Qty", text: Binding(
                                get: { $release.wrappedValue.allocation > 0 ? "\($release.wrappedValue.allocation)" : "" },
                                set: { $release.wrappedValue.allocation = Int($0) ?? 0 }
                            ))
                            StyledInputField(placeholder: "Price", text: Binding(
                                get: { $release.wrappedValue.price > 0 ? String(format: "%.2f", $release.wrappedValue.price) : "" },
                                set: { $release.wrappedValue.price = Double($0) ?? 0.0 }
                            ))
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: {
                let newRelease = TicketRelease(name: "Early Bird", allocation: 50, price: 25.0, availability: .init(type: .onSaleImmediately))
                viewModel.ticketTypes.append(TicketType(name: "General Admission", releases: [newRelease]))
            }) {
                Label("Add Ticket Type", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description (About This Event)").font(.headline)
            CustomTextEditor(placeholder: "Enter details about the event for the ticket page...", text: $viewModel.description)
        }
    }

    private var importantInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Important Info").font(.headline)
            CustomTextEditor(placeholder: "e.g., Age restrictions, what to bring...", text: $viewModel.importantInfo)
        }
    }
    
    private var complimentaryTicketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Complimentary Tickets").font(.headline)
            StyledInputField(placeholder: "Number of comps", text: $viewModel.complimentaryTickets)
        }
    }
}
