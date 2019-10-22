//
//  ALKFriendGenericCardCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 05/12/18.
//

import Applozic
import Foundation

open class ALKFriendGenericCardCell: ALKGenericCardBaseCell {
    var messageView = ALKFriendMessageView()
    lazy var messageViewHeight = self.messageView.heightAnchor.constraint(equalToConstant: 0)

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func update(viewModel: ALKMessageViewModel, width: CGFloat) {
        messageView.update(viewModel: viewModel)
        let messageWidth = width - (ChatCellPadding.ReceivedMessage.Message.left +
            ChatCellPadding.ReceivedMessage.Message.right)
        let height = ALKFriendMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        messageViewHeight.constant = height
        layoutIfNeeded()

        super.update(viewModel: viewModel, width: width)
    }

    override func setupViews() {
        setupCollectionView()

        contentView.addViewsForAutolayout(views: [self.collectionView, self.messageView])
        contentView.bringSubviewToFront(messageView)

        let leftPadding = ChatCellPadding.ReceivedMessage.Message.left
        let rightPadding = ChatCellPadding.ReceivedMessage.Message.right
        messageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leftPadding).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * rightPadding).isActive = true
        messageViewHeight.isActive = true

        let width = CGFloat(ALKMessageStyle.receivedBubble.widthPadding)
        let templateLeftPadding = leftPadding + 64 - width

        collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: templateLeftPadding).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: ALKFriendGenericCardCell.cardTopPadding).isActive = true
        collectionView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.collectionView.rawValue).isActive = true
    }

    open override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let messageWidth = width - (ChatCellPadding.ReceivedMessage.Message.left +
            ChatCellPadding.ReceivedMessage.Message.right)
        let messageHeight = ALKFriendMessageView.rowHeight(viewModel: viewModel, width: messageWidth)
        let cardHeight = super.cardHeightFor(message: viewModel, width: width)
        return cardHeight + messageHeight + 10 // Extra 10 below complete view. Modify this for club/unclub.
    }

    private func setupCollectionView() {
        let layout: TopAlignedFlowLayout = TopAlignedFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        collectionView = ALKGenericCardCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
    }
}
