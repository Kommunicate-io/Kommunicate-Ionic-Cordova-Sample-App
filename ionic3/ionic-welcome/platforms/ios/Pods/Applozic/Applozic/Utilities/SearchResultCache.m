//
//  SearchResultCache.m
//  Applozic
//
//  Created by Shivam Pokhriyal on 02/07/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SearchResultCache.h"

@implementation SearchResultCache

static SearchResultCache *sharedInstance = nil;
NSCache<NSNumber *, ALChannel *> *channelCache;
NSCache<NSString *, ALContact *> *contactCache;

+ (SearchResultCache *)shared {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        sharedInstance = [[SearchResultCache alloc] init];
        channelCache = [[NSCache alloc] init];
        contactCache = [[NSCache alloc] init];
    });
    return sharedInstance;
}

- (void)saveChannels:(NSMutableArray<ALChannel *> *)channels {
    for (ALChannel *channel in channels) {
        [channelCache setObject:channel forKey:channel.key];
    }
}

- (void)saveUserDetails:(NSMutableArray<ALUserDetail *> *)userDetails {
    for (ALUserDetail *userDetail in userDetails) {
        ALContact *contact = [self parseUserDetail: userDetail];
        [contactCache setObject: contact forKey: contact.userId];
    }
}

-(ALContact *) parseUserDetail: (ALUserDetail *) userDetail {
    ALContact * contact = [[ALContact alloc] init];
    contact.userId = userDetail.userId;
    contact.connected = userDetail.connected;
    contact.lastSeenAt = userDetail.lastSeenAtTime;
    contact.unreadCount = userDetail.unreadCount;
    contact.displayName = userDetail.displayName;
    contact.contactImageUrl = userDetail.imageLink;
    contact.contactNumber = userDetail.contactNumber;
    contact.userStatus = userDetail.userStatus;
    contact.userTypeId = userDetail.userTypeId;
    contact.deletedAtTime = userDetail.deletedAtTime;
    contact.roleType = userDetail.roleType;
    contact.metadata = userDetail.metadata;

    if(userDetail.notificationAfterTime && [userDetail.notificationAfterTime longValue]>0){
        contact.notificationAfterTime = userDetail.notificationAfterTime;
    }
    return contact;
}

- (ALChannel *)getChannelWithId:(NSNumber *)key {
    return [channelCache objectForKey: key];
}

- (ALContact *)getContactWithId:(NSString *)key {
    return [contactCache objectForKey: key];
}

@end
