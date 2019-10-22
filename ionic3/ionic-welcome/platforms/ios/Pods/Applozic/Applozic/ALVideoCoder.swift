//
//  ALVideoCoder.swift
//  Pods
//
//  Created by Sander on 9/29/18.
//

import Foundation
import Photos

private struct ProgressItem {
    var convertProgress: Progress
    var trimProgress: Progress
    var durationSeconds: TimeInterval
    var exportSession: AVAssetExportSession
}

protocol AssetSource {
    var durationSeconds: Int { get }
    func getAVAsset(_ handler: @escaping (AVAsset?) -> Void)
}

extension PHAsset: AssetSource {
    
    var durationSeconds: Int {
        return Int(duration)
    }
    
    func getAVAsset(_ handler: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .mediumQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: self, options: options) { (asset, audioMix, info) in
            DispatchQueue.main.async {
                handler(asset)
            }
        }
    }
}
extension AVAsset: AssetSource {
    
     var durationSeconds: Int {
        return Int(CMTimeGetSeconds(duration))
    }
    func getAVAsset(_ handler: @escaping (AVAsset?) -> Void) {
        handler(self)
    }
}

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}

@objc public class ALVideoCoder: NSObject {
    
    private let koef = 100.0
    // EXPORT PROGRESS VALUES
    private var exportingVideoSessions = [AVAssetWriter]()
    private var progressItems = [ProgressItem]()
    private var mainProgress: Progress?
    private var exportSessionMainProgress: Progress?
    private var alertVC: UIViewController?
    private var timer: Timer?
    
    @objc public func convert(phAssets: [PHAsset], range: CMTimeRange, baseVC: UIViewController, completion: @escaping ([String]?) -> Void) {
        convert(videoAssets: phAssets, range: range, baseVC: baseVC, completion: completion)
    }
    
    @objc public func convert(avAssets: [AVURLAsset], range: CMTimeRange, baseVC: UIViewController, completion: @escaping ([String]?) -> Void) {
        convert(videoAssets: avAssets, range: range, baseVC: baseVC, completion: completion)
    }
    
    private func convert(videoAssets: [AssetSource], range: CMTimeRange, baseVC: UIViewController, completion: @escaping ([String]?) -> Void) {
        
        let exportVideo = { [weak self] in
            self?.exportMultipleVideos(videoAssets, range: range, exportStarted: { [weak self] in
                self?.showProgressAlert(on: baseVC)
            }, completion: { [weak vc = baseVC] paths in
                
                if paths != nil {
                    // preventing crash for short video, with the controller that would attempt to dismiss while being presented
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
                        vc?.dismiss(animated: true)
                    }
                }
                completion(paths)
            })
        }
        
        if ALApplozicSettings.is5MinVideoLimitInGalleryEnabled(), videoAssets.first(where: { $0.durationSeconds > 300 }) != nil {
            
            let message = NSLocalizedString("videoWarning", value: "The video you’re attempting to send exceeds the 5 minutes limit. If you proceed, only 5 minutes of the video will be selected and the rest will be trimmed out.", comment: "")
            
            let alertView = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title:NSLocalizedString("okText", value: "OK", comment: ""), style: .default, handler: { _ in
                exportVideo()
            }))
            alertView.addAction(UIAlertAction(title: NSLocalizedString("cancelOptionText", value: "Cancel", comment: ""), style: .cancel, handler: { _ in
                completion(nil)
            }))
            baseVC.present(alertView, animated: true)
        } else {
            exportVideo()
        }
    }
}

// MARK: PRIVATE API
extension ALVideoCoder {
    
    private func showProgressAlert(on vc: UIViewController) {
        let alertView = UIAlertController(title: NSLocalizedString("optimizingText", value: "Optimizing...", comment: ""), message: " ", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title:  NSLocalizedString("cancelOptionText", value: "Cancel", comment: ""), style: .cancel, handler: { [weak self] _ in
            self?.exportingVideoSessions.forEach { $0.cancelWriting() }
            self?.progressItems.forEach { $0.exportSession.cancelExport() }
            DispatchQueue.main.asyncAfter(deadline:.now() + .milliseconds(400), execute: {
                self?.exportingVideoSessions.removeAll()
                self?.progressItems.removeAll()
                self?.timer?.invalidate()
            })
        }))
        var mainProgress: Progress?
            
        let totalDuration = progressItems.reduce(0) { $0 + $1.durationSeconds }
        mainProgress = Progress(totalUnitCount: Int64(totalDuration * koef))

        for item in progressItems {
            mainProgress?.addChild(item.convertProgress, withPendingUnitCount: Int64(item.durationSeconds*koef*0.85))
            mainProgress?.addChild(item.trimProgress, withPendingUnitCount: Int64(item.durationSeconds*koef*0.15))
        }
        self.mainProgress = mainProgress
        
        vc.present(alertView, animated: true, completion: {
            let margin: CGFloat = 8.0
            let rect = CGRect(x: margin, y: 62.0, width: alertView.view.frame.width - margin * 2.0, height: 2.0)
            let progressView = UIProgressView(frame: rect)
            progressView.observedProgress = mainProgress
            progressView.tintColor = UIColor.blue
            alertView.view.addSubview(progressView)
        })
    }
    
    private func exportMultipleVideos(_ assets: [AssetSource], range: CMTimeRange, exportStarted: @escaping () -> Void, completion: @escaping ([String]?) -> Void) {
        
        guard !assets.isEmpty else {
            completion([])
            return
        }
        
        let dispatchExportStartedGroup = DispatchGroup()
        let dispatchExportCompletedGroup = DispatchGroup()
        
        var videoPaths: [String] = []
        for video in assets {
            
            dispatchExportStartedGroup.enter()
            dispatchExportCompletedGroup.enter()
            exportVideoAsset(video, range: range, exportStarted: dispatchExportStartedGroup.leave(), completion: { path in
                if let videoPath = path {
                    videoPaths.append(videoPath)
                }
                dispatchExportCompletedGroup.leave()
            })
        }
        
        dispatchExportStartedGroup.notify(queue: .main, execute: exportStarted)
        dispatchExportCompletedGroup.notify(queue: .main) {
            completion(videoPaths.isEmpty ? nil : videoPaths)
        }
    }
    
    private func exportVideoAsset(_ asset: AssetSource, range: CMTimeRange, exportStarted: @autoclosure @escaping () -> Void, completion: @escaping (String?) -> Void) {
        
        asset.getAVAsset { [weak self] (inAsset) in
            guard let asset = inAsset, let strongSelf = self else {
                completion(nil)
                return
            }
            
            var currentDuration = CMTimeGetSeconds(asset.duration)
            let requestedDuration = CMTimeGetSeconds(range.duration)

            if currentDuration > requestedDuration {
                currentDuration = requestedDuration
            }
            
            let fileManager = FileManager.default
            let filename = String(format: "VIDTrim-%f.mp4", Date().timeIntervalSince1970*1000)
            let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let filePath = documentsUrl.absoluteString.appending(filename)
            
            let trimmedURL = URL(string: filePath)!
            
            // Remove existing file
            try? fileManager.removeItem(at: trimmedURL)
            
            let convertProgress = Progress(totalUnitCount: Int64(currentDuration * Double(strongSelf.koef)))
            let session = strongSelf.trimVideo(videoAsset: asset, range: range, atURL: trimmedURL) { trimmedAsset in
                
                guard let newAsset = trimmedAsset else {
                    completion(nil)
                    return
                }

                /// Converting video to low quality takes too much memory
                /// which gets worse when the video size is large.
                if let size = newAsset.fileSize, size >= (5 * 1024 * 1024) {
                    completion(trimmedURL.path)
                    return
                }
                
                let filename = String(format: "VID-%f.mp4", Date().timeIntervalSince1970*1000)
                let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let filePath = documentsUrl.absoluteString.appending(filename)

                guard var fileurl = URL(string: filePath) else {
                    completion(nil)
                    return
                }
                fileurl = fileurl.standardizedFileURL

                // remove any existing file at that location
                try? FileManager.default.removeItem(at: fileurl)

                ALVideoCoder.convertVideoToLowQuailtyWithInputURL(videoAsset: newAsset, outputURL: fileurl, progress: convertProgress, started: { writer in
                    self?.exportingVideoSessions.append(writer)
                }, completed: {
                    completion(fileurl.path)
                    try? fileManager.removeItem(at: trimmedURL)
                })
            }
            
            let trimProgress = Progress(totalUnitCount: Int64(currentDuration * Double(strongSelf.koef)))
            
            self?.progressItems.append(ProgressItem(convertProgress: convertProgress, trimProgress: trimProgress, durationSeconds: currentDuration, exportSession: session))
            
            exportStarted()
            if self?.timer == nil {
                self?.timer = Timer.scheduledTimer(timeInterval: 0.3, target: strongSelf, selector: #selector(strongSelf.update), userInfo: nil, repeats: true)
            }
        }
    }
    
    // video processing
    private func trimVideo(videoAsset: AVAsset, range: CMTimeRange, atURL:URL, completed: @escaping (AVURLAsset?) -> Void) -> AVAssetExportSession {
        
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputURL = atURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.timeRange = range
        exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        exportSession.exportAsynchronously {
            switch(exportSession.status) {
            case .completed:
                completed(AVURLAsset(url: atURL))
                self.timer?.invalidate()
            case .failed, .cancelled:
                completed(nil)
                self.timer?.invalidate()
            default: break
            }
        }
        return exportSession
    }
    
    @objc func update() {
        for item in progressItems {
            let trimProgress = Int64(Double(item.exportSession.progress) * koef * item.durationSeconds)
            item.trimProgress.completedUnitCount = trimProgress
        }
    }
    
    private class func convertVideoToLowQuailtyWithInputURL(videoAsset: AVURLAsset, outputURL: URL, progress: Progress, started: (AVAssetWriter) -> Void, completed: @escaping () -> Void) {
        
        //tracks
        let videoTrack = videoAsset.tracks(withMediaType: .video)[0]
        let audioTrack = videoAsset.tracks(withMediaType: .audio).first
        
        // video output settings
        let videoReaderSettings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        
        // audio output settings
        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        
        let outputSettings: [String : Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVChannelLayoutKey: NSData(bytes:&channelLayout, length:MemoryLayout.size(ofValue: channelLayout)),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        // video/audio asset outputs
        let videoAssetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        var audioAssetReaderOutput: AVAssetReaderTrackOutput?
        if let audio = audioTrack {
            audioAssetReaderOutput = AVAssetReaderTrackOutput(track: audio, outputSettings: outputSettings)
        }
        // setup asset readers
        let assetReader = try! AVAssetReader(asset: videoAsset)
        
        // add video/audio outputs to the readers
        if assetReader.canAdd(videoAssetReaderOutput) {
            assetReader.add(videoAssetReaderOutput)
        }
        if let audioOutput = audioAssetReaderOutput, assetReader.canAdd(audioOutput) {
            assetReader.add(audioOutput)
        }
        
        // video asset input settings
        let videoSize = videoTrack.naturalSize
        
        let widthIsBigger = max(videoSize.height, videoSize.width) == videoSize.width
        let ratio = (widthIsBigger ? videoSize.height : videoSize.width) / 480.0
        
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey : 815_000
        ]
        
        let videoWriterOutputSettings: [String : Any] = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoCompressionPropertiesKey : videoWriterCompressionSettings,
            AVVideoWidthKey : Int(videoSize.width/ratio),
            AVVideoHeightKey : Int(videoSize.height/ratio)
        ]
        
        // audio asset input settings
        let audioWriterOutputSettings: [String : Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                                         AVNumberOfChannelsKey: 2,
                                                         AVSampleRateKey: 44100.0,
                                                         AVEncoderBitRateKey: 64000]
        
        // audio/video writer inputs
        let videoAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterOutputSettings)
        videoAssetWriterInput.expectsMediaDataInRealTime = true
        videoAssetWriterInput.transform = videoTrack.preferredTransform
        let audioAssetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterOutputSettings)
        
        // asset writer
        let assetWriter = try! AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        assetWriter.shouldOptimizeForNetworkUse = true
        
        if assetWriter.canAdd(videoAssetWriterInput) {
            assetWriter.add(videoAssetWriterInput)
        }
        if assetWriter.canAdd(audioAssetWriterInput) {
            assetWriter.add(audioAssetWriterInput)
        }
        
        //start writing from video reader
        assetWriter.startWriting()
        assetReader.startReading()
        
        assetWriter.startSession(atSourceTime: .zero)
        
        let group = DispatchGroup()
        group.enter()
        
        // read/write video
        let processingQueue1 = DispatchQueue(label: "processingQueue1")
        videoAssetWriterInput.requestMediaDataWhenReady(on: processingQueue1) {
            while videoAssetWriterInput.isReadyForMoreMediaData {
                
                if let sampleBuffer = videoAssetReaderOutput.copyNextSampleBuffer() {
                    videoAssetWriterInput.append(sampleBuffer)
                    let timeStamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    progress.completedUnitCount = Int64(timeStamp*100)
                } else {
                    videoAssetWriterInput.markAsFinished()
                    group.leave()
                }
            }
        }
        
        group.enter()
        let processingQueue2 = DispatchQueue(label: "processingQueue2")
        
        // read/write audio
        audioAssetWriterInput.requestMediaDataWhenReady(on: processingQueue2) {
            while audioAssetWriterInput.isReadyForMoreMediaData {
                
                if let sampleBuffer = audioAssetReaderOutput?.copyNextSampleBuffer() {
                    audioAssetWriterInput.append(sampleBuffer)
                } else {
                    audioAssetWriterInput.markAsFinished()
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main, work: DispatchWorkItem {
            assetWriter.finishWriting {
                completed()
            }
            assetReader.cancelReading()
        })
        
        started(assetWriter)
    }
}
