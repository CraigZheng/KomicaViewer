//
//  ForumTextInputViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol ForumTextInputViewControllerProtocol {
    func forumDetailEntered(_ inputViewController: ForumTextInputViewController, enteredDetails: String, forField: ForumField)
}

class ForumTextInputViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var insertBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    
    var allowEditing = true
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
        NotificationCenter.default.addObserver(self, selector: #selector(ForumTextInputViewController.handlekeyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ForumTextInputViewController.handleKeyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        // Configure the text view.
        insertBarButtonItem.isEnabled = pageSpecifier?.isEmpty == false ?? false
        if !allowEditing {
            textView.isEditable = false
            insertBarButtonItem.isEnabled = false
            saveBarButtonItem.isEnabled = false
        } else {
            textView.becomeFirstResponder()
        }
    }

}

extension ForumTextInputViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // When page specifier is not empty.
        if let pageSpecifier = pageSpecifier, !pageSpecifier.isEmpty
        {
            // Insert button enables itself when the textView.text does not contain the page specifier.
            insertBarButtonItem.isEnabled = (textView.text as NSString).range(of: pageSpecifier).location == NSNotFound
        }
    }
    
}

// MARK: UI actions.
extension ForumTextInputViewController {
    
    @IBAction func saveAction(_ sender: AnyObject) {
        textView.resignFirstResponder()
        if let enteredText = textView.text, !enteredText.isEmpty {
            // If page specifier is not empty and the enteredText does not contain it, show a warning.
            if let pageSpecifier = pageSpecifier, !pageSpecifier.isEmpty && !enteredText.contains(pageSpecifier) {
                ProgressHUD.showMessage("Cannot save, \(pageSpecifier) is required.")
            } else {
                delegate?.forumDetailEntered(self, enteredDetails: enteredText, forField: field)
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func insertAction(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Insert \(pageSpecifier ?? "")", message: "Insert the tag specifier to the current position", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
            if let pageSpecifier = self.pageSpecifier, !pageSpecifier.isEmpty {
                let generalPasteboard = UIPasteboard.general
                let items = generalPasteboard.items
                generalPasteboard.string = pageSpecifier
                self.textView.paste(self)
                generalPasteboard.items = items
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        if let topViewController = UIApplication.topViewController {
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: keyboard events.
extension ForumTextInputViewController {
    
    func handlekeyboardWillShow(_ notification: Notification) {
        if let keyboardValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        {
            let keyboardRect = view.convert(keyboardValue.cgRectValue, from: nil)
            textViewBottomConstraint.constant = keyboardRect.size.height
            toolbarBottomConstraint.constant = keyboardRect.size.height
        }
    }
    
    func handleKeyboardWillHide(_ notification: Notification) {
        textViewBottomConstraint.constant = 0
        toolbarBottomConstraint.constant = 0
    }
    
}
