import SwiftUI
import Kingfisher

struct DarkModePreviewView: View {
    @Binding var tour: Tour
    var onUpload: (Int) -> Void
    var previewMode: LandingPageConfigView.PreviewDevice

    // --- YOUR MANUAL CONTROLS ---
    struct ManualControls {
        let vSpacing_ArtistToTitle: CGFloat = -5
        let vSpacing_TitleToBio: CGFloat = 12
        let hWidth_Bio_Desktop: CGFloat = 370
        let hWidth_Bio_Mobile: CGFloat = 320
        let vPos_TextContainer: CGFloat = 100
        let hPos_TextContainer: CGFloat = 20
        let vSpacing_HeroToTickets: CGFloat = 140
        let w_TicketCard_Desktop: CGFloat = 400
    }
    private let controls = ManualControls()
    // --- END MANUAL CONTROLS ---

    @GestureState private var dragOffset: CGFloat = 0
    @State private var accumulatedOffsetY: CGFloat = 0.5

    private let backgroundColor = Color.black
    private let cardBackgroundColor = Color(red: 28/255, green: 28/255, blue: 30/255)
    private let cardBorderColor = Color.white.opacity(0.1)
    private let accentColor = Color(red: 177/255, green: 153/255, blue: 255/255)
    // --- FIX: Added a subtle blue to the gradient ---
    private let gradientMidColor = Color(red: 16/255, green: 20/255, blue: 38/255)

    var body: some View {
        ZStack {
            backgroundColor
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        mediaViewAndGradient
                        textOverlay
                    }
                    showsSection
                }
            }
        }
        .cornerRadius(12)
        .frame(width: previewMode == .desktop ? nil : 390, height: previewMode == .desktop ? nil : 844)
        .onAppear {
            self.accumulatedOffsetY = tour.landingPageHeaderFocusY ?? 0.5
        }
    }
    
    private var mediaViewAndGradient: some View {
        let heroHeight: CGFloat = previewMode == .desktop ? 350 : 450
        
        return ZStack {
            mediaViewContent
                .frame(height: heroHeight)

            // --- FIX: Updated gradient for a smoother, blue-tinted fade to black ---
            LinearGradient(colors: [.clear, .clear, gradientMidColor.opacity(0.5), backgroundColor], startPoint: .top, endPoint: .bottom)
        }
        .frame(height: heroHeight)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { onUpload(1) }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    let newOffset = accumulatedOffsetY + (value.translation.height / (heroHeight / 2))
                    accumulatedOffsetY = min(1.0, max(0.0, newOffset))
                    tour.landingPageHeaderFocusY = accumulatedOffsetY
                }
        )
    }

    @ViewBuilder
    private var mediaViewContent: some View {
        let heroHeight: CGFloat = previewMode == .desktop ? 350 : 450
        
        if let videoURLString = tour.landingPageHeaderVideoUrl {
            Text("Video Preview").foregroundColor(.white)
        } else if let imageURLString = tour.landingPageHeaderImageUrl, let url = URL(string: imageURLString) {
            KFImage(url)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: previewMode == .desktop ? nil : 390, height: heroHeight * 1.5)
                .offset(y: calculateImageOffset(containerHeight: heroHeight))
        } else {
            Color(white: 0.1)
        }
    }

    private func calculateImageOffset(containerHeight: CGFloat) -> CGFloat {
        let extraHeight = (containerHeight * 1.5) - containerHeight
        let initialCenteringOffset = -extraHeight / 2
        // --- FIX: Inverted the sign of the drag offset calculation ---
        let dragPixelOffset = (0.5 - accumulatedOffsetY) * -extraHeight
        
        return initialCenteringOffset + dragPixelOffset + dragOffset
    }

    private var textOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: controls.vSpacing_ArtistToTitle) {
                Text(tour.artist)
                    .font(.system(size: previewMode == .desktop ? 18 : 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(tour.tourName)
                    .font(.system(size: previewMode == .desktop ? 52 : 40, weight: .bold))
                    .tracking(-1)
            }
            
            Text(tour.landingPageBio ?? "Adam Snow is bringing his signature indie-pop glow to the stage...")
                // --- FIX: Using updated font size from your manual change ---
                .font(.system(size: previewMode == .desktop ? 11 : 10))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
                .frame(maxWidth: previewMode == .desktop ? controls.hWidth_Bio_Desktop : controls.hWidth_Bio_Mobile, alignment: .leading)
                .padding(.top, controls.vSpacing_TitleToBio)
        }
        .padding()
        .padding(.leading, controls.hPos_TextContainer)
        .offset(y: controls.vPos_TextContainer)
        .allowsHitTesting(false)
    }

    private var showsSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Get Tickets")
                .font(previewMode == .desktop ? .title2.bold() : .title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                showCardPreview(city: "Auckland", venue: "Tuning Fork", date: "AUG 19")
                showCardPreview(city: "Wellington", venue: "Meow Bar", date: "AUG 21")
                showCardPreview(city: "Christchurch", venue: "Tuning Fork", date: "AUG 22")
            }
            .frame(width: previewMode == .desktop ? controls.w_TicketCard_Desktop : nil)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
        .padding(.top, controls.vSpacing_HeroToTickets)
        .padding(.bottom)
    }
    
    private func showCardPreview(city: String, venue: String, date: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(city).font(.headline.bold())
                Text(venue).font(.subheadline).foregroundColor(.gray)
                Text("Selling Out")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(accentColor.opacity(0.2))
                    .foregroundColor(accentColor)
                    .cornerRadius(5)
                    .padding(.top, 2)
            }
            Spacer()
            Text(date).font(.headline.bold())
        }
        .foregroundColor(.white)
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardBorderColor, lineWidth: 1))
    }
}
