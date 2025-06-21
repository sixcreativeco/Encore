import SwiftUI

struct FlightItemCard: View {
    // FIX: Changed from FlightModel to our new Flight struct.
    let flight: Flight
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let editColor = Color(red: 116/255, green: 151/255, blue: 173/255)
    private let deleteColor = Color(red: 193/255, green: 106/255, blue: 106/255)

    var body: some View {
        // NOTE: All UI code below is identical to your original file.
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // FIX: Using optional-safe access for new model properties
                        Text("\(flight.airline ?? "N/A") - \(flight.flightNumber ?? "----")")
                            .font(.caption)
                            .foregroundColor(isAirNZ ? .white : .gray)

                        // FIX: Using new property names 'origin' and 'destination'
                        Text("\(flight.origin) - \(flight.destination)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(isAirNZ ? .white : .black)

                        HStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "airplane.departure")
                                    .font(.caption)
                                    .foregroundColor(isAirNZ ? .white : .gray)
                                // FIX: Accessing .dateValue() from the Timestamp property
                                Text("\(formattedTime(flight.departureTimeUTC.dateValue()))")
                                    .font(.caption)
                                    .foregroundColor(isAirNZ ? .white : .gray)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "airplane.arrival")
                                    .font(.caption)
                                    .foregroundColor(isAirNZ ? .white : .gray)
                                // FIX: Accessing .dateValue() from the Timestamp property
                                Text("\(formattedArrivalTime(flight.arrivalTimeUTC.dateValue()))")
                                    .font(.caption)
                                    .foregroundColor(isAirNZ ? .white : .gray)
                            }
                        }
                    }

                    Spacer()
                    
                    // This logic remains the same, but is now safer with nil-coalescing
                    let airlineCode = extractAirlineCode(from: flight.flightNumber ?? "")
                    let imageName = airlineCode.uppercased() == "NZ" ? "\(airlineCode)_icon_light" : "\(airlineCode)_icon"

                    Image(imageName)
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
        .background(isAirNZ ? Color(red: 20/255, green: 20/255, blue: 20/255) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var isAirNZ: Bool {
        extractAirlineCode(from: flight.flightNumber ?? "").uppercased() == "NZ"
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
    
    // NOTE: This logic seems to assume a 3-hour flight. You may want to revise this later.
    private func formattedArrivalTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }
}
