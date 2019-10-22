//
//  ALRealTimeUpdate.h
//  Applozic
//
//  Created by Sunil on 08/03/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessage.h"
#import "ALUserDetail.h"
#import "ALChannel.h"

@protocol ApplozicUpdatesDelegate <NSObject>

/**
 onMessageReceived will be called once the message is received.

 @param alMessage have ALMessage object which is recieved message.
 @ref ALMessage for message properties.
 */
-(void) onMessageReceived:(ALMessage *) alMessage;

/**
 onMessageSent will be called once the message is sent by same user login in different devices or platforms.

 @param alMessage have ALMessage object which is sent message.
 @ref ALMessage for message properties.

 */
-(void) onMessageSent:(ALMessage *) alMessage;

/**
 onUserDetailsUpdate will be called once the user details updated like name, profile imageUrl, status etc.

 @param userDetail for user properties.
 */
-(void) onUserDetailsUpdate:(ALUserDetail *) userDetail;

/**
 onMessageDelivered will be called once message is delivered to receiver.

 @param message will have ALMessage object which is delivered message it has status.
 */
-(void) onMessageDelivered:(ALMessage *) message;

/**
 onMessageDeleted will be called once message is deleted by same user login in different devices or platforms.

 @param messageKey it will have messageKey of message which is deleted.

 */
-(void) onMessageDeleted:(NSString *) messageKey;

/**
 onMessageDeliveredAndRead will be called once the message is read and delivered by receiver user.

 @param message will have ALMessage object which is delivered and read.
 @param userId of a user which is delivered and read a message.
 */
-(void) onMessageDeliveredAndRead:(ALMessage *) message withUserId:(NSString *) userId;

/**
 onConversationDelete will be called once the conversation is deleted

 @param userId if conversation is deleted for user then userId will be
 @param groupId if conversation is deleted for channel then groupId will be there its channelKey
 */
-(void) onConversationDelete:(NSString *) userId withGroupId: (NSNumber*) groupId;

/**
 conversationReadByCurrentUser will be called once the conversation read by same user login in different devices or platforms.

 @param userId if conversation read for user then userId will be there else groupId will be there.
 @param groupId if conversation raad for channel/group then channelKey will be there and userId will be nil.
 */
-(void) conversationReadByCurrentUser:(NSString *)userId withGroupId:(NSNumber *) groupId;

/**
 onUpdateTypingStatus will be called once the typing.

 @param userId will have user's userId who is typing.
 @param status if status flag is YES or true then user started typing, if status is NO or false then user stop the typing
 */
-(void) onUpdateTypingStatus:(NSString *) userId status: (BOOL) status;

/**
 onUpdateLastSeenAtStatus will be called once the user comes online or goes offline.

 @param alUserDetail will have ALUserDetail  which has a
 */
-(void) onUpdateLastSeenAtStatus: (ALUserDetail *) alUserDetail;

/**
 onUserBlockedOrUnBlocked will be called once the user is blocked or unblocked

 @param userId will have the user's userId blocked or unblocked
 @param flag if true or YES then user is blocked else false or NO then unblocked
 */
-(void) onUserBlockedOrUnBlocked:(NSString *)userId andBlockFlag:(BOOL)flag;
-(void) onChannelUpdated:(ALChannel *)channel;

/**
 onAllMessagesRead will be called once the receiver read the message conversation.

 @param userId will have receiver userId who has read the conversation.
 */
-(void) onAllMessagesRead:(NSString *)userId;

/**
 onMqttConnectionClosed will be called if the MQTT is disconnected you can  resubscribe to conversation
 */
-(void) onMqttConnectionClosed;

/**
 onMqttConnected will be called once the MQTT is connected
 */
-(void) onMqttConnected;

-(void)onUserMuteStatus:(ALUserDetail *)userDetail;

@end

@interface ALRealTimeUpdate : NSObject

@end
