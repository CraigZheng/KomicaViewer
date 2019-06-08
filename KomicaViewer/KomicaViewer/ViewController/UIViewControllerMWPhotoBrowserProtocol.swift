//
//  UIViewControllerMWPhotoBrowserProtocol.swift
//  KomicaViewer
//
//  Created by Craig on 14/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import MWPhotoBrowser

protocol UIViewControllerMWPhotoBrowserProtocol {
    var photoURLs: [URL]? { get set }
    var thumbnailURLs: [URL]? { get set }
    var photoIndex: Int? { get set }
    func presentPhotos()
}

extension UIViewControllerMWPhotoBrowserProtocol where Self: UIViewController {
    
    fileprivate var photoBrowser: MWPhotoBrowser {
        PhotoBrowserDelegate.singleton.photoURLs = photoURLs ?? []
        PhotoBrowserDelegate.singleton.thumbnailURLs = thumbnailURLs
        let photoBrowser = MWPhotoBrowser(delegate: PhotoBrowserDelegate.singleton)
        photoBrowser!.displayNavArrows = true; // Whether to display left and right nav arrows on toolbar (defaults to false)
        photoBrowser!.displaySelectionButtons = false; // Whether selection buttons are shown on each image (defaults to false)
        photoBrowser!.zoomPhotosToFill = false; // Images that almost fill the screen will be initially zoomed to fill (defaults to true)
        photoBrowser!.alwaysShowControls = false; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to false)
        photoBrowser!.enableGrid = true; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to true)
        photoBrowser!.startOnGrid = false; // Whether to start on the grid of thumbnails instead of the first photo (defaults to false)
        photoBrowser!.delayToHideElements = UInt(8);
        photoBrowser!.enableSwipeToDismiss = false; // dont dismiss
        photoBrowser!.displayActionButton = true;
        photoBrowser!.hidesBottomBarWhenPushed = true;

        if let photoIndex = photoIndex {
            photoBrowser?.setCurrentPhotoIndex(UInt(photoIndex))
        }
        return photoBrowser!
    }

    func presentPhotos() {
        if let photoURLs = photoURLs, !photoURLs.isEmpty {
            if let photoIndex = photoIndex, (photoURLs[photoIndex].absoluteString as NSString).pathExtension.lowercased() == "webm" {
                // Open webm file.
                if let webMPlayerViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebMPlayerViewController") as? WebMPlayerViewController {
                    webMPlayerViewController.webMSourceURL = photoURLs[photoIndex]
                    navigationController?.present(webMPlayerViewController, animated: true, completion: nil)
                }
            } else {
                navigationController?.pushViewController(photoBrowser, animated:true)
            }
        }
    }
    
}

private class PhotoBrowserDelegate: NSObject, MWPhotoBrowserDelegate {
    @objc static let singleton = PhotoBrowserDelegate()
    
    @objc var photoURLs: [URL]!
    @objc var thumbnailURLs: [URL]?
    
    @objc func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(photoURLs.count)
    }
    
    @objc func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        return MWPhoto(url: photoURLs[Int(index)])
    }
    
    @objc fileprivate func photoBrowser(_ photoBrowser: MWPhotoBrowser!, thumbPhotoAt index: UInt) -> MWPhotoProtocol! {
        let url = (thumbnailURLs != nil) ? thumbnailURLs?[Int(index)] : photoURLs[Int(index)]
        return MWPhoto(url: url)
    }
    
}
