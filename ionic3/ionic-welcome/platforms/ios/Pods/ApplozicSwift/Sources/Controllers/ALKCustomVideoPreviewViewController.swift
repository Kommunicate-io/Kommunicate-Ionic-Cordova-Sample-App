//
//  ALKCustomVideoPreviewViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 06/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit

final class ALKCustomVideoPreviewViewController: ALKBaseViewController, Localizable {
    // MARK: - Variables and Types

    weak var customCamDelegate: ALKCustomCameraProtocol?

    var path: String!

    @IBOutlet var playButton: UIButton!
    @IBOutlet var customVideoView: UIView!
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var imageView: UIImageView!

    @IBOutlet private var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    static func instance(with path: String) -> ALKCustomVideoPreviewViewController {
        let viewController: ALKCustomVideoPreviewViewController = UIStoryboard(storyboard: .video).instantiateViewController()
        viewController.path = path
        return viewController
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        title = localizedString(forKey: "SendVideo", withDefaultValue: SystemMessage.LabelName.SendVideo, fileName: configuration.localizedStringFileName)
    }

    public required init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
    }

    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }

    private func setupNavigation() {
        navigationItem.title = title

        navigationController?.navigationBar.setBackgroundImage(UIImage(color: .main, alpha: 0.6), for: .default)
        guard let navVC = self.navigationController else { return }
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
    }

    //    func setSelectedImage(pickImage:UIImage,camDelegate:ALKCustomCameraProtocol)
    //    {
    //        self.image = pickImage
    //        self.customCamDelegate = camDelegate
    //    }

    func setUpPath(path: String) {
        self.path = path
    }

    private func playVideo() {
        guard let path = path else {
            debugPrint("video.m4v not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        player.actionAtItemEnd = .none
        let videoLayer = AVPlayerLayer(player: player)
        videoLayer.frame = customVideoView.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        customVideoView.layer.addSublayer(videoLayer)
    }

    @IBAction private func sendPhotoPress(_: Any) {
//        self.navigationController?.dismiss(animated: false, completion: {
//            self.customCamDelegate.customCameraDidTakePicture(cropedImage:self.image
//            )
//        })
    }

    @IBAction private func close(_: Any) {
        _ = navigationController?.popViewController(animated: false)
    }

    @IBAction func playButtonAction(_: UIButton) {
        let playerController = AVPlayerViewController()
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        player.actionAtItemEnd = .pause
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
}
