import SwiftUI
import FirebaseFirestore

struct NewItineraryDayView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var userID: String
    var onSave: () -> Void

    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Add Itinerary Day").font(.largeTitle.bold())

            CustomDateField(date: $date)
            StyledInputField(placeholder: "Notes", text: $notes)

            Button("Save Day", action: saveDay)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func saveDay() {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "date": Timestamp(date: date),
            "notes": notes
        ]

        db.collection("users").document(userID).collection("tours").document(tourID).collection("itineraries").addDocument(data: data) { error in
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}
