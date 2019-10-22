//
//  ALUserClientService.m
//  Applozic
//
//  Created by Devashish on 21/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALUserClientService.h"
#import <Foundation/Foundation.h>
#import "ALConstant.h"
#import "ALUserDefaultsHandler.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "NSString+Encode.h"
#import "ALAPIResponse.h"
#import "ALUserDetailListFeed.h"
#import "AlApplicationInfoFeed.h"

NSString * const ApplozicDomain = @"Applozic";

typedef NS_ENUM(NSInteger, ApplozicUserClientError) {
    MessageKeyNotPresent = 2
};

@implementation ALUserClientService

+(void)userLastSeenDetail:(NSNumber *)lastSeenAt withCompletion:(void(^)(ALLastSeenSyncFeed *))completionMark
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/status",KBASE_URL];
    if(!lastSeenAt){
        lastSeenAt = [ALUserDefaultsHandler getLastSyncTime];
        ALSLog(ALLoggerSeverityInfo, @"lastSeenAt is coming as null seeting default vlaue to %@", lastSeenAt);
    }
    NSString * theParamString = [NSString stringWithFormat:@"lastSeenAt=%@",lastSeenAt];
    ALSLog(ALLoggerSeverityInfo, @"calling last seen at api for userIds: %@", theParamString);
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USER_LAST_SEEN_NEW" WithCompletionHandler:^(id theJson, NSError *theError) {
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"ERROR IN LAST SEEN %@", theError);
        }
        else
        {
//            NSLog(@"SERVER RESPONSE FROM JSON : %@", (NSString *)theJson);
            NSNumber * generatedAt =  [theJson  valueForKey:@"generatedAt"];
            [ALUserDefaultsHandler setLastSeenSyncTime:generatedAt];
            ALLastSeenSyncFeed  * responseFeed =  [[ALLastSeenSyncFeed alloc] initWithJSONString:(NSString*)theJson];
            
            completionMark(responseFeed);
        }
        
        
    }];
    
}

-(void)userDetailServerCall:(NSString *)contactId withCompletion:(void(^)(ALUserDetail *))completionMark
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/detail",KBASE_URL];
    NSString * theParamString = [NSString stringWithFormat:@"userIds=%@",[contactId urlEncodeUsingNSUTF8StringEncoding]];
    
    ALSLog(ALLoggerSeverityInfo, @"calling last seen at api for userIds: %@", contactId);
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USER_LAST_SEEN" WithCompletionHandler:^(id theJson, NSError *theError) {
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"ERROR IN LAST SEEN %@", theError);
            completionMark(nil);
        }
        else
        {
            if(((NSArray*)theJson).count > 0)
            {
                ALSLog(ALLoggerSeverityInfo, @"SERVER RESPONSE FROM JSON : %@", (NSString *)theJson);
                ALUserDetail *userDetailObject = [[ALUserDetail alloc] initWithDictonary:[theJson objectAtIndex:0]];
                [userDetailObject userDetail];
                completionMark(userDetailObject);
            }
            else
            {
                completionMark(nil);
            }
        }
        
    }];
    
}

-(void)updateUserDisplayName:(ALContact *)alContact withCompletion:(void(^)(id theJson, NSError *theError))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/name", KBASE_URL];
    NSString * theParamString = [NSString stringWithFormat:@"userId=%@&displayName=%@", [alContact.userId urlEncodeUsingNSUTF8StringEncoding],
                                                                                     [alContact.displayName urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USER_DISPLAY_NAME_UPDATE" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError)
        {
            completion(nil,theError);
            return ;
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"Response of USER_DISPLAY_NAME_UPDATE : %@", (NSString *)theJson);
            completion((NSString *)theJson, nil);
        }
        
    }];
    
}

-(void)markConversationAsReadforContact:(NSString *)contactId withCompletion:(void (^)(NSString *, NSError *))completion
{
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/read/conversation",KBASE_URL];
    NSString * theParamString;
    theParamString = [NSString stringWithFormat:@"userId=%@",[contactId urlEncodeUsingNSUTF8StringEncoding]];
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"MARK_CONVERSATION_AS_READ" WithCompletionHandler:^(id theJson, NSError *theError) {
        if (theError) {
            completion(nil,theError);
            ALSLog(ALLoggerSeverityError, @"theError");
            return ;
        }else{
            //read sucessfull
            ALSLog(ALLoggerSeverityInfo, @"sucessfully marked read !");
        }
        ALSLog(ALLoggerSeverityInfo, @"Response: %@", (NSString *)theJson);
        completion((NSString *)theJson,nil);
    }];
}

//==============================================
#pragma BLOCK USER SERVER CALL
//==============================================

+(void)userBlockServerCall:(NSString *)userId withCompletion:(void (^)(NSString *json, NSError *error))completion
{    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/block",KBASE_URL];
    NSString * theParamString;
    theParamString = [NSString stringWithFormat:@"userId=%@",[userId urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USER_BLOCKED" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        ALSLog(ALLoggerSeverityInfo, @"USER_BLOCKED RESPONSE JSON: %@", (NSString *)theJson);
        if (theError){
            ALSLog(ALLoggerSeverityError, @"theError %@",theError);
        }
        else{
        
            completion((NSString *)theJson, nil);
        }
        
        ALSLog(ALLoggerSeverityInfo, @"Response USER_BLOCKED:%@",theJson);
    }];
}

+(void)userBlockSyncServerCall:(NSNumber *)lastSyncTime withCompletion:(void (^)(NSString *json, NSError *error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/blocked/sync",KBASE_URL];
    NSString * theParamString;
    theParamString = [NSString stringWithFormat:@"lastSyncTime=%@",lastSyncTime];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USER_BLOCK_SYNC" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        ALSLog(ALLoggerSeverityInfo, @"USER_BLOCKED SYNC RESPONSE JSON: %@", (NSString *)theJson);
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"theError");
        }
        else
        {
            completion((NSString *)theJson, nil);
        }
        
    }];
}

//==============================================
#pragma UNBLOCK USER SERVER CALL
//==============================================

+(void)userUnblockServerCall:(NSString *)userId withCompletion:(void (^)(NSString *json, NSError *error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/unblock",KBASE_URL];
    NSString * theParamString;
    theParamString = [NSString stringWithFormat:@"userId=%@",[userId urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USER_UNBLOCKED" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        ALSLog(ALLoggerSeverityInfo, @"USER_UNBLOCKED RESPONSE JSON: %@", (NSString *)theJson);
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"theError,%@",theError);
        }
        else{
            completion((NSString *)theJson, nil);
        }
        ALSLog(ALLoggerSeverityInfo, @"Response USER_UNBLOCKED:%@",(NSString *)theJson);
    }];
}

#pragma mark - Mark Message Read
//==============================

-(void)markMessageAsReadforPairedMessageKey:(NSString *)pairedMessageKey withCompletion:(void (^)(NSString *, NSError *))completion{
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/read",KBASE_URL];
    NSString * theParamString;
    theParamString = [NSString stringWithFormat:@"key=%@",pairedMessageKey];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"MARK_MESSAGE_AS_READ" WithCompletionHandler:^(id theJson, NSError *theError) {
        if (theError) {
            completion(nil,theError);
            ALSLog(ALLoggerSeverityError, @"theError");
            return ;
        }
        ALSLog(ALLoggerSeverityInfo, @"markMessageAsRead %@",theJson);
        completion((NSString *)theJson,nil);
    }];
}

#pragma mark - Multi User Send Message
//===================================

+(void)multiUserSendMessage:(NSDictionary *)messageDictionary
                 toContacts:(NSMutableArray*)contactIdsArray
                   toGroups:(NSMutableArray*)channelKeysArray
             withCompletion:(void (^)(NSString *json, NSError *error))completion{
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/sendall",KBASE_URL];
    
    NSMutableDictionary *channelDictionary = [NSMutableDictionary new];
    [channelDictionary setObject:contactIdsArray forKey:@"userNames"];
    [channelDictionary setObject:channelKeysArray forKey:@"groupIds"];
    [channelDictionary setObject:messageDictionary forKey:@"messageObject"];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:channelDictionary options:0 error:&error];
    NSString *theParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"MULTI_USER_SEND" WithCompletionHandler:^(id theJson, NSError *theError) {
        completion(theJson,theError);
        
    }];
}

-(void)getListOfRegisteredUsers:(NSNumber *)startTime andPageSize:(NSUInteger)pageSize
                 withCompletion:(void(^)(ALContactsResponse * response, NSError * error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/filter",KBASE_URL];
    NSString * pageSizeString = [NSString stringWithFormat:@"%lu", (unsigned long)pageSize];
    
    NSString * theParamString = @"";
    theParamString = [NSString stringWithFormat:@"pageSize=%@", pageSizeString];
    if(startTime)
    {
        theParamString = [NSString stringWithFormat:@"pageSize=%@&startTime=%@", pageSizeString, startTime];
    }
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    [ALResponseHandler processRequest:theRequest andTag:@"FETCH_REGISTERED_CONTACT_WITH_PAGE_SIZE" WithCompletionHandler:^(id theJson, NSError * theError) {
        
        if (theError)
        {
            completion(nil, theError);
            ALSLog(ALLoggerSeverityError, @"ERROR_IN_FETCH_CONTACT_WITH_PAGE_SIZE : %@", theError);
            return;
        }
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REGISTERED_CONTACT_WITH_PAGE_SIZE_JSON : %@",(NSString *)theJson);
        ALContactsResponse * contactResponse = [[ALContactsResponse alloc] initWithJSONString:(NSString *)theJson];
        completion(contactResponse, nil);
        [ALUserDefaultsHandler setContactViewLoadStatus:YES];
    }];
}

-(void)fetchOnlineContactFromServer:(NSUInteger)limit withCompletion:(void (^)(id json, NSError * error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/ol/list",KBASE_URL];
    NSString * theParamString = [NSString stringWithFormat:@"startIndex=0&pageSize=%lu",(unsigned long)limit];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"CONTACT_FETCH_WITH_LIMIT" WithCompletionHandler:^(id theJson, NSError * theError) {
        
        if (theError)
        {
            completion(nil, theError);
            ALSLog(ALLoggerSeverityError, @"ERROR_IN_CONTACT_FETCH_WITH_LIMIT : %@",theError);
            return ;
        }
        
        NSString * JSONString = (NSString *)theJson;
        ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_CONTACT_FETCH_WITH_LIMIT_JSON : %@", JSONString);
        completion(theJson, theError);
    }];
}

-(void)subProcessUserDetailServerCall:(NSString *)paramString withCompletion:(void(^)(NSMutableArray * userDetailArray, NSError * theError))completionMark
{
    
    @try
    {
        
        NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/detail",KBASE_URL];
        NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:paramString];
        
        [ALResponseHandler processRequest:theRequest andTag:@"USERS_DETAILS_FOR_ONLINE_CONTACT_LIMIT" WithCompletionHandler:^(id theJson, NSError *theError) {
            
            if (theError)
            {
                completionMark(nil, theError);
                ALSLog(ALLoggerSeverityError, @"ERROR_IN_USERS_DETAILS_FOR_ONLINE_CONTACT_LIMIT : %@", theError);
                return;
            }
            
            ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_FOR_ONLINE_CONTACT_LIMIT_JSON : %@", (NSString *)theJson);
            NSArray * jsonArray = [NSArray arrayWithArray:(NSArray *)theJson];
            if(jsonArray.count)
            {
                NSMutableArray * ALLUserDetailArray = [NSMutableArray new];
                NSDictionary * JSONDictionary = (NSDictionary *)theJson;
                for (NSDictionary * theDictionary in JSONDictionary)
                {
                    ALUserDetail * userDetail = [[ALUserDetail alloc] initWithDictonary:theDictionary];
                    userDetail.unreadCount = 0;
                    [ALLUserDetailArray addObject:userDetail];
                }
                completionMark(ALLUserDetailArray, theError);
            }else{
                completionMark(nil, theError);
            }
        }];
        
    }
    @catch(NSException * exp)
    {
        ALSLog(ALLoggerSeverityError, @"EXCEPTION : UserDetail :: %@",exp.description);

    }
    
}

//========================================================================================================================
# pragma mark CALL FOR RESETTING UNREAD COUNT
//========================================================================================================================

+(void)readCallResettingUnreadCountWithCompletion:(void (^)(NSString *json, NSError *error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/read",KBASE_URL];
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:nil];
    
    [ALResponseHandler processRequest:theRequest andTag:@"RESETTING_UNREAD_COUNT" WithCompletionHandler:^(id theJson, NSError * theError) {
    
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE RESETTING_UNREAD_COUNT :: %@",(NSString *)theJson);
        if(theError)
        {
            completion(nil,theError);
            ALSLog(ALLoggerSeverityError, @"ERROR : RESETTING UNREAD COUNT :: %@",theError.description);
            return;
        }
        completion((NSString *)theJson,nil);
    }];
}

//========================================================================================================================
#pragma mark UPDATE USER Display Name/Status/Profile Image
//========================================================================================================================

-(void)updateUserDisplayName:(NSString *)displayName andUserImageLink:(NSString *)imageLink userStatus:(NSString *)status
              withCompletion:(void (^)(id theJson, NSError * error))completionHandler
{
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/update",KBASE_URL];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:displayName forKey:@"displayName"];
    [dictionary setObject:imageLink forKey:@"imageLink"];
    [dictionary setObject:status forKey:@"statusMessage"];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    NSString *theParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"UPDATE_DISPLAY_NAME_AND_PROFILE_IMAGE" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        ALSLog(ALLoggerSeverityInfo, @"UPDATE_USER_DISPLAY_NAME/PROFILE_IMAGE/USER_STATUS :: %@",(NSString *)theJson);
        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)theJson];
        if([apiResponse.status isEqualToString:@"error"])
        {
            NSError * reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                     userInfo:[NSDictionary dictionaryWithObject:@"ERROR IN JSON STATUS WHILE UPDATING USER STATUS"
                                                                                          forKey:NSLocalizedDescriptionKey]];
            completionHandler(theJson, reponseError);
            return;
        }
        completionHandler(theJson, theError);
        
    }];
}

- (void)updateUser:(NSString *)phoneNumber email:(NSString *)email ofUser:(NSString *)userId withCompletion:(void (^)(id, NSError *))completion {
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/update", KBASE_URL];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    if (phoneNumber) {
        [dictionary setObject:phoneNumber forKey:@"phoneNumber"];
    }
    if (email) {
        [dictionary setObject:email forKey:@"email"];
    }

    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    NSString *theParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];

    NSMutableURLRequest * theRequest = [ALRequestHandler
                                        createPOSTRequestWithUrlString:theUrlString
                                        paramString:theParamString
                                        ofUserId:userId];

    [ALResponseHandler processRequest:theRequest andTag:@"UPDATE_PHONE_AND_EMAIL" WithCompletionHandler:^(id theJson, NSError *theError) {
        ALSLog(ALLoggerSeverityInfo, @"Update user phone/email :: %@",(NSString *)theJson);
        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)theJson];
        if([apiResponse.status isEqualToString:@"error"])
        {
            NSError * reponseError =
            [NSError errorWithDomain:@"Applozic"
                                code:1
                            userInfo: [NSDictionary
                                       dictionaryWithObject:@"error updating user"
                                       forKey:NSLocalizedDescriptionKey]];
            completion(nil, reponseError);
            return;
        }
        completion(apiResponse.response, theError);
    }];
}

// POST CALL

-(void)subProcessUserDetailServerCallPOST:(ALUserDetailListFeed *)ob withCompletion:(void(^)(NSMutableArray * userDetailArray, NSError * theError))completionMark
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/detail",KBASE_URL];
    
    NSError * error;
    NSData * postdata = [NSJSONSerialization dataWithJSONObject:ob.dictionary options:0 error:&error];
    NSString *paramString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    ALSLog(ALLoggerSeverityInfo, @"PARAM_POST_CALL : %@",paramString);
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:paramString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"USERS_DETAILS_FOR_ONLINE_CONTACT_LIMIT_POST" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_POST_CONTACT : %@", (NSString *)theJson);
        if ((NSString *)theJson == nil || theError)
        {
            completionMark(nil, theError);
            ALSLog(ALLoggerSeverityError, @"ERROR_SERVER_RESPONSE_POST_CONTACT : %@", theError);
            return;
        }
        
        NSArray * jsonArray = [NSArray arrayWithArray:(NSArray *)theJson];
        if(jsonArray.count)
        {
            NSMutableArray * ALLUserDetailArray = [NSMutableArray new];
            NSDictionary * JSONDictionary = (NSDictionary *)theJson;
            for (NSDictionary * theDictionary in JSONDictionary)
            {
                ALUserDetail * userDetail = [[ALUserDetail alloc] initWithDictonary:theDictionary];
                [ALLUserDetailArray addObject:userDetail];
            }
            completionMark(ALLUserDetailArray, theError);
        }
    }];
}


//========================================================================================================================
#pragma mark UPDATE Application info
//========================================================================================================================

-(void) updateApplicationInfoDeatils:(AlApplicationInfoFeed *)applicationInfoDeatils withCompletion:(void (^)(NSString *json, NSError *error))completion{
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/apps/customer/application/info/update",KBASE_URL];
    NSError *error;
    NSData * postdata = [NSJSONSerialization dataWithJSONObject:applicationInfoDeatils.dictionary options:0 error:&error];
    NSString *paramString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:paramString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"UPDATE_APPLICATION_INFO" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        ALSLog(ALLoggerSeverityInfo, @"Update Application Info reponse  :: %@",(NSString *)theJson);
        NSString * jsonString  = (NSString *)theJson;
        
        if(jsonString != nil  && [jsonString isEqualToString:@"/success/"] ){
            completion(theJson, theError);
        }else{
            NSError * reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                     userInfo:[NSDictionary dictionaryWithObject:@"ERROR IN JSON FOR UPDATEING THE APPLICATION INFO"
                                                                                          forKey:NSLocalizedDescriptionKey]];
            completion(theJson, reponseError);
            return ;
        }
        
    }];
    
}

-(void)updatePassword:(NSString*)oldPassword withNewPassword :(NSString *) newPassword  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion{

    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/update/password", KBASE_URL];
    NSString * theParamString = [NSString stringWithFormat:@"oldPassword=%@&newPassword=%@", oldPassword,
                                 newPassword];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"UPDATE_USER_PASSWORD" WithCompletionHandler:^(id theJson, NSError *theError) {
        ALAPIResponse *apiResponse = nil;
        if(!theError){
            apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)theJson];
        }
        completion(apiResponse, theError);

    }];
    
}

-(void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse* response, NSError * error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/search/contact",KBASE_URL];
    
    NSString * theParamString = [NSString stringWithFormat:@"name=%@", [userName urlEncodeUsingNSUTF8StringEncoding]];

    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    [ALResponseHandler processRequest:theRequest andTag:@"FETCH_LIST_OF_USERS_WITH_NAME" WithCompletionHandler:^(id theJson, NSError * theError) {
        
        if (theError)
        {
            completion(nil, theError);
            ALSLog(ALLoggerSeverityError, @"Error in list of users api  call : %@", theError);
            return;
        }
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_FETCH_LIST_OF_USERS_WITH_NAME_JSON : %@",(NSString *)theJson);
        
        ALAPIResponse * aLAPIResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)theJson];
        completion(aLAPIResponse, theError);
    }];
}


-(void)getMutedUserListWithCompletion:(void(^)(id theJson, NSError * error))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/chat/mute/list",KBASE_URL];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:nil];
    [ALResponseHandler processRequest:theRequest andTag:@"FETCH_MUTED_USER_LIST" WithCompletionHandler:^(id theJson, NSError * theError) {
        
        if (theError)
        {
            completion(nil, theError);
            ALSLog(ALLoggerSeverityError, @"Error in mute user list api  call : %@", theError);
            return;
        }
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_FETCH_MUTED_USER_LIST : %@",(NSString *)theJson);
        
        completion(theJson, theError);
    }];
}


-(void) muteUser:(ALMuteRequest *)alMuteRequest withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion
{
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/chat/mute?userId=%@&notificationAfterTime=%@",KBASE_URL,[alMuteRequest.userId urlEncodeUsingNSUTF8StringEncoding],alMuteRequest.notificationAfterTime];

    
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:nil];
    
    [ALResponseHandler processRequest:theRequest andTag:@"MUTE_USER" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"Error in mute user  : %@", theError);
            completion(nil, theError);
            return;
        }
        ALAPIResponse*  response = [[ALAPIResponse alloc] initWithJSONString:theJson];
        completion(response, nil);
        
    }];
    
}


-(void)reportUserWithMessageKey:(NSString *) messageKey  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion{

    if(messageKey == nil){
       NSError * error =  [NSError errorWithDomain:ApplozicDomain
                            code:MessageKeyNotPresent
                        userInfo:@{NSLocalizedDescriptionKey : @"Message key is nil"}];
        completion(nil,error);
        return;
    }

    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/report?messageKey=%@", KBASE_URL, messageKey];

    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:nil];

    [ALResponseHandler processRequest:theRequest andTag:@"REPORT_USER" WithCompletionHandler:^(id theJson, NSError *theError) {
        if(theError){
            ALSLog(ALLoggerSeverityError, @"Error in reporting  user  : %@", theError);
            completion(nil, theError);
            return;
        }

        NSString *responseString  = (NSString *)theJson;

        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REPORT_USER : %@",responseString);

        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:responseString];
        completion(apiResponse, theError);
    }];

}

@end
