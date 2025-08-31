import SwiftUI

struct ShowPDFCard: View {
    let show: Show

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "music.mic.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading) {
                    Text(show.venueName)
                        .font(.system(size: 12, weight: .bold))
                    Text(show.city)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("SHOW DAY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            
            Text(show.venueAddress)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.leading, 34) // Align with title
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
