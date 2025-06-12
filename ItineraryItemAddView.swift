import SwiftUI
import FirebaseFirestore

struct ItineraryItemAddView: View {
    @Environment(\.dismiss) var dismiss

    var tourID: String
    var userID: String
    var itineraryDayID: String
    var onSave: () -> Void

    @State private var selectedType: ItineraryItem.ItemType = .loadIn
    @State private var title: String = ""
    @State private var time: Date = Date()
    @State private var note: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Add Itinerary Item").font(.largeTitle.bold())

            // Type selector
            Picker("Type", selection: $selectedType) {
                ForEach(ItineraryItem.ItemType.allCases, id: \.self) { type in
                    Text(label(for: type)).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedType) { updateTitle() }

            StyledInputField(placeholder: "Title", text: $title)
            StyledTimePicker(label: "Time", time: $time)
            StyledInputField(placeholder: "Notes (optional)", text: $note)

            Button("Save Item", action: saveItem)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .onAppear { updateTitle() }
    }

    private func updateTitle() {
        switch selectedType {
        case .travel: title = "Travel"
        case .arrival: title = "Arrival"
        case .loadIn: title = "Load In"
        case .soundCheck: title = "Soundcheck"
        case .show: title = "Show"
        case .packOut: title = "Pack Out"
        case .hotel: title = "Hotel"
        case .freeTime: title = "Free Time"
        case .catering: title = "Catering"
        case .meeting: title = "Meeting"
        case .custom: title = ""
        }
    }

    private func label(for type: ItineraryItem.ItemType) -> String {
        switch type {
        case .travel: return "Travel"
        case .arrival: return "Arrival"
        case .loadIn: return "Load In"
        case .soundCheck: return "Soundcheck"
        case .show: return "Show"
        case .packOut: return "Pack Out"
        case .hotel: return "Hotel"
        case .freeTime: return "Free Time"
        case .catering: return "Catering"
        case .meeting: return "Meeting"
        case .custom: return "Custom"
        }
    }

    private func saveItem() {
        let db = Firestore.firestore()

        let data: [String: Any] = [
            "type": selectedType.rawValue,
            "title": title,
            "time": Timestamp(date: time),
            "note": note
        ]

        db.collection("users").document(userID)
            .collection("tours").document(tourID)
            .collection("itineraries").document(itineraryDayID)
            .collection("items").addDocument(data: data) { error in
                if error == nil {
                    onSave()
                    dismiss()
                }
            }
    }
}
