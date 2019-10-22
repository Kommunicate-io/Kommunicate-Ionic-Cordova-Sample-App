//
//  ALKContextTitleView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/12/17.
//

import Kingfisher
import UIKit

public protocol ALKContextTitleViewType {
    func configureWith(value: ALKContextTitleDataType)
    func setupUI()
}

open class ALKContextTitleView: UIView, ALKContextTitleViewType {
    private var viewModel: ALKContextTitleViewModelType?

    public let contextImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

    public let titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.setFont(UIFont.font(.normal(size: 14)))
        label.textColor = UIColor.white
        return label
    }()

    public let subtitleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.setFont(UIFont.font(.normal(size: 14)))
        label.textColor = UIColor.white
        return label
    }()

    public let topRightInfoLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.setFont(UIFont.font(.normal(size: 14)))
        label.contentMode = .right
        label.textColor = UIColor.white
        return label
    }()

    public let bottomRightInfoLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.setFont(UIFont.font(.normal(size: 14)))
        label.contentMode = .right
        label.textColor = UIColor.white
        return label
    }()

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    public func configureWith(value data: ALKContextTitleDataType) {
        viewModel = ALKContextTitleViewModel(data: data)
        setupUI()
    }

    open func setupUI() {
        let imageUrl = viewModel?.getTitleImageURL
        contextImageView.kf.setImage(with: imageUrl)
        titleLabel.text = viewModel?.getTitleText
        subtitleLabel.text = viewModel?.getSubtitleText
        topRightInfoLabel.text = viewModel?.getFirstKeyValuePairText
        bottomRightInfoLabel.text = viewModel?.getSecondKeyValuePairText
    }

    // MARK: - Private Methods

    private func setupConstraints() {
        let view = self
        view.addViewsForAutolayout(views: [contextImageView, titleLabel, subtitleLabel, topRightInfoLabel, bottomRightInfoLabel])
        contextImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        contextImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        contextImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        contextImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true

        titleLabel.leadingAnchor.constraint(equalTo: contextImageView.trailingAnchor, constant: 10).isActive = true
        titleLabel.topAnchor.constraint(equalTo: contextImageView.topAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: topRightInfoLabel.leadingAnchor, constant: -10).isActive = true
        titleLabel.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.3).isActive = true

        subtitleLabel.leadingAnchor.constraint(equalTo: contextImageView.trailingAnchor, constant: 10).isActive = true
        subtitleLabel.bottomAnchor.constraint(equalTo: contextImageView.bottomAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: bottomRightInfoLabel.leadingAnchor, constant: -10).isActive = true
        subtitleLabel.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 10).isActive = true

        topRightInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 10).isActive = true
        topRightInfoLabel.topAnchor.constraint(equalTo: contextImageView.topAnchor).isActive = true
        topRightInfoLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.4).isActive = true
        topRightInfoLabel.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.3).isActive = true

        bottomRightInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 10).isActive = true
        bottomRightInfoLabel.bottomAnchor.constraint(equalTo: contextImageView.bottomAnchor).isActive = true
        bottomRightInfoLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.4).isActive = true
        bottomRightInfoLabel.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.3).isActive = true
        view.layoutIfNeeded()
    }
}
