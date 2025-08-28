import SwiftUI
import FirebaseFirestore

struct ContactEditView: View {
    @EnvironmentObject var appState: AppState
    
    // This view now correctly takes a Binding to the optional contact in AppState.
    @Binding var contact: Contact?

    @State private var isSaving = false

    private var isFormValid: Bool {
        if let contact = contact {
            return !contact.name.trimmingCharacters(in: .whitespaces).isEmpty && !contact.roles.isEmpty
        }
        return false
    }

    var body: some View {
        // This guard safely unwraps the contact. The view's content is only built if a contact exists.
        if var unwrappedContact = contact {
            // This creates a non-optional binding for the form body to use.
            let contactBinding = Binding(
                get: { unwrappedContact },
                set: { updatedContact in
                    // When the form changes the contact, update the state here.
                    self.contact = updatedContact
                    unwrappedContact = updatedContact
                }
            )

            VStack(spacing: 0) {
                // Header
                HStack {
                    StyledInputField(placeholder: "Full Name", text: contactBinding.name)
                        .font(.largeTitle.bold())

                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding([.horizontal, .top], 32)
                .padding(.bottom, 16)

                // Scrollable Form Content
                ScrollView {
                    ContactFormBody(contact: contactBinding, isDisabled: false)
                        .padding(.horizontal, 32)
                }

                // Footer with Save Button
                HStack {
                    Button(action: { updateContact(contactToSave: unwrappedContact) }) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().colorInvert()
                            } else {
                                Text("Save")
                            }
                            Spacer()
                        }
                        .fontWeight(.bold)
                        .padding()
                        .background(isFormValid ? Color.white : Color.gray)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isFormValid || isSaving)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
            .background(.regularMaterial)
        }
    }
    
    private func dismiss() {
        withAnimation {
            appState.contactToEdit = nil
            appState.isContactPanelManuallyDismissed = true
        }
    }
    
    private func updateContact(contactToSave: Contact) {
        guard let contactID = contactToSave.id else { return }
        guard isFormValid else { return }
        
        isSaving = true
        let db = Firestore.firestore()
        let documentRef = db.collection("contacts").document(contactID)
        
        do {
            try documentRef.setData(from: contactToSave, merge: true) { error in
                self.isSaving = false
                if let error = error {
                    print("Error updating contact: \(error.localizedDescription)")
                } else {
                    print("✅ Contact updated successfully.")
                    dismiss()
                }
            }
        } catch {
            print("❌ Error encoding contact for update: \(error.localizedDescription)")
            self.isSaving = false
        }
    }
}
