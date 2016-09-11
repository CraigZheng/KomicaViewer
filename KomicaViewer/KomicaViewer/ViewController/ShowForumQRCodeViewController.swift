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
    var forum: KomicaForum?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let forum = forum,
            let jsonString = forum.jsonEncode(),
            let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)
            where !jsonString.isEmpty
        {
            title = forum.name
            qrImageView.image = qrForData(jsonData)
        }
    }

    // Copied from http://stackoverflow.com/questions/12051118/is-there-a-way-to-generate-qr-code-image-on-ios and mofieid.
    private func qrForData(data: NSData) -> UIImage? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        if let rawOutput = filter?.outputImage {
            let outputImage = rawOutput.imageByApplyingTransform(CGAffineTransformMakeScale(5.0, 5.0))
            return UIImage(CIImage: outputImage)
        } else {
            return nil
        }
    }
    
}
