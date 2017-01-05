//
//  SVWebViewProtocol.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import SVWebViewController

protocol SVWebViewProtocol: class {
    var svWebViewGuardDog: WebViewGuardDog? { get set }
    var svWebViewURL: URL? { get set }
    
    func presentSVWebView()
}

extension SVWebViewProtocol where Self: UIViewController {
    
    func presentSVWebView() {
        if let svWebViewURL = svWebViewURL
        {
            if let navigationController = self.navigationController,
                let webViewController = SVWebViewController(url: svWebViewURL) {
                webViewController.delegate = svWebViewGuardDog
                navigationController.pushViewController(webViewController, animated: true)
            } else if let webViewController = SVModalWebViewController(url: svWebViewURL) {
                webViewController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
                webViewController.barsTintColor = navigationController?.navigationBar.barTintColor
                webViewController.webViewDelegate = svWebViewGuardDog
                webViewController.popoverPresentationController?.sourceView = self.view
                webViewController.popoverPresentationController?.sourceRect = self.view.bounds
                present(webViewController, animated: true, completion: nil)
            }
        }
    }
    
}
