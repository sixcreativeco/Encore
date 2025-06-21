import SwiftUI
import FirebaseFirestore

struct ItineraryItemAddView: View {
    var tourID: String
    var userID: String // This is the ownerID
    var presetDate: Date
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var type: ItineraryItemType = .custom
    @State private var title = ""
    @State private var time: Date = Date()
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Add Itinerary Item").font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: type.iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    StyledInputField(placeholder: "Event (e.g. 'Dinner reservation', 'Drive to venue')", text: $title)
                        .onChange(of: title) { _, newValue in
                            updateType(from: newValue)
                        }
                }
                
                StyledTimePicker(label: "Time", time: $time)
                
                CustomTextEditor(placeholder: "Notes (optional)", text: $note)
            }

            Spacer()

            Button("Save Item") {
                saveItem()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(title.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(title.isEmpty)
        }
        .padding(32)
        .frame(width: 500, height: 420)
        .onAppear {
            initializeTime()
        }
    }

    private func updateType(from eventTitle: String) {
        let lowercasedTitle = eventTitle.lowercased()
        
        if ["hotel", "motel", "airbnb", "lobby", "accommodation", "check in", "check out"].contains(where: lowercasedTitle.contains) {
            self.type = .hotel
        } else if ["drive", "transport", "pickup", "pick up", "drop off", "bus", "van", "car", "taxi", "uber", "lyft", "shuttle", "transfer", "transportation", "travel"].contains(where: lowercasedTitle.contains) {
            self.type = .travel
        } else if ["photoshoot", "shoot", "film", "content", "tiktok", "promo", "photo", "photo shoot" , "video", "video shoot", "social media"].contains(where: lowercasedTitle.contains) {
            self.type = .content
        } else if ["breakfast", "lunch", "dinner", "food", "catering", "buffet", "meal", "brunch", "lunchtime"].contains(where: lowercasedTitle.contains) {
            self.type = .catering
        } else if ["merch", "merchandise"].contains(where: lowercasedTitle.contains) {
            self.type = .merch
        } else if ["flight", "fly to", "airport", "take off", "land", "lands", "landing"].contains(where: lowercasedTitle.contains) {
            self.type = .flight
        } else if ["soundcheck", "sound check", "line check"].contains(where: lowercasedTitle.contains) {
            self.type = .soundcheck
        } else if ["load in", "load-in", "frieght"].contains(where: lowercasedTitle.contains) {
            self.type = .loadIn
        } else if ["doors"].contains(where: lowercasedTitle.contains) {
            self.type = .doors
        } else {
            self.type = .custom
        }
    }

    private func initializeTime() {
        let calendar = Calendar.current
        let now = Date()
        let merged = calendar.date(
            bySettingHour: calendar.component(.hour, from: now),
            minute: calendar.component(.minute, from: now),
            second: 0,
            of: presetDate
        ) ?? presetDate

        self.time = merged
    }

    private func saveItem() {
        // FIX: Create an instance of our new 'ItineraryItem' model
        let newItem = ItineraryItem(
            tourId: self.tourID,
            showId: nil, // This view doesn't specify a show, which is fine
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: self.type.rawValue,
            timeUTC: Timestamp(date: time),
            notes: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            // FIX: Save the new object directly to the top-level /itineraryItems collection
            _ = try Firestore.firestore().collection("itineraryItems").addDocument(from: newItem)
            onSave()
            dismiss()
        } catch {
            print("Error adding itinerary item: \(error.localizedDescription)")
        }
    }
}
