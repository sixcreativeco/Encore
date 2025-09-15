import SwiftUI
import Kingfisher

struct DefaultPreviewView: View {
    @Binding var tour: Tour
    var onUpload: (Int) -> Void
    var previewMode: LandingPageConfigView.PreviewDevice

    var body: some View {
        VStack {
            ZStack(alignment: .bottomLeading) {
                // Media View
                Group {
                    if let videoURLString = tour.landingPageHeaderVideoUrl, let url = URL(string: videoURLString) {
                        Text("Video Preview Not Available").foregroundColor(.white) // Placeholder for video
                    } else if let imageURLString = tour.landingPageHeaderImageUrl, let url = URL(string: imageURLString) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(height: previewMode == .desktop ? 250 : 180)
                .clipped()
                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom))
                // --- FIX 2: Constrain the tappable area ---
                .contentShape(Rectangle())
                .onTapGesture { onUpload(1) }
                
                // Text Overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(tour.artist)
                        .font(previewMode == .desktop ? .title2 : .headline)
                    Text(tour.tourName)
                        .font(previewMode == .desktop ? .system(size: 40, weight: .bold) : .title.bold())
                    Text(tour.landingPageBio ?? "Tour bio appears here...")
                        .font(previewMode == .desktop ? .subheadline : .caption)
                        .lineLimit(2)
                }
                .foregroundColor(.white)
                .padding()
            }
            
            // Show Cards
            VStack(spacing: 8) {
                Text("Upcoming Shows").font(.headline).padding(.top)
                showCardPreview
                showCardPreview
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .scaleEffect(previewMode == .desktop ? 1.0 : 0.6)
        .frame(width: previewMode == .desktop ? nil : 375, height: previewMode == .desktop ? nil : 667)
    }
    
    private var showCardPreview: some View {
        HStack {
            VStack(alignment: .center, spacing: 2) {
                Text("CITY").font(.title3.bold())
                Text("Venue Name").font(.caption)
            }
            Spacer()
            Text("DATE").font(.headline)
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(8)
    }
}
