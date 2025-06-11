import SwiftUI
import FirebaseFirestore

struct AddShowView: View {
    @Environment(\.dismiss) var dismiss
    var tourID: String
    var onSave: (([String: Any]) -> Void)? = nil

    @State private var city = ""
    @State private var country = ""
    @State private var venue = ""
    @State private var address = ""
    @State private var date = Date()

    @State private var loadIn = Date()
    @State private var soundCheck = Date()
    @State private var doorsOpen = Date()
    @State private var openerSets: [Date] = [Date()]
    @State private var changeovers: [Int] = [10]
    @State private var headlineSet = Date()
    @State private var setDurationHours = 1
    @State private var setDurationMinutes = 30
    @State private var packOut = Date()
    @State private var packOutNextDay = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    Text("Add Show")
                        .font(.largeTitle.bold())
                        .padding(.top, 4)
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
                    Text("Date")
                        .font(.subheadline.bold())
                    CustomDateField(date: $date)
                }

                Divider()

                Text("Timings")
                    .font(.title3.bold())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StyledTimePicker(label: "Load-In", time: $loadIn)
                    StyledTimePicker(label: "Soundcheck", time: $soundCheck)
                    StyledTimePicker(label: "Doors", time: $doorsOpen)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Opener Sets")
                        .font(.headline)
                    ForEach(openerSets.indices, id: \.self) { index in
                        HStack(spacing: 16) {
                            StyledTimePicker(label: "Set \(index + 1)", time: $openerSets[index])
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Changeover")
                                    .font(.subheadline.bold())
                                Stepper(value: $changeovers[index], in: 0...60) {
                                    Text("\(changeovers[index]) min")
                                }
                            }
                        }
                    }

                    Button("+ Add another opener set") {
                        openerSets.append(Date())
                        changeovers.append(10)
                    }
                    .font(.subheadline)
                }

                StyledTimePicker(label: "Headline Set", time: $headlineSet)

                VStack(alignment: .leading) {
                    Text("Set Duration")
                        .font(.headline)
                    HStack(spacing: 16) {
                        Stepper("Hours: \(setDurationHours)", value: $setDurationHours, in: 0...5)
                        Stepper("Minutes: \(setDurationMinutes)", value: $setDurationMinutes, in: 0...59)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pack Out")
                        .font(.headline)
                    HStack(spacing: 12) {
                        StyledTimePicker(label: "", time: $packOut)
                            .frame(maxWidth: 160)
                        Toggle("Next Day", isOn: $packOutNextDay)
                            .toggleStyle(.switch)
                    }
                }

                Button(action: {
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
                        "openerSets": openerSets.map { Timestamp(date: $0) },
                        "changeovers": changeovers,
                        "headlineSet": Timestamp(date: headlineSet),
                        "setDurationHours": setDurationHours,
                        "setDurationMinutes": setDurationMinutes,
                        "packOut": Timestamp(date: packOut),
                        "packOutNextDay": packOutNextDay,
                        "createdAt": FieldValue.serverTimestamp()
                    ]

                    onSave?(showData)

                    db.collection("tours").document(tourID).collection("stops").addDocument(data: showData) { error in
                        if let error = error {
                            print("❌ Error adding document: \(error.localizedDescription)")
                        } else {
                            dismiss()
                        }
                    }
                }) {
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
}

// MARK: - Styled Inputs

struct StyledInputField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.subheadline.bold())
            TextField("", text: $text)
                .padding(12)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
                .font(.body)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }
}

struct StyledTimePicker: View {
    var label: String
    @Binding var time: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline.bold())
            }
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .padding(12)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
                .datePickerStyle(.compact)
                .frame(height: 44)
        }
    }
}
