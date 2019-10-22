//
//  TextViewSizeCalcultor.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 12/06/19.
//

import UIKit

/// This is used since boundingRect method doesn't give accurate size for TextView.
/// Here we use sizeThatFits of textView.
struct TextViewSizeCalculator {
    static func height(_ textView: UITextView,
                       text: String,
                       maxWidth: CGFloat) -> CGFloat {
        textView.text = text
        let size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        return ceil(size.height)
    }

    static func height(_ textView: UITextView,
                       attributedText: NSAttributedString,
                       maxWidth: CGFloat) -> CGFloat {
        textView.attributedText = attributedText
        let size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        return ceil(size.height)
    }
}
