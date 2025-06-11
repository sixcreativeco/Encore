import SwiftUI
import AppKit

extension View {
    func getHostingWindow() -> NSWindow? {
        let allWindows = NSApplication.shared.windows
        return allWindows.first
    }
}
