//
//  ALKMyDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import Applozic
import Foundation
import Kingfisher
import UIKit

class ALKMyDocumentCell: ALKDocumentCell {
    struct Padding {
        struct StateView {
            static let trailing: CGFloat = 2
            static let bottom: CGFloat = 1
            static let height: CGFloat = 9
            static let width: CGFloat = 17
        }

        struct AvatarImageView {
            static let top: CGFloat = 18
            static let leading: CGFloat = 9
            static let height: CGFloat = 37
        }

        struct TimeLabel {
            static let trailing: CGFloat = 2
            static let bottom: CGFloat = 0
        }

        struct BubbleView {
            static let top: CGFloat = 10
            static let leading: CGFloat = 57
            static let bottom: CGFloat = 7
            static let trailing: CGFloat = 14
        }
    }

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [timeLabel, stateView])
        stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height).isActive = true
        stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -Padding.StateView.bottom).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -Padding.StateView.trailing).isActive = true

        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -Padding.TimeLabel.trailing).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.TimeLabel.bottom).isActive = true

        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.BubbleView.top).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.BubbleView.leading).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.BubbleView.trailing).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.BubbleView.bottom).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        if viewModel.isAllRead {
            stateView.image = UIImage(named: "read_state_3", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor(netHex: 0x0578FF)
        } else if viewModel.isAllReceived {
            stateView.image = UIImage(named: "read_state_2", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = nil
        } else if viewModel.isSent {
            stateView.image = UIImage(named: "read_state_1", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = nil
        } else {
            stateView.image = UIImage(named: "seen_state_0", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.red
        }
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
        bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
    }

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.BubbleView.bottom + Padding.BubbleView.top
    }

    override class func rowHeigh(viewModel _: ALKMessageViewModel, width _: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 0
        var messageHeight: CGFloat = 0.0
        messageHeight += heightPadding()
        return max(messageHeight, minimumHeight)
    }
}
