import SwiftUI

struct SetlistCardView: View {
    let item: SetlistItemModel
    let onOpenNotes: () -> Void

    var body: some View {
        // The root is now just the content, not the outer HStack
        // This allows it to be composed nicely with the drag handle in the parent SetlistView
        switch item.itemType {
        case .song(let details):
            songView(details: details)
        case .marker(let details):
            markerView(details: details)
        }
    }
    
    private func songView(details: SongDetails) -> some View {
        HStack {
            // Number is now part of the main row content
            Text("\(item.order + 1).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(details.name)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    if let bpm = details.bpm {
                        Label("\(bpm) BPM", systemImage: "metronome")
                    }
                    if let key = details.key, let tonality = details.tonality {
                        Label("\(key) \(tonality)", systemImage: "music.key.shift.fill")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onOpenNotes) {
                Image(systemName: "note.text")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func markerView(details: MarkerDetails) -> some View {
        HStack {
            // Number is now part of the main row content
            Text("\(item.order + 1).")
                .font(.headline.italic())
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .leading)

            Label(details.description, systemImage: "pause.fill")
                .font(.subheadline.italic())
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
