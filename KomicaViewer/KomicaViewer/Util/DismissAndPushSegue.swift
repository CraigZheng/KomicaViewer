//
//  DismissAndPushSegue.swift
//  KomicaViewer
//
//  Adapted from BareFeetWare BFWControls (free to use with acknowledgement).
//

import UIKit

class DismissAndPushSegue: UIStoryboardSegue {

    override func perform() {
        guard let presentingViewController = source.presentingViewController else { return }
        presentingViewController.dismiss(animated: true) {
            let presentingNavigationController = presentingViewController as? UINavigationController
                ?? presentingViewController.navigationController
            guard let presentingNavigationController else { return }
            var destinationViewController = self.destination
            if let destinationNavigationController = destinationViewController as? UINavigationController {
                destinationViewController = destinationNavigationController.viewControllers.first!
            }
            presentingNavigationController.pushViewController(destinationViewController, animated: true)
        }
    }
}
