//
//  DocumentViewController.swift
//  Red Zebra
//
//  Created by Jan Kříž on 12/02/2019.
//  Copyright © 2019 Jan Kříž. All rights reserved.
//
import UIKit
import RedZebraShared

class DocumentViewController: CustomBaseViewController, UITextViewDelegate {
    
    @IBOutlet var titleLabel: UINavigationItem!
    @IBOutlet var textView: UITextView!
    @IBOutlet var undoButtonLabel: UIBarButtonItem!
    @IBOutlet var redoButtonLabel: UIBarButtonItem!
    @IBOutlet var doneButtonLabel: UIBarButtonItem!
    @IBOutlet var previewButtonLabel: UIBarButtonItem!
    @IBOutlet var moreButtonLabel: UIBarButtonItem!
    
    var document: Document?
    
    // previously called fileLoadedSuccessfully
    // The name changed because there are now two reasons the document shouldn't be saved:
    // 1) Something went wrong with opening the file
    // 2) User chose the "Close without saving" option in "More..."
    private var saveWhileClosing = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.saveTheDocument), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.saveTheDocument), name: UIApplication.willTerminateNotification, object: nil)
        
        textView.delegate = self
        
        undoButtonLabel.isEnabled = false
        redoButtonLabel.isEnabled = false
        doneButtonLabel.isEnabled = false
        
        titleLabel.accessibilityLabel           = "\(document!.fileURL.lastPathComponent)"
        textView.accessibilityLabel             = "Enter your text here"
        undoButtonLabel.accessibilityLabel      = "Undo"
        redoButtonLabel.accessibilityLabel      = "Redo"
        doneButtonLabel.accessibilityLabel      = "Hide keyboard"
        moreButtonLabel.accessibilityLabel      = "More options"
        
        if self.document!.isHTML() {
            previewButtonLabel.title              = "Preview"
            previewButtonLabel.accessibilityLabel = "Preview \(document!.fileURL.lastPathComponent)"
            previewButtonLabel.isEnabled          = true
        } else {
            previewButtonLabel.title     = ""
            previewButtonLabel.isEnabled = false
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.textView.text = ""
        
        UserSettings.sharedInstance.loadSettings()
        self.textView.font = UserSettings.sharedInstance.font
        
        // Access the document
        document?.open(completionHandler: { (success) in
            if success {
                
                self.titleLabel.title      = self.document?.fileURL.lastPathComponent
                self.textView.text         = self.document!.text
                self.saveWhileClosing      = true
                
            } else {
                
                self.saveWhileClosing      = false
                self.titleLabel.title      = ""
                self.textView.text         = ""
                self.textView.isEditable   = false
                
                self.showErrorPopUp(message: "Failed to load file \(self.document?.fileURL.lastPathComponent ?? "UNABLE_TO_FIND_FILE_NAME") properly.\nPlease close the file & try again.")
            }
        })
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.saveTheDocument()
    }
    
    
    @IBAction func dismissDocumentViewController() {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func undoTapped(_ sender: UIBarButtonItem) {
        
        textView.undoManager?.undo()
        let canUndo: Bool = textView.undoManager?.canUndo ?? false
        
        if canUndo {
            undoButtonLabel.isEnabled = true
        } else {
            undoButtonLabel.isEnabled = false
        }
    }
    
    
    @IBAction func redoTapped(_ sender: UIBarButtonItem) {
        
        textView.undoManager?.redo()
        let canRedo: Bool = textView.undoManager?.canRedo ?? false
        
        if canRedo {
            redoButtonLabel.isEnabled = true
        } else {
            redoButtonLabel.isEnabled = false
        }
    }
    
    
    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
    }
    
    
    
    @IBAction func previewButton(_ sender: UIBarButtonItem) {
        
        if self.document!.isHTML() {
            
            let webBrowser = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebBrowserViewController") as! WebBrowserViewController
            
            webBrowser.webContent = WebContent(data: self.textView.text, url: self.document?.fileURL)
            
            self.present(webBrowser, animated: true)
            
        }
        
    }
    
    
    @IBAction func moreButton(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "What do you want to do?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Word Count", style: .default, handler: { _ in self.wordCount() } ))
        alert.addAction(UIAlertAction(title: "Zalgo-ify text", style: .default, handler: { _ in self.zalgoify() } ))
        alert.addAction(UIAlertAction(title: "S̶t̶r̶i̶k̶e̶ t̶h̶r̶o̶u̶g̶h̶ text", style: .default, handler: { _ in self.strikeThru() } ))
        alert.addAction(UIAlertAction(title: "Close without saving", style: .default, handler: { _ in self.closeWithoutSaving() } ))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in return } ))
        
        alert.popoverPresentationController?.barButtonItem = self.moreButtonLabel
        
        self.present(alert, animated: true)
    }
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        let canUndo: Bool = textView.undoManager?.canUndo ?? false
        let canRedo: Bool = textView.undoManager?.canRedo ?? false
        
        if canUndo {
            undoButtonLabel.isEnabled = true
        } else {
            undoButtonLabel.isEnabled = false
        }
        
        if canRedo {
            redoButtonLabel.isEnabled = true
        } else {
            redoButtonLabel.isEnabled = false
        }
        
    }
    
    
}



extension DocumentViewController {
    
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "h", modifierFlags: .command, action: #selector(doNothing), discoverabilityTitle: "Home Screen"),
            UIKeyCommand(input: "z", modifierFlags: .command, action: #selector(doNothing), discoverabilityTitle: "Undo"),
            UIKeyCommand(input: "z", modifierFlags: UIKeyModifierFlags(arrayLiteral: .command, .shift), action: #selector(doNothing), discoverabilityTitle: "Redo"),
            UIKeyCommand(input: "a", modifierFlags: .command, action: #selector(doNothing), discoverabilityTitle: "Select all"),
            UIKeyCommand(input: "x", modifierFlags: .command, action: #selector(doNothing), discoverabilityTitle: "Cut"),
            UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(doNothing), discoverabilityTitle: "Copy"),
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(doNothing), discoverabilityTitle: "Paste"),
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(saveTheDocument), discoverabilityTitle: "Save"),
            UIKeyCommand(input: "q", modifierFlags: .command, action: #selector(closeWithoutSaving), discoverabilityTitle: "Close without saving"),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(dismissDocumentViewController), discoverabilityTitle: "Save & Close")
        ]
    }
    
    
    @objc private func doNothing() {
        // this dummy function is here only because built in keyboard shortcuts (like cmd+z to undo)
        // aren't exposed to the user by default - see "keyCommands" above
    }
    
    
    @objc private func saveTheDocument() {
        
        guard self.saveWhileClosing else { return }
        guard self.document?.text != self.textView.text else { return }
        
        document?.text = textView.text
        document?.updateChangeCount(.done)
        
        self.document?.close(completionHandler: nil)
    }
    
    
    @objc func adjustForKeyboard(notification: Notification) {
        // scrolls the textView so it doesn't become "invisible" behind the keyboard
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            
            textView.contentInset     = UIEdgeInsets.zero
            doneButtonLabel.isEnabled = false
            
        } else {
            
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
            doneButtonLabel.isEnabled = true
        }
        
        textView.scrollIndicatorInsets = textView.contentInset
        
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }
    
    
    private func wordCount() {
        let wc = WordCount(self.textView.text)
        
        var title = "📖 Word Count 📖"
        let message = """
        
        Characters: \(wc.characters.asFormattedString()),
        Bytes: \(wc.bytes.asFormattedString()),
        Words: \(wc.words.asFormattedString()),
        Lines: \(wc.lines.asFormattedString()).
        
        """
        
        if wc.characters < 280 {
            title = "🐥 It's tweetable! 🐥"
        }
        
        self.showAlertPopUp(title: title, message: message)
    }
    
    
    private func zalgoify() {
        
        let zalgo = Zalgo()
        let zalgoifiedText = zalgo.transform(self.textView.text)
        
        let alert = UIAlertController(title: "Copy to clipboard?", message: "\n\(zalgoifiedText)\n", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Default action"), style: .default, handler: { _ in UIPasteboard.general.string = zalgoifiedText }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Cancel action"), style: .destructive, handler: { _ in return }))
        
        self.present(alert, animated: true)
    }
    
    
    private func strikeThru() {
        
        
        let strikedThruText = strikeThrough(self.textView.text)
        
        let alert = UIAlertController(title: "Copy to clipboard?", message: "\n\(strikedThruText)\n", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Default action"), style: .default, handler: { _ in UIPasteboard.general.string = strikedThruText }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Cancel action"), style: .destructive, handler: { _ in return }))
        
        self.present(alert, animated: true)
    }
    
    
    @objc private func closeWithoutSaving() {
        self.saveWhileClosing = false
        self.dismissDocumentViewController()
    }
    
}
