//
//  ALKActivityIndicator.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 21/06/19.
//

import UIKit

/// Custom ActivityIndicator view which will present a white large styled UIActivityIndicator
/// on top a rectangular background.
public class ALKActivityIndicator: UIView {
    public struct Size {
        public let width: CGFloat
        public let height: CGFloat
        public init(width: CGFloat, height: CGFloat) {
            self.width = width
            self.height = height
        }
    }

    let size: Size

    fileprivate var indicator = UIActivityIndicatorView(style: .whiteLarge)

    /// Initializers
    ///
    /// - Parameters:
    ///   - frame: Used to set view's frame.
    ///   - backgroundColor: Color of rectangular background.
    ///   - indicatorColor: Color of ActivityIndicator.
    ///   - size: Size of activity indicator.
    ///
    /// - Note: Make sure you use the same size passed here to set constraints to this view.
    public init(frame: CGRect, backgroundColor: UIColor, indicatorColor: UIColor, size: Size) {
        self.size = size
        super.init(frame: frame)
        self.backgroundColor = backgroundColor
        indicator.color = indicatorColor
        setupView()
        isHidden = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func startAnimating() {
        isHidden = false
        indicator.startAnimating()
    }

    public func stopAnimating() {
        isHidden = true
        indicator.stopAnimating()
    }

    private func setupView() {
        layer.cornerRadius = 10
        clipsToBounds = true

        addViewsForAutolayout(views: [indicator])
        bringSubviewToFront(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: size.width / 2),
            indicator.heightAnchor.constraint(equalToConstant: size.height / 2),
        ])
    }
}
