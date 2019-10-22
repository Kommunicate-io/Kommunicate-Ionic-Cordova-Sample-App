//
//  AudioRecordButton.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 17/08/18.
//

import Applozic
import Foundation

public protocol ALKAudioRecorderProtocol: AnyObject {
    func moveButton(location: CGPoint)
    func finishRecordingAudio(soundData: NSData)
    func startRecordingAudio()
    func cancelRecordingAudio()
    func permissionNotGrant()
}

open class AudioRecordButton: UIButton {
    public enum ALKSoundRecorderState {
        case recording
        case none
    }

    public var states: ALKSoundRecorderState = .none {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    weak var delegate: ALKAudioRecorderProtocol?

    // aduio session
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    fileprivate var audioFilename: URL!
    private var audioPlayer: AVAudioPlayer?

    let recordButton: UIButton = UIButton(type: .custom)

    func setAudioRecDelegate(recorderDelegate: ALKAudioRecorderProtocol?) {
        delegate = recorderDelegate
    }

    func setupRecordButton() {
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recordButton)

        addConstraints([NSLayoutConstraint(item: recordButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)])

        addConstraints([NSLayoutConstraint(item: recordButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0)])

        addConstraints([NSLayoutConstraint(item: recordButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0)])

        addConstraints([NSLayoutConstraint(item: recordButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)])

        var image = UIImage(named: "microphone", in: Bundle.applozic, compatibleWith: nil)

        if #available(iOS 9.0, *) {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
        } else {
            // Fallback on earlier versions
        }

        recordButton.setImage(image, for: .normal)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(userDidTapRecord(_:)))
        longPress.cancelsTouchesInView = false
        longPress.allowableMovement = 10
        longPress.minimumPressDuration = 0.2
        recordButton.addGestureRecognizer(longPress)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupRecordButton()
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var intrinsicContentSize: CGSize {
        if state == .none {
            return recordButton.intrinsicContentSize
        } else {
            return CGSize(width: recordButton.intrinsicContentSize.width * 3, height: recordButton.intrinsicContentSize.height)
        }
    }

    // MARK: - Function

    private func checkMicrophonePermission() -> Bool {
        let soundSession = AVAudioSession.sharedInstance()
        let permissionStatus = soundSession.recordPermission
        var isAllow = false

        switch permissionStatus {
        case AVAudioSession.RecordPermission.undetermined:
            soundSession.requestRecordPermission { isGrant in
                if isGrant {
                    isAllow = true
                } else {
                    isAllow = false
                }
            }
        case AVAudioSession.RecordPermission.denied:
            // direct to settings...
            isAllow = false
        case AVAudioSession.RecordPermission.granted:
            // mic access ok...
            isAllow = true
        }

        return isAllow
    }

    @objc fileprivate func startAudioRecord() {
        recordingSession = AVAudioSession.sharedInstance()
        audioFilename = URL(fileURLWithPath: NSTemporaryDirectory().appending("tempRecording.m4a"))
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        do {
            if #available(iOS 10.0, *) {
                try recordingSession.setCategory(.playAndRecord, mode: .default)
            } else {
                // Fallback on earlier versions
                recordingSession = ALAudioSession().getWithPlayback(false)
            }
            try recordingSession.overrideOutputAudioPort(.speaker)
            try recordingSession.setActive(true)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            states = .recording
        } catch {
            stopAudioRecord()
        }
    }

    @objc func cancelAudioRecord() {
        if states == .recording {
            audioRecorder.stop()
            audioRecorder = nil
            states = .none
        }
    }

    @objc fileprivate func stopAudioRecord() {
        if states == .recording {
            audioRecorder.stop()
            audioRecorder = nil
            states = .none
            // play back?
            if audioFilename.isFileURL {
                guard let soundData = NSData(contentsOf: audioFilename) else { return }
                delegate?.finishRecordingAudio(soundData: soundData)
            }
        }
    }

    @objc func userDidTapRecord(_ gesture: UIGestureRecognizer) {
        let button = gesture.view as! UIButton
        let location = gesture.location(in: button)
        let height = button.frame.size.height

        switch gesture.state {
        case .began:
            if checkMicrophonePermission() == false {
                delegate?.permissionNotGrant()
            } else {
                startAudioRecord()
                delegate?.startRecordingAudio()
            }

        case .changed:
            if location.y < -10 || location.y > height + 10 {
                if states == .recording {
                    delegate?.cancelRecordingAudio()
                    cancelAudioRecord()
                }
            }
            delegate?.moveButton(location: location)

        case .ended:
            if state == .none {
                return
            }
            stopAudioRecord()

        case .failed, .possible, .cancelled:
            if states == .recording {
                stopAudioRecord()
            } else {
                delegate?.cancelRecordingAudio()
                cancelAudioRecord()
            }
        }
    }
}

extension AudioRecordButton: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopAudioRecord()
        }
    }
}
