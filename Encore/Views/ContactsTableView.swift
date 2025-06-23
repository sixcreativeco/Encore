import SwiftUI
import FirebaseFirestore

struct UnifiedContact: Identifiable, Hashable {
    let id: String
    var name: String
    var email: String?
    var phone: String?
    var roles: [String]
    var source: String
}

struct ContactsTableView: View {
    let contacts: [UnifiedContact]
    @Binding var sortField: String
    @Binding var sortAscending: Bool
    
    var onContactSelected: (UnifiedContact) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    sortableHeader("Name")
                    sortableHeader("Role")
                    sortableHeader("Email")
                    sortableHeader("Phone")
                    sortableHeader("Source")
                }
                .padding(.vertical, 8)
                Divider()

                ForEach(sortedContacts) { contact in
                    Button(action: { onContactSelected(contact) }) {
                        HStack {
                            Text(contact.name).frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.roles.joined(separator: ", ")).frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.email ?? "").frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.phone ?? "").frame(maxWidth: .infinity, alignment: .leading)
                            Text(contact.source).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }

    private var sortedContacts: [UnifiedContact] {
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
            case "Source":
                comparison = a.source < b.source
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
