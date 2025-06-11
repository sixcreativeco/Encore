import SwiftUI
import FirebaseFirestore

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var userID: String
    var onSave: () -> Void

    @State private var city = ""
    @State private var country = ""
    @State private var venue = ""
    @State private var address = ""
    @State private var date = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Add Show").font(.largeTitle.bold())
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StyledInputField(placeholder: "City", text: $city)
                    StyledInputField(placeholder: "Country (optional)", text: $country)
                    StyledInputField(placeholder: "Venue", text: $venue)
                    StyledInputField(placeholder: "Address", text: $address)
                }

                VStack(alignment: .leading) {
                    Text("Date").font(.subheadline.bold())
                    CustomDateField(date: $date)
                }

                Button(action: saveShow) {
                    Text("Save Show")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity)
    }

    private func saveShow() {
        let db = Firestore.firestore()
        let showData: [String: Any] = [
            "city": city,
            "country": country,
            "venue": venue,
            "address": address,
            "date": Timestamp(date: date),
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").addDocument(data: showData) { error in
            if let error = error {
                print("❌ Error adding document: \(error.localizedDescription)")
            } else {
                onSave()
                dismiss()
            }
        }
    }
}
