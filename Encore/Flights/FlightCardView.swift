import SwiftUI

struct FlightCardView: View {
    let airlineName: String
    let flightCode: String
    let departureIATA: String
    let arrivalIATA: String
    let departureTime: String
    let arrivalTime: String
    let duration: String
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(airlineName) - \(flightCode)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                let airlineCode = extractAirlineCode(from: flightCode)
                Image("\(airlineCode)_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

            Text("\(departureIATA) - \(arrivalIATA)")
                .font(.title3).bold()
                .lineLimit(1)

            HStack(spacing: 12) {
                Label(departureTime, systemImage: "airplane.departure")
                    .font(.caption)
                Label(arrivalTime, systemImage: "airplane.arrival")
                    .font(.caption)
                Label(duration, systemImage: "clock")
                    .font(.caption)
            }
        }
        .padding()
        .background(isDarkMode ? Color.black : Color.white)
        .cornerRadius(14)
    }

    private func extractAirlineCode(from flightNumber: String) -> String {
        let prefix = flightNumber.prefix { $0.isLetter }
        return String(prefix)
    }
}
