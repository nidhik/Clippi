//
//  ViewController.swift
//  Clippi
//
//  Created by Nidhi Kulkarni on 4/21/21.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var playerView: PlayerView!
    
    // hardcoded stream details
    let url = URL(string: "https://stream.mux.com/rs2F5rY9QEKIAWyskqcNlwyQnB6i9ShDEQ7GDURpErw.m3u8")!
    let sourceAssetId = "uJ01RH02xUZOEIhifYQl01NpDStYE2ow01F200LiA83E2hLI"
    let sourcePlaybackId = "sm5tO01IBu8zx57KM3m2QYiEkHUb46j00Xf8c7QpQ4U8A"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = AVPlayer(url: url)
        playerView.player?.play()
    }
    
    
    

    @IBAction func didPressClip(_ sender: Any) {
        APIClient().clip(playbackId: sourcePlaybackId)
    }
}

