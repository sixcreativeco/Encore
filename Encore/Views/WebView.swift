import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL

    // The Coordinator class acts as a delegate to respond to WebView events.
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // This delegate function is called when the web content has finished loading.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // This JavaScript makes the page's background transparent.
            let javascript = """
            document.documentElement.style.background = 'transparent';
            document.body.style.background = 'transparent';
            document.body.style.backgroundColor = 'transparent';
            """
            
            // Execute the JavaScript
            webView.evaluateJavaScript(javascript)
        }
    }

    // Creates the coordinator that will listen for events.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Set the coordinator as the web view's navigation delegate.
        webView.navigationDelegate = context.coordinator
        
        // This is the correct method to make a WKWebView transparent on macOS.
        webView.setValue(false, forKey: "drawsBackground")
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // The request is loaded here when the URL changes.
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}
