//
//  ALKDocumentViewerController.swift
//  ApplozicSwift
//
//  Created by apple on 13/03/19.
//

import Foundation
import WebKit

class ALKDocumentViewerController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView = WKWebView()
    var fileName: String = ""
    var filePath: String = ""
    var fileUrl: URL = URL(fileURLWithPath: "")

    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    required init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        fileUrl = ALKFileUtils().getDocumentDirectory(fileName: filePath)
        activityIndicator.startAnimating()
        webView.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showShare(_:)))
        title = fileName
    }

    @objc func showShare(_: Any?) {
        let vc = UIActivityViewController(activityItems: [fileUrl], applicationActivities: [])
        present(vc, animated: true)
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
