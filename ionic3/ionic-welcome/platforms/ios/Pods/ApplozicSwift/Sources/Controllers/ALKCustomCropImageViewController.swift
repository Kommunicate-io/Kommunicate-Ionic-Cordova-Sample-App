//
//  CustomCropImageViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

final class ALKCustomCropImageViewController: ALKBaseViewController, Localizable {
    @IBOutlet var previewScroll: UIScrollView!

    weak var customCamDelegate: ALKCustomCameraProtocol?
    fileprivate lazy var localizedStringFileName: String = configuration.localizedStringFileName
    var imgview: UIImageView! = UIImageView()
    var imagepicked: UIImage!
    var imageCroped: UIImage!
    var minZoomScale: CGFloat!

    @IBOutlet var btnSave: UIButton!
    @IBOutlet var btnReset: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_: Bool) {
        // Do any additional setup after loading the view.
        previewScroll.delegate = self

        imgview.image = imagepicked
        imgview.frame = CGRect(x: 0, y: 0, width: imgview.image!.size.width, height: imgview.image!.size.height)

        previewScroll.addSubview(imgview)
        previewScroll.contentSize = imgview.image!.size

        previewScroll.contentMode = UIView.ContentMode.scaleAspectFit
        previewScroll.maximumZoomScale = 4.0
        previewScroll.minimumZoomScale = 1.0
        previewScroll.contentOffset.y = imgview.bounds.size.height / 2.0 - previewScroll.bounds.size.height / 2.0
        previewScroll.contentOffset.x = imgview.bounds.size.width / 2.0 - previewScroll.bounds.size.width / 2.0
        setZoomScale()
        setupGestureRecognizer()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Set Image

    func setupUI() {
        view.backgroundColor = UIColor.mainRed()

        title = localizedString(forKey: "CropImage", withDefaultValue: SystemMessage.LabelName.CropImage, fileName: localizedStringFileName)
        btnReset.setTitle(localizedString(forKey: "ResetPhotoButton", withDefaultValue: SystemMessage.ButtonName.ResetPhoto, fileName: localizedStringFileName), for: .normal)
        btnSave.setTitle(localizedString(forKey: "SelectButton", withDefaultValue: SystemMessage.ButtonName.Select, fileName: localizedStringFileName), for: .normal)

        btnSave.layer.cornerRadius = 15
        btnSave.clipsToBounds = true

        btnReset.layer.cornerRadius = 15
        btnReset.layer.borderWidth = 2
        btnReset.clipsToBounds = true

        previewScroll.delegate = self
        previewScroll.showsVerticalScrollIndicator = false
        previewScroll.showsHorizontalScrollIndicator = false

        setZoomScale()
        setupGestureRecognizer()
    }

    func setSelectedImage(pickImage: UIImage, camDelegate: ALKCustomCameraProtocol?) {
        imagepicked = pickImage
        customCamDelegate = camDelegate
    }

    @IBAction func cropImgPress(_: Any) {
        // get offset and zoom scale of scrollview
        let offset = previewScroll.contentOffset
        previewScroll.isUserInteractionEnabled = false
        // render new image
        UIGraphicsBeginImageContextWithOptions(previewScroll.bounds.size, true, UIScreen.main.scale)
        UIGraphicsGetCurrentContext()!.translateBy(x: -offset.x, y: -offset.y)
        previewScroll.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageCroped = UIGraphicsGetImageFromCurrentImageContext()
    }

    @IBAction func resetImgPress(_: Any) {
        let zoomedImageHeight = imgview.bounds.size.height / 2 * previewScroll.zoomScale
        let zoomedImageWidth = imgview.bounds.size.width / 2 * previewScroll.zoomScale
        previewScroll.contentOffset.y = zoomedImageHeight - previewScroll.bounds.size.height / 2.0
        previewScroll.contentOffset.x = zoomedImageWidth - previewScroll.bounds.size.width / 2.0
        previewScroll.setZoomScale(previewScroll.minimumZoomScale, animated: true)
        previewScroll.isUserInteractionEnabled = true
    }

    @IBAction func saveImgPress(_: Any) {
        if imageCroped == nil {
            cropImgPress(Any.self)
        }

        navigationController?.dismiss(animated: false, completion: {
            self.customCamDelegate?.customCameraDidTakePicture(cropedImage: self.imageCroped)
        })
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

extension ALKCustomCropImageViewController: UINavigationControllerDelegate, UIScrollViewDelegate {
    func setZoomScale() {
        let widthScale = previewScroll.frame.size.width / imgview.bounds.width
        let heightScale = previewScroll.frame.size.height / imgview.bounds.height

        let greaterScale = max(widthScale, heightScale)
        previewScroll.minimumZoomScale = greaterScale
        previewScroll.zoomScale = greaterScale
    }

    func viewForZoomingInScrollView(scrollView _: UIScrollView) -> UIView? {
        return imgview
    }

    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imgview
    }

    func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        previewScroll.addGestureRecognizer(doubleTap)
    }

    func scrollViewDidZoom(_: UIScrollView) {
        let imageViewSize = imgview.frame.size
        let scrollViewSize = previewScroll.bounds.size

        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        previewScroll.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }

    @objc func handleDoubleTap(recognizer _: UITapGestureRecognizer) {
        if previewScroll.zoomScale > previewScroll.minimumZoomScale {
            previewScroll.setZoomScale(previewScroll.minimumZoomScale, animated: true)
        } else {
            previewScroll.setZoomScale(previewScroll.maximumZoomScale, animated: true)
        }
    }
}
