import SwiftUI
import FirebaseFirestore

struct FlightPDFCard: View {
    let flight: Flight
    let crew: [TourCrew]
    
    // This helper function now correctly formats the time based on the timezone
    // of the departure or arrival airport.
    private func formattedDateTime(for timestamp: Timestamp, airportCode: String) -> (date: String, time: String) {
        let date = timestamp.dateValue()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mma"
        
        // Find the airport in our data source to get its timezone identifier.
        if let airport = AirportService.shared.airports.first(where: { $0.iata == airportCode }),
           let tz = TimeZone(identifier: airport.tz) {
            dateFormatter.timeZone = tz
            timeFormatter.timeZone = tz
        }
        
        return (dateFormatter.string(from: date), timeFormatter.string(from: date).lowercased())
    }

    private func passengerName(for crewId: String) -> String {
        crew.first { $0.id == crewId }?.name ?? "Unknown"
    }

    private func airlineCode(from flightNumber: String?) -> String {
        guard let flightNumber = flightNumber else { return "" }
        return String(flightNumber.prefix { $0.isLetter })
    }

    var body: some View {
        let departure = formattedDateTime(for: flight.departureTimeUTC, airportCode: flight.origin)
        let arrival = formattedDateTime(for: flight.arrivalTimeUTC, airportCode: flight.destination)
        
        // --- THIS IS THE FIX ---
        // Detect if the timezones are different between origin and destination.
        let departureTZ = TimeZone(identifier: AirportService.shared.airports.first { $0.iata == flight.origin }?.tz ?? "UTC")
        let arrivalTZ = TimeZone(identifier: AirportService.shared.airports.first { $0.iata == flight.destination }?.tz ?? "UTC")
        let timezoneDidChange = departureTZ != arrivalTZ
        // --- END OF FIX ---
        
        return VStack(alignment: .leading, spacing: 10) {
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
                    Text(departure.date)
                        .font(.system(size: 10, weight: .semibold))
                    Text(departure.time)
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(width: 100)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arrival")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                    Text(arrival.date)
                        .font(.system(size: 10, weight: .semibold))
                    Text(arrival.time)
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
            
            // Add the note if timezones are different
            if timezoneDidChange {
                Divider().padding(.vertical, 2)
                Text("Note: Times displayed in local timezone for each airport.")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
    }
}
