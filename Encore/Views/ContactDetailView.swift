import SwiftUI
import FirebaseFirestore

struct ContactDetailView: View {
    // FIX: The view now accepts the new 'Contact' model.
    let contact: Contact

    // FIX: The private state copy now also uses the new 'Contact' model.
    @State private var formContact: Contact

    // State to control the presentation of the edit sheet.
    @State private var isPresentingEditView = false

    // The initializer correctly sets up the private state copy when the view is created.
    init(contact: Contact) {
        self.contact = contact
        self._formContact = State(initialValue: contact)
    }

    var body: some View {
        // We reuse the exact same form body here, but pass `isDisabled: true`
        // to make all the input fields read-only.
        // This will cause an error next, because ContactFormBody needs to be updated.
        ContactFormBody(contact: $formContact, isDisabled: true)
            .navigationTitle(contact.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        isPresentingEditView = true
                    }
                }
            }
            .sheet(isPresented: $isPresentingEditView) {
                // This will cause an error next, because ContactEditView needs to be updated.
                ContactEditView(contact: self.contact)
            }
    }
}

struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Example of how to use the ContactDetailView within a NavigationView
        NavigationView {
            // FIX: The preview now uses the new 'Contact' model.
            ContactDetailView(contact: Contact(
                ownerId: "previewOwner",
                name: "Taine Noble",
                roles: ["Content Creator", "Lighting", "Tour Manager"],
                email: "taine.noble@example.com",
                phone: "+64 21 123 4567",
                location: "Auckland, NZ"
            ))
        }
        .preferredColorScheme(.dark)
    }
}
