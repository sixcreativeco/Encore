import SwiftUI
import Kingfisher

struct ScrapbookPreviewView: View {
    @Binding var tour: Tour
    var onUpload: (Int) -> Void
    var previewMode: LandingPageConfigView.PreviewDevice
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                KFImage(URL(string: tour.landingPageHeaderImageUrl ?? ""))
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipped()
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .rotationEffect(.degrees(-5))
                    .contentShape(Rectangle()) // --- FIX 2: Constrain the tappable area ---
                    .onTapGesture { onUpload(1) }
                
                KFImage(URL(string: tour.landingPageScrapbookImageUrl2 ?? ""))
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 140)
                    .clipped()
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .rotationEffect(.degrees(8))
                    .offset(x: 80, y: 30)
                    .contentShape(Rectangle()) // --- FIX 2: Constrain the tappable area ---
                    .onTapGesture { onUpload(2) }
                
                VStack {
                    Text(tour.artist).font(.caption).bold()
                    Text(tour.tourName).font(.title.bold())
                }
                .foregroundColor(.white)
                .blendMode(.difference)
            }
            .frame(height: 250)

            Text(tour.landingPageBio ?? "Tour bio appears here...").font(.caption).multilineTextAlignment(.center).lineLimit(2)
            
            showCardPreview
            showCardPreview
            
            Spacer()
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .scaleEffect(previewMode == .desktop ? 1.0 : 0.6)
        .frame(width: previewMode == .desktop ? nil : 375, height: previewMode == .desktop ? nil : 667)
    }
    
    private var showCardPreview: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("CITY").font(.headline.bold())
                Text("Venue Name").font(.caption)
            }
            Spacer()
            Text("DATE").font(.headline)
        }
        .foregroundColor(.black)
        .padding()
        .background(Color.orange.opacity(0.8))
        .cornerRadius(8)
    }
}
