//
//  UIButton+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 19/03/19.
//

import MGSwipeTableCell

extension MGSwipeButton {
    func alignVertically(padding _: CGFloat = 10.0) {
        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
            alignVerticalRTL()
        } else {
            alignVerticalLTR()
        }
    }

    private func alignVerticalLTR(padding: CGFloat = 10.0) {
        guard let imageViewSize = self.imageView?.bounds.size else { return }
        titleLabel?.font = UIFont.systemFont(ofSize: 14)
        imageEdgeInsets = UIEdgeInsets(
            top: -padding,
            left: (bounds.size.width - imageViewSize.width) / 2,
            bottom: padding,
            right: (bounds.size.width - imageViewSize.width) / 2
        )
        titleEdgeInsets = UIEdgeInsets(
            top: imageViewSize.height + padding,
            left: -imageViewSize.width,
            bottom: 0.0,
            right: 0.0
        )
    }

    private func alignVerticalRTL(padding: CGFloat = 10.0) {
        guard let imageViewSize = self.imageView?.bounds.size else { return }
        titleLabel?.font = UIFont.systemFont(ofSize: 14)
        imageEdgeInsets = UIEdgeInsets(
            top: -padding,
            left: 5.0,
            bottom: 0.0,
            right: (bounds.size.width - imageViewSize.width) / 2
        )
        let text = NSString(string: titleLabel!.text!)
        let textSize = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        titleEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: 0,
            bottom: -(imageViewSize.height + padding),
            right: -((bounds.size.width - textSize.width) / 2)
        )
    }
}
