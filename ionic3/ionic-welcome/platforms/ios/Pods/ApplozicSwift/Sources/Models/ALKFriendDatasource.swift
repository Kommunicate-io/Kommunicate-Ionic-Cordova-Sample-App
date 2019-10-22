//
//  FriendDatasource.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

enum ALKDatasourceState {
    case full, filtered

    init(isInUsed: Bool) {
        if isInUsed {
            self = .filtered
        } else {
            self = .full
        }
    }
}

protocol ALKFriendDatasourceProtocol: AnyObject {
    func getDatasource(state: ALKDatasourceState) -> [ALKFriendViewModel]
    func count(state: ALKDatasourceState) -> Int
    func getItem(atIndex: Int, state: ALKDatasourceState) -> ALKFriendViewModel?
    func updateItem(item: ALKFriendViewModel, atIndex: Int, state: ALKDatasourceState)
    func update(datasource: [ALKFriendViewModel], state: ALKDatasourceState)
}

final class ALKFriendDatasource: ALKFriendDatasourceProtocol {
    private var filteredList = [ALKFriendViewModel]()
    private var friendList = [ALKFriendViewModel]()

    func getDatasource(state: ALKDatasourceState) -> [ALKFriendViewModel] {
        switch state {
        case .full:
            return friendList
        case .filtered:
            return filteredList
        }
    }

    func count(state: ALKDatasourceState) -> Int {
        switch state {
        case .full:
            return friendList.count
        case .filtered:
            return filteredList.count
        }
    }

    func getItem(atIndex: Int, state: ALKDatasourceState) -> ALKFriendViewModel? {
        let count = self.count(state: state)
        if count > atIndex {
            switch state {
            case .full:
                return friendList[atIndex]
            case .filtered:
                return filteredList[atIndex]
            }
        }
        return nil
    }

    func updateItem(item: ALKFriendViewModel, atIndex: Int, state: ALKDatasourceState) {
        let count = self.count(state: state)
        if count > atIndex {
            switch state {
            case .full:
                friendList[atIndex] = item
            case .filtered:
                filteredList[atIndex] = item
            }
        }
    }

    func update(datasource: [ALKFriendViewModel], state: ALKDatasourceState) {
        switch state {
        case .full:
            friendList = datasource
        case .filtered:
            filteredList = datasource
        }
    }
}
