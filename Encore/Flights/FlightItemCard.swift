import SwiftUI
import FirebaseFirestore

struct FlightItemCard: View {
    let flight: Flight
    let crew: [TourCrew]
    let airports: [AirportEntry]
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let editColor = Color(red: 116/255, green: 151/255, blue: 173/255)
    private let deleteColor = Color(red: 193/255, green: 106/255, blue: 106/255)

    private var isAirNZTheme: Bool {
        extractAirlineCode(from: flight.flightNumber ?? "").uppercased() == "NZ"
    }
    
    private var isVirginTheme: Bool {
        extractAirlineCode(from: flight.flightNumber ?? "").uppercased() == "VA"
    }

    private var cardBackgroundColor: Color {
        if isAirNZTheme { return Color(red: 20/255, green: 20/255, blue: 20/255) }
        if isVirginTheme { return Color(red: 5/255, green: 30/255, blue: 85/255) }
        return Color.white
    }

    private var primaryTextColor: Color {
        return (isAirNZTheme || isVirginTheme) ? .white : .black
    }

    private var secondaryTextColor: Color {
        return (isAirNZTheme || isVirginTheme) ? .white.opacity(0.8) : .gray
    }
    
    private var totalBaggage: Int {
        flight.passengers.reduce(0) { total, passenger in
            total + (Int(passenger.baggage ?? "0") ?? 0)
        }
    }

    var body: some View {
        Button(action: onExpandToggle) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(flight.airline ?? "N/A") - \(flight.flightNumber ?? "----")")
                            .font(.caption)
                        
                        Text("\(flight.origin) - \(flight.destination)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "airplane.departure")
                                Text(formattedDateTimeString(for: flight.departureTimeUTC, airportCode: flight.origin))
                                Rectangle().frame(width: 20, height: 1).opacity(0.3)
                                Text(flightDuration())
                                Rectangle().frame(width: 20, height: 1).opacity(0.3)
                                Text(formattedDateTimeString(for: flight.arrivalTimeUTC, airportCode: flight.destination))
                                Image(systemName: "airplane.arrival")
                            }
                            .font(.system(size: 11, weight: .medium))
                            Spacer()
                        }
                    }
                    .padding(.all, 16)

                    let airlineCode = extractAirlineCode(from: flight.flightNumber ?? "")
                    let imageName = (isAirNZTheme || isVirginTheme) ? "\(airlineCode)_icon_light" : "\(airlineCode)_icon"
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .padding([.top, .trailing], 25)
                }
                .frame(height: 120)
                .foregroundColor(secondaryTextColor)

                if isExpanded {
                    expandedActionView
                }
            }
        }
        .buttonStyle(.plain)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var expandedActionView: some View {
        VStack(spacing: 16) {
            if !flight.passengers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Passengers & Baggage")
                        .font(.headline)
                        .foregroundColor(primaryTextColor)
                    
                    ForEach(flight.passengers) { passenger in
                        HStack {
                            Text(crew.first{ $0.id == passenger.crewId }?.name ?? "Unknown Crew")
                                .foregroundColor(primaryTextColor)
                            Spacer()
                            if let baggage = passenger.baggage, !baggage.isEmpty {
                                Text("\(baggage) kg")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total Baggage")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(totalBaggage) kg")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(primaryTextColor)
                }
                .padding(.horizontal)
                Divider().padding(.horizontal)
            }
            
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

    private func extractAirlineCode(from flightNumber: String) -> String {
        let prefix = flightNumber.prefix { $0.isLetter }
         return String(prefix)
    }

    private func formattedDateTimeString(for timestamp: FirebaseFirestore.Timestamp, airportCode: String) -> String {
        let date = timestamp.dateValue()
        
        guard let airportData = airports.first(where: { $0.iata == airportCode }),
              let airportTimeZone = TimeZone(identifier: airportData.tz) else {
            return date.formatted()
        }

        let formatter = DateFormatter()
        formatter.timeZone = airportTimeZone
        formatter.dateFormat = "h:mma, MMM d"

        return formatter.string(from: date).uppercased()
    }
    
    private func flightDuration() -> String {
        let durationInSeconds = flight.arrivalTimeUTC.seconds - flight.departureTimeUTC.seconds
        guard durationInSeconds > 0 else { return "-"}
        
        let hours = durationInSeconds / 3600
        let minutes = (durationInSeconds % 3600) / 60
        
        return "\(hours)H \(minutes)M"
    }
}
