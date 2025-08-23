import SwiftUI
import FirebaseFirestore

struct FlightPDFCard: View {
    let flight: Flight
    let crew: [TourCrew]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }
    
    private func passengerName(for crewId: String) -> String {
        crew.first { $0.id == crewId }?.name ?? "Unknown"
    }

    private func airlineCode(from flightNumber: String?) -> String {
        guard let flightNumber = flightNumber else { return "" }
        return String(flightNumber.prefix { $0.isLetter })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image("\(airlineCode(from: flight.flightNumber))_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text("\(flight.airline ?? "Airline") \(flight.flightNumber ?? "")")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text("\(flight.origin) → \(flight.destination)")
                    .font(.system(size: 12, weight: .bold))
            }

            // Body
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Departure")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                    Text(dateFormatter.string(from: flight.departureTimeUTC.dateValue()))
                        .font(.system(size: 10, weight: .semibold))
                    Text(timeFormatter.string(from: flight.departureTimeUTC.dateValue()))
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(width: 100)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arrival")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                    Text(dateFormatter.string(from: flight.arrivalTimeUTC.dateValue()))
                        .font(.system(size: 10, weight: .semibold))
                    Text(timeFormatter.string(from: flight.arrivalTimeUTC.dateValue()))
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(width: 100)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Passengers")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                    ForEach(flight.passengers) { passenger in
                        Text(passengerName(for: passenger.crewId))
                            .font(.system(size: 10))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
    }
}
