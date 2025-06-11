import SwiftUI

struct TourCard: View {
    let tour: TourModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster Image
            AsyncImage(url: URL(string: tour.posterURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.system(size: 24))
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(10)

            // Tour Info
            Text(tour.name)
                .font(.headline)
                .foregroundColor(.primary)

            Text(tour.artist)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(tour.startDate.formatted(date: .abbreviated, time: .omitted)) → \(tour.endDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
