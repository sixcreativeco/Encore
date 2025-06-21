import SwiftUI
import FirebaseFirestore

struct DBAddContactView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var newContact: Contact
    @State private var isSaving = false
    
    var onContactAdded: () -> Void
    
    init(onContactAdded: @escaping () -> Void) {
        self.onContactAdded = onContactAdded
        // Initialize with a blank contact model for the form.
        // The ownerId will be replaced with the real one upon saving.
        self._newContact = State(initialValue: Contact(ownerId: "", name: "", roles: []))
    }

    private var isFormValid: Bool {
        !newContact.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !newContact.roles.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Add New Contact")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding([.top, .horizontal], 32)
            .padding(.bottom, 16)
            
            // This now correctly passes a binding to the new Contact model.
            ContactFormBody(contact: $newContact, isDisabled: false)
            
            Spacer()
            
            // Footer with Save Button
            HStack {
                Spacer()
                Button(action: saveContact) {
                    HStack {
                        if isSaving {
                            ProgressView().colorInvert()
                        } else {
                            Text("Save Contact")
                        }
                    }
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid || isSaving)
                Spacer()
            }
            .padding(.vertical)
        }
        .frame(minWidth: 700, minHeight: 800)
        .background(Color(red: 28/255, green: 28/255, blue: 30/255))
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
            name: newContact.name,
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
            // createdAt is handled by @ServerTimestamp in the model
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
