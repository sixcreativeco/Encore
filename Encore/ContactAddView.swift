import SwiftUI
import FirebaseFirestore

struct ContactAddView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var newContact = ContactModel(name: "", roles: [])
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
        // FIXED: Replaced 'idealHeight' with 'height' for a fixed-size sheet.
        .frame(width: 680, height: 750)
    }
    
    private func toFirestore(contact: ContactModel) -> [String: Any] {
        var data: [String: Any] = [
            "name": contact.name, "roles": contact.roles,
            "email": contact.email ?? NSNull(), "phone": contact.phone ?? NSNull(),
            "notes": contact.notes ?? NSNull(), "location": contact.location ?? NSNull(),
            "profileImageURL": contact.profileImageURL ?? NSNull(),
            "dateOfBirth": contact.dateOfBirth != nil ? Timestamp(date: contact.dateOfBirth!) : NSNull(),
            "countryOfBirth": contact.countryOfBirth ?? NSNull(),
            "allergies": contact.allergies ?? NSNull(), "medications": contact.medications ?? NSNull(),
            "createdAt": Timestamp(date: Date())
        ]
        if let passport = contact.passport {
            data["passport"] = [
                "passportNumber": passport.passportNumber, "issuedDate": Timestamp(date: passport.issuedDate),
                "expiryDate": Timestamp(date: passport.expiryDate), "issuingCountry": passport.issuingCountry
            ]
        }
        if let emergencyContact = contact.emergencyContact {
            data["emergencyContact"] = ["name": emergencyContact.name, "phone": emergencyContact.phone]
        }
        return data
    }
    
    private func saveContact() {
        guard let userID = appState.userID else { return }
        guard isFormValid else { return }
        
        isSaving = true
        
        let db = Firestore.firestore()
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
