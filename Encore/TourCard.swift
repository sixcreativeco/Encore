import SwiftUI
import Kingfisher // Or SDWebImageSwiftUI, depending on your library

struct TourCard: View {
    // This now accepts our new Tour struct
    let tour: Tour

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                // Using Kingfisher, but you can use your preferred image loading library
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

            // Using the new 'tourName' property
            Text(tour.tourName)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}
