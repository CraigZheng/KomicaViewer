//
//  WebViewGuardDog.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 19/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol WebViewGuardDogDelegate: AnyObject {
    func blockedRequest(_ request: URLRequest)
}

/**
 Host allow-list helper previously used with UIWebView.
 In-app browsing now uses SFSafariViewController, so this is retained
 only for existing call sites that still set `home` / warning flags.
 */
class WebViewGuardDog: NSObject {
    // Home host, any host that does not match this host would be rejected.
    var home: String?
    var showWarningOnBlock = false
    var onBlockMessage = "You cannot navigate away from this page."
    weak var delegate: WebViewGuardDogDelegate?

    func shouldAllow(request: URLRequest, isUserLinkClick: Bool) -> Bool {
        guard let home, isUserLinkClick else { return true }
        guard request.url?.host != home else { return true }
        delegate?.blockedRequest(request)
        if showWarningOnBlock && !onBlockMessage.isEmpty {
            ProgressHUD.showMessage(onBlockMessage)
        }
        return false
    }
}
