import SwiftUI

struct StyledStepper: View {
    var label: String
    @Binding var value: Int
    var step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption)
            Stepper("\(value) min", value: $value, in: 0...300, step: step)
                .labelsHidden()
        }
    }
}
