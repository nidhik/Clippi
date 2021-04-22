//
//  ViewController.swift
//  PryntTrimmerView
//
//  Created by Henry on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//
import UIKit
import AVFoundation
import PryntTrimmerView
import PhotosUI

/// A view controller to demonstrate the trimming of a video. Make sure the scene is selected as the initial
// view controller in the storyboard
class CreateClipViewController: UIViewController {

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!

    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    let sourceAssetId = "U4RQ8cgj8zeL00VsacQe7lLCEyYkXIPHn1AMEWSdT6bo"
    var clipAssetId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        trimmerView.handleColor = UIColor.orange
        trimmerView.mainColor = UIColor.purple
        trimmerView.minDuration = 5.0
        loadAsset()
    }

    @IBAction func didPressCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressShare(_ sender: Any) {
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let assetId = self.clipAssetId else {
            return
        }
        NSLog("Trim from \(CMTimeGetSeconds(startTime)) to \(CMTimeGetSeconds(endTime))")
        
        DispatchQueue.global(qos: .background).async {
            if let url = (self.trimmerView.asset as? AVURLAsset)?.url,
                let urlData = NSData(contentsOf: url) {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                let filePath="\(documentsPath)/tempFile.mp4"
                let trimmedFilePath="\(documentsPath)/myclip.mp4"
                DispatchQueue.main.async {
                    urlData.write(toFile: filePath, atomically: true)
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                    }) { completed, error in
                        if completed {
                            print("Video is saved!")
                            VideoTrimmer().trimVideo(sourceURL: URL(fileURLWithPath: filePath), destinationURL: URL(fileURLWithPath: trimmedFilePath), trimPoints: [(startTime, endTime)]) { (result) in
                                switch result {
                                    case .success(let url):
                                        DispatchQueue.main.async {
                                            let items = [url]
                                            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                                            self.present(ac, animated: true)
                                        }
                                    case .failure(let error):
                                        print(error.localizedDescription)
                                    }
                            }
                            
                        }
                    }
                }
            }
        }
        
        
//        APIClient().clip(assetId: assetId, startTime: Float(CMTimeGetSeconds(startTime)), endTime:  Float(CMTimeGetSeconds(endTime))) { (successResponse) in
//            NSLog("SHAREME: https://stream.mux.com/\(successResponse.data.playbackId).m3u8")
//            let mp4 = "https://stream.mux.com/\(successResponse.data.playbackId)/low.mp4"
//
//
//
//        } onFailure: { (errorReponse, error) in
//            NSLog("Failed to trim clip \(error)")
//        }
    }
    
    func play() {

        guard let player = player else { return }

        if !self.isPlaying() {
            player.play()
            startPlaybackTimeChecker()
        } else {
            player.pause()
            stopPlaybackTimeChecker()
        }
    }
    
    func isPlaying() -> Bool {
        return self.player?.rate != 0 && self.player?.error == nil
    }

    func loadAsset() {
        APIClient().clip(assetId: sourceAssetId, startTime: nil, endTime: nil) { [self] (successResponse) in
            NSLog("Download: https://stream.mux.com/\(successResponse.data.playbackId)/low.mp4")
            self.clipAssetId = successResponse.data.assetId
            let mp4 = "https://stream.mux.com/\(successResponse.data.playbackId)/low.mp4"
            let asset = AVAsset(url: URL(string: mp4)!)
            self.trimmerView.asset = asset
            self.trimmerView.delegate = self
            self.addVideoPlayer(with: asset, playerView: self.playerView)
            
        } onFailure: { (errorReponse, error) in
            NSLog("Failed to make 30 clip \(error)")
        }

        
    }

    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        NotificationCenter.default.addObserver(self, selector: #selector(CreateClipViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
        play()
    }

    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
        }
    }

    func startPlaybackTimeChecker() {

        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(CreateClipViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }

    func stopPlaybackTimeChecker() {

        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }

    @objc func onPlaybackTimeChecker() {

        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }

        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)

        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

extension CreateClipViewController: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}
