//
//  ALUserService.m
//  Applozic
//
//  Created by Divjyot Singh on 05/11/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#define CONTACT_PAGE_SIZE 100

#import "ALUserService.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALUtilityClass.h"
#import "ALSyncMessageFeed.h"
#import "ALMessageDBService.h"
#import "ALMessageList.h"
#import "ALMessageClientService.h"
#import "ALMessageService.h"
#import "ALContactDBService.h"
#import "ALMessagesViewController.h"
#import "ALLastSeenSyncFeed.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserClientService.h"
#import "ALUserDetail.h"
#import "ALMessageDBService.h"
#import "ALContactService.h"
#import "ALUserDefaultsHandler.h"
#import "ALApplozicSettings.h"
#import "NSString+Encode.h"

@implementation ALUserService
{
    NSString * paramString;
}

+(ALUserService *)sharedInstance
{
    static ALUserService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALUserService alloc] init];
    });
    return sharedInstance;
}


//1. call this when each message comes
+ (void)processContactFromMessages:(NSArray *) messagesArr withCompletion:(void(^)(void))completionMark
{

    NSMutableOrderedSet* contactIdsArr=[[NSMutableOrderedSet alloc] init ];

    NSMutableString * repString=[[NSMutableString alloc] init];

    for(ALMessage* msg in messagesArr) {
        if(![ALUserDefaultsHandler isServerCallDoneForUserInfoForContact:msg.contactIds]) {
            [contactIdsArr addObject:[NSString stringWithFormat:@"&userIds=%@",[msg.contactIds urlEncodeUsingNSUTF8StringEncoding]]];
        }
    }

    if ([contactIdsArr count] == 0) {
        completionMark();
        return;
    }

    for(NSString *strr in contactIdsArr){
        [repString appendString:strr];
    }

    ALSLog(ALLoggerSeverityInfo, @"USER_ID_STRING :: %@",repString);

    ALUserClientService * client = [ALUserClientService new];
    [client subProcessUserDetailServerCall:repString withCompletion:^(NSMutableArray * userDetailArray, NSError * error) {

        if(error || !userDetailArray)
        {
            completionMark();
            return;
        }
        ALContactDBService * contactDB = [ALContactDBService new];
        for(ALUserDetail * userDetail in userDetailArray)
        {
            [contactDB updateUserDetail: userDetail];
            ALContact * contact = [contactDB loadContactByKey:@"userId" value:userDetail.userId];
            [ALUserDefaultsHandler setServerCallDoneForUserInfo:YES ForContact:contact.userId];
        }

        completionMark();

    }];
}

+(void)getLastSeenUpdateForUsers:(NSNumber *)lastSeenAt withCompletion:(void(^)(NSMutableArray *))completionMark
{

    [ALUserClientService userLastSeenDetail:lastSeenAt withCompletion:^(ALLastSeenSyncFeed * messageFeed) {
         NSMutableArray* lastSeenUpdateArray=   messageFeed.lastSeenArray;
        ALContactDBService *contactDBService =  [[ALContactDBService alloc]init];
        for (ALUserDetail * userDetail in lastSeenUpdateArray){
            userDetail.unreadCount = 0;
            [contactDBService updateUserDetail:userDetail];
        }
        completionMark(lastSeenUpdateArray);
    }];


}

+(void)userDetailServerCall:(NSString *)contactId withCompletion:(void(^)(ALUserDetail *))completionMark
{
    ALUserClientService * userDetailService = [[ALUserClientService alloc] init];

    [userDetailService userDetailServerCall:contactId withCompletion:^(ALUserDetail * userDetail) {
        completionMark(userDetail);

    }];
}

+(void)updateUserDetail:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark
{
    [self userDetailServerCall:userId withCompletion:^(ALUserDetail *userDetail) {

        if(userDetail)
        {
            userDetail.unreadCount = 0;
            ALContactDBService *contactDB = [ALContactDBService new];
            [contactDB updateUserDetail:userDetail];
        }
        completionMark(userDetail);
    }];
}

- (void)updateUser:(NSString *)phoneNumber email:(NSString *)email ofUser:(NSString *)userId withCompletion:(void (^)(BOOL))completion {
    ALUserClientService *userClientService =  [[ALUserClientService alloc] init];
    [userClientService updateUser:phoneNumber email:email ofUser:userId withCompletion:^(id theJson, NSError *theError) {
        if (theJson) {
            /// Updation success.
            ALContact *contact = [[[ALContactService alloc] init] loadContactByKey:@"userId" value:userId];
            if (!contact) {
                completion(NO);
                return;
            }
            if (email) {
                [contact setEmail:email];
            }
            if (phoneNumber) {
                [contact setContactNumber:phoneNumber];
            }
            [[[ALContactDBService alloc] init] updateContact:contact];
            completion(YES);
            return;
        }
        completion(NO);
    }];
}

+(void)updateUserDisplayName:(ALContact *)alContact
{
    if(alContact.userId && alContact.displayName)
    {
        ALUserClientService * alUserClientService  = [[ALUserClientService alloc] init];
        [alUserClientService updateUserDisplayName:alContact withCompletion:^(id theJson, NSError *theError) {

            if(theError)
            {
                ALSLog(ALLoggerSeverityError, @"GETTING ERROR in SEVER CALL FOR DISPLAY NAME");
            }
            else
            {
                ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:theJson];
                ALSLog(ALLoggerSeverityInfo, @"RESPONSE_STATUS :: %@", apiResponse.status);
            }

        }];
    }
    else
    {
         return;
    }
}

-(void)markConversationAsRead:(NSString *)contactId withCompletion:(void (^)(NSString *, NSError *))completion{

    [ALUserService setUnreadCountZeroForContactId:contactId];

    ALContactDBService * userDBService =[[ALContactDBService alloc] init];
    NSUInteger count = [userDBService markConversationAsDeliveredAndRead:contactId];
    ALSLog(ALLoggerSeverityInfo, @"Found %ld messages for marking as read.", (unsigned long)count);

    if(count == 0){
        return;
    }
    ALUserClientService * clientService = [[ALUserClientService alloc] init];
    [clientService markConversationAsReadforContact:contactId withCompletion:^(NSString *response, NSError * error){
                completion(response,error);
    }];

}

+(void)setUnreadCountZeroForContactId:(NSString*)contactId{

    ALContactService * contactService=[[ALContactService alloc] init];
    ALContact * contact =[contactService loadContactByKey:@"userId" value:contactId];
    contact.unreadCount=[NSNumber numberWithInt:0];
    [contactService setUnreadCountInDB:contact];

}
#pragma mark- Mark message READ
//===========================================
+(void)markMessageAsRead:(ALMessage *)alMessage withPairedkeyValue:(NSString *)pairedkeyValue withCompletion:(void (^)(NSString *, NSError *))completion{


    if(alMessage.groupId != NULL){
        [ALChannelService setUnreadCountZeroForGroupID:alMessage.groupId];
        ALChannelDBService * channelDBService = [[ALChannelDBService alloc] init];
        [channelDBService markConversationAsRead:alMessage.groupId];
    }
    else{
        [ALUserService setUnreadCountZeroForContactId:alMessage.contactIds];
        ALContactDBService * contactDBService=[[ALContactDBService alloc] init];
        [contactDBService markConversationAsDeliveredAndRead:alMessage.contactIds];
        //  TODO: Mark message read&delivered in DB not whole conversation
    }



    //Server Call
    ALUserClientService * clientService = [[ALUserClientService alloc] init];
    [clientService markMessageAsReadforPairedMessageKey:pairedkeyValue withCompletion:^(NSString * response, NSError * error) {
        ALSLog(ALLoggerSeverityInfo, @"Response Marking Message :%@",response);
        completion(response,error);
    }];

}

//===============================================================================================
#pragma BLOCK USER API
//===============================================================================================

-(void)blockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userBlock))completion
{
    [ALUserClientService userBlockServerCall:userId withCompletion:^(NSString *json, NSError *error) {

        if(!error)
        {
            ALAPIResponse *forBlockUserResponse = [[ALAPIResponse alloc] initWithJSONString:json];
            if([forBlockUserResponse.status isEqualToString:@"success"])
            {
                ALContactDBService *contactDB = [[ALContactDBService alloc] init];
                [contactDB setBlockUser:userId andBlockedState:YES];
                completion(error, YES);
                return;
            }
        }
        completion(error, NO);

    }];
}

//===============================================================================================
#pragma BLOCK/UNBLOCK USER SYNCHRONIZATION API
//===============================================================================================

-(void)blockUserSync:(NSNumber *)lastSyncTime
{
    [ALUserClientService userBlockSyncServerCall:lastSyncTime withCompletion:^(NSString *json, NSError *error) {

        if(!error)
        {
            ALUserBlockResponse * block = [[ALUserBlockResponse alloc] initWithJSONString:(NSString *)json];
            [self updateBlockUserStatusToLocalDB:block];
            [ALUserDefaultsHandler setUserBlockLastTimeStamp:block.generatedAt];
        }

    }];
}

-(void)updateBlockUserStatusToLocalDB:(ALUserBlockResponse *)userblock
{
    ALContactDBService *dbService = [ALContactDBService new];
    [dbService blockAllUserInList:userblock.blockedUserList];
    [dbService blockByUserInList:userblock.blockByUserList];
}

//===============================================================================================
#pragma UNBLOCK USER API
//===============================================================================================

-(void)unblockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userUnblock))completion
{

    [ALUserClientService userUnblockServerCall:userId withCompletion:^(NSString *json, NSError *error) {

        if(!error)
        {
            ALAPIResponse *forBlockUserResponse = [[ALAPIResponse alloc] initWithJSONString:json];
            if([forBlockUserResponse.status isEqualToString:@"success"])
            {
                ALContactDBService *contactDB = [[ALContactDBService alloc] init];
                [contactDB setBlockUser:userId andBlockedState:NO];
                completion(error, YES);
                return;
            }
        }
        completion(error, NO);

    }];

}

-(NSMutableArray *)getListOfBlockedUserByCurrentUser
{
    ALContactDBService * dbService = [ALContactDBService new];
    NSMutableArray * blockedUsersList = [dbService getListOfBlockedUsers];

    return blockedUsersList;
}

-(void)getListOfRegisteredUsersWithCompletion:(void(^)(NSError * error))completion
{
    ALUserClientService * clientService = [ALUserClientService new];
    NSNumber * startTime;
    if(![ALUserDefaultsHandler isContactServerCallIsDone]){
        startTime = 0;
    }else{
        startTime  = [ALApplozicSettings getStartTime];
    }
    NSUInteger pageSize = (NSUInteger)CONTACT_PAGE_SIZE;

    [clientService getListOfRegisteredUsers:startTime andPageSize:pageSize withCompletion:^(ALContactsResponse * response, NSError * error) {

        if(error)
        {
            completion(error);
            return;
        }

        [ALApplozicSettings setStartTime:response.lastFetchTime];
        ALContactDBService * dbServie = [ALContactDBService new];
        [dbServie updateFilteredContacts:response];
        completion(error);

    }];

}
//===============================================================================================
#pragma ONLINE FETCH CONTACT API
//===============================================================================================

-(void)fetchOnlineContactFromServer:(void(^)(NSMutableArray * array, NSError * error))completion
{
    ALUserClientService * client = [ALUserClientService new];
    [client fetchOnlineContactFromServer:[ALApplozicSettings getOnlineContactLimit] withCompletion:^(id json, NSError * error) {

        if(error)
        {
            completion(nil, error);
            return;
        }

        NSDictionary * JSONDictionary = (NSDictionary *)json;
        if(JSONDictionary.count)
        {
            NSMutableArray * contactArray = [NSMutableArray new];
            ALUserDetail * userDetail = [ALUserDetail new];
            [userDetail parsingDictionaryFromJSON:JSONDictionary];
            self->paramString = userDetail.userIdString;

            [client subProcessUserDetailServerCall:self->paramString withCompletion:^(NSMutableArray * userDetailArray, NSError * error) {

                if(error)
                {
                    completion(nil, error);
                    return;
                }
                ALContactDBService * contactDB = [ALContactDBService new];
                for(ALUserDetail * userDetail in userDetailArray)
                {
                    [contactDB updateUserDetail: userDetail];
                    ALContact * contact = [contactDB loadContactByKey:@"userId" value:userDetail.userId];
                    [contactArray addObject:contact];
                }
                completion(contactArray, error);
            }];
        }
    }];
}

//=========================================================================================================================
#pragma OVER ALL UNREAD COUNT (CHANNEL + CONTACTS)
//=========================================================================================================================

-(NSNumber *)getTotalUnreadCount
{
    ALContactService * contactService = [ALContactService new];
    NSNumber * contactUnreadCount = [contactService getOverallUnreadCountForContact];

    ALChannelService * channelService = [ALChannelService new];
    NSNumber * channelUnreadCount = [channelService getOverallUnreadCountForChannel];

    int totalCount = [contactUnreadCount intValue] + [channelUnreadCount intValue];
    NSNumber * unreadCount = [NSNumber numberWithInt:totalCount];

    return unreadCount;
}

-(void)resettingUnreadCountWithCompletion:(void (^)(NSString *json, NSError *error))completion
{
    [ALUserClientService readCallResettingUnreadCountWithCompletion:^(NSString *json, NSError *error) {

        completion(json,error);
    }];
}

//=========================================================================================================================
#pragma UPDATE USER DISPLAY NAME AND PROFILE PICTURE
//=========================================================================================================================

-(void)updateUserDisplayName:(NSString *)displayName andUserImage:(NSString *)imageLink userStatus:(NSString *)status
              withCompletion:(void (^)(id theJson, NSError * error))completion
{
    ALUserClientService *clientService = [ALUserClientService new];
    [clientService updateUserDisplayName:displayName andUserImageLink:imageLink userStatus:status withCompletion:^(id theJson, NSError *error) {

        completion(theJson, error);

    }];
}

-(void) fetchAndupdateUserDetails:(NSMutableArray *)userArray withCompletion:(void (^)(NSMutableArray * array, NSError *error))completion

{

    ALUserDetailListFeed *ob = [ALUserDetailListFeed new];
    [ob setArray:userArray];
    ob.contactSync = YES;
    ALUserClientService *clientService = [ALUserClientService new];
    ALContactDBService *dbService = [ALContactDBService new];

    [clientService subProcessUserDetailServerCallPOST:ob withCompletion:^(NSMutableArray *userDetailArray, NSError *theError) {


        if(userDetailArray && userDetailArray.count)
        {
            [dbService addUserDetailsWithoutUnreadCount:userDetailArray];
        }
        completion(userDetailArray,theError);
    }];

}

-(void)getUserDetail:(NSString*)userId withCompletion:(void(^)(ALContact *contact))completion
{

        ALContactService *contactService = [ALContactService new];
        ALContactDBService *contactDBService = [ALContactDBService new];

        if(![contactService isContactExist:userId])
        {
            ALSLog(ALLoggerSeverityError, @"###contact is not found");

            [ALUserService userDetailServerCall:userId withCompletion:^(ALUserDetail *alUserDetail) {

                [contactDBService updateUserDetail:alUserDetail];
                ALContact * alContact = [contactDBService loadContactByKey:@"userId" value:userId];
                completion(alContact);
            }];
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @" contact is found");

            ALContact * alContact = [contactDBService loadContactByKey:@"userId" value:userId];
            completion(alContact);
        }
}

-(void)updateUserApplicationInfo{

    AlApplicationInfoFeed *userApplicationInfo = [AlApplicationInfoFeed new];
    userApplicationInfo.applicationKey = [ALUserDefaultsHandler getApplicationKey];
    userApplicationInfo.bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    ALUserClientService *clientService = [ALUserClientService new];
    [clientService updateApplicationInfoDeatils:userApplicationInfo withCompletion:^(NSString *json, NSError *error) {
        ALSLog(ALLoggerSeverityInfo, @"Response For user application update reponse :%@",json);
    }];

}


-(void)updatePassword:(NSString*)oldPassword withNewPassword :(NSString *) newPassword  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion{

    if(!oldPassword || !newPassword){
        completion(nil, nil);
    }

    ALUserClientService *clientService = [ALUserClientService new];
    [clientService updatePassword:oldPassword  withNewPassword: newPassword  withCompletion:^(ALAPIResponse *alAPIResponse, NSError *theError) {

        if(!theError){

            if([alAPIResponse.status isEqualToString:@"error"])
            {
                NSError * reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                         userInfo:[NSDictionary dictionaryWithObject:@"ERROR IN UPDATING PASSWORD "
                                                                                              forKey:NSLocalizedDescriptionKey]];
                completion(alAPIResponse, reponseError);
                return;
            }
            [ALUserDefaultsHandler setPassword:newPassword];
        }

        completion(alAPIResponse, theError);
    }];

}

//==============================================================================================================================================
#pragma mark - REST UNREAD COUNT + CONVERSATION READ HELPER METHODS
//==============================================================================================================================================

-(void)processResettingUnreadCount
{
    ALUserService * userService = [ALUserService new];
    int count = [[userService getTotalUnreadCount] intValue];
    NSLog(@"CHATVC_UNREAD_COUNT :: %i",count);
    if(count == 0)
    {
        [userService resettingUnreadCountWithCompletion:^(NSString *json, NSError *error) {

            NSLog(@"RESET_UNREAD_COUNT CALL :: %@ and ERROR :: %@",json, error.description);
        }];
    }
}



-(void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse* response, NSError * error))completion
{

    if(!userName){
        NSError * reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                 userInfo:[NSDictionary dictionaryWithObject:@"Error userName is nil " forKey:NSLocalizedDescriptionKey]];
        completion(nil,reponseError);
        return;
    }

    ALUserClientService * clientService = [ALUserClientService new];

    [clientService getListOfUsersWithUserName:userName withCompletion:^(ALAPIResponse *response, NSError *error) {

        if(error)
        {
            completion(response,error);
            return;
        }
        ALContactDBService * dbServie = [ALContactDBService new];
        if([response.status isEqualToString:@"success"]){

            NSMutableArray * array = (NSMutableArray*)response.response;
            for(NSDictionary *userDeatils in array)
            {
                ALUserDetail *userDeatil = [[ALUserDetail alloc] initWithDictonary:userDeatils];

                userDeatil.unreadCount = 0;
                [dbServie updateUserDetail:userDeatil];
            }
        }
        completion(response,error);
    }];

}


-(void)updateConversationReadWithUserId:(NSString *)userId withDelegate: (id<ApplozicUpdatesDelegate>)delegate{
    
    [ALUserService setUnreadCountZeroForContactId:userId];
    if(delegate){
        [delegate conversationReadByCurrentUser:userId withGroupId:nil];
    }
    NSDictionary *dict = @{@"userId":userId};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_unread_count" object:dict];

}

-(void)getMutedUserListWithDelegate:(id<ApplozicUpdatesDelegate>)delegate withCompletion:(void (^)(NSMutableArray *, NSError *))completion{
    
    ALUserClientService *userClientService = [[ALUserClientService alloc]init];
    [userClientService getMutedUserListWithCompletion:^(id theJson, NSError *error) {
        
        NSArray * jsonArray = [NSArray arrayWithArray:(NSArray *)theJson];
        NSMutableArray * userDetailArray = [NSMutableArray new];
        
        if(jsonArray.count)
        {
            NSDictionary * jsonDictionary = (NSDictionary *)theJson;
            ALContactDBService *contactDataBase = [[ALContactDBService alloc] init];
            userDetailArray = [contactDataBase addMuteUserDetailsWithDelegate:delegate withNSDictionary:jsonDictionary];
        }
        completion(userDetailArray,error);
    }];
}

-(void) muteUser:(ALMuteRequest *)alMuteRequest withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion{

    ALUserClientService *userClientService = [[ALUserClientService alloc] init];
    [userClientService muteUser:alMuteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        if(response && [response.status isEqualToString:@"success"]){
            ALContactService *contactService = [[ALContactService alloc]init];
            
            [contactService updateMuteAfterTime:alMuteRequest.notificationAfterTime andUserId:alMuteRequest.userId];
        }
        completion(response,error);
    }];
    
}


-(void)reportUserWithMessageKey:(NSString *) messageKey  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion{

    ALUserClientService *userClientService = [[ALUserClientService alloc] init];
    [userClientService reportUserWithMessageKey:messageKey withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        completion(apiResponse,error);
    }];
}

@end
