//
//  DocumentBrowserViewController.swift
//  Red Zebra
//
//  Created by Jan Kříž on 12/02/2019.
//  Copyright © 2019 Jan Kříž. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        UserSettings.sharedInstance.loadSettings()
        
        let icon = UIImage(named: "settings_icon", in: nil, compatibleWith: nil)
        let item = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(presentSettingsView))
        self.additionalLeadingNavigationBarButtonItems = [item]
        
        
        delegate = self
        
        allowsDocumentCreation     = true
        allowsPickingMultipleItems = false
        
        browserUserInterfaceStyle  = .dark
        view.tintColor             = .red
    }
    
    
    
    private func createNamedFile(controller: UIDocumentBrowserViewController, importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        /*
         
         this function in a hacky way mixes together the pop-up for naming your file and the file creation,
         normally handled by:
         
         func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void)
         
         Probably should refactor in the future.
         
         */
        
        let alert = UIAlertController(title: "Name your file", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "e.g.: myFile.txt"
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Default action"), style: .cancel, handler: { _ in
            
            importHandler(nil, .none)
            return
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            
            // what happens when user presses "OK"
            
            guard let name = alert.textFields![0].text else {
                importHandler(nil, .none)
                return
            }
            
            guard name.first?.isLetter == true else {
                self.showErrorPopUp(text: #"You have to begin your file name with a letter ("a-z" or "A-Z")"#)
                importHandler(nil, .none)
                return
            }
            
            guard self.doesHaveAnExtension(fileName: name) == true else {
                self.showErrorPopUp(text: #"You have to give your file an extension (e.g.: ".txt", ".swift" etc.)"#)
                importHandler(nil, .none)
                return
            }
            
            guard self.fileNameIsOkToUse(fileName: name) == true else {
                // Cancel document creation
                self.showErrorPopUp(text: #"You can only use characters "a-z", "A-Z", "0-9", "_" & "." followed by an extension name (e.g.: "Hello_World_v2.swift")"#)
                importHandler(nil, .none)
                return
            }
            
            let newDocument    = Document(fileName: name)
            let newDocumentURL = newDocument.fileURL
            
            // Create a new document in a temporary location
            newDocument.save(to: newDocumentURL, for: .forCreating) { (saveSuccess) in
                
                // Make sure the document saved successfully
                guard saveSuccess else {
                    // Cancel document creation
                    self.showErrorPopUp(text: "You have to name your file")
                    importHandler(nil, .none)
                    return
                }
                
                // Close the document.
                newDocument.close(completionHandler: { (closeSuccess) in
                    
                    // Make sure the document closed successfully
                    guard closeSuccess else {
                        // Cancel document creation
                        self.showErrorPopUp(text: "Unable to create new document")
                        importHandler(nil, .none)
                        return
                    }
                    
                    // Pass the document's temporary URL to the import handler.
                    importHandler(newDocumentURL, .move)
                })
            }
            
            return }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        createNamedFile(controller: controller, importHandler: importHandler)
    }
    
    
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        
        guard let sourceURL = documentURLs.first else {
            showErrorPopUp(text: "Unable to open file")
            return
        }
        
        // Present the Document View Controller for the first document that was picked.
        presentDocument(at: sourceURL)
    }
    
    
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        
        showErrorPopUp(text: "Unable to open file")
    }
    
    
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentViewController") as! DocumentViewController
        documentViewController.document = Document(fileURL: documentURL)
        
        present(documentViewController, animated: true, completion: nil)
    }
    
    
    @objc private func presentSettingsView() {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let settingsVC = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
        settingsVC.modalPresentationStyle = .formSheet
        
        present(settingsVC, animated: true, completion: nil)
    }
    
    
    private func showErrorPopUp(text: String) {
        
        let alert = UIAlertController(title: "🤔 ERROR 🤷🏽‍♀️", message: text, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in return }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func fileNameIsOkToUse(fileName file: String) -> Bool {
        
        for i in file {
            if i.isLetter == false && i.isNumber == false && i != "." && i != "_" && i != "-" && i != "(" && i != ")" && i != " " {
                return false
            }
        }
        return true
    }
    
    
    private func doesHaveAnExtension(fileName: String) -> Bool {
        
        var file = fileName
        
        for _ in file {
            
            let dot = file.removeFirst()
            
            if dot == "." {
                
                for _ in file {
                    
                    let ext = file.removeFirst()
                    if ext == " " {
                        return false
                    }
                }
                return true
            }
        }
        return false
    }
    
    
}

