import SwiftUI

struct AirportSelectorComponent: View {
    @Binding var selectedAirport: AirportEntry?

    @State private var searchText: String = ""
    @State private var isDropdownVisible = false

    private let airports = AirportService.shared.airports

    private var filteredAirports: [AirportEntry] {
        if searchText.isEmpty { return [] }
        return airports.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.city.lowercased().contains(searchText.lowercased()) ||
            $0.iata.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Departure Airport").font(.subheadline)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    TextField("Start typing airport or city...", text: $searchText, onEditingChanged: { editing in
                        isDropdownVisible = editing
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { _ in
                        isDropdownVisible = true
                        selectedAirport = nil
                    }

                    if isDropdownVisible && !filteredAirports.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredAirports) { airport in
                                    Button(action: {
                                        selectAirport(airport)
                                    }) {
                                        HStack {
                                            Text("\(airport.name) (\(airport.iata))")
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxHeight: 200)
                    }
                }
            }

            if let selected = selectedAirport {
                Text("Selected: \(selected.name)").font(.caption).foregroundColor(.gray)
            }
        }
    }

    private func selectAirport(_ airport: AirportEntry) {
        selectedAirport = airport
        searchText = "\(airport.name) (\(airport.iata))"
        isDropdownVisible = false
    }
}
