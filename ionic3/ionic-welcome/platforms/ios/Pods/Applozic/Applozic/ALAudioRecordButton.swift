//
//  AudioRecordButton.swift
//  Applozic
//
//  Created by Shivam Pokhriyal on 12/10/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

import Foundation

@objc public protocol ALAudioRecorderProtocol: class {
    func moveButton(location: CGPoint)
    func finishRecordingAudioWith(filePath: String)
    func startAudioRecord()
    func cancelAudioRecord()
    func permissionNotGranted()
}

@objc public class ALAudioRecordButton: UIButton{
    
    public enum ALKSoundRecorderState{
        case Recording
        case None
    }
    
    public var states : ALKSoundRecorderState = .None {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    private var delegate: ALAudioRecorderProtocol!
    
    //aduio session
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    fileprivate var audioFilename:URL!
    private var audioPlayer: AVAudioPlayer?
    
    let recordButton: UIButton = UIButton(type: .custom)
    
    @objc public func setAudioRecDelegate(recorderDelegate:ALAudioRecorderProtocol) {
        delegate = recorderDelegate
    }
    
    func setupRecordButton(){
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recordButton)
        
        self.addConstraints([NSLayoutConstraint(item: recordButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)])
        
        self.addConstraints([NSLayoutConstraint(item: recordButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0)])
        
        self.addConstraints([NSLayoutConstraint(item: recordButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0)])
        
        self.addConstraints([NSLayoutConstraint(item: recordButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)])
        
        var image = UIImage.init(named: "mic_icon", in: Bundle(for: ALChatViewController.self), compatibleWith: nil)
        if #available(iOS 9.0, *) {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
        } else {
            // Fallback on earlier versions
        }
        
        recordButton.setImage(image, for: .normal)
        recordButton.setImage(image, for: .highlighted)
        recordButton.backgroundColor = ALApplozicSettings.getColorForNavigation()
        recordButton.layer.cornerRadius = 20
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(userDidTapRecord(_:)))
        longPress.cancelsTouchesInView = false
        longPress.allowableMovement = 10
        longPress.minimumPressDuration = 0.2
        recordButton.addGestureRecognizer(longPress)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        setupRecordButton()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var intrinsicContentSize: CGSize {
        if state == .none {
            return recordButton.intrinsicContentSize
        } else {
            return CGSize(width: recordButton.intrinsicContentSize.width * 3, height: recordButton.intrinsicContentSize.height)
        }
    }
    
    //MARK: - Function
    private func checkMicrophonePermission() -> Bool {
        
        let soundSession = AVAudioSession.sharedInstance()
        let permissionStatus = soundSession.recordPermission
        var isAllow = false
        
        switch (permissionStatus) {
        case AVAudioSession.RecordPermission.undetermined:
            soundSession.requestRecordPermission({ (isGrant) in
                if (isGrant) {
                    isAllow = true
                }
                else {
                    isAllow = false
                }
            })
            break
        case AVAudioSession.RecordPermission.denied:
            // direct to settings...
            isAllow = false
            break;
        case AVAudioSession.RecordPermission.granted:
            // mic access ok...
            isAllow = true
            break;
        }
        
        return isAllow
    }
    
    @objc fileprivate func startAudioRecord()
    {
        // Getting audio session from objective-c as setCategory is unavailable in swift
        recordingSession = ALAudioSession().getWithPlayback(false)
        audioFilename = URL(fileURLWithPath: NSTemporaryDirectory().appending("tempRecording.m4a"))
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        do {
            try recordingSession.overrideOutputAudioPort(.speaker)
            try recordingSession.setActive(true)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            states = .Recording
        } catch {
            stopAudioRecord()
        }
    }
    
    @objc public func cancelAudioRecord() {
        if states == .Recording{
            audioRecorder.stop()
            audioRecorder = nil
            states = .None
        }
    }
    
    @objc fileprivate func stopAudioRecord()
    {
        if states == .Recording{
            audioRecorder.stop()
            audioRecorder = nil
            states = .None
            //play back?
            if audioFilename.isFileURL
            {
                guard let soundData = NSData(contentsOf: audioFilename) else {return}
                let fileName = String(format: "AUD-%f.m4a", Date().timeIntervalSince1970*1000)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fullPath = documentsURL.appendingPathComponent(fileName)
                do {
                    try soundData.write(to: fullPath, options: .atomic)
                } catch {
                    NSLog("error when saving the voice message")
                    delegate.cancelAudioRecord()
                    return
                }
                delegate.finishRecordingAudioWith(filePath: fileName)
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
                if delegate != nil {
                    delegate.permissionNotGranted()
                }
            } else {
                if delegate != nil {
                    delegate.startAudioRecord()
                }
                startAudioRecord()
            }
            
        case .changed:
            if location.y < -10 || location.y > height+10{
                if states == .Recording {
                    delegate.cancelAudioRecord()
                    cancelAudioRecord()
                }
            }
            delegate.moveButton(location: location)
            
        case .ended:
            if state == .none {
                return
            }
            stopAudioRecord()
            
        case .failed, .possible ,.cancelled :
            if states == .Recording {
                stopAudioRecord()
            } else {
                delegate.cancelAudioRecord()
                cancelAudioRecord()
            }
        }
    }
}

extension ALAudioRecordButton: AVAudioRecorderDelegate
{
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopAudioRecord()
        }
    }
}

