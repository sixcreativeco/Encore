import SwiftUI
import Kingfisher
import FirebaseFirestore

struct PrintPreviewView: View {
    @Binding var tour: Tour
    var onUpload: (Int) -> Void
    var previewMode: LandingPageConfigView.PreviewDevice

    fileprivate struct PreviewShow: Identifiable {
        let id: String
        let city: String
        let venueName: String
        let date: Date
        var isSellingOut: Bool = false
    }
    
    // Custom Colors
    private let primaryDarkText = Color(red: 30/255, green: 30/255, blue: 30/255)
    private let secondaryGreyText = Color(red: 100/255, green: 100/255, blue: 100/255)
    private let lightGreyBackground = Color(red: 247/255, green: 247/255, blue: 247/255)
    private let cardBackground = Color.white
    private let cardBorder = Color(red: 230/255, green: 230/255, blue: 230/255)
    private let sellingOutBg = Color(red: 236/255, green: 247/255, blue: 237/255)
    private let sellingOutText = Color(red: 54/255, green: 173/255, blue: 62/255)

    private var previewShows: [PreviewShow] {
        return [
            PreviewShow(
                id: "1",
                city: "Auckland",
                venueName: "Tuning Fork",
                date: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 19))!,
                isSellingOut: true
            ),
            PreviewShow(
                id: "2",
                city: "Wellington",
                venueName: "Meow Bar",
                date: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 21))!,
                isSellingOut: true
            )
        ]
    }

    var body: some View {
        let isMobile = previewMode == .mobile
        
        // --- FIX: The root is now a ScrollView to handle varying content heights ---
        ScrollView {
            VStack(spacing: 0) {
                
                // Main Image
                KFImage(URL(string: tour.landingPageHeaderImageUrl ?? ""))
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.1)
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: isMobile ? 400 : 280)
                    .cornerRadius(isMobile ? 8 : 12)
                    .clipped()
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 8)
                    .padding(.top, isMobile ? 24 : 36)
                    .padding(.bottom, isMobile ? 24 : 36)
                    .contentShape(Rectangle())
                    .onTapGesture { onUpload(1) }

                // Text Content Block
                VStack(alignment: isMobile ? .center : .leading, spacing: 0) {
                    Text(tour.artist)
                        .font(.system(size: isMobile ? 16 : 20, design: .serif))
                        .foregroundColor(secondaryGreyText)
                        .padding(.bottom, 2)

                    Text(tour.tourName)
                        .font(.system(size: isMobile ? 36 : 48, weight: .bold, design: .serif))
                        .foregroundColor(primaryDarkText)
                        .lineLimit(2)
                        .padding(.bottom, 8)

                    Text(tour.landingPageBio ?? "Tour bio appears here... A vibrant run of shows blooming with color, energy, and heart.")
                        .font(.system(size: isMobile ? 12 : 12, design: .serif))
                        .foregroundColor(secondaryGreyText)
                        .lineLimit(4)
                        .padding(.bottom, isMobile ? 32 : 48)
                }
                .multilineTextAlignment(isMobile ? .center : .leading)
                .frame(maxWidth: .infinity, alignment: isMobile ? .center : .leading)
                
                // Show Cards List
                VStack(spacing: isMobile ? 12 : 16) {
                    ForEach(previewShows) { show in
                        ShowCardPreview(
                            show: show,
                            isMobile: isMobile,
                            primaryDarkText: primaryDarkText,
                            secondaryGreyText: secondaryGreyText,
                            cardBackground: cardBackground,
                            cardBorder: cardBorder,
                            sellingOutBg: sellingOutBg,
                            sellingOutText: sellingOutText
                        )
                    }
                }
                .frame(maxWidth: isMobile ? .infinity : 420)
                
                Spacer()
            }
            .padding(.horizontal, isMobile ? 18 : 40)
        }
        // --- FIX: This frame modifier now correctly handles the preview window size ---
        .frame(width: isMobile ? 390 : nil, height: isMobile ? 844 : nil)
        .background(lightGreyBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }
}

// MARK: - ShowCardPreview Helper (No changes needed here)

fileprivate struct ShowCardPreview: View {
    let show: PrintPreviewView.PreviewShow
    let isMobile: Bool
    let primaryDarkText: Color
    let secondaryGreyText: Color
    let cardBackground: Color
    let cardBorder: Color
    let sellingOutBg: Color
    let sellingOutText: Color

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: isMobile ? 2 : 4) {
                Text(show.city)
                    .font(.system(size: isMobile ? 18 : 20, weight: .medium))
                    .foregroundColor(primaryDarkText)
                Text(show.venueName)
                    .font(.system(size: isMobile ? 14 : 16, weight: .regular))
                    .foregroundColor(secondaryGreyText)

                if show.isSellingOut {
                    Text("Selling Out")
                        .font(.system(size: isMobile ? 10 : 12, weight: .medium))
                        .padding(.horizontal, isMobile ? 6 : 8)
                        .padding(.vertical, isMobile ? 3 : 4)
                        .background(sellingOutBg)
                        .foregroundColor(sellingOutText)
                        .cornerRadius(isMobile ? 3 : 4)
                        .padding(.top, isMobile ? 2 : 4)
                }
            }
            Spacer()
            Text(dateFormatter.string(from: show.date).uppercased())
                .font(.system(size: isMobile ? 18 : 20, weight: .medium))
                .foregroundColor(primaryDarkText)
        }
        .padding(.vertical, isMobile ? 16 : 20)
        .padding(.horizontal, isMobile ? 20 : 25)
        .background(cardBackground)
        .cornerRadius(isMobile ? 8 : 12)
        .shadow(color: .black.opacity(0.05), radius: isMobile ? 4 : 8, y: isMobile ? 2 : 4)
        .overlay(
            RoundedRectangle(cornerRadius: isMobile ? 8 : 12)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }
}
