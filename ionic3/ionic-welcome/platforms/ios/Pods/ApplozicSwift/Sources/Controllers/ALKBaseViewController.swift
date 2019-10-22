//
//  ALKBaseViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Applozic
import UIKit

open class ALKBaseViewController: UIViewController, ALKConfigurable {
    public var configuration: ALKConfiguration!

    public required init(configuration: ALKConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        addObserver()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NSLog("🐸 \(#function) 🍀🍀 \(self) 🐥🐥🐥🐥")
        addObserver()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = configuration.navigationBarBackgroundColor
        navigationController?.navigationBar.tintColor = configuration.navigationBarItemColor

        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: configuration.navigationBarTitleColor]

        navigationController?.navigationBar.isTranslucent = false
        if navigationController?.viewControllers.first != self {
            var backImage = UIImage(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
            backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backTapped))
        }
        if configuration.hideNavigationBarBottomLine {
            navigationController?.navigationBar.hideBottomHairline()
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        checkPricingPackage()
    }

    @objc func backTapped() {
        _ = navigationController?.popViewController(animated: true)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSLog("🐸 \(#function) 🍀🍀 \(self) 🐥🐥🐥🐥")
        addObserver()
    }

    func addObserver() {}

    func removeObserver() {}

    deinit {
        removeObserver()
        NSLog("💩 \(#function) ❌❌ \(self)‼️‼️‼️‼️")
    }

    func checkPricingPackage() {
        if ALApplicationInfo().isChatSuspended() {
            showAccountSuspensionView()
        }
    }

    func showAccountSuspensionView() {}
}
