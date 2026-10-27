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
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var warningAlertController: UIAlertController?
    
    fileprivate struct SegueIdentifier {
        static let addForum = "addForum"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Request camera permission.
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
            DispatchQueue.main.async(execute: {
                if (granted) {
                    self.setUpScanner()
                } else {
                    let alertController = UIAlertController(title: "\(UIApplication.appName) Would Like To Use Your Camera", message: nil, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
                        _ = self?.navigationController?.popToRootViewController(animated: true)
                    }))
                    alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraPreviewView.bounds
    }

    fileprivate func setUpScanner() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        let session = AVCaptureSession()
        captureSession = session
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }
        guard session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr, .ean13]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = cameraPreviewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraPreviewView.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
}

// MARK: Navigation
extension ForumQRScannerViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.addForum, let destinationViewController = segue.destination as? AddForumTableViewController {
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
            UIApplication.shared.open(scanForumQRHelpURL, options: [:], completionHandler: nil)
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterContentType: "SELECT REMOTE URL" as NSObject,
                AnalyticsParameterItemID: "\(scanForumQRHelpURL.absoluteString)" as NSString,
                AnalyticsParameterItemName: "\(scanForumQRHelpURL.absoluteString)" as NSString])
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage,
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
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let readableObject = metadataObjects.last as? AVMetadataMachineReadableCodeObject,
           readableObject.type == .qr,
           let stringValue = readableObject.stringValue,
           parseJsonString(stringValue) {
            captureSession?.stopRunning()
            return
        }
        if warningAlertController == nil {
            warningAlertController = UIAlertController(title: "QR code cannot be parsed, please try again", message: nil, preferredStyle: .alert)
            warningAlertController?.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
                self.warningAlertController = nil
            }))
            present(warningAlertController!, animated: true, completion: nil)
        }
    }
    
    func parseJsonString(_ jsonString: String) -> Bool {
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
    func performQRCodeDetection(_ image: CIImage) -> [String] {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0])
        let features = detector?.features(in: image)
        var strings = [String]()
        features?.forEach { feature in
            if let feature = feature as? CIQRCodeFeature, let message = feature.messageString {
                strings.append(message)
            }
        }
        return strings
    }
    
}
