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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://stream.mux.com/rs2F5rY9QEKIAWyskqcNlwyQnB6i9ShDEQ7GDURpErw.m3u8")
        playerView.player = AVPlayer(url: url!)
        playerView.player?.play()
    }
    
    
    
    func displayAVPlayerController(url: URL) {
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: url)
        self.addChild(vc)
        vc.view.frame = self.view.bounds
        self.playerView.insertSubview(vc.view, at: 0)
        vc.didMove(toParent: self)
    }


    @IBAction func didPressClip(_ sender: Any) {
        NSLog("Clip me! playback id: dcfVtiuE9sBugLRfHe88fTkjWMVT5sa5PQ55LOmgcv4")
    }
}

