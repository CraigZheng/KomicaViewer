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
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var delegate: ForumTextInputViewControllerProtocol?
    var prefilledString: String?
    var pageSpecifier: String?
    var field: ForumField! {
        didSet {
            self.title = field.rawValue
            switch field! {
            case ForumField.listURL:
                pageSpecifier = "<PAGE>"
            case ForumField.responseURL:
                pageSpecifier = "<ID>"
            default:
                break;
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let prefilledString = prefilledString {
            textView.text = prefilledString
        }
        // Keyboard events observer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ForumTextInputViewController.handlekeyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ForumTextInputViewController.handleKeyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }

}

extension ForumTextInputViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        
    }
    
}

// MARK: UI actions.
extension ForumTextInputViewController {
    
    @IBAction func saveAction(sender: AnyObject) {
        textView.resignFirstResponder()
        if let enteredText = textView.text where !enteredText.isEmpty {
            // If page specifier is not empty and the enteredText does not contain it, show a warning.
            if let pageSpecifier = pageSpecifier where !pageSpecifier.isEmpty && !enteredText.containsString(pageSpecifier) {
                ProgressHUD.showMessage("Cannot save, \(pageSpecifier) is required.")
            } else {
                delegate?.forumDetailEntered(self, enteredDetails: enteredText, forField: field)
                navigationController?.popViewControllerAnimated(true)
            }
        }
    }
}

// MARK: keyboard events.
extension ForumTextInputViewController {
    
    func handlekeyboardWillShow(notification: NSNotification) {
        if let keyboardValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        {
            let keyboardRect = view.convertRect(keyboardValue.CGRectValue(), fromView: nil)
            bottomConstraint.constant = keyboardRect.size.height
        }
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 0
    }
    
}