import SwiftUI
import FirebaseFirestore

struct ContactEditView: View {
    // Environment
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    // The original contact model to edit.
    let originalContact: ContactModel

    // State
    @State private var editableContact: ContactModel
    @State private var isSaving = false

    // Initializer
    init(contact: ContactModel) {
        self.originalContact = contact
        self._editableContact = State(initialValue: contact)
    }
    
    // Form validation
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
    
    /// Converts the ContactModel to a Firestore-compatible dictionary.
    private func toFirestore(contact: ContactModel) -> [String: Any] {
        var data: [String: Any] = [
            "name": contact.name,
            "roles": contact.roles,
            "email": contact.email ?? NSNull(),
            "phone": contact.phone ?? NSNull(),
            "notes": contact.notes ?? NSNull(),
            "location": contact.location ?? NSNull(),
            "profileImageURL": contact.profileImageURL ?? NSNull(),
            "dateOfBirth": contact.dateOfBirth != nil ? Timestamp(date: contact.dateOfBirth!) : NSNull(),
            "countryOfBirth": contact.countryOfBirth ?? NSNull(),
            "allergies": contact.allergies ?? NSNull(),
            "medications": contact.medications ?? NSNull(),
            // FIXED: Preserve original creation date, or set a new one if it's somehow nil.
            "createdAt": Timestamp(date: originalContact.createdAt ?? Date())
        ]
        
        if let passport = contact.passport {
            data["passport"] = [
                "passportNumber": passport.passportNumber,
                "issuedDate": Timestamp(date: passport.issuedDate),
                "expiryDate": Timestamp(date: passport.expiryDate),
                "issuingCountry": passport.issuingCountry
            ]
        }
        
        if let emergencyContact = contact.emergencyContact {
            data["emergencyContact"] = [
                "name": emergencyContact.name,
                "phone": emergencyContact.phone
            ]
        }
        
        if let documents = contact.documents {
             data["documents"] = documents.map { ["id": $0.id, "name": $0.name, "url": $0.url] }
        }
        
        return data
    }
    
    /// Saves the updated contact to Firestore, merging the changes.
    private func updateContact() {
        guard let userID = appState.userID else {
            print("Error: User ID is nil. Cannot update contact.")
            return
        }

        guard isFormValid else { return }
        
        isSaving = true
        
        let db = Firestore.firestore()
        let documentRef = db.collection("users").document(userID).collection("contacts").document(originalContact.id)
        let contactData = toFirestore(contact: editableContact)
        
        documentRef.setData(contactData, merge: true) { error in
            isSaving = false
            if let error = error {
                print("Error updating contact: \(error.localizedDescription)")
            } else {
                print("Contact updated successfully.")
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
