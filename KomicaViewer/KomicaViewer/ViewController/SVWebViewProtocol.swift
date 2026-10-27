//
//  SVWebViewProtocol.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit
import SafariServices

protocol SVWebViewProtocol: AnyObject {
    var svWebViewGuardDog: WebViewGuardDog? { get set }
    var svWebViewURL: URL? { get set }

    func presentSVWebView()
}

extension SVWebViewProtocol where Self: UIViewController {

    func presentSVWebView() {
        guard let svWebViewURL else { return }
        let safari = SFSafariViewController(url: svWebViewURL)
        safari.preferredControlTintColor = navigationController?.navigationBar.tintColor
        present(safari, animated: true, completion: nil)
    }
}
