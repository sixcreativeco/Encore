import SwiftUI
import FirebaseFirestore

struct DBAddContactView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var name: String = ""
    @State private var role: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var notes: String = ""
    
    @State private var isSaving = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !role.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
            .padding(.bottom, 16)

            // Form Fields
            VStack(spacing: 16) {
                StyledInputField(placeholder: "Full Name*", text: $name)
                StyledInputField(placeholder: "Role*", text: $role)
                StyledInputField(placeholder: "Email", text: $email)
                StyledInputField(placeholder: "Phone", text: $phone)
                
                Text("Notes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
            }
            
            Spacer()

            // Save Button
            Button(action: saveContact) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .colorInvert()
                    } else {
                        Text("Save Contact")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.accentColor : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isSaving)
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 600)
    }
    
    private func saveContact() {
        guard let userID = appState.userID else {
            print("Error: User ID is nil. Cannot save contact.")
            return
        }
        
        isSaving = true
        
        let db = Firestore.firestore()
        let collectionRef = db.collection("users").document(userID).collection("contacts")
        
        let newContactData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "role": role.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "phone": phone.trimmingCharacters(in: .whitespaces),
            "notes": notes.trimmingCharacters(in: .whitespaces),
            "createdAt": Timestamp(date: Date())
        ]
        
        collectionRef.addDocument(data: newContactData) { error in
            isSaving = false
            if let error = error {
                print("Error saving contact: \(error.localizedDescription)")
            } else {
                print("Contact saved successfully.")
                dismiss()
            }
        }
    }
}
