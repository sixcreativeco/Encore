import SwiftUI
import FirebaseFirestore

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var onSave: (() -> Void)?

    @State private var city = ""
    @State private var country = ""
    @State private var venue = ""
    @State private var address = ""
    @State private var date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Add Show").font(.largeTitle.bold())

            TextField("City", text: $city).textFieldStyle(.roundedBorder)
            TextField("Country", text: $country).textFieldStyle(.roundedBorder)
            TextField("Venue", text: $venue).textFieldStyle(.roundedBorder)
            TextField("Address", text: $address).textFieldStyle(.roundedBorder)
            DatePicker("Date", selection: $date, displayedComponents: .date)

            Button("Save") { saveShow() }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
        .frame(minWidth: 400)
    }

    private func saveShow() {
        let db = Firestore.firestore()

        let showData: [String: Any] = [
            "city": city,
            "country": country,
            "venue": venue,
            "address": address,
            "date": Timestamp(date: date)
        ]

        db.collection("tours").document(tourID).collection("shows").addDocument(data: showData) { err in
            if err == nil {
                onSave?()
                dismiss()
            }
        }
    }
}
