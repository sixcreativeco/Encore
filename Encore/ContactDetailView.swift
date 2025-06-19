import SwiftUI

struct ContactDetailView: View {
    // The contact model is passed from a parent view.
    let contact: ContactModel

    // A private state copy is needed because ContactFormBody requires a Binding.
    // This allows the form to display the data without allowing the detail view itself to be mutated.
    @State private var formContact: ContactModel

    // State to control the presentation of the edit sheet.
    @State private var isPresentingEditView = false

    // The initializer sets up the private state copy when the view is created.
    init(contact: ContactModel) {
        self.contact = contact
        self._formContact = State(initialValue: contact)
    }

    var body: some View {
        // We reuse the exact same form body here, but pass `isDisabled: true`
        // to make all the input fields read-only.
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
                // When "Edit" is tapped, we will present the ContactEditView.
                // This requires ContactEditView to be created next.
                ContactEditView(contact: self.contact)
            }
    }
}

struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Example of how to use the ContactDetailView within a NavigationView
        NavigationView {
            ContactDetailView(contact: ContactModel(
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
