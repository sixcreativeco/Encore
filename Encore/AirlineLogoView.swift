import SwiftUI

struct AirlineLogoView: View {
    let airlineCode: String
    let isIcon: Bool

    var body: some View {
        let imageName = "\(airlineCode)\(isIcon ? "_icon" : "_logo")"
        if let _ = Bundle.main.url(forResource: imageName, withExtension: "png") {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "airplane.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}
