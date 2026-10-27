//
//  WebMPlayerViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 2/11/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit
import WebKit
import AVKit

class WebMPlayerViewController: UIViewController {

    var webMSourceURL: URL!

    private let webView = WKWebView(frame: .zero)
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Loading WebM…"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneAction)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Safari",
            style: .plain,
            target: self,
            action: #selector(safariAction)
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let webMSourceURL else { return }

        // Prefer system video playback when the asset is playable; otherwise fall back to WKWebView.
        let asset = AVURLAsset(url: webMSourceURL)
        Task { @MainActor in
            let playable = try? await asset.load(.isPlayable)
            if playable == true {
                let player = AVPlayer(url: webMSourceURL)
                let controller = AVPlayerViewController()
                controller.player = player
                present(controller, animated: true) {
                    player.play()
                }
                statusLabel.text = nil
            } else {
                statusLabel.isHidden = true
                webView.load(URLRequest(url: webMSourceURL))
            }
        }
    }

    @IBAction func doneAction(_ sender: AnyObject) {
        _ = navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func safariAction(_ sender: AnyObject) {
        guard let webMSourceURL else { return }
        UIApplication.shared.open(webMSourceURL, options: [:], completionHandler: nil)
    }
}
