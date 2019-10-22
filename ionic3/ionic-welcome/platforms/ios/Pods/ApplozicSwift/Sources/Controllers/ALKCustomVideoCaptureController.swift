//
//  CustomVideoCaptureController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 06/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

final class ALKCustomVideoViewController: ALKBaseViewController, Localizable {
    // delegate
    weak var customCamDelegate: ALKCustomCameraProtocol?
    var camera = ALKCameraType.back
    var videoFileOutput = AVCaptureMovieFileOutput()
    var filePath: URL?
    // photo library
    var asset: PHAsset!
    var allPhotos: PHFetchResult<PHAsset>!
    var selectedImage: UIImage!
    var cameraMode: ALKCameraPhotoType = .noCropOption
    let option = PHImageRequestOptions()

    @IBOutlet private var previewView: UIView!
    @IBOutlet private var btnCapture: UIButton!
    @IBOutlet private var btnSwitchCam: UIButton!

    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    // If we find a device we'll store it here for later use
    private var captureDevice: AVCaptureDevice?
    private var captureDeviceInput: AVCaptureDeviceInput?
    fileprivate var isUserControlEnable = true

    fileprivate lazy var localizedStringFileName: String = configuration.localizedStringFileName

    override func viewDidLoad() {
        super.viewDidLoad()

        title = localizedString(forKey: "Camera", withDefaultValue: SystemMessage.LabelName.Camera, fileName: localizedStringFileName)
        btnSwitchCam.isHidden = true
        reloadCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        let outputs = captureSession.outputs
        if let output = outputs.first {
            captureSession.removeOutput(output)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // ask for permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .denied:

            // ask for permissions
            let camNotAvailable = localizedString(forKey: "CamNotAvaiable", withDefaultValue: SystemMessage.Warning.CamNotAvaiable, fileName: localizedStringFileName)
            let pleaseAllowCamera = localizedString(forKey: "PleaseAllowCamera", withDefaultValue: SystemMessage.Camera.PleaseAllowCamera, fileName: localizedStringFileName)
            let alertController = UIAlertController(title: camNotAvailable, message: pleaseAllowCamera, preferredStyle: .alert)
            let settingsTitle = localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: localizedStringFileName)
            let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            alertController.addAction(settingsAction)
            let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)
            let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        default: ()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLayoutSubviews() {
        // set frame
        previewLayer?.frame = previewView.frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Set protocol and Observer

    func setCustomCamDelegate(camMode: ALKCameraPhotoType, camDelegate: ALKCustomCameraProtocol) {
        cameraMode = camMode
        customCamDelegate = camDelegate
    }

    // MARK: - UI control

    private func setupNavigation() {
        navigationController?.title = title
        navigationController?.navigationBar.setBackgroundImage(UIImage(color: .main, alpha: 0.6), for: .default)
        guard let navVC = self.navigationController else { return }
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
    }

    private func reloadCamera() {
        // stop previous capture session
        captureSession.stopRunning()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        previewLayer.removeFromSuperlayer()
        self.previewLayer?.removeFromSuperlayer()

        // Do any additional setup after loading the view.
        captureSession.sessionPreset = AVCaptureSession.Preset.high

        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices

        for device in devices {
            if camera == .back {
                if device.position == AVCaptureDevice.Position.back {
                    captureDevice = device
                    if captureDevice != nil {
                        checkCameraPermission()
                    }
                }
            } else {
                if device.position == AVCaptureDevice.Position.front {
                    captureDevice = device
                    if captureDevice != nil {
                        checkCameraPermission()
                    }
                }
            }
        }
    }

    private func checkCameraPermission() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
            btnSwitchCam.isHidden = false
            beginSession()
        case .denied:
            // ask for permissions
            let camNotAvailable = localizedString(forKey: "CamNotAvaiable", withDefaultValue: SystemMessage.Warning.CamNotAvaiable, fileName: localizedStringFileName)
            let pleaseAllowCamera = localizedString(forKey: "PleaseAllowCamera", withDefaultValue: SystemMessage.Camera.PleaseAllowCamera, fileName: localizedStringFileName)
            let alertController = UIAlertController(title: camNotAvailable, message: pleaseAllowCamera, preferredStyle: .alert)
            let settingsTitle = localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: localizedStringFileName)
            let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            alertController.addAction(settingsAction)
            let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)
            let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        case .notDetermined:
            // ask for permissions
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [weak self] isGrant in
                guard let weakSelf = self else { return }
                if isGrant {
                    DispatchQueue.main.async {
                        weakSelf.btnSwitchCam.isHidden = false
                    }
                }
            })
            beginSession()
        default: ()
        }
    }

    @IBAction private func actionCameraCapture(_: AnyObject) {
        saveToCamera()
    }

    private func beginSession() {
        do {
            try captureDeviceInput = AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(captureDeviceInput!)
        } catch {}

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        // orientation of video
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        var initialVideoOrientation = AVCaptureVideoOrientation.portrait
        if statusBarOrientation != UIInterfaceOrientation.unknown {
            initialVideoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue)!
        }

        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = initialVideoOrientation
        self.previewLayer = previewLayer
        // add camera view
        previewView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }

    private func saveToCamera() {
        if videoFileOutput.isRecording {
            videoFileOutput.stopRecording()
        } else {
            let recordingDelegate: AVCaptureFileOutputRecordingDelegate? = self

            captureSession.addOutput(videoFileOutput)

            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = String(format: "/VID-%f.mov", Date().timeIntervalSince1970)
            filePath = documentsURL.appendingPathComponent(fileName)

            // Do recording and save the output to the `filePath`
            videoFileOutput.startRecording(to: filePath!, recordingDelegate: recordingDelegate!)
        }
    }

    @IBAction private func switchCamPress(_: Any) {
        if isUserControlEnable {
            isUserControlEnable = false

            if camera == .back {
                camera = .front
            } else {
                camera = .back
            }

            let devices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            ).devices
            let newCamera: AVCaptureDevice?

            if camera == .front {
                newCamera = cameraWithPosition(position: AVCaptureDevice.Position.front, in: devices)
            } else {
                newCamera = cameraWithPosition(position: AVCaptureDevice.Position.back, in: devices)
            }
            guard let newCam = newCamera else { return }

            let currentCameraInput: AVCaptureInput = captureSession.inputs[0]
            captureSession.removeInput(currentCameraInput)

            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: newCam))
            } catch {
                print("Error while adding camera input: \(error)")
            }
            captureSession.commitConfiguration()

            enableCameraControl(inSec: 1)
        }
    }

    private func cameraWithPosition(position: AVCaptureDevice.Position, in devices: [AVCaptureDevice]) -> AVCaptureDevice? {
        for device in devices where (device as AnyObject).position == position {
            return device
        }
        return AVCaptureDevice(uniqueID: "")
    }

    @IBAction private func dismissCameraPress(_: Any) {
        navigationController?.dismiss(animated: false, completion: nil)
    }

    private func enableCameraControl(inSec: Double) {
        let disT: DispatchTime = DispatchTime.now() + inSec
        DispatchQueue.main.asyncAfter(deadline: disT) {
            self.isUserControlEnable = true
        }
    }

    // MARK: - Access to gallery images

    private func getAllImage(completion: (_ success: Bool) -> Void) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = false
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        (allPhotos != nil) ? completion(true) : completion(false)
    }

//    private func createScrollGallery(isGrant:Bool) {
//        if isGrant
//        {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//                self.previewGallery.reloadData()
//            })
//        }
//
//    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        var destination = segue.destination

        if let topViewController = (destination as? UINavigationController)?.topViewController {
            destination = topViewController
        }

        if let customCameraPreviewVC = destination as? ALKCustomVideoPreviewViewController {
            guard let url = filePath else { return }
            customCameraPreviewVC.setUpPath(path: url.path)
        }
    }
}

extension ALKCustomVideoViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_: AVCaptureFileOutput, didStartRecordingTo _: URL, from _: [AVCaptureConnection]) {}

    func fileOutput(_: AVCaptureFileOutput, didFinishRecordingTo _: URL, from _: [AVCaptureConnection], error _: Error?) {
        performSegue(withIdentifier: "pushToVideoPreviewViewController", sender: nil)
    }
}
