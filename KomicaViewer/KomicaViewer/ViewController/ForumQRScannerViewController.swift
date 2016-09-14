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

extension ForumQRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBAction func loadFromLibraryAction(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = .PhotoLibrary
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func scanQRHelpBarButtonItemAction(sender: AnyObject) {
        if let scanForumQRHelpURL = Configuration.singleton.scanForumQRHelpURL
        where UIApplication.sharedApplication().canOpenURL(scanForumQRHelpURL)
        {
            UIApplication.sharedApplication().openURL(scanForumQRHelpURL)
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage,
            let ciImage = CIImage(image: pickedImage)
        {
            let parsedResult = performQRCodeDetection(ciImage)
            if let last = parsedResult.last {
                if !parseJsonString(last) {
                    ProgressHUD.showMessage("QR code cannot be parsed, please try again")
                }
            }
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate
extension ForumQRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if let lastMetadataObject = metadataObjects.last,
            let readableObject = lastMetadataObject as? AVMetadataMachineReadableCodeObject
        {
            if (readableObject.type == AVMetadataObjectTypeQRCode) {
                if parseJsonString(readableObject.stringValue) {
                    captureSession?.stopRunning()
                    return
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
    
    func parseJsonString(jsonString: String) -> Bool {
        // Construct a forum object with the scanned result.
        if let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
            let jsonDict = (try? NSJSONSerialization.JSONObjectWithData(jsonData,
                options: .AllowFragments)) as? [String: AnyObject]
            where !jsonString.isEmpty
        {
            capturedForum = KomicaForum(jsonDict: jsonDict)
            if ((capturedForum?.isReady()) != nil) {
                performSegueWithIdentifier(SegueIdentifier.addForum, sender: nil)
                return true
            }
        }
        return false
    }
    
}

// MARK: Read from library
extension ForumQRScannerViewController {
    // Shamelessly copied from http://stackoverflow.com/questions/35956538/how-to-read-qr-code-from-static-image and modified to my need.
    func performQRCodeDetection(image: CIImage) -> [String] {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0])
        let features = detector!.featuresInImage(image)
        var strings = [String]()
        features.forEach { feature in
            if let feature = feature as? CIQRCodeFeature {
                strings.append(feature.messageString!)
            }
        }
        return strings
    }
    
}
