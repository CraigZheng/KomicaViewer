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
    var photos: [MWPhoto]? { get set }
    var thumbnails: [MWPhoto]? { get set }
    var photoIndex: Int? { get set }
    func presentPhotos()
}

extension UIViewControllerMWPhotoBrowserProtocol where Self: UIViewController {
    
    private var photoBrowser: MWPhotoBrowser {
        PhotoBrowserDelegate.singleton.photos = photos ?? []
        PhotoBrowserDelegate.singleton.thumbnails = thumbnails
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
            photoBrowser.setCurrentPhotoIndex(UInt(photoIndex))
        }
        return photoBrowser
    }

    func presentPhotos() {
        if let photos = photos where !photos.isEmpty {
            navigationController?.pushViewController(photoBrowser, animated:true)
        }
    }
    
}

private class PhotoBrowserDelegate: NSObject, MWPhotoBrowserDelegate {
    static let singleton = PhotoBrowserDelegate()
    
    var photos: [MWPhoto]!
    var thumbnails: [MWPhoto]?
    
    @objc func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(photos.count)
    }
    
    @objc func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        return photos[Int(index)]
    }
    
    @objc private func photoBrowser(photoBrowser: MWPhotoBrowser!, thumbPhotoAtIndex index: UInt) -> MWPhotoProtocol! {
        return thumbnails != nil ? thumbnails?[Int(index)] : photos[Int(index)]
    }
    
}