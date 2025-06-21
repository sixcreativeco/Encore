import SwiftUI
import FirebaseFirestore

struct ContactEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    // FIX: The state now uses our new, top-level 'Contact' model.
    @State private var editableContact: Contact

    @State private var isSaving = false

    // Initializer now accepts the new 'Contact' model.
    init(contact: Contact) {
        self._editableContact = State(initialValue: contact)
    }
    
    private var isFormValid: Bool {
        !editableContact.name.trimmingCharacters(in: .whitespaces).isEmpty && !editableContact.roles.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Contact")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(32)

            // Scrollable Form Content
            ScrollView {
                // This will cause an error next, which is expected,
                // as ContactFormBody needs to be updated.
                ContactFormBody(contact: $editableContact, isDisabled: false)
                    .padding(.horizontal, 32)
            }

            // Footer with Save Button
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button(action: {
                        updateContact()
                    }) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Update Contact")
                            }
                            Spacer()
                        }
                        .fontWeight(.bold)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isFormValid || isSaving)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }
            .background(Material.bar)
        }
        .frame(width: 680, height: 750)
    }
    
    // --- FIX IS HERE ---
    private func updateContact() {
        guard let contactID = editableContact.id else {
            print("Error: Contact ID is nil. Cannot update contact.")
            return
        }
        guard isFormValid else { return }
        
        isSaving = true
        
        let db = Firestore.firestore()
        let documentRef = db.collection("contacts").document(contactID)
        
        do {
            // Use Codable to save the entire object directly to the top-level /contacts collection.
            try documentRef.setData(from: editableContact, merge: true) { error in
                self.isSaving = false
                if let error = error {
                    print("Error updating contact: \(error.localizedDescription)")
                } else {
                    print("✅ Contact updated successfully.")
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            print("❌ Error encoding contact for update: \(error.localizedDescription)")
            self.isSaving = false
        }
    }
}
