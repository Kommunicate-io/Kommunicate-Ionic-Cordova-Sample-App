//
//  TypingNoticeView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

class TypingNotice: UIView, Localizable {
    fileprivate var localizedStringFileName: String!
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */

    private lazy var lblIsTyping: UILabel = {
        let isTypingString = localizedString(forKey: "IsTyping", withDefaultValue: SystemMessage.Message.isTyping, fileName: localizedStringFileName)
        let isTypingWidth: CGFloat = isTypingString.evaluateStringWidth(textToEvaluate: isTypingString, fontSize: 12)

        let lblIsTyping = UILabel(frame: .zero)

        lblIsTyping.font = UIFont(name: "HelveticaNeue-Italic", size: 12)!
        lblIsTyping.textColor = UIColor.lightGray
        lblIsTyping.text = isTypingString
        return lblIsTyping

    }()

    private var imgAnimate: UIImageView = {
        var animationImages = [UIImage]()
        for index in 0 ... 31 {
            var numStr = ""
            if index < 10 {
                numStr = "0"
            }

            if let img = UIImage(named: "animate-typing00\(numStr)\(index)", in: Bundle.applozic, compatibleWith: nil) {
                animationImages.append(img)
            }
        }

        let imgAnimate = UIImageView(frame: .zero)
        imgAnimate.contentMode = .scaleAspectFit
        imgAnimate.animationImages = animationImages
        imgAnimate.animationDuration = TimeInterval(1.3)
        imgAnimate.animationRepeatCount = 0
        imgAnimate.startAnimating()
        return imgAnimate

    }()

    init(localizedStringFileName: String) {
        super.init(frame: .zero)
        self.localizedStringFileName = localizedStringFileName
        createUI()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createUI() {
        clipsToBounds = false
        backgroundColor = UIColor.white

        addViewsForAutolayout(views: [lblIsTyping, imgAnimate])

        lblIsTyping.topAnchor.constraint(equalTo: topAnchor).isActive = true
        lblIsTyping.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        lblIsTyping.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lblIsTyping.widthAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        imgAnimate.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imgAnimate.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        imgAnimate.leadingAnchor.constraint(equalTo: lblIsTyping.trailingAnchor).isActive = true
        imgAnimate.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 0).isActive = true
        imgAnimate.widthAnchor.constraint(equalToConstant: 44).isActive = true
    }

    func setDisplayName(displayName: String) {
        guard !displayName.isEmpty else {
            return
        }
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            let isTyping = localizedString(forKey: "IsTypingForRTL", withDefaultValue: SystemMessage.Message.isTypingForRTL, fileName: localizedStringFileName)
            populateTypingStatus(isTyping: isTyping, displayName: displayName)
        } else {
            let isTyping = localizedString(forKey: "IsTyping", withDefaultValue: SystemMessage.Message.isTyping, fileName: localizedStringFileName)
            populateTypingStatus(isTyping: isTyping, displayName: displayName)
        }
    }

    func populateTypingStatus(isTyping: String, displayName: String) {
        if isTyping.contains("%@") {
            lblIsTyping.text = String(format: isTyping, displayName)
        } else {
            lblIsTyping.text = displayName + " " + isTyping
        }
    }

    func setDisplayGroupTyping(number: Int) {
        if number > 1 {
            let displayName = "\(number) people"
            let isTyping = localizedString(forKey: "AreTyping", withDefaultValue: SystemMessage.Message.areTyping, fileName: localizedStringFileName)
            populateTypingStatus(isTyping: isTyping, displayName: displayName)
        }
    }
}
