//
//  ALKTemplateMessagesView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import UIKit

/*
 It's responsible to display the template message buttons.
 Currently only textual messages are supported.
 A callback is sent, when any message is selected.
 */
open class ALKTemplateMessagesView: UIView {
    // MARK: Public properties

    open var viewModel: ALKTemplateMessagesViewModel!

    open var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()

    /// Closure to be executed when a template message is selected
    open var messageSelected: ((ALKTemplateMessageModel) -> Void)?

    // MARK: Intialization

    public init(frame: CGRect, viewModel: ALKTemplateMessagesViewModel) {
        super.init(frame: frame)
        self.viewModel = viewModel
        setupViews()
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private methods

    private func setupViews() {
        setupCollectionView()
    }

    private func setupCollectionView() {
        // Set datasource and delegate
        collectionView.dataSource = self
        collectionView.delegate = self

        // Register cells
        collectionView.register(ALKTemplateMessageCell.self)

        // Set constaints
        addViewsForAutolayout(views: [collectionView])

        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

extension ALKTemplateMessagesView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getNumberOfItemsIn(section: section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ALKTemplateMessageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        cell.update(text: viewModel.getTextForItemAt(row: indexPath.row) ?? "")
        return cell
    }

    public func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedTemplate = viewModel.getTemplateForItemAt(row: indexPath.row) else { return }
        messageSelected?(selectedTemplate)

        // Send a notification (can be used outside the framework)
        let notificationCenter = NotificationCenter()
        notificationCenter.post(name: NSNotification.Name(rawValue: "TemplateMessageSelected"), object: selectedTemplate)
    }

    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return viewModel.getSizeForItemAt(row: indexPath.row)
    }
}
