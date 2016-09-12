//
//  ForumQRScannerViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 11/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import AVFoundation
import KomicaEngine

class ForumQRScannerViewController: UIViewController {
    
    @IBOutlet var cameraPreviewView: UIView!
    var capturedForum: KomicaForum?
    private var captureSession: AVCaptureSession?
    private var warningAlertController: UIAlertController?
    
    private struct SegueIdentifier {
        static let addForum = "addForum"
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
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

// MARK: Navigation
extension ForumQRScannerViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.addForum, let destinationViewController = segue.destinationViewController as? AddForumTableViewController {
            // Passing nil to the destination would cause the app to crash, so if capturedForum is nil, pass a new komica forum object to it.
            destinationViewController.newForum = capturedForum ?? KomicaForum()
        }
    }
    
}

// MARK: UI actions.

extension ForumQRScannerViewController {
    
    @IBAction func loadFromLibraryAction(sender: AnyObject) {
        
    }
    
    @IBAction func scanQRHelpBarButtonItemAction(sender: AnyObject) {
        
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate
extension ForumQRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if let lastMetadataObject = metadataObjects.last,
            let readableObject = lastMetadataObject as? AVMetadataMachineReadableCodeObject
        {
            if (readableObject.type == AVMetadataObjectTypeQRCode) {
                // Construct a forum object with the scanned result.
                if let jsonData = readableObject.stringValue.dataUsingEncoding(NSUTF8StringEncoding),
                    let jsonDict = (try? NSJSONSerialization.JSONObjectWithData(jsonData,
                                                                               options: .AllowFragments)) as? [String: AnyObject]
                {
                    capturedForum = KomicaForum(jsonDict: jsonDict)
                    if ((capturedForum?.isReady()) != nil) {
                        performSegueWithIdentifier(SegueIdentifier.addForum, sender: nil)
                        return
                    }
                }
            }
        }
        if warningAlertController == nil {
            // Cannot parse.
            warningAlertController = UIAlertController(title: "QR code cannot be parsed, please try again", message: nil, preferredStyle: .Alert)
            warningAlertController?.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (_) in
                self.warningAlertController = nil
            }))
            presentViewController(warningAlertController!, animated: true, completion: nil)
        }
    }
    
}

// MARK: Read from library
extension ForumQRScannerViewController {
    // Shamelessly copied from http://stackoverflow.com/questions/35956538/how-to-read-qr-code-from-static-image
    func performQRCodeDetection(image: CIImage) -> (outImage: CIImage?, decode: String) {
        var resultImage: CIImage?
        var decode = ""
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0])
        let features = detector.featuresInImage(image)
        for feature in features as! [CIQRCodeFeature] {
            resultImage = drawHighlightOverlayForPoints(image,
                                                        topLeft: feature.topLeft,
                                                        topRight: feature.topRight,
                                                        bottomLeft: feature.bottomLeft,
                                                        bottomRight: feature.bottomRight)
            decode = feature.messageString
        }
        return (resultImage, decode)
    }
    
    func drawHighlightOverlayForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint,
                                       bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
        overlay = overlay.imageByCroppingToRect(image.extent)
        overlay = overlay.imageByApplyingFilter("CIPerspectiveTransformWithExtent",
                                                withInputParameters: [
                                                    "inputExtent": CIVector(CGRect: image.extent),
                                                    "inputTopLeft": CIVector(CGPoint: topLeft),
                                                    "inputTopRight": CIVector(CGPoint: topRight),
                                                    "inputBottomLeft": CIVector(CGPoint: bottomLeft),
                                                    "inputBottomRight": CIVector(CGPoint: bottomRight)
            ])
        return overlay.imageByCompositingOverImage(image)
    }
}
