//
//  WebMPlayerViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 2/11/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import OGVKit

class WebMPlayerViewController: UIViewController {
    
    @objc var webMSourceURL: URL!

    @IBOutlet weak var playerView: OGVPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.delegate = self
        playerView.sourceURL = webMSourceURL
        playerView.play()
    }

    @IBAction func doneAction(_ sender: AnyObject) {
        playerView.pause()
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func safariAction(_ sender: AnyObject) {
        if webMSourceURL != nil {
            UIApplication.shared.openURL(webMSourceURL)
        }
    }
    
}

extension WebMPlayerViewController: OGVPlayerDelegate {
    
}
