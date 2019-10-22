//
//  ALKPreviewPhotoViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

final class ALKPreviewPhotoViewController: ALKBaseViewController {
    fileprivate let scrollView: UIScrollView = {
        let sv = UIScrollView(frame: .zero)
        sv.backgroundColor = UIColor.clear
        sv.isUserInteractionEnabled = true
        sv.isScrollEnabled = true
        return sv
    }()

    fileprivate let imageView: UIImageView = {
        let mv = UIImageView(frame: .zero)
        mv.contentMode = .scaleAspectFit
        mv.backgroundColor = UIColor.clear
        mv.isUserInteractionEnabled = false
        return mv
    }()

    fileprivate let closeButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.tintColor = .white
        bt.setImage(UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        bt.backgroundColor = .clear
        return bt
    }()

    var image: UIImage = UIImage()

    var imageViewTopConstraint: NSLayoutConstraint?
    var imageViewBottomConstraint: NSLayoutConstraint?
    var imageViewLeadingConstraint: NSLayoutConstraint?
    var imageViewTrailingConstraint: NSLayoutConstraint?

    convenience init(configuration: ALKConfiguration, image: UIImage) {
        self.init(configuration: configuration)
        self.image = image
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public required init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
    }

    func setupViews() {
        scrollView.delegate = self

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        singleTap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(tap:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        singleTap.require(toFail: doubleTap)

        closeButton.addTarget(self, action: #selector(dissmiss), for: .touchUpInside)

        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        imageView.image = image

        view.addViewsForAutolayout(views: [scrollView, closeButton])
        scrollView.addViewsForAutolayout(views: [imageView])

        view.bringSubviewToFront(closeButton)

        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 64).isActive = true

        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        imageViewTopConstraint?.isActive = true

        imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        imageViewBottomConstraint?.isActive = true

        imageViewLeadingConstraint = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        imageViewLeadingConstraint?.isActive = true

        imageViewTrailingConstraint = imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        imageViewTrailingConstraint?.isActive = true

        view.layoutIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMinZoomScaleForSize(size: view.bounds.size)
        updateConstraintsForSize(size: view.bounds.size)
    }

    @objc func doubleTapped(tap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: {
            let view = self.imageView

            let viewFrame = view.frame

            let location = tap.location(in: view)
            let viewWidth = viewFrame.size.width / 2.0
            let viewHeight = viewFrame.size.height / 2.0

            let rect = CGRect(x: location.x - (viewWidth / 2), y: location.y - (viewHeight / 2), width: viewWidth, height: viewHeight)

            if self.scrollView.minimumZoomScale == self.scrollView.zoomScale {
                self.scrollView.zoom(to: rect, animated: false)
            } else {
                self.updateMinZoomScaleForSize(size: self.view.bounds.size)
            }

        }, completion: nil)
    }

    @objc func singleTapped(tap _: UITapGestureRecognizer) {
        if scrollView.minimumZoomScale == scrollView.zoomScale {
            dissmiss()
        }
    }

    @objc func dissmiss() {
        dismiss(animated: true, completion: nil)
    }

    func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)

        updateConstraintsXY(xOffset: xOffset, yOffset: yOffset)
    }

    func updateConstraintsXY(xOffset: CGFloat, yOffset: CGFloat) {
        imageViewTopConstraint?.constant = yOffset
        imageViewBottomConstraint?.constant = yOffset

        imageViewLeadingConstraint?.constant = xOffset
        imageViewTrailingConstraint?.constant = xOffset
    }
}

extension ALKPreviewPhotoViewController: UIScrollViewDelegate {
    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_: UIScrollView) {
        updateConstraintsForSize(size: view.bounds.size)
        view.layoutIfNeeded()
    }
}
