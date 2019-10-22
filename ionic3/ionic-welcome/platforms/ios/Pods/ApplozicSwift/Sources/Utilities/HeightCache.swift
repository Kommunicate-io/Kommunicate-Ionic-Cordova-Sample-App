//
//  HeightCache.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 12/04/19.
//

import Foundation

/// A Utility to cache height for messages.
class HeightCache {
    /// Wrapper around CGFloat as NSCache only accepts class not structs.
    private class Float {
        let value: CGFloat
        init(_ value: CGFloat) {
            self.value = value
        }
    }

    static let shared = HeightCache()
    private let cache = NSCache<NSString, Float>()

    private init() {
        cache.name = "MessageHeightCache"
    }

    func setHeight(_ height: CGFloat, for key: String) {
        cache.setObject(Float(height), forKey: key as NSString)
    }

    func getHeight(for key: String) -> CGFloat? {
        guard let height = cache.object(forKey: key as NSString) else {
            return nil
        }
        return height.value
    }
}
