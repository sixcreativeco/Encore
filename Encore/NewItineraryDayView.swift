import SwiftUI
import FirebaseFirestore

struct NewItineraryDayView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var userID: String
    var onSave: () -> Void

    @State private var date = Date()
    @State private var notes = ""
    @State private var lobbyCall = Date()
    @State private var transportCall = Date()
    @State private var catering = Date()
    @State private var hotelCheckIn = Date()
    @State private var hotelCheckOut = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Add Itinerary Day").font(.largeTitle.bold())
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 16) {
                    CustomDateField(date: $date)
                    StyledInputField(placeholder: "Notes", text: $notes)
                    StyledTimePicker(label: "Lobby Call", time: $lobbyCall)
                    StyledTimePicker(label: "Transport Call", time: $transportCall)
                    StyledTimePicker(label: "Catering", time: $catering)
                    StyledTimePicker(label: "Hotel Check-In", time: $hotelCheckIn)
                    StyledTimePicker(label: "Hotel Check-Out", time: $hotelCheckOut)
                }

                Button(action: saveItinerary) {
                    Text("Save Day")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity)
    }

    private func saveItinerary() {
        let db = Firestore.firestore()
        let itineraryData: [String: Any] = [
            "date": Timestamp(date: date),
            "notes": notes,
            "lobbyCall": Timestamp(date: lobbyCall),
            "transportCall": Timestamp(date: transportCall),
            "catering": Timestamp(date: catering),
            "hotelCheckIn": Timestamp(date: hotelCheckIn),
            "hotelCheckOut": Timestamp(date: hotelCheckOut),
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userID).collection("tours").document(tourID).collection("itineraries").addDocument(data: itineraryData) { error in
            if let error = error {
                print("❌ Error adding itinerary: \(error.localizedDescription)")
            } else {
                onSave()
                dismiss()
            }
        }
    }
}
