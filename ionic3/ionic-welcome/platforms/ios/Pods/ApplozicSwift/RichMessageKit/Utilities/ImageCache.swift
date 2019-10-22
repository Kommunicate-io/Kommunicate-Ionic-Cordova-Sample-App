//
//  ImageCache.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 21/01/19.
//

import UIKit

class ImageCache {
    static let cache = NSCache<NSString, AnyObject>()

    static func downloadImage(url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        // Check if image is present in cache
        guard let imageFromCache = cache.object(forKey: url.absoluteString as NSString) as? UIImage else {
            // Download image and store in cache
            URLSession.shared.dataTask(with: url) {
                data, _, error in
                guard let data = data, let image = UIImage(data: data) else {
                    print("Error downloading image \(String(describing: error))")
                    completion(nil)
                    return
                }
                cache.setObject(image, forKey: url.absoluteString as NSString)
                completion(image)
            }.resume()
            return
        }

        completion(imageFromCache)
    }
}
