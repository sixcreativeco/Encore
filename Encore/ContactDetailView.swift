import SwiftUI

struct ContactDetailView: View {
    @State var contact: ContactModel

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Name", text: $contact.name)
                TextField("Role", text: $contact.role)
            }

            Section(header: Text("Contact Details")) {
                TextField("Email", text: emailBinding)
                TextField("Phone", text: phoneBinding)
                TextField("Notes", text: notesBinding)
            }
        }
        .navigationTitle("Edit Contact")
    }

    // Computed bindings to safely unwrap optionals
    var emailBinding: Binding<String> {
        Binding<String>(
            get: { contact.email ?? "" },
            set: { contact.email = $0 }
        )
    }

    var phoneBinding: Binding<String> {
        Binding<String>(
            get: { contact.phone ?? "" },
            set: { contact.phone = $0 }
        )
    }

    var notesBinding: Binding<String> {
        Binding<String>(
            get: { contact.notes ?? "" },
            set: { contact.notes = $0 }
        )
    }
}
