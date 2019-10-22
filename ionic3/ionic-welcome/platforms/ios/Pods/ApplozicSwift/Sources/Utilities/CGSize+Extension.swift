//
//  CGSize+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension CGSize {
    static func getSizeAndScaleNotMoreThan(_ originalSize: CGSize, maximumSize: CGSize, aspectRatio _: Bool) -> (CGSize, CGFloat) {
        if maximumSize.width < originalSize.width || maximumSize.height < originalSize.height {
            var scaleFactor: CGFloat = 0.0

            if originalSize.width < originalSize.height { // vertical
                scaleFactor = maximumSize.height / originalSize.height
            } else { // horizontal or square
                scaleFactor = maximumSize.width / originalSize.width
            }

            // it should be multiply of 16 or 8 or 4. you can see link:
            // http://stackoverflow.com/questions/22883525/avassetexportsession-giving-me-a-green-border-on-right-and-bottom-of-output-vide
            let overlapHeigth = (originalSize.height * scaleFactor).truncatingRemainder(dividingBy: 4.0)
            let overlapWidth = (originalSize.width * scaleFactor).truncatingRemainder(dividingBy: 4.0)

            let newHeigth = (originalSize.height * scaleFactor) - overlapHeigth
            let newWidth = (originalSize.width * scaleFactor) - overlapWidth

            return (CGSize(width: newWidth, height: newHeigth), scaleFactor)
        }

        var scaleFactor: CGFloat = (originalSize.width < originalSize.height) ? (originalSize.height / originalSize.width) : (originalSize.width / originalSize.height)
        scaleFactor = (scaleFactor >= 1.0) ? 1.0 : scaleFactor

        return (originalSize, scaleFactor)
    }
}
