//
//  ALKListTemplateCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 18/02/19.
//

import UIKit

// MARK: - `ALKListTemplateCell` for sender side.

public class ALKMyListTemplateCell: ALKListTemplateCell {
    var messageView = ALKMyMessageView()
    lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)

    public override func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        let messageWidth = maxWidth -
            (ChatCellPadding.SentMessage.Message.left + ChatCellPadding.SentMessage.Message.right)
        let height = ALKMyMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        messageViewHeight.constant = height
        messageView.update(viewModel: viewModel)
        super.update(viewModel: viewModel, maxWidth: maxWidth)
    }

    public override class func rowHeight(viewModel: ALKMessageViewModel, maxWidth: CGFloat) -> CGFloat {
        let messageWidth = maxWidth -
            (ChatCellPadding.SentMessage.Message.left + ChatCellPadding.SentMessage.Message.right)
        let height = ALKMyMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        let templateHeight = super.rowHeight(viewModel: viewModel, maxWidth: maxWidth)
        return height + templateHeight + paddingBelowCell
    }

    override func setupConstraints() {
        let leftPadding = ChatCellPadding.SentMessage.Message.left
        let rightPadding = ChatCellPadding.SentMessage.Message.right
        contentView.addViewsForAutolayout(views: [messageView, listTemplateView])
        messageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leftPadding).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * rightPadding).isActive = true
        messageViewHeight.isActive = true

        let width = CGFloat(ALKMessageStyle.sentBubble.widthPadding)
        let templateLeftPadding = leftPadding + width
        let templateRightPadding = rightPadding - width
        listTemplateView.topAnchor.constraint(equalTo: messageView.bottomAnchor).isActive = true
        listTemplateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: templateLeftPadding).isActive = true
        listTemplateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * templateRightPadding).isActive = true
        listTemplateHeight.isActive = true
    }
}

// MARK: - `ALKListTemplateCell` for receiver side.

public class ALKFriendListTemplateCell: ALKListTemplateCell {
    var messageView = ALKFriendMessageView()
    lazy var messageViewHeight = self.messageView.heightAnchor.constraint(equalToConstant: 0)

    public override func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        let messageWidth = maxWidth -
            (ChatCellPadding.ReceivedMessage.Message.left + ChatCellPadding.ReceivedMessage.Message.right)
        let height = ALKFriendMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        messageViewHeight.constant = height
        messageView.update(viewModel: viewModel)
        super.update(viewModel: viewModel, maxWidth: maxWidth)
    }

    public override class func rowHeight(viewModel: ALKMessageViewModel,
                                         maxWidth: CGFloat) -> CGFloat {
        let messageWidth = maxWidth -
            (ChatCellPadding.ReceivedMessage.Message.left + ChatCellPadding.ReceivedMessage.Message.right)
        let height = ALKFriendMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        let templateHeight = super.rowHeight(viewModel: viewModel, maxWidth: maxWidth)
        return height + templateHeight + paddingBelowCell + 5 // Padding between messages
    }

    override func setupConstraints() {
        contentView.addViewsForAutolayout(views: [messageView, listTemplateView])

        let leftPadding = ChatCellPadding.ReceivedMessage.Message.left
        let rightPadding = ChatCellPadding.ReceivedMessage.Message.right
        messageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ChatCellPadding.ReceivedMessage.Message.top).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leftPadding).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * rightPadding).isActive = true
        messageViewHeight.isActive = true

        let width = CGFloat(ALKMessageStyle.receivedBubble.widthPadding)
        let templateLeftPadding = leftPadding + 64 - width
        let templateRightPadding = rightPadding - width
        listTemplateView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 5).isActive = true
        listTemplateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: templateLeftPadding).isActive = true
        listTemplateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * templateRightPadding).isActive = true
        listTemplateHeight.isActive = true
    }
}

// MARK: - `ALKListTemplateCell`

public class ALKListTemplateCell: ALKChatBaseCell<ALKMessageViewModel> {
    static var paddingBelowCell: CGFloat = 10

    var listTemplateView: ListTemplateView = {
        let view = ListTemplateView(frame: .zero)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()

    lazy var listTemplateHeight = listTemplateView.heightAnchor.constraint(equalToConstant: 0)

    public var templateSelected: ((_ text: String?, _ action: ListTemplate.Action) -> Void)? {
        didSet {
            listTemplateView.selected = templateSelected
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(viewModel: ALKMessageViewModel, maxWidth _: CGFloat) {
        guard let metadata = viewModel.metadata,
            let template = try? TemplateDecoder.decode(ListTemplate.self, from: metadata) else {
            listTemplateView.isHidden = true
            layoutIfNeeded()
            return
        }
        listTemplateView.isHidden = false
        listTemplateView.update(item: template)
        listTemplateHeight.constant = ListTemplateView.rowHeight(template: template)
        layoutIfNeeded()
    }

    public class func rowHeight(viewModel: ALKMessageViewModel, maxWidth _: CGFloat) -> CGFloat {
        guard let metadata = viewModel.metadata,
            let template = try? TemplateDecoder.decode(ListTemplate.self, from: metadata) else {
            return CGFloat(0)
        }
        return ListTemplateView.rowHeight(template: template)
    }

    func setupConstraints() {
        fatalError("This method must be overriden.")
    }
}
