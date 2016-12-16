//
//  WebViewGuardDog.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 19/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol WebViewGuardDogDelegate: class {
    func blockedRequest(_ request: URLRequest)
}

/**
 Allows only NSURL host that matches home.
 */
class WebViewGuardDog: NSObject, UIWebViewDelegate {
    // Home host, any host that does not match this host would be rejected.
    var home: String?
    var showWarningOnBlock = false
    var onBlockMessage = "You cannot navigate away from this page."
    var delegate: WebViewGuardDogDelegate?
    // MARK: UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var should = true
        if let home = home {
            if request.url?.host != home && navigationType == .linkClicked{
                should = false
                delegate?.blockedRequest(request)
                if showWarningOnBlock && !onBlockMessage.isEmpty {
                    ProgressHUD.showMessage(onBlockMessage)
                }
            }
        }
        return should
    }
}
