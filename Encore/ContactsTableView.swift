import SwiftUI

struct ContactsTableView: View {
    let contacts: [ContactModel]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Name").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Role").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Email").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Phone").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Notes").bold().frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)

            Divider()

            ForEach(contacts) { contact in
                NavigationLink(destination: ContactDetailView(contact: contact)) {
                    HStack {
                        Text(contact.name).frame(maxWidth: .infinity, alignment: .leading)
                        Text(contact.role).frame(maxWidth: .infinity, alignment: .leading)
                        Text(contact.email ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        Text(contact.phone ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        Text(contact.notes ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                Divider()
            }
        }
    }
}
