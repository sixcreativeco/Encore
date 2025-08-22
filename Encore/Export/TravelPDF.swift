import SwiftUI
import FirebaseFirestore

struct TravelPDF: View {
    let tour: Tour
    let itinerary: [ItineraryItem]
    let flights: [Flight]
    let hotels: [Hotel]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    // Pre-filter the itinerary items to simplify the body
    private var travelItineraryItems: [ItineraryItem] {
        itinerary.filter { item in
            let type = ItineraryItemType(rawValue: item.type)
            return type == .travel || type == .arrival
        }
    }

    // The main body is now a simple composition of smaller views
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            
            if !flights.isEmpty {
                flightsSection
            }
            
            if !hotels.isEmpty {
                hotelsSection
            }
            
            if !travelItineraryItems.isEmpty {
                groundTransportSection
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4
        .background(Color.white)
    }

    // MARK: - Subviews
    
    private var header: some View {
        VStack(alignment: .leading) {
            Text(tour.artist.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            Text("\(tour.tourName) - Travel Itinerary")
                .font(.system(size: 36, weight: .bold))
        }
    }
    
    private var flightsSection: some View {
        PDFSection(title: "Flights") {
            ForEach(flights) { flight in
                VStack(alignment: .leading) {
                    Text("\(flight.flightNumber ?? "N/A"): \(flight.origin) → \(flight.destination)").font(.headline)
                    Text("Departs: \(flight.departureTimeUTC.dateValue().formatted(.dateTime.day().month().year().hour().minute()))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var hotelsSection: some View {
        PDFSection(title: "Hotels") {
            ForEach(hotels) { hotel in
                VStack(alignment: .leading) {
                    Text(hotel.name).font(.headline)
                    Text("Check-in: \(hotel.checkInDate.dateValue().formatted(.dateTime.day().month().year().hour().minute()))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var groundTransportSection: some View {
        PDFSection(title: "Ground Transport & Other") {
            ForEach(travelItineraryItems) { item in
                 HStack {
                    Text(timeFormatter.string(from: item.timeUTC.dateValue())).font(.caption).frame(width: 80)
                    Text(item.title)
                }
            }
        }
    }
}
