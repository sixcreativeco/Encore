import SwiftUI
import FirebaseFirestore

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var userID: String
    var artistName: String
    var onSave: () -> Void

    @State private var city = ""
    @State private var country = ""
    @State private var venue = ""
    @State private var address = ""
    @State private var date = Date()
    @State private var loadIn = defaultTime(hour: 15)
    @State private var soundCheck = defaultTime(hour: 17)
    @State private var doorsOpen = defaultTime(hour: 19)

    @State private var supportActs: [SupportActInput] = [SupportActInput()]
    @State private var allSupportActs: [String] = []

    @State private var headlinerSoundCheck = defaultTime(hour: 18)
    @State private var headlinerSetTime = defaultTime(hour: 20)
    @State private var headlinerSetDurationMinutes = 60

    @State private var packOut = defaultTime(hour: 23)
    @State private var packOutNextDay = false

    struct SupportActInput: Identifiable {
        var id = UUID().uuidString
        var name = ""
        var type = "Touring"
        var soundCheck = defaultTime(hour: 16)
        var setTime = defaultTime(hour: 18)
        var changeoverMinutes = 15
        var suggestion = ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                showDetailsSection
                timingSection
                supportActSection
                headlinerSection
                packOutSection
                saveButton
            }
            .padding()
            .onAppear(perform: loadSupportActs)
        }
        .frame(minWidth: 600, maxWidth: .infinity)
    }

    private var headerSection: some View {
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
    }

    private var showDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StyledDateField(date: $date)
                    .frame(width: 200)
                    .padding(.leading, -40)
                Spacer()
            }
            HStack(spacing: 16) {
                StyledInputField(placeholder: "City", text: $city)
                StyledInputField(placeholder: "Country (optional)", text: $country)
            }
            HStack(spacing: 16) {
                StyledInputField(placeholder: "Venue", text: $venue)
                StyledInputField(placeholder: "Address", text: $address)
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

    private var supportActSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Acts").font(.headline)
            ForEach($supportActs) { $sa in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            ZStack(alignment: .leading) {
                                TextField("Name", text: $sa.name)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(12)
                                    .background(Color.gray.opacity(0.06))
                                    .cornerRadius(10)
                                    .font(.body)
                                    .onChange(of: sa.name) { newValue in
                                        if let match = allSupportActs.first(where: { $0.lowercased().hasPrefix(newValue.lowercased()) }) {
                                            sa.suggestion = match
                                        } else {
                                            sa.suggestion = ""
                                        }
                                    }
                                    .onSubmit {
                                        if !sa.suggestion.isEmpty {
                                            sa.name = sa.suggestion
                                        }
                                    }

                                if !sa.suggestion.isEmpty && sa.suggestion.lowercased().hasPrefix(sa.name.lowercased()) && sa.name != sa.suggestion {
                                    let remaining = String(sa.suggestion.dropFirst(sa.name.count))
                                    HStack(spacing: 0) {
                                        Text(sa.name)
                                        Text(remaining).foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding(12)
                                }
                            }
                        }
                        StyledDropdown(label: "Type", selection: $sa.type, options: ["Touring", "Local"])
                            .frame(width: 160)
                    }
                    HStack(spacing: 16) {
                        StyledTimePicker(label: "Soundcheck", time: $sa.soundCheck)
                        StyledTimePicker(label: "Set Time", time: $sa.setTime)
                        Stepper("Changeover: \(sa.changeoverMinutes) min", value: $sa.changeoverMinutes, in: 0...60, step: 5)
                    }
                }
                Divider()
            }

            StyledButtonV2(title: "+ Add Support Act", action: { supportActs.append(SupportActInput()) }, showArrow: false, width: 200)
        }
    }

    private var headlinerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Headliner: \(artistName)").font(.headline)
            HStack(spacing: 16) {
                StyledTimePicker(label: "Soundcheck", time: $headlinerSoundCheck)
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
        StyledButtonV2(title: "Save Show", action: saveShow, fullWidth: true, showArrow: true)
    }

    private func loadSupportActs() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("supportActs")
            .order(by: "name").getDocuments { snapshot, _ in
                self.allSupportActs = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
            }
    }

    private func saveShow() {
        let db = Firestore.firestore()

        let showData: [String: Any] = [
            "city": city,
            "country": country,
            "venue": venue,
            "address": address,
            "date": Timestamp(date: date),
            "loadIn": Timestamp(date: loadIn),
            "soundCheck": Timestamp(date: soundCheck),
            "doorsOpen": Timestamp(date: doorsOpen),
            "headlinerSoundCheck": Timestamp(date: headlinerSoundCheck),
            "headlinerSetTime": Timestamp(date: headlinerSetTime),
            "headlinerSetDurationMinutes": headlinerSetDurationMinutes,
            "packOut": Timestamp(date: packOut),
            "packOutNextDay": packOutNextDay,
            "createdAt": FieldValue.serverTimestamp()
        ]

        let showRef = db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").document()
        showRef.setData(showData)

        for sa in supportActs {
            let saData: [String: Any] = [
                "name": sa.name,
                "type": sa.type,
                "soundCheck": Timestamp(date: sa.soundCheck),
                "setTime": Timestamp(date: sa.setTime),
                "changeoverMinutes": sa.changeoverMinutes,
                "createdAt": FieldValue.serverTimestamp()
            ]
            showRef.collection("supportActs").addDocument(data: saData)

            db.collection("users").document(userID).collection("tours").document(tourID).collection("supportActs").document(sa.name).setData([
                "name": sa.name,
                "type": sa.type,
                "createdAt": FieldValue.serverTimestamp()
            ])
        }

        onSave()
        dismiss()
    }

    private static func defaultTime(hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
