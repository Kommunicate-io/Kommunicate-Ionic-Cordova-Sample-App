//
//  ALMessageService.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALConstant.h"
#import "ALSyncMessageFeed.h"
#import "ALMessageList.h"
#import "ALMessage.h"
#import "DB_FileMetaInfo.h"
#import "ALUserDetail.h"
#import "ALChannelService.h"
#import  "MessageListRequest.h"
#import "ALMessageInfoResponse.h"
#import "ALMQTTConversationService.h"
#import "ALRealTimeUpdate.h"
#import "ALConversationProxy.h"

#define NEW_MESSAGE_NOTIFICATION @"newMessageNotification"
#define CONVERSATION_CALL_COMPLETED @"conversationCallCompleted"
#define MESSAGE_META_DATA_UPDATE @"messageMetaDataUpdateNotification"

@interface ALMessageService : NSObject 

+(ALMessageService *)sharedInstance;

@property (nonatomic, weak) id<ApplozicUpdatesDelegate> delegate;

+(void) processLatestMessagesGroupByContact;

+(void) processLatestMessagesGroupByContactWithCompletion:(void(^)(void))completion;

-(void) getMessageListForUser:(MessageListRequest*)messageListRequest withCompletion:(void(^)(NSMutableArray * messages, NSError * error, NSMutableArray *userDetailArray)) completion;

+(void) getMessageListForContactId:(NSString *)contactIds isGroup:(BOOL )isGroup channelKey:(NSNumber *)channelKey conversationId:(NSNumber *)conversationId startIndex:(NSInteger)startIndex withCompletion:(void (^)(NSMutableArray *))completion;

-(void) sendMessages:(ALMessage *)message withCompletion:(void(^)(NSString * message, NSError * error)) completion;

+(void) getLatestMessageForUser:(NSString *)deviceKeyString withCompletion:(void(^)(NSMutableArray  * message, NSError *error)) completion;

+(ALMessage*) processFileUploadSucess: (ALMessage *)message;

+(void)deleteMessageThread:( NSString * ) contactId orChannelKey:(NSNumber *)channelKey withCompletion:(void (^)(NSString *, NSError *))completion;

+(void )deleteMessage:( NSString * ) keyString andContactId:( NSString * )contactId withCompletion:(void (^)(NSString *, NSError *))completion;

-(void)processPendingMessages;

+(ALMessage*)getMessagefromKeyValuePair:(NSString*)key andValue:(NSString*)value;

-(void)getMessageInformationWithMessageKey:(NSString *)messageKey withCompletionHandler:(void(^)(ALMessageInfoResponse *msgInfo, NSError *theError))completion;

+(void)multiUserSendMessage:(ALMessage *)alMessage
                 toContacts:(NSMutableArray*)contactIdsArray
                   toGroups:(NSMutableArray*)channelKeysArray
             withCompletion:(void(^)(NSString * json, NSError * error)) completion;

+(void)getMessageSENT:(ALMessage*)alMessage  withCompletion:(void (^)( NSMutableArray *, NSError *))completion;

+(void)getMessageSENT:(ALMessage*)alMessage withDelegate : (id<ApplozicUpdatesDelegate>)theDelegate  withCompletion:(void (^)( NSMutableArray *, NSError *))completion;

+(ALMessage *) createCustomTextMessageEntitySendTo:(NSString *)to withText:(NSString*)text;

+(void)getMessageListForUserIfLastIsHiddenMessageinMessageList:(ALMessageList*)alMessageList withCompletion:(void (^)(NSMutableArray *, NSError *, NSMutableArray *))completion;

+(void)getMessagesListGroupByContactswithCompletionService:(void(^)(NSMutableArray * messages, NSError * error))completion;

+(ALMessage *)createHiddenMessageEntitySentTo:(NSString*)to withText:(NSString*)text;

+(ALMessage *)createMessageWithMetaData:(NSMutableDictionary *)metaData andContentType:(short)contentType andReceiverId:(NSString *)receiverId andMessageText:(NSString *)msgTxt;

-(NSUInteger)getMessagsCountForUser:(NSString *)userId;

-(ALMessage *)getLatestMessageForUser:(NSString *)userId;

-(ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey excludeChannelOperations:(BOOL)flag;

-(ALMessage *)getALMessageByKey:(NSString*)messageReplyId;

+(void)addBroadcastMessageToDB:(ALMessage *)alMessage;
+(void)syncMessages;
+(void) getLatestMessageForUser:(NSString *)deviceKeyString withDelegate : (id<ApplozicUpdatesDelegate>)theDelegate withCompletion:(void (^)( NSMutableArray *, NSError *))completion;

-(void) getLatestMessages:(BOOL)isNextPage withOnlyGroups:(BOOL)isGroup withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion;

+(void)addOpenGroupMessage:(ALMessage*)alMessage withDelegate:(id<ApplozicUpdatesDelegate>)delegate;

-(ALMessage *)handleMessageFailedStatus:(ALMessage *)message;

-(ALMessage*) getMessageByKey:(NSString*)messageKey;

+(void) syncMessageMetaData:(NSString *)deviceKeyString withCompletion:(void (^)( NSMutableArray *, NSError *))completion;

-(void)updateMessageMetadataOfKey:(NSString*) messageKey withMetadata: (NSMutableDictionary *) metadata withCompletion:(void(^)(ALAPIResponse* theJson, NSError *theError)) completion;
@end
