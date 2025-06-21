import SwiftUI
import FirebaseFirestore

struct FlightCardView: View {
    // FIX: The view now accepts the complete, new 'Flight' model.
    let flight: Flight
    
    // We can determine dark mode from the flight data now.
    private var isDarkMode: Bool {
        (flight.airline ?? "").lowercased() == "air new zealand"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(flight.airline ?? "N/A") - \(flight.flightNumber ?? "----")")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                let airlineCode = extractAirlineCode(from: flight.flightNumber ?? "")
                // This assumes you have image assets named like "NZ_icon", "AA_icon", etc.
                Image("\(airlineCode)_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

            Text("\(flight.origin) → \(flight.destination)")
                .font(.title3).bold()
                .lineLimit(1)

            HStack(spacing: 12) {
                // FIX: These labels now call a helper to format the Timestamp directly.
                Label(formattedTime(from: flight.departureTimeUTC), systemImage: "airplane.departure")
                    .font(.caption)
                Label(formattedTime(from: flight.arrivalTimeUTC), systemImage: "airplane.arrival")
                    .font(.caption)
                
                // This calculates the duration between the two timestamps.
                Label(flightDuration(from: flight.departureTimeUTC, to: flight.arrivalTimeUTC), systemImage: "clock")
                    .font(.caption)
            }
        }
        .padding()
        .background(isDarkMode ? Color.black : Color.white)
        .cornerRadius(14)
    }

    /// Extracts the 2-letter airline code from a flight number.
    private func extractAirlineCode(from flightNumber: String) -> String {
        let prefix = flightNumber.prefix { $0.isLetter }
        return String(prefix)
    }

    /// Formats a Firestore Timestamp into a time string (e.g., "7:40 PM").
    private func formattedTime(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Calculates and formats the duration between two Timestamps.
    private func flightDuration(from start: Timestamp, to end: Timestamp) -> String {
        let durationInSeconds = end.seconds - start.seconds
        let hours = durationInSeconds / 3600
        let minutes = (durationInSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
