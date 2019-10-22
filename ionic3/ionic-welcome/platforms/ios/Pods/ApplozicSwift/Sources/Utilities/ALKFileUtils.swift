//
//  ALKFileUtils.swift
//  ApplozicSwift
//
//  Created by Sunil on 14/03/19.
//

import Applozic
import Foundation

class ALKFileUtils: NSObject {
    func getFileName(filePath: String?, fileMeta: ALFileMetaInfo?) -> String {
        guard let fileMetaInfo = fileMeta, let fileName = fileMetaInfo.name else {
            guard let localPathName = filePath else {
                return ""
            }
            return (localPathName as NSString).lastPathComponent as String
        }
        return fileName
    }

    func getFileSize(filePath: String?, fileMetaInfo: ALFileMetaInfo?) -> String? {
        guard let fileName = filePath else {
            return fileMetaInfo?.getTheSize()
        }

        let filePath = getDocumentDirectory(fileName: fileName).path

        guard let size = try? FileManager.default.attributesOfItem(atPath: filePath)[FileAttributeKey.size], let fileSize = size as? UInt64
        else {
            return ""
        }
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return String(format: "%.1f KB", floatSize)
        }

        floatSize /= 1024
        if floatSize < 1023 {
            return String(format: "%.1f MB", floatSize)
        }

        floatSize /= 1024
        return String(format: "%.1f GB", floatSize)
    }

    func getFileExtenion(filePath: String?, fileMeta: ALFileMetaInfo?) -> String {
        guard let localPathName = filePath else {
            guard let fileMetaInfo = fileMeta, let name = fileMetaInfo.name, let pathExtension = URL(string: name)?.pathExtension else {
                return ""
            }
            return pathExtension
        }
        return getDocumentDirectory(fileName: localPathName).pathExtension
    }

    func getDocumentDirectory(fileName: String) -> URL {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docDirPath.appendingPathComponent(fileName)
    }

    func isSupportedFileType(filePath: String?) -> Bool {
        guard filePath != nil else {
            return false
        }

        let pathExtension = getDocumentDirectory(fileName: filePath ?? "").pathExtension
        let fileTypes = ["docx", "pdf", "doc", "java", "js", "txt", "html", "xlsx", "xls", "ppt", "pptx"]
        return fileTypes.contains(pathExtension)
    }
}
