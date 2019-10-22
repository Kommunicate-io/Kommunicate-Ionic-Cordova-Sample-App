//
//  ALKPreviewImageViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

final class ALKPreviewImageViewModel: NSObject, Localizable {
    var localizedStringFileName: String

    var imageUrl: URL
    private var savingImagesuccessBlock: (() -> Void)?
    private var savingImagefailBlock: ((Error) -> Void)?

    fileprivate var downloadImageSuccessBlock: (() -> Void)?
    fileprivate var downloadImageFailBlock: ((String) -> Void)?

    fileprivate lazy var loadingFailErrorMessage: String = {
        let text = localizedString(
            forKey: "DownloadOriginalImageFail",
            withDefaultValue: SystemMessage.Warning.DownloadOriginalImageFail,
            fileName: localizedStringFileName
        )
        return text
    }()

    init(imageUrl: URL, localizedStringFileName: String) {
        self.localizedStringFileName = localizedStringFileName
        self.imageUrl = imageUrl
    }

    func saveImage(image: UIImage?, successBlock: @escaping () -> Void, failBlock: @escaping (Error) -> Void) {
        savingImagesuccessBlock = successBlock
        savingImagefailBlock = failBlock

        guard let image = image else {
            failBlock(NSError(domain: "IMAGE_NOT_AVAILABLE", code: 0, userInfo: nil))
            return
        }

        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(ALKPreviewImageViewModel.image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc func image(_: UIImage, didFinishSavingWithError error: Error?, contextInfo _: UnsafeRawPointer) {
        if let error = error, let failBlock = savingImagefailBlock {
            failBlock(error)
        } else if let successBlock = savingImagesuccessBlock {
            successBlock()
        }
    }
}
