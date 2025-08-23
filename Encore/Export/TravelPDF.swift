import SwiftUI
import FirebaseFirestore
import Kingfisher

struct TravelPDF: View {
    let tour: Tour
    let itinerary: [ItineraryItem]
    let flights: [Flight]
    let hotels: [Hotel]
    let crew: [TourCrew]
    let posterImage: NSImage?

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
    
    // Group flights by date for a more organized layout
    private var flightsByDate: [Date: [Flight]] {
        Dictionary(grouping: flights) { flight in
            Calendar.current.startOfDay(for: flight.departureTimeUTC.dateValue())
        }
    }
    
    private var sortedFlightDates: [Date] {
        flightsByDate.keys.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(tour.artist.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("\(tour.tourName) - Travel Itinerary")
                        .font(.system(size: 36, weight: .bold))
                }
                
                Spacer()
                
                if let image = posterImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 120) // 2:3 ratio
                        .clipped()
                        .cornerRadius(6)
                }
            }
            
            Divider()

            // Flights Section
            if !flights.isEmpty {
                PDFSection(title: "Flights") {
                    ForEach(sortedFlightDates, id: \.self) { date in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(date, style: .date)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.bottom, 4)
                            
                            ForEach(flightsByDate[date] ?? []) { flight in
                                FlightPDFCard(flight: flight, crew: crew)
                            }
                        }
                    }
                }
            }
            
            // Hotels and other sections would go here...
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                Image("EncoreLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 20)
                    .opacity(0.8)
                Spacer()
            }
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4
        .background(Color.white)
        .foregroundColor(.black)
    }
}
