//
//  AboutViewController.swift
//  Red Zebra
//
//  Created by Jan Kříž on 24/02/2019.
//  Copyright © 2019 Jan Kříž. All rights reserved.
//
import UIKit
import StoreKit
import MessageUI

class AboutViewController: CustomBaseViewController {
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var aboutTheAppLabel: UITextView!
    
    // if this text is changed in any way, you need to update "feedbackFirstLetterIndex" (in "@IBAction func tapGestureRecognizer(_ sender: UITapGestureRecognizer)") accordingly!
    private var aboutTheAppText = #"""
    
    Red Zebra is a simple text editor inspired by iOS app Textor & GNU's terminal text editor NANO. Red Zebra is open-source software and you can find the source code on Github.
    
    I highly appreciate any feedback and/or App Store review.
    
    As stated previously, this app offers only basic text editing functionality in a familiar iOS Files-like user interface. If you're looking for something more "pro" & you are familiar with Vi-like editors, I'd highly recommend another open-source app - iVim.
    
    
    Privacy Policy:
    
    I don't have access to any of your personal data and/or information. The only way I can gain access to said information is if you decide to send me an e-mail. In that case, I will never willingly share your e-mail address or any private information included in that e-mail with anyone.
    
    
    Red Zebra © 2019-2020 Jan Kříž
    
    """#
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        aboutTheAppLabel.delegate = self
        aboutTheAppLabel.accessibilityLabel = "About the app"
        
        updateAboutTheAppTextView()
    }
    
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    
    private func updateAboutTheAppTextView() {
        
        let appVersion  = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
        aboutTheAppText.append("\nversion \(appVersion ?? "_version_number_")")
        aboutTheAppText.append("\nbuild \(buildNumber ?? "_build_number_")\n")
        
        let textForRanges  = NSString(string: aboutTheAppText)
        let wholeTextRange = textForRanges.range(of: aboutTheAppText)
        
        let textorRange    = textForRanges.range(of: "Textor")
        let nanoRange      = textForRanges.range(of: "NANO")
        let githubRange    = textForRanges.range(of: "Github")
        let iVimRange      = textForRanges.range(of: "iVim")
        let feedbackRange  = textForRanges.range(of: "feedback")
        let reviewRange    = textForRanges.range(of: "review")
        
        let attributedString = NSMutableAttributedString(string: aboutTheAppText)
        attributedString.addAttribute(.link, value: "https://github.com/louisdh/textor", range: textorRange)
        attributedString.addAttribute(.link, value: "https://www.nano-editor.org", range: nanoRange)
        attributedString.addAttribute(.link, value: "https://github.com/JKKross/Red_Zebra", range: githubRange)
        attributedString.addAttribute(.link, value: "https://itunes.apple.com/app/ivim/id1266544660?mt=8", range: iVimRange)
        attributedString.addAttribute(.link, value: "https://itunes.apple.com/app/red-zebra/id1463017929?l=cs&ls=1&mt=8", range: reviewRange)
        
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: wholeTextRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.red, range: feedbackRange)
        
        let font = aboutTheAppLabel.font
        aboutTheAppLabel.attributedText = attributedString
        aboutTheAppLabel.font           = font
    }
    
    
    private func showMailComposer() {
        
        guard MFMailComposeViewController.canSendMail() else {
            
            let alert = UIAlertController(title: "Oops!", message: "Seems like you're not able to send email from this device! You can message me at zawadski.jkk@gmail.com", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            present(alert, animated: true)
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["zawadski.jkk@gmail.com"])
        mailComposer.setSubject("Red Zebra feedback")
        
        present(mailComposer, animated: true)
    }
    
    
    @IBAction func tapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        
        // you have to change this value if you modified "aboutTheAppText"!!!
        let feedbackFirstLetterIndex = 199
        
        let feedbackLocation = aboutTheAppLabel.layoutManager.boundingRect(forGlyphRange: NSRange(location: feedbackFirstLetterIndex, length: 8), in: aboutTheAppLabel.layoutManager.textContainers[0])
        
        let tapAtCGPoint = tapGestureRecognizer.location(in: aboutTheAppLabel)
        
        
        if tapAtCGPoint.x > feedbackLocation.minX && tapAtCGPoint.x < feedbackLocation.maxX && tapAtCGPoint.y > feedbackLocation.minY && tapAtCGPoint.y < feedbackLocation.maxY {
            
            // user tapped "feedback"
            showMailComposer()
            
        }
    }
    
    
}



extension AboutViewController: MFMailComposeViewControllerDelegate, UITextViewDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        let alert = UIAlertController(title: "Oops!", message: "Something went wrong! You can message me at zawadski.jkk@gmail.com", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        
        if let _ = error {
            present(alert, animated: true)
            controller.dismiss(animated: true)
        }
        
        switch result {
        case .failed:
            present(alert, animated: true)
            
        case .sent:
            let thanksPopUp = UIAlertController(title: "Thanks for your feedback!", message: nil, preferredStyle: .alert)
            thanksPopUp.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            present(thanksPopUp, animated: true)
            
        default:
            controller.dismiss(animated: true)
        }
        
        controller.dismiss(animated: true)
    }
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // Added because default behavior of links in UITextViews in iOS13 does not respond to
        // to taps by default
        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        return true
    }
    
}
