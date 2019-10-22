//
//  ALKDownloadTask.swift
//  Applozic
//
//  Created by Mukesh Thawani on 08/11/17.
//

import Foundation

public class ALKUploadTask {
    let url: URL?
    public var completed: Bool = false
    internal var totalBytesUploaded: Int64 = 0
    internal var totalBytesExpectedToUpload: Int64 = 0

    internal var isUploading = false
    public var fileName: String?
    public var contentType: String?
    public var uploadError: Error?
    public var filePath: String?
    public var identifier: String?

    public init(url: URL, fileName: String) {
        self.url = url
        self.fileName = fileName
    }
}
