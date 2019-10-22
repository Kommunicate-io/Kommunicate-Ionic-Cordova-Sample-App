//
//  ALUserService.h
//  Applozic
//
//  Created by Divjyot Singh on 05/11/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALConstant.h"
#import "ALSyncMessageFeed.h"
#import "ALMessageList.h"
#import "ALMessage.h"
#import "DB_FileMetaInfo.h"
#import "ALLastSeenSyncFeed.h"
#import "ALUserClientService.h"
#import "ALAPIResponse.h"
#import "ALUserBlockResponse.h"
#import "ALRealTimeUpdate.h"
#import "ALMuteRequest.h"

@interface ALUserService : NSObject

+(ALUserService *)sharedInstance;

+(void)processContactFromMessages:(NSArray *) messagesArr withCompletion:(void(^)(void))completionMark;

+(void)getLastSeenUpdateForUsers:(NSNumber *)lastSeenAt withCompletion:(void(^)(NSMutableArray *))completionMark;

+(void)userDetailServerCall:(NSString *)contactId withCompletion:(void(^)(ALUserDetail *))completionMark;

+(void)updateUserDisplayName:(ALContact *)alContact;

-(void)markConversationAsRead:(NSString *)contactId withCompletion:(void (^)(NSString *, NSError *))completion;

+(void)markMessageAsRead:(ALMessage *)alMessage withPairedkeyValue:(NSString *)pairedkeyValue withCompletion:(void (^)(NSString *, NSError *))completion;

-(void)blockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userBlock))completion;

-(void)blockUserSync:(NSNumber *)lastSyncTime;

-(void)unblockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userUnblock))completion;

-(void)updateBlockUserStatusToLocalDB:(ALUserBlockResponse *)userblock;

-(NSMutableArray *)getListOfBlockedUserByCurrentUser;

+(void)setUnreadCountZeroForContactId:(NSString*)contactId;

-(void)getListOfRegisteredUsersWithCompletion:(void(^)(NSError * error))completion;

-(void)fetchOnlineContactFromServer:(void(^)(NSMutableArray * array, NSError * error))completion;

-(NSNumber *)getTotalUnreadCount;

-(void)resettingUnreadCountWithCompletion:(void (^)(NSString *json, NSError *error))completion;

-(void)updateUserDisplayName:(NSString *)displayName andUserImage:(NSString *)imageLink userStatus:(NSString *)status
              withCompletion:(void (^)(id theJson, NSError * error))completion;

+(void)updateUserDetail:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark;

-(void)updateUser:(NSString *)phoneNumber
            email:(NSString *)email
           ofUser:(NSString *)userId
   withCompletion:(void (^)(BOOL))completion;

-(void) fetchAndupdateUserDetails:(NSMutableArray *)userArray withCompletion:(void (^)(NSMutableArray * array, NSError *error))completion;

-(void)getUserDetail:(NSString*)userId withCompletion:(void(^)(ALContact *contact))completion;

-(void)updateUserApplicationInfo;

-(void)updatePassword:(NSString*)oldPassword withNewPassword :(NSString *) newPassword withCompletion:(void(^)( ALAPIResponse* alAPIResponse, NSError *theError))completion;
-(void)processResettingUnreadCount;

-(void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse* response, NSError * error))completion;

/**
 This method will update unread count to zero for user once the conversation notification is received

 @param userId  of user the count will be reset to zero
 @param delegate is used for updating the callback for real time updates
 */
-(void)updateConversationReadWithUserId:(NSString *)userId withDelegate: (id<ApplozicUpdatesDelegate>)delegate;

-(void)getMutedUserListWithDelegate: (id<ApplozicUpdatesDelegate>)delegate withCompletion:(void(^)(NSMutableArray* userDetailArray, NSError * error))completion;

-(void) muteUser:(ALMuteRequest *)alMuteRequest withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion;

/**
 This method will report the message to admin of the account

 @param messageKey Pass message key of message object
 @param completion ALAPIResponse repoonse callback if success or error and NSError if any error occurs
 */
-(void)reportUserWithMessageKey:(NSString *) messageKey  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

@end
