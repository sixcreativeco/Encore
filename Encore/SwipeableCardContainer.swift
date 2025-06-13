import SwiftUI

struct SwipeableCardContainer<Content: View>: View {
    let content: () -> Content
    let onDelete: () -> Void
    let onEdit: () -> Void

    @State private var offsetX: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let swipeThreshold: CGFloat = 80

    var body: some View {
        ZStack(alignment: .leading) {
            // FULL BACKGROUND ACTIONS (no corner radius)
            fullSwipeBackground

            // CARD FLOATS ON TOP
            content()
                .offset(x: offsetX + dragOffset)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded(onDragEnded)
                )
                .animation(.spring(), value: offsetX)
        }
        .padding(.horizontal)
    }

    private var fullSwipeBackground: some View {
        HStack(spacing: 0) {
            // Edit zone on left
            Rectangle()
                .fill(Color.blue)
                .frame(width: 80)
                .overlay(
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .font(.title)
                )

            Spacer()

            // Delete zone on right
            Rectangle()
                .fill(Color.red)
                .frame(width: 80)
                .overlay(
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .font(.title)
                )
        }
    }

    private func onDragEnded(_ value: DragGesture.Value) {
        let totalOffset = offsetX + value.translation.width

        if totalOffset > swipeThreshold {
            onEdit()
            offsetX = 0
        } else if totalOffset < -swipeThreshold {
            onDelete()
            offsetX = 0
        } else {
            offsetX = 0
        }
    }
}
