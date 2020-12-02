//
//  UISignUpButton.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 25.10.2020.
//

import UIKit

/// Custom extension UIButton class.
/// This class have embedded UIActivityIndicatorView for display activity that enables what isEnabled property set to false.
/// Of course this class support cornerRadius!
///     let button: UIRoundedButton

@IBDesignable
class UIRoundedButton: UIButton {
    private var activityIndicator: UIActivityIndicatorView!
    @IBInspectable var activityIndicatorColor: UIColor = .white
    @IBInspectable var cornerRadius: CGFloat = 2.0 {
        didSet {
            layer.cornerRadius = self.cornerRadius
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve) {
                if self.isEnabled {
                    self.alpha = 1.0
                    self.disableIndicator()
                }
                else {
                    self.alpha = 0.5
                    self.enableIndicator()
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeActivityIndicator()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeActivityIndicator()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.initializeActivityIndicator()
    }
    
    private func initializeActivityIndicator() {
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.activityIndicator.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.activityIndicator.color = self.activityIndicatorColor
        self.activityIndicator.isHidden = !self.isEnabled
        self.setTitle("", for: .disabled)
    }
    
    private func enableIndicator() {
        self.activityIndicator.startAnimating()
        self.addSubview(self.activityIndicator)
    }
    
    private func disableIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.removeFromSuperview()
    }
}
