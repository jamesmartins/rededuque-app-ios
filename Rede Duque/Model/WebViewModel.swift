import SwiftUI
import WebKit

struct WebViewModel: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    let url : URL
    var didStart: () -> Void
    var didFinish: () -> Void
    var didFail: (String) -> Void
    var callMainView: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        
        let request = URLRequest(url: url)
        webView.load(request)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(didStart: didStart, didFinish: didFinish, didFail: didFail, callMainView: callMainView)
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    
    var didStart: () -> Void
    var didFinish: () -> Void
    var didFail: (String) -> Void
    var callMainView: () -> Void
    
    init(didStart: @escaping () -> Void, didFinish: @escaping () -> Void, didFail: @escaping (String) -> Void, callMainView: @escaping () -> Void) {
        self.didStart = didStart
        self.didFinish = didFinish
        self.didFail = didFail
        self.callMainView = callMainView
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        didStart()
        print("didStart url:\(webView.url?.absoluteString ?? "-")")
        if let url = webView.url, url.absoluteString.localizedCaseInsensitiveContains("intro.do") {
            webView.stopLoading()
            callMainView()
        } else if let url = webView.url, url.absoluteString.localizedCaseInsensitiveContains("intro.php") {
            webView.stopLoading()
            callMainView()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinish()
        print("didFinish url:\(webView.url?.absoluteString ?? "-")")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      if let error = error as? NSError, error.domain == NSURLErrorDomain, error.code == NSURLErrorTimedOut {
          print("Carregamento expirou didFail: webview reload")
          didFail(error.localizedDescription)
      } else {
          didFail(error.localizedDescription)
          print("didFail url:\(webView.url?.absoluteString ?? "-")\nerror:\(error.localizedDescription)")
      }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFail(error.localizedDescription)
        print("didFail url:\(webView.url?.absoluteString ?? "-")\nerror:\(error.localizedDescription)")
    }
}

