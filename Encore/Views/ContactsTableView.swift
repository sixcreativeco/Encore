import SwiftUI
import FirebaseFirestore

struct ContactsTableView: View {
    // FIX: The view now accepts an array of our new 'Contact' model.
    let contacts: [Contact]
    @Binding var sortField: String
    @Binding var sortAscending: Bool
    
    // FIX: The closure now provides the new 'Contact' model.
    var onContactSelected: (Contact) -> Void

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

                // FIX: The ForEach now iterates directly over the sorted contacts array.
                // The complex merging logic has been removed.
                ForEach(sortedContacts) { contact in
                    Button(action: { onContactSelected(contact) }) {
                        HStack {
                            Text(contact.name).frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.roles.joined(separator: ", ")).frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.email ?? "").frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.phone ?? "").frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.notes ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle()) // Ensure the whole area is tappable
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }

    // FIX: This computed property now sorts the new [Contact] array directly.
    private var sortedContacts: [Contact] {
        contacts.sorted { a, b in
            let comparison: Bool
            switch sortField {
            case "Name":
                comparison = a.name < b.name
            case "Role":
                comparison = a.roles.joined() < b.roles.joined()
            case "Email":
                comparison = (a.email ?? "") < (b.email ?? "")
            case "Phone":
                comparison = (a.phone ?? "") < (b.phone ?? "")
            default:
                comparison = a.name < b.name
            }
            return sortAscending ? comparison : !comparison
        }
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
