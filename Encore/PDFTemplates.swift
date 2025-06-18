import SwiftUI

// This file contains the SwiftUI Views that will be rendered as PDF pages.

struct ShowTimingPDFView: View {
    let show: ShowModel
    let tour: TourModel

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
                Text("\(tour.artist) - \(tour.name)")
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
                    Text(fullDateFormatter.string(from: show.date))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Venue").font(.headline)
                    Text(show.venue)
                    Text(show.address)
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
                EventRow(title: "Venue Access", time: show.venueAccess)
                EventRow(title: "Load In", time: show.loadIn)
                
                // Support Acts
                ForEach(show.supportActs) { act in
                    EventRow(title: "\(act.name) Soundcheck", time: act.soundCheck)
                    EventRow(title: "\(act.name) Set", time: act.setTime)
                }
                
                // Headliner
                if let headliner = show.headliner {
                    EventRow(title: "Headliner Soundcheck", time: headliner.soundCheck)
                }
                
                EventRow(title: "Doors Open", time: show.doorsOpen)
                
                if let headliner = show.headliner {
                    EventRow(title: "Headliner Set", time: headliner.setTime)
                }
                
                EventRow(title: "Pack Out", time: show.packOut)
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
