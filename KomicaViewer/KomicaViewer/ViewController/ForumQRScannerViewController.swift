//
//  ForumQRScannerViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 11/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import AVFoundation

class ForumQRScannerViewController: UIViewController {
    
    var captureSession: AVCaptureSession?
    @IBOutlet var cameraPreviewView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Request camera permission.
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted) in
            dispatch_async(dispatch_get_main_queue(), {
                if (granted) {
                    // Permission has been granted. Use dispatch_async for any UI updating
                    // code because this block may be executed in a thread.
                    self.setUpScanner()
                } else {
                    // No permission, inform user about the permission issue, or quit.
                    let alertController = UIAlertController(title: "\(UIApplication.appName) Would Like To Use Your Camera", message: nil, preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in
                        // Dismiss self.
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }))
                    alertController.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
                        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                        if let url = settingsUrl {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            })
        })
    }

    private func setUpScanner() {
        captureSession?.stopRunning()
        captureSession = AVCaptureSession()
        let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if let videoInput = try? AVCaptureDeviceInput(device:videoCaptureDevice),
            let captureSession = captureSession
        {
            captureSession.addInput(videoInput)
            let metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue:dispatch_get_main_queue())
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code]
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = self.cameraPreviewView.bounds; // Align to cameraPreviewView.
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            cameraPreviewView.layer.addSublayer(previewLayer)
            captureSession.startRunning()
        }
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate
extension ForumQRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if let lastMetadataObject = metadataObjects.last,
            let readableObject = lastMetadataObject as? AVMetadataMachineReadableCodeObject
        {
            if (readableObject.type == AVMetadataObjectTypeQRCode) {
                captureSession?.stopRunning()
                // Construct a forum object with the scanned result.
            }
        }
    }
    
}
