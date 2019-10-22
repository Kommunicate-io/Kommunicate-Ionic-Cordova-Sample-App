//
//  AlignedCollectionViewFlowLayout.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 22/02/19.
//

import UIKit

class TopAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)?
            .map { $0.copy() } as? [UICollectionViewLayoutAttributes]

        attributes?
            // Filter collectionView cells, not header,footer etc.
            .filter { $0.representedElementCategory == .cell }
            .reduce([:]) {
                // combine attributes to dictionary [CGFloat : Attribute],
                // where $0 is center y position and $1 is attribute.
                $0.merging([ceil($1.center.y): [$1]]) {
                    $0 + $1
                }
            }
            .values.forEach { line in
                /// Get y coordinate of cell with maximum height.
                let maxHeightY = line.max {
                    $0.frame.size.height < $1.frame.size.height
                }?.frame.origin.y

                /// Shift all the cells upwards using above y coordinate.
                line.forEach {
                    $0.frame = $0.frame.offsetBy(
                        dx: 0,
                        dy: (maxHeightY ?? $0.frame.origin.y) - $0.frame.origin.y
                    )
                }
            }
        return attributes
    }
}

class TopRightAlignedFlowLayout: TopAlignedFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)?
            .map { $0.copy() } as? [UICollectionViewLayoutAttributes]

        guard
            let collectionViewWidth = collectionView?.frame.size.width,
            let attribs = attributes,
            attribs.count == 1
        else {
            return attributes
        }

        /// Only 1 item is present. Align it to right.
        let safeWidth = collectionViewWidth - sectionInset.right
        /// safeWidth is the total accessible width of collectionView.
        /// To align right ::  Move frame's x position so that
        /// diff + `new_x_pos` + width = safeWidth
        attribs[0].frame.origin.x = safeWidth - attribs[0].frame.size.width
        return attribs
    }
}
