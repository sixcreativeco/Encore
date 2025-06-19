import SwiftUI

struct SetlistCardView: View {
    let item: SetlistItemModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Column
            Image(systemName: item.type.icon)
                .font(.system(size: 18))
                .frame(width: 24, alignment: .center)
                .foregroundColor(.accentColor)
                .padding(.top, 2)

            // Content Column
            VStack(alignment: .leading, spacing: 4) {
                switch item.type {
                case .song:
                    songView
                case .note:
                    noteView
                case .lighting:
                    lightingView
                case .tech:
                    techView
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }

    @ViewBuilder
    private var songView: some View {
        Text(item.title ?? "Untitled Song")
            .font(.headline)
        if let notes = item.notes, !notes.isEmpty {
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var noteView: some View {
        Text(item.notes ?? "Empty Note")
            .font(.subheadline)
            .foregroundColor(.primary)
    }

    @ViewBuilder
    private var lightingView: some View {
        HStack(spacing: 8) {
            Text("Lighting Cue")
                .font(.headline)
            Circle()
                .fill(item.mainColor)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
        if let notes = item.notes, !notes.isEmpty {
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var techView: some View {
        Text("Technical Change")
            .font(.headline)
        if let notes = item.notes, !notes.isEmpty {
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct SetlistCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            SetlistCardView(item: .init(order: 0, type: .song, title: "Opening Track", notes: "Intro with synth pad."))
            SetlistCardView(item: .init(order: 1, type: .lighting, notes: "Full stage wash, strobes on chorus.", mainColorHex: "#FF5733"))
            SetlistCardView(item: .init(order: 2, type: .note, notes: "Band introduction here."))
            SetlistCardView(item: .init(order: 3, type: .tech, notes: "Switch to acoustic guitar."))
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}
