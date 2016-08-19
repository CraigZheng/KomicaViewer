//
//  WebViewGuardDog.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 19/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

/**
 Allows only NSURL host that matches home.
 */
class WebViewGuardDog: NSObject, UIWebViewDelegate {
    // Home host, any host that does not match this host would be rejected.
    var home: String?
    
    // MARK: UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var should = true
        if let home = home {
            if request.URL?.host != home {
                should = false
            }
        }
        return should
    }
}
