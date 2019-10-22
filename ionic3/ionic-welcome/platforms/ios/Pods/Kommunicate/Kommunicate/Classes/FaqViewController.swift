//
//  FaqViewController.swift
//  Kommunicate
//
//  Created by Shivam Pokhriyal on 07/05/19.
//

import ApplozicSwift
import WebKit

public class FaqViewController: UIViewController, Localizable {

    var webView: WKWebView = WKWebView()
    let url: URL
    let configuration: ALKConfiguration

    public init(url: URL, configuration: ALKConfiguration) {
        self.url = url
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        view = webView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: url))
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let navigationController = navigationController else { return }
        configureNavigationBar(navigationController.navigationBar)
        var backImage = UIImage.init(named: "icon_back", in: Bundle.kommunicate, compatibleWith: nil)
        backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: backImage, style: .plain, target: self , action: #selector(backTapped))
        navigationItem.title = localizedString(forKey: "FaqTitle", fileName: configuration.localizedStringFileName)
    }

    @objc func backTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    private func configureNavigationBar(_ navigationBar: UINavigationBar) {
        navigationBar.barTintColor = configuration.navigationBarBackgroundColor
        navigationBar.tintColor = configuration.navigationBarItemColor
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: configuration.navigationBarTitleColor]
        navigationBar.isTranslucent = false
    }

}

extension FaqViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }
        webView.load(navigationAction.request)
        decisionHandler(.cancel)
    }

}
