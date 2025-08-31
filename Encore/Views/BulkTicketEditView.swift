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
                        // In a real app, you would show an alert for this error
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

    private var ticketTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ticket Types").font(.headline)
            Text("These ticket types will replace any existing types on the selected shows.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach($viewModel.ticketTypes) { $ticketType in
                ticketTypeRow(ticketType: $ticketType)
                Divider().padding(.vertical, 4)
            }
            
            Button(action: {
                viewModel.ticketTypes.append(TicketType(name: "", allocation: 0, price: 0.0, currency: "NZD"))
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
    
    private func ticketTypeRow(ticketType: Binding<TicketType>) -> some View {
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
            Button(role: .destructive, action: {
                viewModel.ticketTypes.removeAll { $0.id == ticketType.id }
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
    }
}
