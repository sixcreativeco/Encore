import SwiftUI

struct MultiShowSelector: View {
    let shows: [Show]
    @Binding var selectedShowIDs: Set<String>

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Include Shows")
                    .font(.headline)
                Spacer()
                Button("Select All") { selectedShowIDs = Set(shows.compactMap { $0.id }) }
                Button("Deselect All") { selectedShowIDs.removeAll() }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(shows) { show in
                        Toggle(isOn: Binding(
                            get: { selectedShowIDs.contains(show.id!) },
                            set: { isSelected in
                                if isSelected {
                                    selectedShowIDs.insert(show.id!)
                                } else {
                                    selectedShowIDs.remove(show.id!)
                                }
                            }
                        )) {
                            VStack(alignment: .leading) {
                                Text(show.city)
                                    .fontWeight(.medium)
                                Text("\(dateFormatter.string(from: show.date.dateValue())) - \(show.venueName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
            .frame(maxHeight: 250)
        }
    }
}
