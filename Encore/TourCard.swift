import SwiftUI
import Kingfisher

struct TourCard: View {
    let tour: TourModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                KFImage(URL(string: tour.posterURL ?? ""))
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.1)
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.system(size: 24))
                        }
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .aspectRatio(2/3, contentMode: .fit)
            .cornerRadius(8)


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
