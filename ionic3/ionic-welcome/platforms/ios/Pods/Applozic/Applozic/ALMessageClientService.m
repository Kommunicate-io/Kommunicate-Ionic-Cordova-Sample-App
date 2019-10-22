//
//  ALMessageClientService.m
//  ChatApp
//
//  Created by devashish on 02/10/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALMessageClientService.h"
#import "ALConstant.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALMessage.h"
#import "ALUserDefaultsHandler.h"
#import "ALMessageDBService.h"
#import "ALDBHandler.h"
#import "ALChannelService.h"
#import "ALSyncMessageFeed.h"
#import "ALUtilityClass.h"
#import "ALConversationService.h"
#import "MessageListRequest.h"
#import "ALUserBlockResponse.h"
#import "ALUserService.h"
#import "NSString+Encode.h"
#import "ALApplozicSettings.h"
#import "UIImageView+WebCache.h"
#import "ALConnectionQueueHandler.h"
#import "ALApplozicSettings.h"
#import "SearchResultCache.h"

@implementation ALMessageClientService

-(void) downloadImageUrl: (NSString *) blobKey withCompletion:(void(^)(NSString * fileURL, NSError *error)) completion{
     [self getNSMutableURLRequestForImage:blobKey withCompletion:^(NSMutableURLRequest *urlRequest, NSString *fileUrl) {
         NSMutableURLRequest * nsMutableURLRequest = urlRequest;

         if(nsMutableURLRequest){
             [ALResponseHandler processRequest:urlRequest andTag:@"FILE DOWNLOAD URL" WithCompletionHandler:^(id theJson, NSError *theError) {
                 
                 if (theError)
                 {
                     completion(nil,theError);
                     return;
                 }
                 NSString * imageDownloadURL = (NSString *)theJson;
                 ALSLog(ALLoggerSeverityInfo, @"RESPONSE_IMG_URL :: %@",imageDownloadURL);
                 completion(imageDownloadURL, nil);
                 
             }];
         }else{
             completion(fileUrl,nil);
         }
     }];
    
}

-(void)getNSMutableURLRequestForImage:(NSString *) blobKey  withCompletion:(void(^)(NSMutableURLRequest * urlRequest, NSString *fileUrl)) completion{
    
    NSMutableURLRequest * urlRequest = [[NSMutableURLRequest alloc] init];
    if([ALApplozicSettings isGoogleCloudServiceEnabled]){
        NSString * theUrlString = [NSString stringWithFormat:@"%@/files/url",KBASE_FILE_URL];
        NSString * blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        urlRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:blobParamString];
        completion(urlRequest, nil);
        return;
    }else if([ALApplozicSettings isS3StorageServiceEnabled]) {
        NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/file/url",KBASE_FILE_URL];
        NSString * blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        urlRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:blobParamString];
        completion(urlRequest, nil);
        return;
    }else if([ALApplozicSettings isStorageServiceEnabled]) {
        NSString * theUrlString = [NSString stringWithFormat:@"%@%@%@",KBASE_FILE_URL,IMAGE_DOWNLOAD_ENDPOINT,blobKey];
        completion(nil, theUrlString);
        return;
    }else {
        NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/aws/file/%@",KBASE_FILE_URL,blobKey];
        completion(nil, theUrlString);
        return;
    }
}

-(NSMutableURLRequest *) getURLRequestForThumbnail: (NSString *)blobKey {
    if (blobKey == nil) {
        return nil;
    }
    if ([ALApplozicSettings isGoogleCloudServiceEnabled]) {
        NSString * theUrlString = [NSString stringWithFormat:@"%@/files/url",KBASE_FILE_URL];
        NSString * blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        return [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:blobParamString];
    } else if([ALApplozicSettings isS3StorageServiceEnabled]) {
        NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/file/url",KBASE_FILE_URL];
        NSString * blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        return [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:blobParamString];
    }
    return nil;
}

- (void)downloadImageThumbnailUrl:(NSString *)url blobKey:(NSString *)blobKey completion:(void (^)(NSString *, NSError *))completion {
    NSMutableURLRequest * urlRequest = [self getURLRequestForThumbnail:blobKey];
    if (urlRequest) {
        [ALResponseHandler processRequest:urlRequest andTag:@"FILE DOWNLOAD URL" WithCompletionHandler:^(id theJson, NSError *theError) {
            if (theError)
            {
                completion(nil,theError);
                return;
            }
            NSString * imageDownloadURL = (NSString *)theJson;
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_IMG_URL :: %@",imageDownloadURL);
            completion(imageDownloadURL, nil);
        }];
    } else {
        completion(url, nil);
    }
}

-(void) downloadImageThumbnailUrl: (ALMessage *) message withCompletion:(void(^)(NSString * fileURL, NSError *error)) completion{
    [self downloadImageThumbnailUrl:message.fileMeta.thumbnailUrl blobKey:message.fileMeta.thumbnailBlobKey completion:^(NSString *fileURL, NSError *error) {
        completion(fileURL, error);
    }];
}

-(void) downloadImageUrlAndSet: (NSString *) blobKey imageView:(UIImageView *) imageView defaultImage:(NSString *) defaultImage {
    
    NSURL * theUrl1 = [NSURL URLWithString:blobKey];
    [imageView sd_setImageWithURL:theUrl1 placeholderImage:[ALUtilityClass getImageFromFramworkBundle:defaultImage] options:SDWebImageRefreshCached];
}

-(void) addWelcomeMessage:(NSNumber *)channelKey
{
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    ALMessageDBService* messageDBService = [[ALMessageDBService alloc]init];
    
    ALMessage * theMessage = [ALMessage new];
    
    
    theMessage.contactIds = @"applozic";//1
    theMessage.to = @"applozic";//2
    theMessage.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    theMessage.deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    theMessage.sendToDevice = NO;
    theMessage.shared = NO;
    theMessage.fileMeta = nil;
    theMessage.status = [NSNumber numberWithInt:READ];
    theMessage.key = @"welcome-message-temp-key-string";
    theMessage.delivered=NO;
    theMessage.fileMetaKey = @"";//4
    theMessage.contentType = 0;
    theMessage.status = [NSNumber numberWithInt:DELIVERED_AND_READ];
    if(channelKey!=nil) //Group's Welcome
    {
        theMessage.type=@"101";
        theMessage.message=@"You have created a new group, Say something!!";
        theMessage.groupId = channelKey;
    }
    else //Individual's Welcome
    {
        theMessage.type = @"4";
         theMessage.message = @"Welcome to Applozic! Drop a message here or contact us at devashish@applozic.com for any queries. Thanks";//3
        theMessage.groupId = nil;
    }
    [messageDBService createMessageEntityForDBInsertionWithMessage:theMessage];
    [theDBHandler.managedObjectContext save:nil];
    
}


-(void) getLatestMessageGroupByContact:(NSUInteger)mainPageSize startTime:(NSNumber *)startTime
                        withCompletion:(void(^)(ALMessageList * alMessageList, NSError * error)) completion
{
    ALSLog(ALLoggerSeverityInfo, @"\nGet Latest Messages \t State:- User Login ");
    
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/list",KBASE_URL];
    
    NSString * theParamString = [NSString stringWithFormat:@"startIndex=%@&mainPageSize=%lu&deletedGroupIncluded=%@",
                                 @"0",(unsigned long)mainPageSize,@(YES)];
    
    if(startTime)
    {
      theParamString = [NSString stringWithFormat:@"startIndex=%@&mainPageSize=%lu&endTime=%@&deletedGroupIncluded=%@",
                        @"0", (unsigned long)mainPageSize, startTime,@(YES)];
    }
    if([ALApplozicSettings getCategoryName]){
        theParamString = [theParamString stringByAppendingString:[NSString stringWithFormat:@"&category=%@",
        [ALApplozicSettings getCategoryName]]];
    }
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"GET MESSAGES GROUP BY CONTACT" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError)
        {
            completion(nil, theError);
            return ;
        }


        ALMessageList *messageListResponse =  [[ALMessageList alloc] initWithJSONString:theJson] ;
        ALSLog(ALLoggerSeverityInfo, @"message list response THE JSON %@",theJson);

        if(theJson){

            if(messageListResponse.userDetailsList){
                ALContactDBService *alContactDBService = [[ALContactDBService alloc] init];
                [alContactDBService addUserDetails:messageListResponse.userDetailsList];
            }

            ALChannelService *channelService = [[ALChannelService alloc] init];
            [channelService callForChannelServiceForDBInsertion:theJson];
        }

        //USER BLOCK SYNC CALL
        ALUserService * userService = [ALUserService new];
        [userService blockUserSync: [ALUserDefaultsHandler getUserBlockLastTimeStamp]];

        completion(messageListResponse, nil);

    }];
    
}

-(void) getMessagesListGroupByContactswithCompletion:(void(^)(NSMutableArray * messages, NSError * error)) completion
{
    ALSLog(ALLoggerSeverityInfo, @"\nGet Latest Messages \t State:- User Opens Message List View");
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/list",KBASE_URL];
    
    NSString * theParamString = [NSString stringWithFormat:@"startIndex=%@&deletedGroupIncluded=%@",@"0",@(YES)];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"GET MESSAGES GROUP BY CONTACT" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError) {
            completion(nil,theError);
            return;
        }
        
        ALMessageList *messageListResponse =  [[ALMessageList alloc] initWithJSONString:theJson];
        
        [ALMessageService getMessageListForUserIfLastIsHiddenMessageinMessageList:messageListResponse withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {
            completion(messages,error);
        }];
//        NSLog(@"getMessagesListGroupByContactswithCompletion message list response THE JSON %@",theJson);
        //        [ALUserService processContactFromMessages:[messageListResponse messageList]];
        
        ALChannelService *channelService = [[ALChannelService alloc] init];
        [channelService callForChannelServiceForDBInsertion:theJson];
        
    }];
    
}

-(void)getMessageListForUser:(MessageListRequest *)messageListRequest withOpenGroup:(BOOL )isOpenGroup withCompletion:(void (^)(NSMutableArray *, NSError *, NSMutableArray *))completion
{
    ALSLog(ALLoggerSeverityInfo, @"CHATVC_OPENS_1st TIME_CALL");
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/list",KBASE_URL];
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:messageListRequest.getParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"GET MESSAGES LIST FOR USERID" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"MSG_LIST ERROR :: %@",theError.description);
            completion(nil, theError, nil);
            return;
        }
        if(messageListRequest.channelKey && !(messageListRequest.channelType == OPEN))
        {
            [ALUserDefaultsHandler setServerCallDoneForMSGList:true forContactId:[messageListRequest.channelKey stringValue]];
        }
        else
        {
            [ALUserDefaultsHandler setServerCallDoneForMSGList:true forContactId:messageListRequest.userId];
        }
        if(messageListRequest.conversationId)
        {
            [ALUserDefaultsHandler setServerCallDoneForMSGList:true forContactId:[messageListRequest.conversationId stringValue]];
        }
        
        ALMessageList *messageListResponse = [[ALMessageList alloc] initWithJSONString:theJson
                                                                         andWithUserId:messageListRequest.userId
                                                                          andWithGroup:messageListRequest.channelKey];
        
        if(!isOpenGroup){
            ALMessageDBService *almessageDBService = [[ALMessageDBService alloc] init];
            [almessageDBService addMessageList:messageListResponse.messageList];
        }
        ALConversationService * alConversationService = [[ALConversationService alloc] init];
        [alConversationService addConversations:messageListResponse.conversationPxyList];
        
        ALChannelService *channelService = [[ALChannelService alloc] init];
        [channelService callForChannelServiceForDBInsertion:theJson];
        
        completion(messageListResponse.messageList, nil, messageListResponse.userDetailsList);
        ALSLog(ALLoggerSeverityInfo, @"MSG_LIST RESPONSE :: %@",(NSString *)theJson);
        
    }];
}

-(void)getMessageListForUser:(MessageListRequest *)messageListRequest withCompletion:(void (^)(NSMutableArray *, NSError *, NSMutableArray *))completion
{
    ALChannel *channel = nil;
    if(messageListRequest.channelKey){
       channel =  [[ALChannelService sharedInstance] getChannelByKey:messageListRequest.channelKey];
    }

    [self getMessageListForUser:messageListRequest withOpenGroup:(channel != nil && channel.type == OPEN) withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {

        completion(messages, error, userDetailArray);

    }];
}

-(void) sendPhotoForUserInfo:(NSDictionary *)userInfo withCompletion:(void(^)(NSString * message, NSError *error)) completion {
    if(ALApplozicSettings.isStorageServiceEnabled) {
        NSString * theUrlString = [NSString stringWithFormat:@"%@%@", KBASE_FILE_URL, IMAGE_UPLOAD_ENDPOINT];
        completion(theUrlString, nil);
    }else if(ALApplozicSettings.isS3StorageServiceEnabled) {
        NSString * theUrlString = [NSString stringWithFormat:@"%@%@", KBASE_FILE_URL, CUSTOM_STORAGE_IMAGE_UPLOAD_ENDPOINT];
        completion(theUrlString, nil);
    }else if(ALApplozicSettings.isGoogleCloudServiceEnabled){
        NSString * theUrlString = [NSString stringWithFormat:@"%@%@", KBASE_FILE_URL, IMAGE_UPLOAD_ENDPOINT];
        completion(theUrlString, nil);
    }else {
        NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/aws/file/url",KBASE_FILE_URL];
        
        NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:nil];
        
        [ALResponseHandler processRequest:theRequest andTag:@"CREATE FILE URL" WithCompletionHandler:^(id theJson, NSError *theError) {

            if (theError)
            {
                completion(nil,theError);
                return;
            }

            NSString *imagePostingURL = (NSString *)theJson;
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_IMG_URL :: %@",imagePostingURL);
            completion(imagePostingURL, nil);

        }];
    }
}

-(void) getLatestMessageForUser:(NSString *)deviceKeyString withCompletion:(void (^)( ALSyncMessageFeed *, NSError *))completion
{
    [self getLatestMessageForUser:deviceKeyString withMetaDataSync:NO withCompletion:^(ALSyncMessageFeed *syncResponse, NSError *nsError) {
        completion(syncResponse,nsError);
    }];
}

-(void)deleteMessage:(NSString *) keyString andContactId:(NSString *)contactId withCompletion:(void (^)(NSString *, NSError *))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/delete",KBASE_URL];
    NSString * theParamString = [NSString stringWithFormat:@"key=%@&userId=%@",keyString,[contactId urlEncodeUsingNSUTF8StringEncoding]];
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"DELETE_MESSAGE" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError)
        {
            completion(nil,theError);
            return;
        }
        else{
            completion((NSString *)theJson,nil);
        }
      ALSLog(ALLoggerSeverityInfo, @"Response DELETE_MESSAGE: %@", (NSString *)theJson);
    }];
}


-(void)deleteMessageThread:( NSString * ) contactId orChannelKey:(NSNumber *)channelKey withCompletion:(void (^)(NSString *, NSError *))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/delete/conversation",KBASE_URL];
    NSString * theParamString;
    if(channelKey != nil)
    {
        theParamString = [NSString stringWithFormat:@"groupId=%@",channelKey];
    }
    else
    {
        theParamString = [NSString stringWithFormat:@"userId=%@",[contactId urlEncodeUsingNSUTF8StringEncoding]];
    }
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"DELETE_MESSAGE_THREAD" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (!theError)
        {
            ALMessageDBService * dbService = [[ALMessageDBService alloc] init];
            [dbService deleteAllMessagesByContact:contactId orChannelKey:channelKey];
        }
        ALSLog(ALLoggerSeverityInfo, @"Response DELETE_MESSAGE_THREAD: %@", (NSString *)theJson);
        ALSLog(ALLoggerSeverityError, @"ERROR DELETE_MESSAGE_THREAD: %@", theError.description);
        completion((NSString *)theJson,theError);
    }];
}

-(void)sendMessage: (NSDictionary *) userInfo WithCompletionHandler:(void(^)(id theJson, NSError *theError))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/v2/send",KBASE_URL];
    NSString * theParamString = [ALUtilityClass generateJsonStringFromDictionary:userInfo];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"SEND MESSAGE" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError) {
            completion(nil,theError);
            return;
        }
        completion(theJson,nil);
    }];

}

-(void)getCurrentMessageInformation:(NSString *)messageKey withCompletionHandler:(void(^)(ALMessageInfoResponse *msgInfo, NSError *theError))completion
{
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/info", KBASE_URL];
    NSString * theParamString = [NSString stringWithFormat:@"key=%@", messageKey];
    
    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];
    
    [ALResponseHandler processRequest:theRequest andTag:@"MESSSAGE_INFORMATION" WithCompletionHandler:^(id theJson, NSError *theError) {
        
        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"ERROR IN MESSAGE INFORMATION API RESPONSE : %@", theError);
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE MESSSAGE_INFORMATION API JSON : %@", (NSString *)theJson);
            ALMessageInfoResponse *msgInfoObject = [[ALMessageInfoResponse alloc] initWithJSONString:(NSString *)theJson];
            completion(msgInfoObject, theError);
        }
    }];

}

-(void) getLatestMessageForUser:(NSString *)deviceKeyString withMetaDataSync:(BOOL)isMetaDataUpdate withCompletion:(void (^)( ALSyncMessageFeed *, NSError *))completion
{
    if(!deviceKeyString){
        return;
    }
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/sync",KBASE_URL];
    NSString * lastSyncTime;
    NSString * theParamString;
    if(isMetaDataUpdate) {
        lastSyncTime =  [NSString stringWithFormat:@"%@", [ALUserDefaultsHandler getLastSyncTimeForMetaData]];
        theParamString =  [NSString stringWithFormat:@"lastSyncTime=%@&metadataUpdate=true",lastSyncTime];
    } else {
        lastSyncTime =  [NSString stringWithFormat:@"%@", [ALUserDefaultsHandler getLastSyncTime]];
        theParamString =  [NSString stringWithFormat:@"lastSyncTime=%@",lastSyncTime];
    }

    ALSLog(ALLoggerSeverityInfo, @"LAST SYNC TIME IN CALL :  %@", lastSyncTime);

    NSMutableURLRequest * theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];

    [ALResponseHandler processRequest:theRequest andTag:@"SYNC LATEST MESSAGE URL" WithCompletionHandler:^(id theJson, NSError *theError) {

        if(theError)
        {
            [ALUserDefaultsHandler setMsgSyncRequired:YES];
            completion(nil,theError);
            return;
        }

        [ALUserDefaultsHandler setMsgSyncRequired:NO];
        ALSyncMessageFeed *syncResponse =  [[ALSyncMessageFeed alloc] initWithJSONString:theJson];
        ALSLog(ALLoggerSeverityInfo, @"LATEST_MESSAGE_JSON: %@", (NSString *)theJson);
        completion(syncResponse,nil);
    }];
}

- (void)updateMessageMetadataOfKey:(NSString *)messageKey withMetadata:(NSMutableDictionary *)metadata withCompletion:(void (^)(id, NSError *))completion
{
    ALSLog(ALLoggerSeverityInfo, @"Updating message metadata for message : %@", messageKey);
    NSString * theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/update/metadata",KBASE_URL];
    NSMutableDictionary *messageMetadata = [NSMutableDictionary new];

    [messageMetadata setObject:messageKey forKey:@"key"];
    [messageMetadata setObject:metadata forKey:@"metadata"];

    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:messageMetadata options:0 error:&error];
    NSString *theParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    NSMutableURLRequest * theRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:theParamString];

    [ALResponseHandler processRequest:theRequest andTag:@"UPDATE_MESSAGE_METADATA" WithCompletionHandler:^(id theJson, NSError *theError) {
        if (theError) {
            ALSLog(ALLoggerSeverityError, @"Error while updating message metadata: %@", theError);
            completion(nil,theError);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Message metadata updated successfully with result : %@", theJson);
        completion(theJson,nil);
    }];
}

- (void)searchMessage: (NSString *)key withCompletion: (void (^)(NSMutableArray<ALMessage *> *, NSError *))completion {
    ALSLog(ALLoggerSeverityInfo, @"Search messages with %@", key);
    NSString *urlString = [NSString stringWithFormat:@"%@/rest/ws/group/support", KBASE_URL];
    NSString *paramString = [NSString stringWithFormat:@"search=%@", [key urlEncodeUsingNSUTF8StringEncoding]];
    NSMutableURLRequest *urlRequest = [ALRequestHandler
                                       createGETRequestWithUrlString: urlString
                                       paramString: paramString];
    [ALResponseHandler
     processRequest: urlRequest
     andTag: @"Search messages"
     WithCompletionHandler: ^(id theJson, NSError *theError) {
         if (theError) {
             ALSLog(ALLoggerSeverityError, @"Search messages ERROR :: %@",theError.description);
             completion(nil, theError);
             return;
         }
         if (![[theJson valueForKey:@"status"] isEqualToString:@"success"]) {
             ALSLog(ALLoggerSeverityError, @"Search messages ERROR :: %@",theError.description);
             NSError *error = [NSError
                               errorWithDomain:@"Applozic"
                               code:1
                               userInfo:[NSDictionary
                                         dictionaryWithObject:@"Status fail in response"
                                         forKey:NSLocalizedDescriptionKey]];
             completion(nil, error);
             return;
         }
         NSDictionary *response = [theJson valueForKey: @"response"];
         if (response == nil) {
             ALSLog(ALLoggerSeverityError, @"Search messages RESPONSE is nil");
             NSError *error = [NSError errorWithDomain:@"response is nil" code:0 userInfo:nil];
             completion(nil, error);
             return;
         }
         ALSLog(ALLoggerSeverityInfo, @"Search messages RESPONSE :: %@", (NSString *)theJson);
         NSMutableArray<ALMessage *> *messages = [NSMutableArray new];
         NSDictionary *messageDict = [response valueForKey: @"message"];
         for (NSDictionary *dict in messageDict)
         {
             ALMessage *message = [[ALMessage alloc] initWithDictonary: dict];
             [messages addObject: message];
         }
         ALChannelFeed *channelFeed = [[ALChannelFeed alloc] initWithJSONString: response];
         [[SearchResultCache shared] saveChannels: channelFeed.channelFeedsList];
         completion(messages, nil);
         return;
     }];
}

- (void)getMessageListForUser: (MessageListRequest *)messageListRequest
                     isSearch: (BOOL)flag
               withCompletion: (void (^)(NSMutableArray<ALMessage *> *, NSError *))completion {
    NSString * theUrlString = [NSString stringWithFormat: @"%@/rest/ws/message/list", KBASE_URL];
    NSMutableURLRequest * theRequest = [ALRequestHandler
                                        createGETRequestWithUrlString: theUrlString
                                        paramString: messageListRequest.getParamString];

    [ALResponseHandler processRequest:theRequest andTag:@"Messages for searched conversation" WithCompletionHandler:^(id theJson, NSError *theError) {

        if (theError)
        {
            ALSLog(ALLoggerSeverityError, @"Error while getting messages :: %@", theError.description);
            completion(nil, theError);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Messages fetched succesfully :: %@", (NSString *)theJson);

        NSDictionary * messageDict = [theJson valueForKey:@"message"];
        NSMutableArray<ALMessage *> *messages = [NSMutableArray new];
        for (NSDictionary * dict in messageDict) {
            ALMessage *message = [[ALMessage alloc] initWithDictonary: dict];
            [messages addObject: message];
        }

        NSDictionary * userDetailDict = [theJson valueForKey:@"userDetails"];
        NSMutableArray<ALUserDetail *> *userDetails = [NSMutableArray new];
        for (NSDictionary * dict in userDetailDict) {
            ALUserDetail * userDetail = [[ALUserDetail alloc] initWithDictonary: dict];
            [userDetails addObject: userDetail];
        }
        [[SearchResultCache shared] saveUserDetails: userDetails];

        completion(messages, nil);
    }];
}

@end
