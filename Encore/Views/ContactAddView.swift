import SwiftUI
import FirebaseFirestore

struct ContactAddView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // The state holds a temporary, blank contact object for the form to fill.
    @State private var newContact = Contact(ownerId: "", name: "", roles: [])
    @State private var isSaving = false
    
    var onContactAdded: () -> Void

    private var isFormValid: Bool {
        !newContact.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add New Contact")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(32)

            ScrollView {
                // The ContactFormBody correctly binds to our temporary newContact state.
                ContactFormBody(contact: $newContact, isDisabled: false)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button(action: {
                        saveContact()
                    }) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save Contact")
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
    private func saveContact() {
        guard let userID = appState.userID else {
            print("Error: User ID is nil. Cannot save contact.")
            return
        }
        guard isFormValid else { return }
        
        isSaving = true
        
        // Create a new, final Contact object with the correct ownerId from the AppState.
        // This respects the 'let' constant nature of the property.
        let contactToSave = Contact(
            ownerId: userID,
            name: newContact.name.trimmingCharacters(in: .whitespaces),
            roles: newContact.roles,
            email: newContact.email,
            phone: newContact.phone,
            notes: newContact.notes,
            location: newContact.location,
            profileImageURL: newContact.profileImageURL,
            dateOfBirth: newContact.dateOfBirth,
            countryOfBirth: newContact.countryOfBirth,
            passport: newContact.passport,
            documents: newContact.documents,
            emergencyContact: newContact.emergencyContact,
            allergies: newContact.allergies,
            medications: newContact.medications
        )
        
        let db = Firestore.firestore()
        
        do {
            // Use Codable to save the new object directly to the top-level /contacts collection
            try db.collection("contacts").addDocument(from: contactToSave) { error in
                self.isSaving = false
                if let error = error {
                    print("Error saving contact: \(error.localizedDescription)")
                } else {
                    print("✅ Contact saved successfully.")
                    self.onContactAdded()
                    self.dismiss()
                }
            }
        } catch {
            print("❌ Error encoding contact for save: \(error.localizedDescription)")
            self.isSaving = false
        }
    }
}
