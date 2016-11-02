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
    
    var webMSourceURL: NSURL!

    @IBOutlet weak var playerView: OGVPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        playerView.delegate = self
        playerView.sourceURL = webMSourceURL
        playerView.play()
    }

    @IBAction func doneAction(sender: AnyObject) {
        playerView.pause()
        navigationController?.popViewControllerAnimated(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func safariAction(sender: AnyObject) {
        if webMSourceURL != nil {
            UIApplication.sharedApplication().openURL(webMSourceURL)
        }
    }
    
}

extension WebMPlayerViewController: OGVPlayerDelegate {
    
}
