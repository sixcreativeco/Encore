import SwiftUI
import FirebaseFirestore

struct DBAddContactView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var newContact: ContactModel
    @State private var isSaving = false
    
    // This closure can be used to refresh the list view after a new contact is added.
    var onContactAdded: () -> Void
    
    init(onContactAdded: @escaping () -> Void) {
        self.onContactAdded = onContactAdded
        // Initialize with an empty contact model for the form
        _newContact = State(initialValue: ContactModel(name: "", roles: []))
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
            
            // Reusable Form Body
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
            "createdAt": Timestamp(date: Date())
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
    
    private func saveContact() {
        guard let userID = appState.userID else {
            print("Error: User ID is nil. Cannot save contact.")
            return
        }
        
        isSaving = true
        
        let db = Firestore.firestore()
        
        // Use the contact's generated ID for the document ID
        let documentRef = db.collection("users").document(userID).collection("contacts").document(newContact.id)
        
        let contactData = toFirestore(contact: newContact)
        
        documentRef.setData(contactData) { error in
            isSaving = false
            if let error = error {
                print("Error saving contact: \(error.localizedDescription)")
            } else {
                print("Contact saved successfully.")
                onContactAdded()
                dismiss()
            }
        }
    }
}
