//
//  ALKMyContactMessageCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 16/04/19.
//

import Applozic

class ALKMyContactMessageCell: ALKContactMessageBaseCell {
    struct Padding {
        struct StateView {
            static let width: CGFloat = 17.0
            static let height: CGFloat = 9.0
            static let bottom: CGFloat = 1
            static let right: CGFloat = 2
        }

        struct TimeLabel {
            static let right: CGFloat = 2
            static let bottom: CGFloat = 2
        }

        struct ContactView {
            static let multiplier: CGFloat = 0.5
            static let right: CGFloat = 10
        }
    }

    fileprivate var timeLabel = UILabel(frame: .zero)

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    override func setupViews() {
        setupConstraints()
    }

    override func update(viewModel: ALKMessageViewModel) {
        loadingIndicator.startLoading(localizationFileName: localizedStringFileName)
        contactView.isHidden = true
        if let filePath = viewModel.filePath {
            updateContactDetails(key: viewModel.identifier, filePath: filePath)
        }
        timeLabel.text = viewModel.time
        timeLabel.setStyle(ALKMessageStyle.time)

        // Set read status
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
        contactView.setColorIn(
            text: ALKMessageStyle.sentMessage.text,
            background: ALKMessageStyle.sentBubble.color
        )
    }

    class func rowHeight() -> CGFloat {
        var height = ContactView.height()
        height += max(Padding.StateView.bottom, Padding.TimeLabel.bottom)
        return height + 5 // Extra padding
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [contactView, timeLabel, stateView, loadingIndicator])
        contentView.bringSubviewToFront(loadingIndicator)

        contactView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.ContactView.right).isActive = true
        contactView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Padding.ContactView.multiplier).isActive = true
        contactView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contactView.heightAnchor.constraint(equalToConstant: ContactView.height()).isActive = true

        loadingIndicator.trailingAnchor.constraint(equalTo: contactView.trailingAnchor).isActive = true
        loadingIndicator.topAnchor.constraint(equalTo: contactView.topAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: contactView.bottomAnchor).isActive = true
        loadingIndicator.leadingAnchor.constraint(equalTo: contactView.leadingAnchor).isActive = true

        stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contactView.bottomAnchor, constant: -1 * Padding.StateView.bottom).isActive = true
        stateView.trailingAnchor.constraint(equalTo: contactView.leadingAnchor, constant: -1 * Padding.StateView.right).isActive = true

        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1 * Padding.TimeLabel.right).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contactView.bottomAnchor, constant: Padding.TimeLabel.bottom).isActive = true
    }
}
