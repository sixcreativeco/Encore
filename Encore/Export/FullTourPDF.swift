import SwiftUI
import FirebaseFirestore
import Kingfisher

struct FullTourPDF: View {
    let tour: Tour
    let shows: [Show]
    let itinerary: [ItineraryItem]
    let flights: [Flight]
    let hotels: [Hotel]
    let crew: [TourCrew]
    let posterImage: NSImage?
    let config: ExportConfiguration

    private var eventsByDay: [Date: [AnyHashable]] {
        var dict: [Date: [AnyHashable]] = [:]
        let calendar = Calendar.current
        for item in itinerary { dict[calendar.startOfDay(for: item.timeUTC.dateValue()), default: []].append(item) }
        for flight in flights { dict[calendar.startOfDay(for: flight.departureTimeUTC.dateValue()), default: []].append(flight) }
        for hotel in hotels { dict[calendar.startOfDay(for: hotel.checkInDate.dateValue()), default: []].append(hotel) }
        for show in shows { dict[calendar.startOfDay(for: show.date.dateValue()), default: []].append(show) }
        
        for (day, items) in dict {
            dict[day] = items.sorted(by: { item1, item2 in
                let date1 = getDate(from: item1)
                let date2 = getDate(from: item2)
                return date1 < date2
            })
        }
        return dict
    }

    private func getDate(from item: AnyHashable) -> Date {
        switch item {
        case let i as ItineraryItem: return i.timeUTC.dateValue()
        case let f as Flight: return f.departureTimeUTC.dateValue()
        case let h as Hotel: return h.checkInDate.dateValue()
        case let s as Show: return s.date.dateValue()
        default: return Date.distantFuture
        }
    }

    private var sortedDays: [Date] {
        eventsByDay.keys.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            if config.includeCoverPage {
                CoverPage(tour: tour, posterImage: posterImage, theme: config.coverPageTheme)
            }

            ForEach(sortedDays, id: \.self) { day in
                if let showForDay = shows.first(where: { Calendar.current.isDate($0.date.dateValue(), inSameDayAs: day) }) {
                    ShowDaySheetPDF(tour: tour, show: showForDay, crew: crew, config: config, posterImage: posterImage)
                } else {
                    DailyItineraryPage(date: day, tour: tour, items: eventsByDay[day] ?? [], crew: crew)
                }
            }
        }
    }
}

// MARK: - PDF Page Subviews

private struct CoverPage: View {
    let tour: Tour
    let posterImage: NSImage?
    let theme: ExportConfiguration.CoverPageTheme

    var body: some View {
        Group {
            switch theme {
            case .theme1:
                Theme1CoverPage(tour: tour, posterImage: posterImage)
            case .theme2:
                Theme2CoverPage(tour: tour, posterImage: posterImage)
            }
        }
        .frame(width: 595, height: 842) // A4
    }
}

private struct Theme1CoverPage: View {
    let tour: Tour
    let posterImage: NSImage?
    var body: some View {
        ZStack {
            if let image = posterImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.4))
            } else { Color.black }

            VStack(spacing: 12) {
                Spacer()
                Text(tour.artist.uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .kerning(4)
                    .foregroundColor(.white.opacity(0.9))
                Text(tour.tourName)
                    .font(.system(size: 60, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
                Image("EncoreLogo")
                    .resizable().renderingMode(.template).scaledToFit()
                    .frame(height: 30).foregroundColor(.white.opacity(0.8))
            }
            .padding(60)
        }
    }
}

private struct Theme2CoverPage: View {
    let tour: Tour
    let posterImage: NSImage?
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let image = posterImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 400)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text(tour.artist.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
                Text(tour.tourName)
                    .font(.system(size: 48, weight: .black))
                Spacer()
                HStack {
                    VStack(spacing: 4) {
                        Rectangle().frame(height: 4)
                        Rectangle().frame(height: 4)
                        Rectangle().frame(height: 4)
                    }
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.5))
                    .frame(width: 50)

                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("POWERED BY")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Image("EncoreLogo")
                            .resizable().renderingMode(.template)
                            .scaledToFit()
                            .frame(height: 24)
                    }
                }
            }
            .padding(40)
        }
        .background(Color.white)
    }
}


private struct DailyItineraryPage: View {
    let date: Date
    let tour: Tour
    let items: [AnyHashable]
    let crew: [TourCrew]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(tour.tourName).font(.system(size: 14, weight: .bold))
                    Text(dateFormatter.string(from: date)).font(.system(size: 12)).foregroundColor(.secondary)
                }
                Spacer()
                Text(tour.artist).font(.system(size: 14, weight: .bold))
            }
            Divider()

            ForEach(items, id: \.self) { item in
                if let itineraryItem = item as? ItineraryItem {
                    ItineraryRow(item: itineraryItem)
                } else if let flight = item as? Flight {
                    FlightPDFCard(flight: flight, crew: crew)
                } else if let hotel = item as? Hotel {
                    HotelPDFCard(hotel: hotel)
                }
            }
            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .foregroundColor(.black)
    }
}

private struct ItineraryRow: View {
    let item: ItineraryItem
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text(timeFormatter.string(from: item.timeUTC.dateValue()))
                .font(.system(size: 10, weight: .bold))
                .frame(width: 70)
            
            Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "circle.fill")
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(item.title).fontWeight(.medium)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
            }
            .font(.system(size: 11))
        }
        .padding(.bottom, 4)
    }
}

private struct HotelPDFCard: View {
    let hotel: Hotel
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hotel: \(hotel.name)").font(.headline)
            Text("Check-in: \(hotel.checkInDate.dateValue().formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
            Text("Address: \(hotel.address)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
