//
//  ALKDownloadTask.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 15/11/17.
//

import Foundation

public class ALKDownloadTask {
    var urlString: String?
    public var completed: Bool = false
    internal var totalBytesDownloaded: Int64 = 0
    internal var totalBytesExpectedToDownload: Int64 = 0

    internal var isDownloading = false
    public var fileName: String?
    public var contentType: String?
    public var downloadError: Error?
    public var identifier: String?
    public var filePath: String?

    public init(downloadUrl url: String, fileName: String?) {
        urlString = url
        self.fileName = fileName
    }
}
