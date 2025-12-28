import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlString: String
    let backgroundColor: Color

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        // Apply background color both to WKWebView and its scrollView
        let uiColor = UIColor(backgroundColor)
        webView.backgroundColor = uiColor
        webView.scrollView.backgroundColor = uiColor
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Re-apply background in case the Color changes
        let uiColor = UIColor(backgroundColor)
        uiView.backgroundColor = uiColor
        uiView.scrollView.backgroundColor = uiColor

        // Load HTML if needed
        if uiView.url == nil && uiView.backForwardList.currentItem == nil {
            uiView.loadHTMLString(htmlString, baseURL: nil)
        }
    }
}

#Preview {
    WebView(htmlString: "<h1>Test</h1>", backgroundColor: .white)
}
