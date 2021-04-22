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
    var url = URL(string: "https://stream.mux.com/rs2F5rY9QEKIAWyskqcNlwyQnB6i9ShDEQ7GDURpErw.m3u8")!
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = AVPlayer(url: url)
        playerView.player?.play()
    }
    

    @IBAction func didPressClip(_ sender: Any) {
        
        
        APIClipRequest(playbackId: "sm5tO01IBu8zx57KM3m2QYiEkHUb46j00Xf8c7QpQ4U8A", startTime: 1.0, endTime: 10.0)
            .dispatch(
                onSuccess: { (successResponse) in
                    NSLog("\(successResponse.id)")
            },
                onFailure: { (errorResponse, error) in
                 NSLog("Error making clip \(error)")
            })
    }
}

