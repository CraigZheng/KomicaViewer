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
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var insertBarButtonItem: UIBarButtonItem!
    
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
        textView.becomeFirstResponder()
        insertBarButtonItem.enabled = pageSpecifier?.isEmpty == false ?? false

    }

}

extension ForumTextInputViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        
    }
    
    func textViewDidChange(textView: UITextView) {
        // When page specifier is not empty.
        if let pageSpecifier = pageSpecifier
            where !pageSpecifier.isEmpty
        {
            // Insert button enables itself when the textView.text does not contain the page specifier.
            insertBarButtonItem.enabled = (textView.text as NSString).rangeOfString(pageSpecifier).location == NSNotFound
        }
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
    
    @IBAction func insertAction(sender: AnyObject) {
        let alertController = UIAlertController(title: "Insert \(pageSpecifier ?? "")", message: "Insert the tag specifier to the current position", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: {_ in
            if let pageSpecifier = self.pageSpecifier where !pageSpecifier.isEmpty {
                let generalPasteboard = UIPasteboard.generalPasteboard()
                let items = generalPasteboard.items
                generalPasteboard.string = pageSpecifier
                self.textView.paste(self)
                generalPasteboard.items = items
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        if let topViewController = UIApplication.topViewController {
            topViewController.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: keyboard events.
extension ForumTextInputViewController {
    
    func handlekeyboardWillShow(notification: NSNotification) {
        if let keyboardValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        {
            let keyboardRect = view.convertRect(keyboardValue.CGRectValue(), fromView: nil)
            textViewBottomConstraint.constant = keyboardRect.size.height
            toolbarBottomConstraint.constant = keyboardRect.size.height
        }
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        textViewBottomConstraint.constant = 0
        toolbarBottomConstraint.constant = 0
    }
    
}