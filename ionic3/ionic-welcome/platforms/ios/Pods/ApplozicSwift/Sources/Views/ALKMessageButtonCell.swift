//
//  ALKMessageButtonCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 10/01/19.
//

open class ALKMyMessageButtonCell: ALKChatBaseCell<ALKMessageViewModel> {
    var messageView = ALKMyMessageView()
    var buttonView = ButtonsView(frame: .zero)
    lazy var messageViewHeight = self.messageView.heightAnchor.constraint(equalToConstant: 0)

    override func setupViews() {
        super.setupViews()
        setupConstraints()
    }

    open func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        self.viewModel = viewModel
        let messageWidth = maxWidth -
            (ChatCellPadding.SentMessage.Message.left + ChatCellPadding.SentMessage.Message.right)
        let height = ALKMyMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        messageViewHeight.constant = height
        messageView.update(viewModel: viewModel)

        guard let dict = viewModel.payloadFromMetadata() else {
            layoutIfNeeded()
            return
        }
        let buttonWidth = maxWidth - (ChatCellPadding.SentMessage.MessageButton.left + ChatCellPadding.SentMessage.MessageButton.right)
        updateMessageButtonView(payload: dict, width: buttonWidth, heightOffset: height)
        layoutIfNeeded()
    }

    open override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let messageWidth = width -
            (ChatCellPadding.SentMessage.Message.left + ChatCellPadding.SentMessage.Message.right)
        let messageHeight = ALKMyMessageView.rowHeight(viewModel: viewModel, width: messageWidth)

        guard let dict = viewModel.payloadFromMetadata() else {
            return messageHeight + 10 // Paddding
        }
        let buttonWidth = width - (ChatCellPadding.SentMessage.MessageButton.left + ChatCellPadding.SentMessage.MessageButton.right)
        let buttonHeight = ButtonsView.rowHeight(payload: dict, maxWidth: buttonWidth)
        return messageHeight + buttonHeight + 20 // Padding between messages
    }

    private func setupConstraints() {
        contentView.addSubview(messageView)
        contentView.addSubview(buttonView)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ChatCellPadding.SentMessage.Message.left).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * ChatCellPadding.SentMessage.Message.right).isActive = true
        messageViewHeight.isActive = true
    }

    private func updateMessageButtonView(payload: [[String: Any]], width: CGFloat, heightOffset: CGFloat) {
        buttonView.maxWidth = width
        buttonView.stackViewAlignment = .trailing
        buttonView.update(payload: payload)

        buttonView.frame = CGRect(x: ChatCellPadding.SentMessage.MessageButton.left,
                                  y: heightOffset + ChatCellPadding.SentMessage.MessageButton.top,
                                  width: width,
                                  height: ButtonsView.rowHeight(payload: payload, maxWidth: width))
    }
}

class ALKFriendMessageButtonCell: ALKChatBaseCell<ALKMessageViewModel> {
    var messageView = ALKFriendMessageView()
    var buttonView = ButtonsView(frame: .zero)
    lazy var messageViewHeight = self.messageView.heightAnchor.constraint(equalToConstant: 0)

    override func setupViews() {
        super.setupViews()
        setupConstraints()
    }

    open func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        self.viewModel = viewModel
        let messageWidth = maxWidth -
            (ChatCellPadding.ReceivedMessage.Message.left + ChatCellPadding.ReceivedMessage.Message.right)
        let height = ALKFriendMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        messageViewHeight.constant = height
        messageView.update(viewModel: viewModel)

        guard let dict = viewModel.payloadFromMetadata() else {
            layoutIfNeeded()
            return
        }
        let buttonWidth = maxWidth - (ChatCellPadding.ReceivedMessage.MessageButton.left + ChatCellPadding.ReceivedMessage.MessageButton.right)
        updateMessageButtonView(payload: dict, width: buttonWidth, heightOffset: height)
        layoutIfNeeded()
    }

    open override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let messageWidth = width -
            (ChatCellPadding.ReceivedMessage.Message.left + ChatCellPadding.ReceivedMessage.Message.right)
        let messageHeight = ALKFriendMessageView.rowHeight(viewModel: viewModel, width: messageWidth)

        guard let dict = viewModel.payloadFromMetadata() else {
            return messageHeight + 10 // Paddding
        }
        let buttonWidth = width - (ChatCellPadding.ReceivedMessage.MessageButton.left + ChatCellPadding.ReceivedMessage.MessageButton.right)
        let buttonHeight = ButtonsView.rowHeight(payload: dict, maxWidth: buttonWidth)
        return messageHeight + buttonHeight + 20 // Padding between messages
    }

    private func setupConstraints() {
        contentView.addSubview(messageView)
        contentView.addSubview(buttonView)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ChatCellPadding.ReceivedMessage.Message.left).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * ChatCellPadding.ReceivedMessage.Message.right).isActive = true
        messageViewHeight.isActive = true
    }

    private func updateMessageButtonView(payload: [[String: Any]], width: CGFloat, heightOffset: CGFloat) {
        buttonView.maxWidth = width
        buttonView.stackViewAlignment = .leading
        buttonView.update(payload: payload)

        buttonView.frame = CGRect(x: ChatCellPadding.ReceivedMessage.MessageButton.left,
                                  y: heightOffset + ChatCellPadding.ReceivedMessage.MessageButton.top,
                                  width: width,
                                  height: ButtonsView.rowHeight(payload: payload, maxWidth: width))
    }
}
