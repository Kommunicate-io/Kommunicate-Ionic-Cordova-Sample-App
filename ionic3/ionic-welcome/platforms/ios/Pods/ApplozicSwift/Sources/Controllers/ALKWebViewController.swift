//
//  ALKWebViewController.swift
//  ApplozicSwift
//
//  Created by Sunil on 12/07/19.
//

import Foundation
import WebKit

class ALKWebViewController: UIViewController, WKNavigationDelegate {
    var wkWebView: WKWebView = WKWebView()
    let htmlString: String
    let url: URL?
    let navTitle: String?

    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    init(htmlString: String, url: URL?, title: String?) {
        self.htmlString = htmlString
        self.url = url
        navTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func webViewConfiguration() -> WKWebViewConfiguration {
        let viewportSource = """
            var meta = document.createElement('meta');
            meta.setAttribute('name', 'viewport');
            meta.setAttribute('content', 'width=device-width');
            meta.setAttribute('initial-scale', '1.0');
            meta.setAttribute('shrink-to-fit', 'no');
            document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let viewportScript = WKUserScript(source: viewportSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let disableCalloutSource = "document.documentElement.style.webkitTouchCallout='none';"

        let disableCalloutScript = WKUserScript(source: disableCalloutSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        /// Add script
        let controller = WKUserContentController()
        controller.addUserScript(viewportScript)
        controller.addUserScript(disableCalloutScript)

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = controller
        return webConfiguration
    }

    private func setupWebView() {
        wkWebView = WKWebView(frame: .zero, configuration: webViewConfiguration())
        wkWebView.translatesAutoresizingMaskIntoConstraints = false
        wkWebView.backgroundColor = UIColor.white
        wkWebView.allowsBackForwardNavigationGestures = false
        wkWebView.contentMode = .scaleAspectFit
        wkWebView.scrollView.isScrollEnabled = true
        wkWebView.scrollView.showsVerticalScrollIndicator = true
        wkWebView.scrollView.showsHorizontalScrollIndicator = true
        wkWebView.scrollView.bounces = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        wkWebView.navigationDelegate = self
        view = wkWebView
        activityIndicator.startAnimating()
        wkWebView.loadHTMLString(htmlString, baseURL: url)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = navTitle
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
