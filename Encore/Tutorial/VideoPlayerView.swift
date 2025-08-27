import SwiftUI
import AVKit

/// A SwiftUI view that plays a local video file on a silent, chromeless, looping player.
/// This implementation uses compiler directives to work on both macOS and iOS.
struct VideoPlayerView: View {
    let fileName: String

    var body: some View {
        _VideoPlayerView(fileName: fileName)
            .aspectRatio(contentMode: .fill)
            .disabled(true) // Disable interaction with the video layer
    }
}

#if os(macOS)
// MARK: - macOS Implementation (NSViewRepresentable)

fileprivate struct _VideoPlayerView: NSViewRepresentable {
    let fileName: String

    func makeNSView(context: Context) -> NSView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .none // Hide video controls
        playerView.player = context.coordinator.player
        context.coordinator.setupPlayer(for: fileName)
        return playerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // This function is now called when the fileName changes.
        context.coordinator.setupPlayer(for: fileName)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let player = AVPlayer()
        private var currentFileName: String?
        private var loopObserver: Any?

        init() {
            player.isMuted = true
            player.actionAtItemEnd = .none
        }
        
        deinit {
            if let loopObserver = loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
            }
        }

        func setupPlayer(for fileName: String) {
            // Only update the player if the file name is different
            guard fileName != currentFileName else { return }

            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else {
                print("❌ ERROR: Video file '\(fileName).mp4' not found in bundle.")
                return
            }
            
            // Clean up the old observer before creating a new item
            if let loopObserver = loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
            }

            let newItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: newItem)
            
            // Add a new observer for the new item to handle looping
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newItem,
                queue: .main
            ) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
            
            currentFileName = fileName
            player.play()
        }
    }
}

#else
// MARK: - iOS Implementation (UIViewRepresentable)

fileprivate struct _VideoPlayerView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> UIView {
        let playerUIView = PlayerUIView(frame: .zero)
        (playerUIView.layer as! AVPlayerLayer).videoGravity = .resizeAspectFill
        playerUIView.player = context.coordinator.player
        context.coordinator.setupPlayer(for: fileName)
        return playerUIView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // This function is now called when the fileName changes.
        context.coordinator.setupPlayer(for: fileName)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        let player = AVPlayer()
        private var currentFileName: String?
        private var loopObserver: Any?

        init() {
            player.isMuted = true
            player.actionAtItemEnd = .none
        }
        
        deinit {
            if let loopObserver = loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
            }
        }

        func setupPlayer(for fileName: String) {
            guard fileName != currentFileName else { return }
            
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else {
                print("❌ ERROR: Video file '\(fileName).mp4' not found in bundle.")
                return
            }
            
            if let loopObserver = loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
            }

            let newItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: newItem)
            
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newItem,
                queue: .main
            ) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
            
            currentFileName = fileName
            player.play()
        }
    }
}

/// A custom UIView subclass that hosts the AVPlayerLayer for iOS.
fileprivate class PlayerUIView: UIView {
    var player: AVPlayer? {
        get { (layer as! AVPlayerLayer).player }
        set { (layer as! AVPlayerLayer).player = newValue }
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

#endif
