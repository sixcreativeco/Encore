import SwiftUI

// This file contains the SwiftUI Views that will be rendered as PDF pages.
struct ShowTimingPDFView: View {
    // FIX: Updated to use the new 'Show' and 'Tour' models.
    let show: Show
    let tour: Tour

    private var eventTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // e.g., 4:30 PM
        return formatter
    }
    
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full // e.g., Tuesday, June 18, 2025
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading) {
                // FIX: Using new property names
                Text("\(tour.artist) - \(tour.tourName)")
                    .font(.largeTitle.bold())
                Text("Show Day Sheet: \(show.city)")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Divider()
            }

            // Info Grid
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date").font(.headline)
                    // FIX: Using .dateValue() on the Timestamp
                    Text(fullDateFormatter.string(from: show.date.dateValue()))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Venue").font(.headline)
                    Text(show.venueName)
                    Text(show.venueAddress)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Venue Contact").font(.headline)
                    Text(show.contactName ?? "N/A")
                    Text(show.contactPhone ?? "")
                }
            }
            .padding(.bottom)

            // Timeline
            VStack(alignment: .leading, spacing: 12) {
                Text("Schedule").font(.title.bold())
                // FIX: Using .dateValue() on Timestamps
                EventRow(title: "Venue Access", time: show.venueAccess?.dateValue())
                EventRow(title: "Load In", time: show.loadIn?.dateValue())
                
                // Note: Support Acts would need to be fetched separately based on the new schema.
                // For now, this part is commented out. We can add it back later.
                /*
                ForEach(show.supportActs) { act in
                    EventRow(title: "\(act.name) Soundcheck", time: act.soundCheck)
                    EventRow(title: "\(act.name) Set", time: act.setTime)
                }
                */
                
                EventRow(title: "Headliner Soundcheck", time: show.soundCheck?.dateValue())
                EventRow(title: "Doors Open", time: show.doorsOpen?.dateValue())
                EventRow(title: "Headliner Set", time: show.headlinerSetTime?.dateValue())
                EventRow(title: "Pack Out", time: show.packOut?.dateValue())
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4 Paper size at 72 dpi
    }

    private func EventRow(title: String, time: Date?) -> some View {
      HStack {
            Text(time != nil ? eventTimeFormatter.string(from: time!) : "TBC")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 100, alignment: .leading)
            Text(title)
                .font(.system(size: 14))
            Spacer()
        }
    }
}
