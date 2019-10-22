//
//  ALChannel.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//  this clss will decide wether go client or groupdb service

#import <Foundation/Foundation.h>
#import <CoreData/NSManagedObject.h>
#import "ALJson.h"
#import "ALConversationProxy.h"

#define CHANNEL_SPECIAL_CASE 7
#define CHANNEL_DEFAULT_MUTE @"MUTE"
#define CHANNEL_CONVERSATION_STATUS @"CONVERSATION_STATUS"

static NSString *const AL_CATEGORY = @"AL_CATEGORY";
static NSString * const AL_CONTEXT_BASED_CHAT = @"AL_CONTEXT_BASED_CHAT";
static NSString * const CONVERSATION_ASSIGNEE = @"CONVERSATION_ASSIGNEE";

/*********************
 type = 7 SPECIAL CASE
*********************/

typedef enum
{
    VIRTUAL = 0,
    PRIVATE = 1,
    PUBLIC = 2,
    SELLER = 3,
    SELF = 4,
    BROADCAST = 5,
    OPEN = 6,
    GROUP_OF_TWO = 7,
    CONTACT_GROUP = 9,
    SUPPORT_GROUP = 10,
    BROADCAST_ONE_BY_ONE = 106
} CHANNEL_TYPE;

typedef enum {
    ALL_CONVERSATION = 0,
    ASSIGNED_CONVERSATION = 1,
    CLOSED_CONVERSATION = 3
} CONVERSATION_CATEGORY;

@interface ALChannel : ALJson

@property (nonatomic, strong) NSNumber *key;
@property (nonatomic, strong) NSString *clientChannelKey;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *channelImageURL;
@property (nonatomic, strong) NSString *adminKey;
@property (nonatomic) short type;
@property (nonatomic, strong) NSNumber *userCount;
@property (nonatomic, strong) NSNumber *unreadCount;
@property (nonatomic, copy) NSManagedObjectID *channelDBObjectId;
@property (nonatomic, strong) NSMutableArray *membersName;
@property (nonatomic, strong) NSMutableArray *membersId;
@property (nonatomic, strong) NSMutableArray *removeMembers;
@property (nonatomic, strong) ALConversationProxy *conversationProxy;
@property (nonatomic, strong) NSNumber *parentKey;
@property (nonatomic, strong) NSString *parentClientKey;
@property (nonatomic, strong) NSMutableArray * groupUsers;
@property (nonatomic, strong) NSMutableArray * childKeys;
@property (nonatomic, strong) NSNumber * notificationAfterTime;
@property (nonatomic, strong) NSNumber * deletedAtTime;
@property (nonatomic, strong) NSMutableDictionary * metadata;
/// This is used to categorize the channel based on the metadata value for `CONVERSATION_CATEGORY`
@property (nonatomic) short category;

-(id)initWithDictonary:(NSDictionary *)messageDictonary;
-(void)parseMessage:(id) messageJson;
-(NSNumber *)getChannelMemberParentKey:(NSString *)userId;
-(BOOL) isNotificationMuted;
-(BOOL) isConversationClosed;
-(BOOL) isContextBasedChat;
-(BOOL) isBroadcastGroup;
-(NSString*)getReceiverIdInGroupOfTwo;

-(NSMutableDictionary *)getMetaDataDictionary:(NSString *)string;
-(BOOL)isPartOfCategory:(NSString*)category;

+(CONVERSATION_CATEGORY)getConversationCategory:(NSDictionary *)metadata;

@end
