//
//  UIViewControllerMWPhotoBrowserProtocol.swift
//  KomicaViewer
//
//  Created by Craig on 14/09/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit
import SDWebImage

protocol UIViewControllerMWPhotoBrowserProtocol: AnyObject {
    var photoURLs: [URL]? { get set }
    var thumbnailURLs: [URL]? { get set }
    var photoIndex: Int? { get set }
    func presentPhotos()
}

extension UIViewControllerMWPhotoBrowserProtocol where Self: UIViewController {

    func presentPhotos() {
        guard let photoURLs = photoURLs, !photoURLs.isEmpty else { return }
        let index = photoIndex ?? 0
        if index < photoURLs.count,
           (photoURLs[index].absoluteString as NSString).pathExtension.lowercased() == "webm" {
            if let webMPlayerViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "WebMPlayerViewController") as? WebMPlayerViewController {
                webMPlayerViewController.webMSourceURL = photoURLs[index]
                present(webMPlayerViewController, animated: true, completion: nil)
            }
            return
        }

        let browser = SimplePhotoBrowserViewController(photoURLs: photoURLs, startIndex: index)
        navigationController?.pushViewController(browser, animated: true)
    }
}

final class SimplePhotoBrowserViewController: UIViewController, UIScrollViewDelegate {

    private let photoURLs: [URL]
    private let startIndex: Int
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var currentIndex: Int

    init(photoURLs: [URL], startIndex: Int) {
        self.photoURLs = photoURLs
        self.startIndex = max(0, min(startIndex, photoURLs.count - 1))
        self.currentIndex = self.startIndex
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        let left = UISwipeGestureRecognizer(target: self, action: #selector(showPrevious))
        left.direction = .right
        view.addGestureRecognizer(left)
        let right = UISwipeGestureRecognizer(target: self, action: #selector(showNext))
        right.direction = .left
        view.addGestureRecognizer(right)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareCurrent)
        )

        loadCurrent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        imageView.frame = scrollView.bounds
        scrollView.contentSize = scrollView.bounds.size
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    private func loadCurrent() {
        title = "\(currentIndex + 1) / \(photoURLs.count)"
        scrollView.setZoomScale(1, animated: false)
        imageView.sd_setImage(with: photoURLs[currentIndex], placeholderImage: nil)
    }

    @objc private func showPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadCurrent()
    }

    @objc private func showNext() {
        guard currentIndex < photoURLs.count - 1 else { return }
        currentIndex += 1
        loadCurrent()
    }

    @objc private func shareCurrent() {
        let activity = UIActivityViewController(activityItems: [photoURLs[currentIndex]], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activity, animated: true)
    }
}
