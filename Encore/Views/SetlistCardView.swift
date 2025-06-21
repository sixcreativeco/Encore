import SwiftUI

struct SetlistCardView: View {
    // This now accepts our new, flat SetlistItem model
    let item: SetlistItem
    let onOpenNotes: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(item.order + 1).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .leading)
            
            // The switch now uses the simpler .song or .marker type
            switch item.type {
            case .song:
                songView()
            case .marker:
                markerView()
            }
        }
        .padding(.vertical, 8)
    }
    
    // This view now accesses the optional properties directly from the 'item'.
    private func songView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.songTitle ?? "Untitled Song") // Use nil-coalescing for safety
                    .font(.headline)
                
                HStack(spacing: 16) {
                    if let bpm = item.bpm {
                        Label("\(bpm) BPM", systemImage: "metronome")
                    }
                    if let key = item.key, !key.isEmpty, let tonality = item.tonality {
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
    
    // This view now accesses the optional markerDescription directly from the 'item'.
    private func markerView() -> some View {
        HStack {
            Label(item.markerDescription ?? "Untitled Marker", systemImage: "pause.fill")
                .font(.subheadline.italic())
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
