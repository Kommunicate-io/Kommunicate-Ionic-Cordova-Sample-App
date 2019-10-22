//
//  ALKAccountSuspensionController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 05/06/18.
//

import UIKit

public class ALKAccountSuspensionController: UIViewController {
    /// When the close button is tapped this will be called.
    public var closePressed: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    @objc func closeButtonAction(_: UIButton) {
        closePressed?()
    }

    private func setupViews() {
        view.backgroundColor = UIColor(netHex: 0xFAFAFA)
        guard let accountView = Bundle.applozic.loadNibNamed("ALKAccountSuspensionView", owner: self, options: nil)?.first as? UIView else {
            return
        }
        accountView.frame = CGRect(x: 0, y: 50, width: view.frame.width, height: view.frame.height - 50)
        view.addSubview(accountView)
        let closeButton = closeButtonOf(frame: CGRect.zero)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        // Constraints
        var topAnchor = view.topAnchor
        if #available(iOS 11, *) {
            topAnchor = view.safeAreaLayoutGuide.topAnchor
        }
        NSLayoutConstraint.activate(
            [closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
             closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
             closeButton.heightAnchor.constraint(equalToConstant: 30),
             closeButton.widthAnchor.constraint(equalToConstant: 30)]
        )
    }

    private func closeButtonOf(frame: CGRect) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = frame
        button.addTarget(self, action: #selector(closeButtonAction(_:)), for: .touchUpInside)
        let closeImage = UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(closeImage, for: .normal)
        button.tintColor = UIColor.black
        return button
    }
}
