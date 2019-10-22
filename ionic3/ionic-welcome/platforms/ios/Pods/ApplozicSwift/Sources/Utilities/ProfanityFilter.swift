//
//  ProfanityFilter.swift
//  ApplozicSwift
//
//  Created by Mukesh on 10/04/19.
//

import Foundation

struct ProfanityFilter {
    enum Errors: Error {
        case fileNotFoundError
        case formattingError
    }

    let fileName: String?
    let restrictedMessageRegex: String?
    var restrictedWords = Set<String>()

    let bundle: Bundle

    private init(
        fileName: String?,
        messageRegex: String?,
        bundle: Bundle
    ) throws {
        self.fileName = fileName
        restrictedMessageRegex = messageRegex
        self.bundle = bundle

        guard let fileName = fileName else { return }
        do {
            restrictedWords = try restrictedWords(fileName: fileName)
        } catch {
            throw error
        }
    }

    func restrictedWords(fileName: String) throws -> Set<String> {
        var words = Set<String>()

        guard let fileURL = bundle.url(
            forResource: fileName,
            withExtension: "txt"
        ) else {
            throw Errors.fileNotFoundError
        }
        guard let wordText = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw Errors.formattingError
        }
        words = Set(wordText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        return words
    }

    func containsRestrictedWords(text: String) -> Bool {
        let wordsInText = text.lowercased().components(separatedBy: " ")
        var isPresent = false
        for word in wordsInText {
            isPresent = restrictedWords.contains(word)
            if isPresent { return true }
        }

        // If not present in the restricted words then match the text
        // against the pattern.
        if let restrictedMessagePattern = restrictedMessageRegex {
            let range = NSRange(text.startIndex ..< text.endIndex, in: text)
            do {
                let regex = try NSRegularExpression(pattern: restrictedMessagePattern, options: [])
                let matches = regex.numberOfMatches(in: text, options: [], range: range)
                print("Restricted text matches: \(matches)")
                if matches > 0 { isPresent = true }
            } catch {
                print("Error while matching restricted text: \(error.localizedDescription)")
            }
        }
        return isPresent
    }
}

extension ProfanityFilter {
    init(fileName: String, bundle: Bundle = .main) throws {
        try self.init(fileName: fileName, messageRegex: nil, bundle: bundle)
    }

    init(restrictedMessageRegex: String, bundle: Bundle = .main) throws {
        try self.init(fileName: nil, messageRegex: restrictedMessageRegex, bundle: bundle)
    }

    init(fileName: String, restrictedMessageRegex: String, bundle: Bundle = .main) throws {
        try self.init(fileName: fileName, messageRegex: restrictedMessageRegex, bundle: bundle)
    }
}
