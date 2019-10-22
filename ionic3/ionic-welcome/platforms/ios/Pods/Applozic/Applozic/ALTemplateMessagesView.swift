//
//  ALTemplateMessagesView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import UIKit
import Foundation


/*
 It's responsible to display the template message buttons.
 Currently only textual messages are supported.
 A callback is sent, when any message is selected.
 */
@objc open class ALTemplateMessagesView: UIView {

    // MARK: Public properties
    
   @objc  open var viewModel: ALTemplateMessagesViewModel!

    @objc   public let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()

    /// Closure to be executed when a template message is selected
   @objc  open var messageSelected:((String)->())?

    //MARK: Intialization

   @objc public init(frame: CGRect, viewModel: ALTemplateMessagesViewModel) {
        super.init(frame: frame)
        self.viewModel = viewModel
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Private methods

    private func setupViews() {
        setupCollectionView()
    }

    private func setupCollectionView() {

        // Set datasource and delegate
        collectionView.dataSource = self
        collectionView.delegate = self

        // Register cells

        collectionView.register(ALTemplateMessageCell.self, forCellWithReuseIdentifier:"ALTemplateMessageCell")
        // Set constaints
        for view in [collectionView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(view)
        }

         if #available(iOS 9.0, *) {
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor,constant: 0).isActive = true
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor,constant: 0).isActive = true
            collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        }
        
    }

}

extension ALTemplateMessagesView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getNumberOfItemsIn(section: section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ALTemplateMessageCell = collectionView.dequeueReusableCell(withReuseIdentifier:"ALTemplateMessageCell", for: indexPath)
            as! ALTemplateMessageCell
        cell.update(text: viewModel.getTextForItemAt(row: indexPath.row) ?? "")
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedTemplate = viewModel.getTemplateForItemAt(row: indexPath.row) else {return}
      messageSelected?(selectedTemplate)

        //Send a notification (can be used outside the framework)
        let notificationCenter = NotificationCenter()
        notificationCenter.post(name: NSNotification.Name(rawValue: "TemplateMessageSelected"), object: selectedTemplate)

    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return viewModel.getSizeForItemAt(row: indexPath.row)
    }

}
