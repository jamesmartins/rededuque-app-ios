import UIKit
import WebKit

final class MenuWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private let pageURL: URL
    private let pageTitle: String
    private var webView: WKWebView!
    private let indicator = UIActivityIndicatorView(style: .large)
    private var hasDismissed = false

    init(url: URL, title: String) {
        self.pageURL = url
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        let contentController = WKUserContentController()
        contentController.add(self, name: "menuBack")
        contentController.addUserScript(WKUserScript(
            source: Self.backButtonJavaScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        indicator.startAnimating()
        webView.load(URLRequest(url: pageURL))
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "menuBack")
    }

    private func dismissToHome() {
        guard !hasDismissed else { return }
        hasDismissed = true
        dismiss(animated: true)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "menuBack" else { return }
        dismissToHome()
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url?.absoluteString,
           shouldReturnToHome(for: url) {
            decisionHandler(.cancel)
            dismissToHome()
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
        if let url = webView.url?.absoluteString, shouldReturnToHome(for: url) {
            dismissToHome()
            return
        }
        webView.evaluateJavaScript(Self.backButtonJavaScript, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        indicator.stopAnimating()
    }

    private func shouldReturnToHome(for url: String) -> Bool {
        let lower = url.lowercased()
        // Back from card pages typically goes to native menu / intro.
        if lower.contains("novomenu") { return true }
        if lower.contains("intro.do") { return true }
        return false
    }

    /// Intercepts the green toolbar back control used by Bunker web pages.
    private static let backButtonJavaScript = """
    (function() {
      if (window.__redeDuqueMenuBackInstalled) { return; }
      window.__redeDuqueMenuBackInstalled = true;

      function notifyBack() {
        try { window.webkit.messageHandlers.menuBack.postMessage('back'); } catch (e) {}
      }

      function isMenuBackCandidate(el) {
        if (!el || el === document.body || el === document.documentElement) { return false; }
        var cls = ((el.className && el.className.toString) ? el.className.toString() : '').toLowerCase();
        var id = (el.id || '').toLowerCase();
        var href = (el.getAttribute && (el.getAttribute('href') || '') || '').toLowerCase();
        var onclick = (el.getAttribute && (el.getAttribute('onclick') || '') || '').toLowerCase();
        var aria = (el.getAttribute && (el.getAttribute('aria-label') || '') || '').toLowerCase();
        var title = (el.getAttribute && (el.getAttribute('title') || '') || '').toLowerCase();
        var src = (el.getAttribute && (el.getAttribute('src') || '') || '').toLowerCase();
        var alt = (el.getAttribute && (el.getAttribute('alt') || '') || '').toLowerCase();

        // Navigate back to native Home (novoMenu / intro).
        if (href.indexOf('novomenu') >= 0 || href.indexOf('intro.do') >= 0) { return true; }
        if (onclick.indexOf('novomenu') >= 0 || onclick.indexOf('intro.do') >= 0) { return true; }
        if (cls.indexOf('voltar') >= 0 || id.indexOf('voltar') >= 0) { return true; }
        if (aria.indexOf('voltar') >= 0 || title.indexOf('voltar') >= 0 || alt.indexOf('voltar') >= 0) { return true; }
        if (src.indexOf('voltar') >= 0 || src.indexOf('seta') >= 0) { return true; }
        return false;
      }

      document.addEventListener('click', function(e) {
        var el = e.target;
        for (var i = 0; i < 6 && el; i++) {
          if (isMenuBackCandidate(el)) {
            e.preventDefault();
            e.stopPropagation();
            notifyBack();
            return false;
          }
          el = el.parentElement;
        }
      }, true);
    })();
    """
}
