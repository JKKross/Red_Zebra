//
//  UserSettings.swift
//  Red Zebra
//
//  Created by Jan Kříž on 04/02/2019.
//  Copyright © 2019 Jan Kříž. All rights reserved.
//
import UIKit

class UserSettings {
    
    
    private init() {}
    static let sharedInstance = UserSettings()
    
    let defaults = UserDefaults.standard
    
    
    var font  = UIFont(name: "Menlo", size: 17)
    
    
    var preferredFontSize: Float = 17
    var preferredFontIndex       = 0
    
    
    func saveSettings() {
        defaults.set(preferredFontIndex, forKey: Keys.fontFamily)
        defaults.set(preferredFontSize, forKey: Keys.fontSize)
    }
    
    
    func loadSettings() {
        
        preferredFontSize   = defaults.float(forKey: Keys.fontSize)
        preferredFontIndex  = defaults.integer(forKey: Keys.fontFamily)
        
        //  The saveSettings() method is not called when
        //  someone starts the app for the very first time,
        //  which results in:
        //
        //    prefferedFontIndex = 0
        //    fontSize           = 0.0
        //
        //  Altough prefferedFontIndex = 0 is what we want ("Menlo" is default font of choice),
        //  font size = 0.0 is not.
        //
        //  That's why:
        if preferredFontSize < 10 {
            preferredFontSize = 17
            
            //  FontChooserViewController also uses some of those values
            //  to set it's default values properly,
            //  that's why we need to save here:
            self.saveSettings()
        }
        
        switch preferredFontIndex {
        case 0:
            // "Menlo"
            font = UIFont(name: "Menlo", size: CGFloat(preferredFontSize))
        default:
            // system
            font = UIFont.systemFont(ofSize: CGFloat(preferredFontSize))
        }
    }
    
    
    
    private struct Keys {
        static let fontFamily      = "Font"
        static let fontSize        = "FontSize"
    }
    
}
