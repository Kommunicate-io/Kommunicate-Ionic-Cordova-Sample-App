//
//  ALChannelInfo.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"

@interface ALChannelInfo : ALJson

@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSString *clientGroupId;
@property (nonatomic, strong) NSMutableArray *groupMemberList;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) NSString *admin;
@property (nonatomic, strong) NSString *parentClientGroupId;
@property (nonatomic, strong) NSNumber *parentKey;
@property(nonatomic) short type;
@property (nonatomic, strong) NSMutableDictionary *metadata;
@property (nonatomic, strong) NSMutableArray *groupRoleUsers;

@end
