//
//  ALKChatBar+AutoSuggestion.swift
//  ApplozicSwift
//
//  Created by Mukesh on 29/05/19.
//

import Foundation

extension ALKChatBar: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return filteredAutocompletionItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! =
            tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: UITableViewCell.reuseIdentifier)
        }

        guard indexPath.row < filteredAutocompletionItems.count else { return cell }
        let item = filteredAutocompletionItems[indexPath.row]
        cell.detailTextLabel?.setTextColor(.gray)
        cell.textLabel?.text = "/\(item.key)"
        cell.detailTextLabel?.text = "\(item.content)"
        return cell
    }

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = filteredAutocompletionItems[indexPath.row].content

        // If we replace the text here then it resizes the textview incorrectly.
        // That's why first resetting the text and then inserting the item content.
        textView.text = ""
        textView.insertText(text)
        updateTextViewHeight(textView: textView, text: text)
        hideAutoCompletionView()
    }
}

extension ALKChatBar {
    func itemsContaining(_ text: String, in list: [AutoCompleteItem]) -> [AutoCompleteItem] {
        return list.filter { $0.key.lowercased().contains(text) }
    }

    /// This will show items relevant to the text entered in quick reply view.
    /// NOTE: Pass everything other than the prefix, caller should consume the prefix.
    func updateAutocompletionFor(text: String) {
        if text.isEmpty {
            filteredAutocompletionItems = autoCompletionItems
        } else {
            filteredAutocompletionItems = itemsContaining(text, in: autoCompletionItems)
        }
        UIView.performWithoutAnimation {
            autocompletionView.reloadData()
        }
        showAutoCompletionView()
    }
}
