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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = AVPlayer(url: url)
        playerView.player?.play()
    }
    
    
    @IBAction func didPressClip(_ sender: Any) {
       
    }
}

