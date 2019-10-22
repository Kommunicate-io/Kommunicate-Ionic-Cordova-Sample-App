//
//  ALMessageDBService.h
//  ChatApp
//
//  Created by Devashish on 21/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DB_FileMetaInfo.h"
#import "DB_Message.h"
#import "ALMessage.h"
#import "ALFileMetaInfo.h"
#import "MessageListRequest.h"

@protocol ALMessagesDelegate <NSObject>

-(void)getMessagesArray:(NSMutableArray*)messagesArray;

-(void) updateMessageList:(NSMutableArray*)messagesArray;

@end

@interface ALMessageDBService : NSObject
//Add Message APIS
-(NSMutableArray *)addMessageList:(NSMutableArray*) messageList;
-(DB_Message*)addMessage:(ALMessage*) message;
-(void)getMessages:(NSMutableArray *)subGroupList;
-(void)fetchAndRefreshFromServer:(NSMutableArray *)subGroupList;
-(void)fetchConversationsGroupByContactId;
-(void)fetchAndRefreshQuickConversationWithCompletion:(void (^)( NSMutableArray *, NSError *))completion;

-(NSManagedObject *)getMeesageById:(NSManagedObjectID *)objectID
                             error:(NSError **)error;
- (NSManagedObject *)getMessageByKey:(NSString *) key value:(NSString*) value;

-(NSMutableArray *)getMessageListForContactWithCreatedAt:(MessageListRequest *)messageListRequest;

-(NSMutableArray *)getAllMessagesWithAttachmentForContact:(NSString *)contactId
                                            andChannelKey:(NSNumber *)channelKey
                                onlyDownloadedAttachments: (BOOL )onlyDownloaded;

-(NSMutableArray *)getPendingMessages;

/**
 * Returns a list of last messages (Group by Contact)
 *
 * @param messageCount The Number of messages required.
 * @param received If YES, messages will be of type received. If NO, then messages can be of type received or sent.
 * @return An array containing the list of messages.
 */
-(NSArray *)getMessageList:(int)messageCount
                               messageTypeOnlyReceived:(BOOL)received;

//update Message APIS
-(void)updateMessageDeliveryReport:(NSString*)messageKeyString withStatus:(int)status;
-(void)updateDeliveryReportForContact:(NSString *)contactId withStatus:(int)status;
-(void)updateMessageSyncStatus:(NSString*) keyString;
-(void)updateFileMetaInfo:(ALMessage *) almessage;

//Delete Message APIS

-(void) deleteMessage;
-(void) deleteMessageByKey:(NSString*) keyString;
-(void) deleteAllMessagesByContact: (NSString*) contactId orChannelKey:(NSNumber *)key;

//Generic APIS
-(BOOL) isMessageTableEmpty;
-(void)deleteAllObjectsInCoreData;

-(DB_Message *) createMessageEntityForDBInsertionWithMessage:(ALMessage *) theMessage;
-(DB_FileMetaInfo *) createFileMetaInfoEntityForDBInsertionWithMessage:(ALFileMetaInfo *) fileInfo;
-(ALMessage *) createMessageEntity:(DB_Message *) theEntity;
-(ALMessage*) getMessageByKey:(NSString*)messageKey;

@property(nonatomic,weak) id <ALMessagesDelegate>delegate;

-(NSMutableArray*)fetchLatestConversationsGroupByContactId :(BOOL) isFetchOnCreatedAtTime ;

-(void)fetchConversationfromServerWithCompletion:(void(^)(BOOL flag))completionHandler;

-(NSUInteger)getMessagesCountFromDBForUser:(NSString *)userId;

-(ALMessage *)getLatestMessageForUser:(NSString *)userId;

-(ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey excludeChannelOperations:(BOOL)flag;

+(void)addBroadcastMessageToDB:(ALMessage *)alMessage;
-(void) updateMessageReplyType:(NSString*)messageKeyString replyType : (NSNumber *) type ;

-(void) updateMessageSentDetails:(NSString*)messageKeyString withCreatedAtTime : (NSNumber *) createdAtTime withDbMessage:(DB_Message *) dbMessage ;

-(void) getLatestMessages:(BOOL)isNextPage withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion;

-(void) getLatestMessages:(BOOL)isNextPage withOnlyGroups:(BOOL)isGroup withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion;

-(ALMessage *)handleMessageFailedStatus:(ALMessage *)message;

-(DB_Message*)addAttachmentMessage:(ALMessage*)message;

-(void) updateMessageMetadataOfKey:(NSString*)messageKey withMetadata:(NSMutableDictionary*) metadata ;

-(ALMessage*)writeDataAndUpdateMessageInDb:(NSData*)data withMessageKey:(NSString *)messageKey withFileFlag:(BOOL)isFile;
@end
