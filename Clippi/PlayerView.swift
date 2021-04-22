//
//  PlayerView.swift
//  Clippi
//
//  Created by Nidhi Kulkarni on 4/21/21.
//
import AVKit
class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
