import SwiftUI

struct WrapView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    var items: Data
    var content: (Data.Element) -> Content

    @State private var totalHeight = CGFloat.zero

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}
