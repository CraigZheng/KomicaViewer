//
//  ShowForumQRCodeViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 11/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

class ShowForumQRCodeViewController: UIViewController {
    @IBOutlet weak var qrImageView: UIImageView!
    @objc var forum: KomicaForum?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let forum = forum,
            let jsonString = forum.jsonEncode(),
            let jsonData = jsonString.data(using: String.Encoding.utf8), !jsonString.isEmpty
        {
            title = forum.name
            qrImageView.image = qrForData(jsonData)
        }
    }

    // Copied from http://stackoverflow.com/questions/12051118/is-there-a-way-to-generate-qr-code-image-on-ios and mofieid.
    fileprivate func qrForData(_ data: Data) -> UIImage? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        if let rawOutput = filter?.outputImage {
            let outputImage = rawOutput.transformed(by: CGAffineTransform(scaleX: 10.0, y: 10.0))
            return UIImage(ciImage: outputImage)
        } else {
            return nil
        }
    }
    
}
