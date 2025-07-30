import SwiftUI

struct ItineraryItemCard: View {
    let item: ItineraryItem
    var locationHint: String?
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // This helper function now correctly formats the time based on the
    // specific timezone saved with each itinerary item.
    private func formattedLocalTime(for item: ItineraryItem) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // e.g., 8:45 PM
        if let timezoneIdentifier = item.timezone {
            formatter.timeZone = TimeZone(identifier: timezoneIdentifier)
        }
        return formatter.string(from: item.timeUTC.dateValue())
    }
    
    var body: some View {
         Button(action: onExpandToggle) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "questionmark.circle")
                            .font(.title2)
                                                
                        Text(item.title)
                            .font(.headline)
                                                
                        Spacer()
                                                
                        // --- THIS IS THE UI FIX ---
                        // It now correctly displays the local time and the new subtitle
                        // which we are using for the timezone note (e.g., "Melbourne Time").
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formattedLocalTime(for: item))
                            if let subtitle = item.subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.subheadline)
                        // --- END OF UI FIX ---
                    }
                    
                    if let note = item.notes, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 38) // Align with title
                    }
                }
                .padding()
                
                if isExpanded {
                    expandedActionView
                }
            }
            .background(Color.black.opacity(0.15))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
        
    private var expandedActionView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                Button(action: onEdit) {
                    Text("Edit")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color(red: 116/255, green: 151/255, blue: 173/255))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                                
                Button(action: onDelete) {
                     Text("Delete")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color(red: 193/255, green: 106/255, blue: 106/255))
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
}
