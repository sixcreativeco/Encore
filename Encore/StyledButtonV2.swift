import SwiftUI

struct StyledButtonV2: View {
    var title: String
    var action: () -> Void
    var fullWidth: Bool = false
    var showArrow: Bool = true
    var width: CGFloat? = nil

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if showArrow {
                    Image(systemName: "arrow.right.circle.fill")
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: fullWidth ? .infinity : width)
            .background(Color(hex: "#EEEEEE"))
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
