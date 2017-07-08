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
import Firebase

class ForumQRScannerViewController: UIViewController {
    
    @IBOutlet var cameraPreviewView: UIView!
    var capturedForum: KomicaForum?
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var warningAlertController: UIAlertController?
    
    fileprivate struct SegueIdentifier {
        static let addForum = "addForum"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Request camera permission.
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
            DispatchQueue.main.async(execute: {
                if (granted) {
                    // Permission has been granted. Use dispatch_async for any UI updating
                    // code because this block may be executed in a thread.
                    self.setUpScanner()
                } else {
                    // No permission, inform user about the permission issue, or quit.
                    let alertController = UIAlertController(title: "\(UIApplication.appName) Would Like To Use Your Camera", message: nil, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
                        // Dismiss self.
                        _ = self?.navigationController?.popToRootViewController(animated: true)
                    }))
                    alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                        let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
                        if let url = settingsUrl {
                            UIApplication.shared.openURL(url)
                        }
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            })
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    fileprivate func setUpScanner() {
        captureSession?.stopRunning()
        captureSession = AVCaptureSession()
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if let videoInput = try? AVCaptureDeviceInput(device:videoCaptureDevice),
            let captureSession = captureSession
        {
            captureSession.addInput(videoInput)
            let metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue:DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code]
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = self.cameraPreviewView.bounds; // Align to cameraPreviewView.
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill;
            cameraPreviewView.layer.addSublayer(previewLayer!)
            captureSession.startRunning()
        }
    }
}

// MARK: Navigation
extension ForumQRScannerViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.addForum, let destinationViewController = segue.destination as? AddForumTableViewController {
            // Passing nil to the destination would cause the app to crash, so if capturedForum is nil, pass a new komica forum object to it.
            destinationViewController.newForum = capturedForum ?? KomicaForum()
        }
    }
    
}

// MARK: UI actions.

extension ForumQRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBAction func loadFromLibraryAction(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func scanQRHelpBarButtonItemAction(_ sender: AnyObject) {
        if let scanForumQRHelpURL = Configuration.singleton.scanForumQRHelpURL, UIApplication.shared.canOpenURL(scanForumQRHelpURL as URL)
        {
            UIApplication.shared.openURL(scanForumQRHelpURL)
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "SELECT REMOTE URL" as NSObject,
                AnalyticsParameterItemID: "\(scanForumQRHelpURL.absoluteString)" as NSString,
                AnalyticsParameterItemName: "\(scanForumQRHelpURL.absoluteString)" as NSString])
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
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
        dismiss(animated: true, completion: nil)
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate
extension ForumQRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
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
            warningAlertController = UIAlertController(title: "QR code cannot be parsed, please try again", message: nil, preferredStyle: .alert)
            warningAlertController?.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
                self.warningAlertController = nil
            }))
            present(warningAlertController!, animated: true, completion: nil)
        }
    }
    
    func parseJsonString(_ jsonString: String) -> Bool {
        // Construct a forum object with the scanned result.
        if let jsonData = jsonString.data(using: String.Encoding.utf8),
            let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData,
                options: .allowFragments)) as? [String: AnyObject], !jsonString.isEmpty
        {
            capturedForum = KomicaForum(jsonDict: jsonDict)
            if ((capturedForum?.isReady()) != nil) {
                performSegue(withIdentifier: SegueIdentifier.addForum, sender: nil)
                return true
            }
        }
        return false
    }
    
}

// MARK: Read from library
extension ForumQRScannerViewController {
    // Shamelessly copied from http://stackoverflow.com/questions/35956538/how-to-read-qr-code-from-static-image and modified to my need.
    func performQRCodeDetection(_ image: CIImage) -> [String] {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0])
        let features = detector?.features(in: image)
        var strings = [String]()
        features?.forEach { feature in
            if let feature = feature as? CIQRCodeFeature {
                strings.append(feature.messageString!)
            }
        }
        return strings
    }
    
}
