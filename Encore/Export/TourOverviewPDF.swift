import SwiftUI
import FirebaseFirestore

struct TourOverviewPDF: View {
    let tour: Tour
    let shows: [Show]
    let itinerary: [ItineraryItem]
    let flights: [Flight]
    let hotels: [Hotel]
    let crew: [TourCrew]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading) {
                Text(tour.artist).font(.system(size: 36, weight: .bold))
                Text(tour.tourName).font(.system(size: 24)).foregroundColor(.secondary)
                Text("Export Date: \(Date().formatted(date: .long, time: .shortened))")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            if !shows.isEmpty {
                PDFSection(title: "Shows") {
                    ForEach(shows) { show in
                        VStack(alignment: .leading) {
                            Text("\(dateFormatter.string(from: show.date.dateValue())): \(show.city)").font(.headline)
                            Text(show.venueName).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !itinerary.isEmpty {
                PDFSection(title: "Itinerary") {
                    ForEach(itinerary) { item in
                        HStack {
                            Text(timeFormatter.string(from: item.timeUTC.dateValue())).font(.caption).frame(width: 80)
                            Text(item.title)
                        }
                    }
                }
            }
            
            if !flights.isEmpty {
                PDFSection(title: "Flights") {
                    ForEach(flights) { flight in
                        Text("\(flight.flightNumber ?? "N/A"): \(flight.origin) -> \(flight.destination)")
                    }
                }
            }
            
            if !hotels.isEmpty {
                PDFSection(title: "Hotels") {
                    ForEach(hotels) { hotel in
                        Text("\(hotel.name) in \(hotel.city)")
                    }
                }
            }
            
            if !crew.isEmpty {
                PDFSection(title: "Touring Party") {
                    ForEach(crew) { member in
                        Text("\(member.name) - \(member.roles.joined(separator: ", "))")
                    }
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4 Paper size
    }
}

// Helper view for consistent PDF section styling
struct PDFSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text(title).font(.title2.bold())
            content
        }
    }
}
