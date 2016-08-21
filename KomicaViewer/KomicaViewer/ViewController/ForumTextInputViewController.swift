//
//  ForumTextInputViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol ForumTextInputViewControllerProtocol {
    func forumDetailEntered(inputViewController: ForumTextInputViewController, enteredDetails: String, forField: String)
}

class ForumTextInputViewController: UIViewController {
    var delegate: ForumTextInputViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

extension ForumTextInputViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        
    }
    
}
