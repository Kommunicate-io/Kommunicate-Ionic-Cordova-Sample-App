//
//  ALChannelService.h
//  Applozic
//
//  Created by devashish on 04/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#define AL_CREATE_GROUP_MESSAGE @"CREATE_GROUP_MESSAGE"
#define AL_REMOVE_MEMBER_MESSAGE @"REMOVE_MEMBER_MESSAGE"
#define AL_ADD_MEMBER_MESSAGE @"ADD_MEMBER_MESSAGE"
#define AL_JOIN_MEMBER_MESSAGE @"JOIN_MEMBER_MESSAGE"
#define AL_GROUP_NAME_CHANGE_MESSAGE @"GROUP_NAME_CHANGE_MESSAGE"
#define AL_GROUP_ICON_CHANGE_MESSAGE @"GROUP_ICON_CHANGE_MESSAGE"
#define AL_GROUP_LEFT_MESSAGE @"GROUP_LEFT_MESSAGE"
#define AL_DELETED_GROUP_MESSAGE @"DELETED_GROUP_MESSAGE"

#import <Foundation/Foundation.h>
#import "ALChannelFeed.h"
#import "ALChannelDBService.h"
#import "ALChannelClientService.h"
#import "ALUserDefaultsHandler.h"
#import "ALChannelSyncResponse.h"
#import "AlChannelFeedResponse.h"
#import "ALRealTimeUpdate.h"
#import "ALChannelInfo.h"


@interface ALChannelService : NSObject

+(ALChannelService *)sharedInstance;

-(void)callForChannelServiceForDBInsertion:(id)theJson;

/**
 This method is used to fetch information of channel like channel name, imageUrl of a channel, type of channel and other information.

 @param channelKey NSNumber its channelkey or groupId that is required to get the channel information.
 @param clientChannelKey if you have your clientChannelKey then you can pass to get the channel information.
 @param completion ALChannel will have information of channel.
 */


-(void)getChannelInformation:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void (^)(ALChannel *alChannel3)) completion;

/**
 This method you can use to fetch the information of channel from local DB.

 @param channelKey NSNumber its channelkey or groupId that is required to get the channel information.
 @return it returns ALChannel object it has information of a channel.
 */
-(ALChannel *)getChannelByKey:(NSNumber *)channelKey;


/**
 This method is used to get the list of users userId from a channel by  channelKey.

 @param channelKey NSNumber its channelkey or groupId that is required to get the channel members userId.
 @return it returns NSMutableArray has users who are in the channel.
 */
-(NSMutableArray *)getListOfAllUsersInChannel:(NSNumber *)channelKey;


/**
 This is the internal method to get the group members name to show in a navigation bar.

 @param key NSNumber its channelkey or groupId that is required to get the channel members name.
 @return NSString of channel members name with comma separated in a name.
 */
-(NSString *)stringFromChannelUserList:(NSNumber *)key;


/**
 This method is used to fetch information of channel like channel name,imageUrl of chanel, type of channel and other information.

 @param channelKey NSNumber its channelkey or groupId that is required to get the channel information.
 @param clientChannelKey if you have your clientChannelKey then you can pass to get the channel information.
 @param completion ALChannel will have information of the channel.
 */

-(void)getChannelInformationByResponse:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void (^)(NSError *error,ALChannel *alChannel3,AlChannelFeedResponse *channelResponse)) completion;

/**
 This method is used to create a channel where it needs below details to pass while creating.

 @param channelName its channel name that you want to set for the channel.
 @param clientChannelKey if you have your own channelClientKey then you can set it while creating channel then you can use this in other places to get the details.
 @param memberArray NSMutableArray pass members userId that you want to add in a channel.
 @param imageLink its URL of channel image which you want to see in the channel profile image.
 @param completion if an error is a nil then the group is created successfully it has ALChannel information of channel else some error while creating if an error is not nil.
 */

-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink
      withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;


/**
 This method is used to create a channel where it needs below details to pass while creating


 @param channelName its channel name that you want to set for the channel.
 @param clientChannelKey if you have your own channelClientKey then you can set it while creating channel then you can use this in other places to get the details.
 @param memberArray NSMutableArray pass members userId that you want to add in a channel.
 @param imageLink its URL of channel image which you want to see in the channel profile image.
 @param type pass type of group you want to create

 Types of the group. PRIVATE = 1,PUBLIC = 2, OPEN = 6

 @param metaData extra information you can pass in metadata if you required some other place.

 @param completion if error is nil then group is created successfully it has ALChannel infomration of channel else some error while creating if error is not nil.
 */
-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type andMetaData:(NSMutableDictionary *)metaData
      withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;


/**
 This method is used to create a channel where it needs below details to pass while creating


 @param channelName it's channel name that you want to set for the channel.
 @param parentChannelKey if you have parent key if the channel you want to link to parent channel then pass parent channel key
 @param clientChannelKey if you have your own channelClientKey then you can set it while creating channel then you can use this in other places to get the details.
 @param memberArray NSMutableArray pass members userId that you want to add in a channel.
 @param imageLink its URL of channel image which you want to see in the channel profile image.

 @param type pass type of group you want to create

 Types of the group. PRIVATE = 1,PUBLIC = 2, OPEN = 6

 @param metaData extra information you can pass in metadata if you required some other place.
 @param completion if an error is a nil then a group is created successfully it has ALChannel information of channel else some error while creating if an error is not nil.
 */
-(void)createChannel:(NSString *)channelName andParentChannelKey:(NSNumber *)parentChannelKey orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;


/**
 This method is used to create a channel where it needs below details to pass while creating

 @param channelName it's channel name that you want to set for the channel.
 @param clientChannelKey if you have your own channelClientKey then you can set it while creating channel then you can use this in other places to get the details.

 @param memberArray NSMutableArray pass members userId that you want to add in a channel.
 @param imageLink its URL of channel image which you want to see in the channel profile image.
 @param type pass type of group you want to create

 Types of the group. PRIVATE = 1,PUBLIC = 2, OPEN = 6

 @param metaData extra information you can pass in metadata if you required some other place.
 @param adminUserId if you want to make any member as admin while creating then you can pass userId of that member.
 @param completion if an error is nil then a group is created successfully it has ALChannel information of channel else some error while creating if an error is not nil.
 */
-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData adminUser:(NSString *)adminUserId withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;


/**
 This method you can use for creating a channel with parent channelKey.

 @param channelName it's channel name that you want to set for the channel.
 @param parentChannelKey if you have parent key if the channel you want to link to parent channel then pass parent channel key
 @param clientChannelKey if you have your own channelClientKey then you can set it while creating channel then you can use this in other places to get the details.
 @param memberArray NSMutableArray pass members userId that you want to add in a channel.
 @param imageLink its URL of channel image which you want to see in the channel profile image.
 @param type pass type of group you want to create

 Types of the group. PRIVATE = 1,PUBLIC = 2, OPEN = 6

 @param metaData extra information you can pass in metadata if you required some other place.
 @param adminUserId if you want to make any member as admin while creating then you can pass userId of that member.
 @param completion if an error is a nil then a group is created successfully it has ALChannel information of channel else some error while creating if an error is not nil.
 */
-(void)createChannel:(NSString *)channelName andParentChannelKey:(NSNumber *)parentChannelKey orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData  adminUser:(NSString *)adminUserId withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;


/**
 This method is used to add a member to a channel.

 @param userId whom you want add in a channel.
 @param channelKey NSNumber its channelkey or groupId that is required for adding a member in a channel.
 @param clientChannelKey or if you have your own clientChannelKey then pass this to add a member in a channel.
 @param completion it has error and ALAPIResponse where you can check if an error is not nil else in ALAPIResponse there is the status to check if its success or failed
 */
-(void)addMemberToChannel:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey
           withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;


/**
 This method is used to remove a member from a channel.

 @param userId whom you want remove from a channel.
 @param channelKey NSNumber its channelkey or groupId that is required for removing a member from a channel.
 @param clientChannelKey  or if you have your own clientChannelKey then pass this to add a member in a channel.
 @param completion it has error and ALAPIResponse where you can check if an error is not nil else in ALAPIResponse there is the status to check if its success or failure.
 */
-(void)removeMemberFromChannel:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey
                withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;


/**
 This method is used to delete a channel from server. Only the group admin can call this method.

 @param channelKey NSNumber its channelkey or groupId that is required for deleting a channel.
 @param clientChannelKey or if you have your own clientChannelKey then pass it for deleting a channel.
 @param completion it has error and ALAPIResponse where you can check if an error is not nil else in ALAPIResponse there is the status to check if its success or failure.
 */
-(void)deleteChannel:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey
      withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

-(BOOL)checkAdmin:(NSNumber *)channelKey;



/**
 You can use this method for leaving a member from channel

 @param channelKey The channel key you can get it from  channel.key
 @param userId pass login userId here to leave from channel
 @param clientChannelKey it is your clientChannelKey where you can pass while updating
 @param completion it has the error  where you can check if an error is not nil the user is left from channel
 */


-(void)leaveChannel:(NSNumber *)channelKey andUserId:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey
     withCompletion:(void(^)(NSError *error))completion;

/**
 This method is used to add multiple members in multiple channels

 @param channelKeys NSMutableArray pass channelKey or array of channelKeys
 @param channelUsers NSMutableArray pass userIds you  want to add in channels or channel
 @param completion it has error
 */
-(void)addMultipleUsersToChannel:(NSMutableArray* )channelKeys channelUsers:(NSMutableArray *)channelUsers andCompletion:(void(^)(NSError * error))completion;

/**
 This is internal method for sync channel from server
 */
-(void)syncCallForChannel;


/**
 This method is used to update channel information like name, imageUrl etc

 @param channelKey The channel key you can get it from  channel.key
 @param newName  its new  channel name of a channel
 @param imageURL image URL will be channel profile image
 @param clientChannelKey it is your clientChannelKey where you can pass while updating
 @param flag if your updating metadata then pass YES or NO
 @param metaData its extra information you can pass
 @param childKeysList its list of childkeys if you have created subgroups
 @param channelUsers NSMutableArray of  ALChannelUser object

 ALChannelUser * alChannelUsers = [ALChannelUser new];
 alChannelUsers.role = [NSNumber numberWithInt:1];//  USER = 0,ADMIN = 1,MODERATOR = 2,MEMBER = 3
 alChannelUsers.userId = userId;//user to update the role
 NSMutableArray * channelUsers = [NSMutableArray new];
 [channelUsers addObject:alChannelUsers.dictionary];

 @param completion it has the error where you can check if an error is not nil if it's updated successfully
 */


-(void)updateChannel:(NSNumber *)channelKey andNewName:(NSString *)newName andImageURL:(NSString *)imageURL orClientChannelKey:(NSString *)clientChannelKey
  isUpdatingMetaData:(BOOL)flag metadata:(NSMutableDictionary *)metaData orChildKeys:(NSMutableArray *)childKeysList orChannelUsers:(NSMutableArray *)channelUsers withCompletion:(void(^)(NSError *error))completion;

/**
 This method is used to update channel metadata

 @param channelKey The channel key you can get it from  channel.key
 @param clientChannelKey it's your clientChannelKey where you can pass while updating
 @param metaData its extra information you can pass
 @param completion it has an error where you can check if an error is not nil if it's updated successfully

 */
-(void)updateChannelMetaData:(NSNumber *)channelKey
          orClientChannelKey:(NSString *)clientChannelKey
                    metadata:(NSMutableDictionary *)metaData
              withCompletion:(void(^)(NSError *error))completion;

/**
 This method is used to mark the conversation as read in channel

 @param channelKey The channel key you can get it from  channel.key
 @param completion it has a response and error if an error is nil then Conversation is marked successfully
 */

-(void)markConversationAsRead:(NSNumber *)channelKey withCompletion:(void (^)(NSString *, NSError *))completion;

/**
 This method is used to check if the logged in user is left from a channel or not. It will return YES or NO.

 @param groupID pass the channel key you can get it from  channel.key

 @return it will return YES OR NO if the login member is channel or not

 */
-(BOOL)isChannelLeft:(NSNumber*)groupID;

/**
 This method is used to check if the channel is deleted or not.

 @param groupId pass the channel key you can get it from  channel.key.
 @return it will return YES OR NO if the channel is deleted or not.
 */
+(BOOL)isChannelDeleted:(NSNumber *)groupId;

/**
 This method is used to check a channel is closed or not.

 @param groupId pass the channel key you can get it from  channel.key.
 @return it will return YES OR NO if the conversation Closed in a channel.
 */
+(BOOL)isConversationClosed:(NSNumber *)groupId;

/**
 This method is used to close the channel conversation.

 @param groupId  pass the channel key you can get it from  channel.key.
 @param completion if error is nil then the  channel is closed.
 */
+(void)closeGroupConverstion :(NSNumber *) groupId  withCompletion:(void(^)(NSError *error))completion ;

/**
 This method is used to check if the channel is muted or not.

 @param groupId pass the channel key you can get it from  channel.key.
 @return it will return YES OR NO if the channel is muted or not.
 */
+(BOOL)isChannelMuted:(NSNumber *)groupId;

/**
 This method is internal, used to set channel unread cout to zero
 */
+(void)setUnreadCountZeroForGroupID:(NSNumber*)channelKey;

/**
 This method is used to fetch the total unread count of channels

 @return NSNumber the  total unread count of channel
 */
-(NSNumber *)getOverallUnreadCountForChannel;

/**
 This method is used to fetch the channel information by channelClientKey.

 @param clientChannelKey  pass the channel key you can get it from  channel.key.
 @return It wil return the channel information ALChannel object.
 */
-(ALChannel *)fetchChannelWithClientChannelKey:(NSString *)clientChannelKey;

/**
 This method is used to check if the logged in user is in channel or not

 @param channelKey pass the channel key you can get it from  channel.key.
 @return it will return YES OR NO if the user is in a channel or not.
 */
-(BOOL)isLoginUserInChannel:(NSNumber *)channelKey;

/**
 This method is used to get all channels for logged in user from local DB

 @return it will return the NSMutableArray of AlChannel object.
 */
-(NSMutableArray *)getAllChannelList;

/**
 This method is used to fetch the child channels under the parent key

 @param parentGroupKey Pass parent channelKey to get the channels
 @return it will return the NSMutableArray of AlChannel object.
 */
-(NSMutableArray *)fetchChildChannelsWithParentKey:(NSNumber *)parentGroupKey;

/**
 This method is used for internal purpose.
 */
-(void)processChildGroups:(ALChannel *)alChannel;

/**
 This method is used to add child keys to the parent key

 @param childKeyList NSMutableArray list of child channelKeys to the parent you want to add
 @param parentKey Pass the parent channelKey
 @param completion if error is nil then its added successfully.
 */
-(void)addChildKeyList:(NSMutableArray *)childKeyList andParentKey:(NSNumber *)parentKey
        withCompletion:(void(^)(id json, NSError *error))completion;

/**
 This method is used to remove the child keys from parent channelKey where it was added to the parent

 @param childKeyList NSMutableArray list of child channelKeys to the parent you want to remove from parentKey

 @param parentKey Pass the parent channelKey.
 @param completion if error is nil then its removed successfully.
 */
-(void)removeChildKeyList:(NSMutableArray *)childKeyList andParentKey:(NSNumber *)parentKey
           withCompletion:(void(^)(id json, NSError *error))completion;


/**
 This method is used to add child keys to client Parent Key.

 @param clientChildKeyList NSMutableArray list of client child channelKeys to the parent you want to add
 @param clientParentKey Pass the client parent channelKey.
 @param completion if an error is nil then its added successfully.
 */

-(void)addClientChildKeyList:(NSMutableArray *)clientChildKeyList andParentKey:(NSString *)clientParentKey
              withCompletion:(void(^)(id json, NSError *error))completion;


/**
 This method is used to remove the child keys from client ParentKey where it was added to the child keys to parent

 @param clientChildKeyList NSMutableArray list of client child channelKeys to the parent you want to remove from clientParentKey
 @param clientParentKey clientParentKey description
 @param completion  if an error is nil then its removed successfully.
 */

-(void)removeClientChildKeyList:(NSMutableArray *)clientChildKeyList andParentKey:(NSString *)clientParentKey
                 withCompletion:(void(^)(id json, NSError *error))completion;


/**
 This method is used to mute or unmute the channel

 @param muteRequest its an object of ALMuteRequest where you need to pass channelKey and notificationTime its time you want to mute from or unmute

 ALMuteRequest * alMuteRequest = [ALMuteRequest new];
 alMuteRequest.id = channelKey;
 alMuteRequest.notificationAfterTime= notificationTime;

 @param completion if an error is nil then check for ALAPIResponse it has status where if its success or error
 */


-(void)muteChannel:(ALMuteRequest *)muteRequest withCompletion:(void(^)(ALAPIResponse * response, NSError *error))completion;

/**
 This method is used to create a broadcast channel.

 @param memberArray pass member userId whom you want to add in the broadcast channel.
 @param metaData You can pass extra information in a channel where you can access it later from channel.metaData from the channel object.
 @param completion if an error is nil, Then the channel is created successfully else some error in creating a channel.
 */
-(void)createBroadcastChannelWithMembersList:(NSMutableArray *)memberArray
                                 andMetaData:(NSMutableDictionary *)metaData
                              withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;

-(ALChannelUserX *)loadChannelUserX:(NSNumber *)channelKey;

/**
 This method is used to fetch channel information from channelKeys array or clientChannelKey array

 @param channelIds Pass channelKeys array to get the list of channel information.
 @param clientChannelIds  or if you have list of  clientChannelKey then pass to get channel information.
 @param completion if error is nil and channelInfoList count is > 0 then you have channels information in NSMutableArray its type is ALChannel object.
 */
-(void)getChannelInfoByIdsOrClientIds:(NSMutableArray*)channelIds
                   orClinetChannelIds:(NSMutableArray*) clientChannelIds
                       withCompletion:(void(^)(NSMutableArray* channelInfoList, NSError *error))completion;

/**
 This method is used to fetch the list of channel information by Category

 @param category pass category that you want to get the channels from category
 @param completion if an error is a nil and the channelInfoList count is > 0 then you have channels information in NSMutableArray its type is ALChannel object.

 */
-(void)getChannelListForCategory:(NSString*)category
                  withCompletion:(void(^)(NSMutableArray * channelInfoList, NSError * error))completion;


/**
 This method is used to fetch the channels from the Applications

 @param endTime pass end to to fetch next set of channels
 @param completion if error is nil and channelInfoList count is >0 then it has channel object in array
 */
-(void)getAllChannelsForApplications:(NSNumber*)endTime withCompletion:(void(^)(NSMutableArray * channelInfoList, NSError * error))completion;


/**
 This method is used to add or create contacts group with a user, type, and name

 @param contactsGroupId pass contactsGroupId which will be a unique string
 @param membersArray pass members userId that you want to add
 @param groupType pass  type as 9 for contacts group

 @param completion if error is nil and ALAPIResponse has status if its  success  then member is added in contacts group
 */
+(void) addMemberToContactGroupOfType:(NSString*) contactsGroupId withMembers: (NSMutableArray *)membersArray withGroupType :(short) groupType withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion;

/**

 This method is used to add or create contacts group with default type

 @param contactsGroupId pass contactsGroupId which will be unique string.
 @param membersArray pass members userId that you want to add
 @param completion if error is nil and ALAPIResponse has status if its  success  then member is added in contacts group
 */
+(void) addMemberToContactGroup:(NSString*) contactsGroupId withMembers:(NSMutableArray *)membersArray  withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion;

/**
 This method is used to get the members from contacts group with the type where it will have members id who are in this contacts group

 @param contactGroupId pass contactsGroupId which will be unique string.
 @param groupType pass  type as 9 for contacts group
 @param completion if error is nil and ALAPIResponse has status if its  success  then you will get members userId who are in contacts group
 */
+(void) getMembersFromContactGroupOfType:(NSString *)contactGroupId  withGroupType :(short) groupType withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion;

/**
 This method is for internal purpose to get the members by channel name
 */

-(NSMutableArray *)getListOfAllUsersInChannelByNameForContactsGroup:(NSString *)channelName;

/**
 This method is used to remove a member from the contacts group.

 @param contactsGroupId pass contactsGroupId which will be unique string.
 @param userId of the user you want to remove the member from the contacts group.
 @param completion  if error is nil and ALAPIResponse has status if its  success  then member is removed from  contacts group.
 */
+(void) removeMemberFromContactGroup:(NSString*) contactsGroupId withUserId :(NSString*) userId  withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion;

/**
 This method is used to remove a member from contacts group with type

 @param contactsGroupId pass contactsGroupId which will be unique string.
 @param groupType pass  type as 9 for contacts group.
 @param userId for the user you want to remove from contacts group.
 @param completion  if error is nil and ALAPIResponse has status if its  success  then member is removed from  contacts group.
 */
+(void) removeMemberFromContactGroupOfType:(NSString*) contactsGroupId  withGroupType:(short) groupType withUserId :(NSString*) userId  withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion;

/**
 This method is used to get the members from multiple contacts groups

 @param contactGroupIds pass contactGroupIds to get the member userIds.
 @param completion  if error is nil and ALAPIResponse has status if status is succes then you will get the list of members userId
 */
+(void)getMembersIdsForContactGroups:(NSArray*)contactGroupIds withCompletion:(void(^)(NSError *error, NSArray *membersArray)) completion;


/**
 This method is used to create a channel where it needs below details to pass while creating

 @param channelName its channel name that you want to set for the channel.
 @param clientChannelKey if you have your own channelClientKey then you can set it while creating channel then you can use this in other places to get the details.

 @param memberArray NSMutableArray pass members userId that you want to add in a channel.
 @param imageLink its URL of channel image which you want to see in the channel profile image.
 @param type pass type of group you want to create

 Types of the group. PRIVATE = 1,PUBLIC = 2, OPEN = 6

 @param metaData extra information you can pass in metadata if you required some other place.
 @param adminUserId if you want to make any member as admin while creating then you can pass userId of that member.
 @param groupRoleUsers you can pass roles of a member in a channel

 @param completion if an error is a nil then a group is created successfully it has ALChannel information of channel else some error while creating if an error is not nil.
 */

-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData adminUser:(NSString *)adminUserId withGroupUsers : (NSMutableArray*) groupRoleUsers withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion;

/**
 Returns a dictionary containing required key value pairs to turn off the notifications
 for all the group action messages.
 */
- (NSDictionary *)metadataToTurnOffActionMessagesNotifications;

/**
 Returns a dictionary containing required key value pairs to hide all the action messages
 and turn off the notifications for them.
 */
- (NSDictionary *)metadataToHideActionMessagesAndTurnOffNotifications;

/**
 You can use this method for leaving a member from channel

 @param channelKey The channel key you can get it from  channel.key
 @param userId pass login userId here to leave from channel
 @param clientChannelKey it's your clientChannelKey where you can pass while updating
 @param completion it has error and ALAPIResponse where you can check if an error is not nil else in ALAPIResponse there is the status to check if its success or failed
 */
-(void)leaveChannelWithChannelKey:(NSNumber *)channelKey andUserId:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey
                   withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/**
 This method is used to update channel information like name, imageUrl etc

 @param channelKey The channel key you can get it from  channel.key
 @param newName  its new  channel name of a channel
 @param imageURL imageURL will be channel profile image
 @param clientChannelKey it's your clientChannelKey where you can pass while updating
 @param flag if your updating metadata then pass YES or NO
 @param metaData its extra information you can pass
 @param childKeysList its list of child keys if you have created subgroups
 @param channelUsers NSMutableArray of  ALChannelUser object

 ALChannelUser * alChannelUsers = [ALChannelUser new];
 alChannelUsers.role = [NSNumber numberWithInt:1];//  USER = 0,ADMIN = 1,MODERATOR = 2,MEMBER = 3
 alChannelUsers.userId = userId;//user to update the role
 NSMutableArray * channelUsers = [NSMutableArray new];
 [channelUsers addObject:alChannelUsers.dictionary];


 @param completion it has error and ALAPIResponse where you can check if error is not nil else in ALAPIResponse there is status to check if its success or failed
 */
-(void)updateChannelWithChannelKey:(NSNumber *)channelKey andNewName:(NSString *)newName andImageURL:(NSString *)imageURL orClientChannelKey:(NSString *)clientChannelKey
                isUpdatingMetaData:(BOOL)flag metadata:(NSMutableDictionary *)metaData orChildKeys:(NSMutableArray *)childKeysList orChannelUsers:(NSMutableArray *)channelUsers withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;


/**
 This method is used for internal purpose.

 @param delegate For real time updates  callback will be triggered for channel update
 */
-(void)syncCallForChannelWithDelegate:(id<ApplozicUpdatesDelegate>)delegate;

/**
 This method will update unread count to zero for channel once the conversation notification is received

 @param channelKey of channel the count will be reset to zero
 @param delegate  is used for updating the callback for real time updates
 */

-(void)updateConversationReadWithGroupId:(NSNumber *)channelKey withDelegate: (id<ApplozicUpdatesDelegate>)delegate;


-(void)createChannelWithChannelInfo:(ALChannelInfo*)channelInfo withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion;

@end
