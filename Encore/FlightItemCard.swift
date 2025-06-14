import SwiftUI

struct FlightItemCard: View {
    let flight: FlightModel
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private let editColor = Color(red: 116/255, green: 151/255, blue: 173/255)
    private let deleteColor = Color(red: 193/255, green: 106/255, blue: 106/255)

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(flight.airline) - \(flight.flightNumber)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("\(flight.departureAirport) - \(flight.arrivalAirport)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "airplane.departure")
                                    .font(.caption)
                                Text("\(formattedTime(flight.departureTime))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "airplane.arrival")
                                    .font(.caption)
                                Text("\(calculatedArrivalTime(departure: flight.departureTime))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    Spacer()

                    let airlineCode = extractAirlineCode(from: flight.flightNumber)
                    Image("\(airlineCode)_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                }
            }
            .padding()
            .onTapGesture {
                onExpandToggle()
            }

            if isExpanded {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        Button(action: { onEdit() }) {
                            Text("Edit")
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(editColor)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Button(action: { onDelete() }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(deleteColor)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func extractAirlineCode(from flightNumber: String) -> String {
        let prefix = flightNumber.prefix { $0.isLetter }
        return String(prefix)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }

    private func calculatedArrivalTime(departure: Date) -> String {
        let arrivalDate = Calendar.current.date(byAdding: .hour, value: 3, to: departure) ?? departure
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: arrivalDate).lowercased()
    }
}
