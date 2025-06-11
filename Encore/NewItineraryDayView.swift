import SwiftUI
import FirebaseFirestore

struct NewItineraryDayView: View {
    var tourID: String
    var onSave: (() -> Void)?

    @Environment(\.dismiss) var dismiss

    @State private var date = Date()
    @State private var notes = ""
    @State private var transportCall: Date? = nil
    @State private var lobbyCall: Date? = nil
    @State private var catering: Date? = nil
    @State private var hotelCheckIn: Date? = nil
    @State private var hotelCheckOut: Date? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("New Itinerary Day")
                    .font(.largeTitle.bold())

                DatePicker("Date", selection: $date, displayedComponents: .date)

                TextField("Notes", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                VStack(alignment: .leading, spacing: 12) {
                    timePicker("Transport Call", time: $transportCall)
                    timePicker("Lobby Call", time: $lobbyCall)
                    timePicker("Catering", time: $catering)
                    timePicker("Hotel Check-In", time: $hotelCheckIn)
                    timePicker("Hotel Check-Out", time: $hotelCheckOut)
                }

                Button("Save") { saveDay() }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func timePicker(_ label: String, time: Binding<Date?>) -> some View {
        VStack(alignment: .leading) {
            Text(label).bold()
            DatePicker(
                "",
                selection: Binding(get: { time.wrappedValue ?? Date() }, set: { time.wrappedValue = $0 }),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
    }

    private func saveDay() {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "date": Timestamp(date: date),
            "notes": notes
        ]
        if let val = transportCall { data["transportCall"] = Timestamp(date: val) }
        if let val = lobbyCall { data["lobbyCall"] = Timestamp(date: val) }
        if let val = catering { data["catering"] = Timestamp(date: val) }
        if let val = hotelCheckIn { data["hotelCheckIn"] = Timestamp(date: val) }
        if let val = hotelCheckOut { data["hotelCheckOut"] = Timestamp(date: val) }

        db.collection("tours").document(tourID).collection("itineraries").addDocument(data: data) { err in
            if err == nil {
                onSave?()
                dismiss()
            }
        }
    }
}
