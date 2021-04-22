//
//  ViewController.swift
//  Clippi
//
//  Created by Nidhi Kulkarni on 4/21/21.
//

import UIKit
import AVKit

class ViewController: AVPlayerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://stream.mux.com/rs2F5rY9QEKIAWyskqcNlwyQnB6i9ShDEQ7GDURpErw.m3u8")
            player = AVPlayer(url: url!)
            player!.play()
    }


}

