import SwiftUI
import FirebaseFirestore

struct ShowEditView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var userID: String
    var ownerUserID: String
    var show: ShowModel

    @State private var city = ""
    @State private var country = ""
    @State private var venue = ""
    @State private var address = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var date = Date()
    @State private var loadIn = defaultTime(hour: 15)
    @State private var soundCheck = defaultTime(hour: 17)
    @State private var doorsOpen = defaultTime(hour: 19)
    @State private var headlinerSetTime = defaultTime(hour: 20)
    @State private var headlinerSetDurationMinutes = 60
    @State private var packOut = defaultTime(hour: 23)
    @State private var packOutNextDay = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                showDetailsSection
                timingSection
                headlinerSection
                packOutSection
                saveButton
            }
            .padding()
            .onAppear(perform: loadShowData)
        }
        .frame(minWidth: 600, maxWidth: .infinity)
    }

    private var headerSection: some View {
        HStack {
            Text("Edit Show").font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .medium))
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
    }

    private var showDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date").font(.headline)
            HStack {
                StyledDateField(date: $date)
                    .frame(width: 200)
                    .padding(.leading, -40)
                Spacer()
            }
            .padding(.bottom, -8)

            Text("Venue").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                StyledInputField(placeholder: "Venue", text: $venue)
            }

            HStack(spacing: 16) {
                StyledInputField(placeholder: "City", text: $city)
                StyledInputField(placeholder: "Country (optional)", text: $country)
            }

            StyledInputField(placeholder: "Address", text: $address)

            HStack(spacing: 16) {
                StyledInputField(placeholder: "Venue Contact Name", text: $contactName)
                StyledInputField(placeholder: "Email", text: $contactEmail)
                StyledInputField(placeholder: "Phone Number", text: $contactPhone)
            }
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timings").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Load In", time: $loadIn)
                StyledTimePicker(label: "Soundcheck", time: $soundCheck)
                StyledTimePicker(label: "Doors", time: $doorsOpen)
            }
        }
    }

    private var headlinerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Headliner").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Set Time", time: $headlinerSetTime)
                Stepper("Set Duration: \(headlinerSetDurationMinutes) min", value: $headlinerSetDurationMinutes, in: 0...300, step: 5)
            }
        }
    }

    private var packOutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pack Out").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Time", time: $packOut)
                Toggle(isOn: $packOutNextDay) {
                    Text("Next Day")
                }
                .toggleStyle(.checkbox)
            }
        }
    }

    private var saveButton: some View {
        StyledButtonV2(title: "Save Changes", action: saveChanges, fullWidth: true, showArrow: true)
    }

    private func loadShowData() {
        self.city = show.city
        self.country = show.country ?? ""
        self.venue = show.venue
        self.address = show.address
        self.date = show.date
        self.loadIn = show.loadIn ?? defaultTime(hour: 15)
        self.soundCheck = show.soundCheck ?? defaultTime(hour: 17)
        self.doorsOpen = show.doorsOpen ?? defaultTime(hour: 19)
        self.headlinerSetTime = show.headliner?.setTime ?? defaultTime(hour: 20)
        self.headlinerSetDurationMinutes = show.headliner?.setDurationMinutes ?? 60
        self.packOut = show.packOut ?? defaultTime(hour: 23)
        self.packOutNextDay = show.packOutNextDay

        let db = Firestore.firestore()
        db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("shows").document(show.id)
            .getDocument { doc, _ in
                let data = doc?.data() ?? [:]
                self.contactName = data["contactName"] as? String ?? ""
                self.contactEmail = data["contactEmail"] as? String ?? ""
                self.contactPhone = data["contactPhone"] as? String ?? ""
            }
    }

    private func saveChanges() {
        let db = Firestore.firestore()
        let showRef = db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("shows").document(show.id)

        let showData: [String: Any] = [
            "city": city,
            "country": country,
            "venue": venue,
            "address": address,
            "contactName": contactName,
            "contactEmail": contactEmail,
            "contactPhone": contactPhone,
            "date": Timestamp(date: date),
            "loadIn": Timestamp(date: loadIn),
            "soundCheck": Timestamp(date: soundCheck),
            "doorsOpen": Timestamp(date: doorsOpen),
            "headlinerSetTime": Timestamp(date: headlinerSetTime),
            "headlinerSetDurationMinutes": headlinerSetDurationMinutes,
            "packOut": Timestamp(date: packOut),
            "packOutNextDay": packOutNextDay,
            "createdAt": Timestamp(date: show.createdAt)
        ]

        showRef.setData(showData, merge: true)
        dismiss()
    }
}

func defaultTime(hour: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}
