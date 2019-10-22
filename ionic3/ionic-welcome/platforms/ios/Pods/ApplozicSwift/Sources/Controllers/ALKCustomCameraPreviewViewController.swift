//
//  ALKCustomCameraPreviewViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

// swiftlint:disable:next type_name
final class ALKCustomCameraPreviewViewController: ALKBaseViewController, Localizable {
    // MARK: - Variables and Types

    weak var customCamDelegate: ALKCustomCameraProtocol?
    var image: UIImage!

    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var imageView: UIImageView!

    @IBOutlet private var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    static func instance(with image: UIImage) -> ALKCustomCameraPreviewViewController {
        let viewController: ALKCustomCameraPreviewViewController = UIStoryboard(storyboard: .camera).instantiateViewController()
        viewController.image = image

        return viewController
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
    }

    override func loadView() {
        super.loadView()
        validateEnvironment()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContent()
        title = localizedString(forKey: "SendPhoto", withDefaultValue: SystemMessage.LabelName.SendPhoto, fileName: configuration.localizedStringFileName)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        updateMinZoomScaleForSize(size: view.bounds.size)
        updateConstraintsForSize(size: view.bounds.size)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Method of class

    private func validateEnvironment() {
        guard image != nil else {
            fatalError("Please use instance(_:) or set image")
        }
    }

    private func setupContent() {
        imageView.image = image
        imageView.sizeToFit()

        scrollView.delegate = self

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(tap:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    private func setupNavigation() {
        navigationItem.title = title

        navigationController?.navigationBar.backgroundColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.black
        guard let navVC = self.navigationController else { return }
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
    }

    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    private func updateConstraintsXY(xOffset: CGFloat, yOffset: CGFloat) {
        imageViewTopConstraint?.constant = yOffset
        imageViewBottomConstraint?.constant = yOffset

        imageViewLeadingConstraint?.constant = xOffset
        imageViewTrailingConstraint?.constant = xOffset
    }

    fileprivate func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)

        updateConstraintsXY(xOffset: xOffset, yOffset: yOffset)
    }

    @objc private func doubleTapped(tap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: { [weak self, weak imageView] in
            guard let self = self else { return }
            guard let imageView = imageView else { return }

            let view = imageView

            let viewFrame = view.frame

            let location = tap.location(in: view)
            let viewWidth = viewFrame.size.width / 2.0
            let viewHeight = viewFrame.size.height / 2.0

            let rect = CGRect(
                x: location.x - (viewWidth / 2),
                y: location.y - (viewHeight / 2),
                width: viewWidth,
                height: viewHeight
            )

            if self.scrollView.minimumZoomScale == self.scrollView.zoomScale {
                self.scrollView.zoom(to: rect, animated: false)
            } else {
                self.updateMinZoomScaleForSize(size: self.view.bounds.size)
            }

        }, completion: nil)
    }

    func setSelectedImage(pickImage: UIImage, camDelegate: ALKCustomCameraProtocol?) {
        image = pickImage
        customCamDelegate = camDelegate
    }

    @IBAction private func sendPhotoPress(_: Any) {
        navigationController?.dismiss(animated: false, completion: {
            self.customCamDelegate?.customCameraDidTakePicture(cropedImage: self.image)
        })
    }

    @IBAction private func close(_: Any) {
        _ = navigationController?.popViewController(animated: false)
    }
}

extension ALKCustomCameraPreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_: UIScrollView) {
        updateConstraintsForSize(size: view.bounds.size)
        view.layoutIfNeeded()
    }
}
