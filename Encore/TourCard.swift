import SwiftUI

struct TourCard: View {
    let tour: TourModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                AsyncImage(url: URL(string: tour.posterURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width * 3 / 2)
                .cornerRadius(8)
            }
            .aspectRatio(2/3, contentMode: .fit)

            Text(tour.artist)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Text(tour.name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}
