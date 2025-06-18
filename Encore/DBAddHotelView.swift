import SwiftUI
import FirebaseFirestore

struct DBAddHotelView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var bookingReference: String = ""
    @State private var contactName: String = ""
    @State private var contactEmail: String = ""
    @State private var contactPhone: String = ""
    
    @State private var isSaving = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Text("Add New Hotel")
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
                HStack {
                    StyledInputField(placeholder: "Hotel Name*", text: $name)
                    StyledInputField(placeholder: "City*", text: $city)
                }
                StyledInputField(placeholder: "Address", text: $address)
                StyledInputField(placeholder: "Booking Reference", text: $bookingReference)

                Divider().padding(.vertical, 8)
                
                HStack {
                    StyledInputField(placeholder: "Contact Name", text: $contactName)
                    StyledInputField(placeholder: "Contact Email", text: $contactEmail)
                }
                StyledInputField(placeholder: "Contact Phone", text: $contactPhone)
            }
            
            Spacer()

            // Save Button
            Button(action: saveHotel) {
                HStack {
                    if isSaving {
                        ProgressView().colorInvert()
                    } else {
                        Text("Save Hotel")
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
    
    private func saveHotel() {
        guard let userID = appState.userID else {
            print("Error: User ID is nil. Cannot save hotel.")
            return
        }
        
        isSaving = true
        
        let db = Firestore.firestore()
        let collectionRef = db.collection("users").document(userID).collection("hotels")
        
        let newHotelData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "address": address.trimmingCharacters(in: .whitespaces),
            "city": city.trimmingCharacters(in: .whitespaces),
            "bookingReference": bookingReference.trimmingCharacters(in: .whitespaces),
            "contactName": contactName.trimmingCharacters(in: .whitespaces),
            "contactEmail": contactEmail.trimmingCharacters(in: .whitespaces),
            "contactPhone": contactPhone.trimmingCharacters(in: .whitespaces),
            "createdAt": Timestamp(date: Date())
        ]
        
        collectionRef.addDocument(data: newHotelData) { error in
            isSaving = false
            if let error = error {
                print("Error saving hotel: \(error.localizedDescription)")
            } else {
                print("Hotel saved successfully.")
                dismiss()
            }
        }
    }
}
