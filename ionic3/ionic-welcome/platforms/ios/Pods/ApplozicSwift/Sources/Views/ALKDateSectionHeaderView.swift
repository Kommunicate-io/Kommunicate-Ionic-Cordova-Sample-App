//
//  DateSectionHeaderView.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

class ALKDateSectionHeaderView: UIView {
    // MARK: - Variables and Types

    // MARK: ChatDate

    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var dateView: UIView! {
        didSet {
            dateView.layer.cornerRadius = dateView.frame.size.height / 2.0
        }
    }

    // MARK: - Lifecycle

    class func instanceFromNib() -> ALKDateSectionHeaderView {
        guard let view = UINib(nibName: ALKDateSectionHeaderView.nibName, bundle: Bundle.applozic).instantiate(withOwner: nil, options: nil).first as? ALKDateSectionHeaderView else {
            fatalError("\(ALKDateSectionHeaderView.nibName) don't existing")
        }
        return view
    }

    // MARK: - Methods of class

    // MARK: ChatDate

    func setupDate(withDateFormat date: String) {
        dateLabel.text = date
    }
}
