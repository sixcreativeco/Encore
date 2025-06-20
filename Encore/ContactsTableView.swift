import SwiftUI

struct ContactsTableView: View {
    let contacts: [ContactModel]
    @Binding var sortField: String
    @Binding var sortAscending: Bool
    var onContactSelected: (ContactModel) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Header row remains the same
                HStack {
                    sortableHeader("Name")
                    sortableHeader("Role")
                    sortableHeader("Email")
                    sortableHeader("Phone")
                    sortableHeader("Notes")
                }
                .padding(.vertical, 8)
                Divider()

                // Data rows are now Buttons that trigger the sheet
                ForEach(sortedMergedContacts, id: \.id) { contact in
                    if let originalContact = findOriginalContact(for: contact.id) {
                        Button(action: { onContactSelected(originalContact) }) {
                            HStack {
                                Text(contact.name).frame(maxWidth: .infinity, alignment: .leading)
                                Text(contact.roles.joined(separator: ", ")).frame(maxWidth: .infinity, alignment: .leading)
                                Text(contact.emails.joined(separator: ", ")).frame(maxWidth: .infinity, alignment: .leading)
                                Text(contact.phones.joined(separator: ", ")).frame(maxWidth: .infinity, alignment: .leading)
                                Text(contact.notes.joined(separator: ", ")).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle()) // Ensure the whole area is tappable
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var mergedContacts: [MergedContact] {
        var dict: [String: MergedContact] = [:]

        for contact in contacts {
            let key = contact.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            if var existing = dict[key] {
                // FIXED: Iterate over the `roles` array and insert each element into the Set.
                contact.roles.forEach { existing.roles.insert($0) }
                
                if let email = contact.email, !email.isEmpty { existing.emails.insert(email) }
                if let phone = contact.phone, !phone.isEmpty { existing.phones.insert(phone) }
                if let note = contact.notes, !note.isEmpty { existing.notes.insert(note) }
                dict[key] = existing
            } else {
                dict[key] = MergedContact(
                    id: contact.id, // Store the ID of the original contact
                    name: contact.name,
                    // FIXED: Initialize the Set directly from the `roles` array.
                    roles: Set(contact.roles),
                    emails: contact.email == nil || contact.email!.isEmpty ? [] : [contact.email!],
                    phones: contact.phone == nil || contact.phone!.isEmpty ? [] : [contact.phone!],
                    notes: contact.notes == nil || contact.notes!.isEmpty ? [] : [contact.notes!]
                )
            }
        }
        return Array(dict.values)
    }

    private var sortedMergedContacts: [MergedContact] {
        mergedContacts.sorted { a, b in
            let comparison: Bool
            switch sortField {
            case "Name": comparison = a.name < b.name
            case "Role": comparison = a.roles.joined() < b.roles.joined()
            default: comparison = a.name < b.name
            }
            return sortAscending ? comparison : !comparison
        }
    }
    
    private func findOriginalContact(for id: String) -> ContactModel? {
        return contacts.first { $0.id == id }
    }

    private func sortableHeader(_ field: String) -> some View {
        Button(action: {
            if sortField == field {
                sortAscending.toggle()
            } else {
                sortField = field
                sortAscending = true
            }
        }) {
            HStack {
                Text(field).bold()
                if sortField == field {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

// MODIFIED: Added 'id' to track the original contact
struct MergedContact: Hashable, Identifiable {
    var id: String
    var name: String
    var roles: Set<String> = []
    var emails: Set<String> = []
    var phones: Set<String> = []
    var notes: Set<String> = []
}
