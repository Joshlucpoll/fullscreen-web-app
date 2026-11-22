import SwiftUI
import WebKit

@main
struct WebApp: App {
    // Set by WEB_APP_URL in project.yml (or the build-ipa.sh environment).
    let url: URL = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "WebAppURL") as? String,
              let url = URL(string: value), url.scheme != nil
        else { fatalError("WebAppURL in Info.plist is missing or invalid; set WEB_APP_URL") }
        return url
    }()

    var body: some Scene {
        WindowGroup {
            FullscreenWebView(url: url)
                .ignoresSafeArea()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden) // auto-hide the home indicator
        }
    }
}

struct FullscreenWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // Some sites reject browsers they don't recognise, so present as Safari.
        config.applicationNameForUserAgent = "Version/27.0 Safari/605.1.15"
        // Some sites only unlock features in an installed PWA; make the page believe it is one.
        config.userContentController.addUserScript(
            WKUserScript(source: pwaSpoof, injectionTime: .atDocumentStart, forMainFrameOnly: false))

        let view = WKWebView(frame: .zero, configuration: config)
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isInspectable = true // debug from Safari > Develop on a Mac
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKUIDelegate {
        // Open pop-ups (e.g. sign-in windows) in the same view; WKWebView drops them otherwise.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            webView.load(navigationAction.request)
            return nil
        }
    }
}

/// Reports "installed PWA" to page scripts: `navigator.standalone` is true and
/// `(display-mode: standalone)` matches, while browser/fullscreen/minimal-ui don't.
let pwaSpoof = #"""
(() => {
  Object.defineProperty(Navigator.prototype, 'standalone', { get: () => true, configurable: true });
  const realMatchMedia = window.matchMedia.bind(window);
  window.matchMedia = (query) => realMatchMedia(String(query).replace(
    /\(\s*display-mode\s*:\s*([a-z-]+)\s*\)/gi,
    (_, mode) => mode.toLowerCase() === 'standalone' ? '(min-width: 0px)' : '(max-width: 0px)'));
})();
"""#
