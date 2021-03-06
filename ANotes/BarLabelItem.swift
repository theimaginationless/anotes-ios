//
//  BarLabelItem.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 27.10.2020.
//

import UIKit

class BarLabelItem: UIBarButtonItem {
    var label: UILabel!
    private var prefix: String!    
    @IBInspectable var textColor: UIColor! {
        set {
            self.label?.textColor = newValue
        }
        get {
            return self.label?.textColor
        }
    }
    
    @IBInspectable var text: String? {
        set {
            UIView.transition(with: self.label, duration: 0.3, options: .transitionCrossDissolve) {
                self.label?.text = newValue
                self.label?.sizeToFit()
            }
        }
        get {
            return self.label?.text
        }
    }
    
    @IBInspectable var date: String? {
        set {
            UIView.transition(with: self.label, duration: 0.3, options: .transitionCrossDissolve) {
                if let text = newValue {
                    self.label?.text = "\(self.prefix!) \(text)"
                }
                else {
                    self.label?.text = NSLocalizedString("Never backed up", comment: "Label placeholder for never backed up notes")
                }
                self.label?.sizeToFit()
            }
        }
        get {
            return self.label?.text
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 5.0 {
        willSet {
            let size = newValue < 0 ? 1 : newValue
            self.fontSize = size
            self.label.font = self.label.font.withSize(self.fontSize)
        }
    }
    
    override init() {
        super.init()
        self.initializeItem()
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeItem()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.initializeItem()
        
    }
    
    private func initializeItem() {
        self.prefix = NSLocalizedString("Last backup", comment: "Prefix for last backup Today, 10:30")
        self.label = UILabel(frame: CGRect.zero)
        self.label.textAlignment = .center
        self.label.sizeToFit()
        self.customView = self.label
    }
}
