//
//  ForumTextInputViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol ForumTextInputViewControllerProtocol {
    func forumDetailEntered(inputViewController: ForumTextInputViewController, enteredDetails: String, forField: ForumField)
}

class ForumTextInputViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    var delegate: ForumTextInputViewControllerProtocol?
    var prefilledString: String?
    var field: ForumField! {
        didSet {
            self.title = field.rawValue
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let prefilledString = prefilledString {
            textView.text = prefilledString
        }
    }

}

extension ForumTextInputViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        
    }
    
}

// MARK: UI actions.
extension ForumTextInputViewController {
    
    @IBAction func saveAction(sender: AnyObject) {
        if let enteredText = textView.text {
            delegate?.forumDetailEntered(self, enteredDetails: enteredText, forField: field)
        }
    }
}