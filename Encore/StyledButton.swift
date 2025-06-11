import SwiftUI

struct StyledButton: View {
    var title: String
    var action: () -> Void
    var fullWidth: Bool = false
    var showArrow: Bool = true

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
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color("#EEEEEE"))
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
