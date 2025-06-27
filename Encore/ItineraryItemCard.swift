import SwiftUI

struct ItineraryItemCard: View {
    let item: ItineraryItem
    var locationHint: String?
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private func formattedLocalTime(for item: ItineraryItem) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if let timezoneIdentifier = item.timezone, let timeZone = TimeZone(identifier: timezoneIdentifier) {
            formatter.timeZone = timeZone
        } else {
            // Fallback to the user's current timezone if the item's timezone is not specified
            formatter.timeZone = .current
        }
        
        let date = item.timeUTC.dateValue()
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onExpandToggle) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "questionmark.circle")
                             #if os(iOS)
                            .font(.headline)
                            #else
                            .font(.title2)
                            #endif
                        
                        Text(item.title)
                             #if os(iOS)
                            .font(.subheadline.weight(.semibold))
                            #else
                            .font(.headline)
                             #endif
                        
                        Spacer()
                        
                        Text(formattedLocalTime(for: item))
                            #if os(iOS)
                            .font(.caption)
                             #else
                            .font(.subheadline)
                            #endif
                    }

                    if let subtitle = item.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            #if os(iOS)
                            .font(.caption)
                             #else
                            .font(.subheadline)
                            #endif
                            .foregroundColor(.gray)
                    }
                    
                    if let note = item.notes, !note.isEmpty {
                        Text(note)
                             #if os(iOS)
                            .font(.caption)
                            #else
                            .font(.subheadline)
                            #endif
                            .foregroundColor(.gray)
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
