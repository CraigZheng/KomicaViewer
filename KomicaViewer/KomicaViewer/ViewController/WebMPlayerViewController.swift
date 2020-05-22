//
//  WebMPlayerViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 2/11/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import MobileVLCKit

class WebMPlayerViewController: UIViewController {
    
    @objc var webMSourceURL: URL!

    @IBOutlet weak var playerView: UIView!
    private let mediaPlayer = VLCMediaPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.backgroundColor = .black
        mediaPlayer.delegate = self
        mediaPlayer.drawable = playerView
        mediaPlayer.media = VLCMedia(url: webMSourceURL)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mediaPlayer.play()
    }

    @IBAction func doneAction(_ sender: AnyObject) {
        mediaPlayer.pause()
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func playAction(_ sender: Any) {
        if mediaPlayer.isPlaying {
            mediaPlayer.pause()
        } else {
            mediaPlayer.play()
        }
    }
    
    @IBAction func safariAction(_ sender: AnyObject) {
        if webMSourceURL != nil {
            UIApplication.shared.openURL(webMSourceURL)
        }
    }

}

extension WebMPlayerViewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        print(aNotification)
        print("state: \(mediaPlayer.state), \(mediaPlayer.state.rawValue)")
    }
}
