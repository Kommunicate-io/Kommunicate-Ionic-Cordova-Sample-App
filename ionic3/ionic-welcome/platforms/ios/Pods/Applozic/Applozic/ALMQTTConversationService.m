//
//  ALMQTTConversationService.m
//  Applozic
//
//  Created by Applozic Inc on 11/27/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALMQTTConversationService.h"
#import "ALUserDefaultsHandler.h"
#import "ALConstant.h"
#import "ALMessage.h"
#import "ALMessageDBService.h"
#import "ALUserDetail.h"
#import "ALPushAssist.h"
#import "ALChannelService.h"
#import "ALContactDBService.h"
#import "ALMessageService.h"
#import "ALUserService.h"
#import "NSData+AES.h"
#import "ALDataNetworkConnection.h"

#define MQTT_TOPIC_STATUS @"status-v2"
#define MQTT_ENCRYPTION_SUB_KEY @"encr-"
static NSString * const observeSupportGroupMessage = @"observeSupportGroupMessage";

@implementation ALMQTTConversationService

/*
 Notification types :
 
 MESSAGE_RECEIVED("APPLOZIC_01"),
 MESSAGE_SENT("APPLOZIC_02"),
 MESSAGE_SENT_UPDATE("APPLOZIC_03"),
 MESSAGE_DELIVERED("APPLOZIC_04"),
 MESSAGE_DELETED("APPLOZIC_05"),
 CONVERSATION_DELETED("APPLOZIC_06"),
 MESSAGE_READ("APPLOZIC_07"),
 MESSAGE_DELIVERED_AND_READ("APPLOZIC_08"),
 CONVERSATION_READ("APPLOZIC_09"),
 CONVERSATION_DELIVERED_AND_READ("APPLOZIC_10"),
 USER_CONNECTED("APPLOZIC_11"),
 USER_DISCONNECTED("APPLOZIC_12"),
 GROUP_DELETED("APPLOZIC_13"),
 GROUP_LEFT("APPLOZIC_14"),
 GROUP_SYNC("APPLOZIC_15"),
 USER_BLOCKED("APPLOZIC_16"),
 USER_UN_BLOCKED("APPLOZIC_17"),
 ACTIVATED("APPLOZIC_18"),
 DEACTIVATED("APPLOZIC_19"),
 REGISTRATION("APPLOZIC_20"),
 GROUP_CONVERSATION_READ("APPLOZIC_21"),
 GROUP_MESSAGE_DELETED("APPLOZIC_22"),
 GROUP_CONVERSATION_DELETED("APPLOZIC_23"),
 APPLOZIC_TEST("APPLOZIC_24"),
 USER_ONLINE_STATUS("APPLOZIC_25"),
 CONTACT_SYNC("APPLOZIC_26"),
 CONVERSATION_DELETED_NEW("APPLOZIC_27"),
 CONVERSATION_DELIVERED_AND_READ_NEW("APPLOZIC_28"),
 CONVERSATION_READ_NEW("APPLOZIC_29"),
 USER_DETAIL_CHANGED("APPLOZIC_30"),
 MESSAGE_METADATA_UPDATE("APPLOZIC_33"),
 USER_DELETE_NOTIFICATION("APPLOZIC_34"),
 USER_MUTE_NOTIFICATION("APPLOZIC_37");

 */

+(ALMQTTConversationService *)sharedInstance
{
    static ALMQTTConversationService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALMQTTConversationService alloc] init];
        sharedInstance.alSyncCallService = [[ALSyncCallService alloc] init];
    });
    return sharedInstance;
}

-(NSString *) getNotificationObjectFromMessage:(ALMessage *) message
{
    if (message.groupId != nil) {
        return [NSString stringWithFormat:@"AL_GROUP:%@:%@",message.groupId.stringValue,message.contactIds];
    } else if (message.conversationId != nil) {
        return [NSString stringWithFormat:@"%@:%@",message.contactIds,message.conversationId.stringValue];
    } else {
        return [[NSString alloc] initWithString:message.contactIds];
    }
}

-(void) subscribeToConversation {
    [self subscribeToConversationWithTopic:[ALUserDefaultsHandler getUserKeyString]];
}

-(void) subscribeToConversationWithTopic:(NSString *) topic {
    
    dispatch_async(dispatch_get_main_queue (),^{
        
        @try
        {
            if (![ALUserDefaultsHandler isLoggedIn]) {
                return;
            }
            if(self.session && (self.session.status == MQTTSessionEventConnected || self.session.status == MQTTSessionStatusConnecting || self.session.status == MQTTSessionStatusConnected)) {
                ALSLog(ALLoggerSeverityInfo, @"MQTT : IGNORING REQUEST, ALREADY CONNECTED");
                return;
            }
            ALSLog(ALLoggerSeverityInfo, @"MQTT : CONNECTING_MQTT_SERVER");
            self.session =   [[MQTTSession alloc]init];
            self.session.clientId = [NSString stringWithFormat:@"%@-%f",
                                                                  [ALUserDefaultsHandler getUserKeyString],fmod([[NSDate date] timeIntervalSince1970], 10.0)];
            
            NSString * willMsg = [NSString stringWithFormat:@"%@,%@,%@",[ALUserDefaultsHandler getUserKeyString],[ALUserDefaultsHandler getDeviceKeyString],@"0"];
            
            self.session.willFlag = YES;
            self.session.willTopic = MQTT_TOPIC_STATUS;
            self.session.willMsg = [willMsg dataUsingEncoding:NSUTF8StringEncoding];
            self.session.willQoS = MQTTQosLevelAtMostOnce;
            [self.session setDelegate:self];

            MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
            transport.host = MQTT_URL;
            transport.port = [MQTT_PORT intValue];
            self.session.transport = transport;
            ALSLog(ALLoggerSeverityInfo, @"MQTT : WAITING_FOR_CONNECT...");


            [self.session connectWithConnectHandler:^(NSError *error) {
                if (error == nil)
                {
                    ALSLog(ALLoggerSeverityInfo, @"MQTT : CONNECTED");
                    NSString * publishString = [NSString stringWithFormat:@"%@,%@,%@", [ALUserDefaultsHandler getUserKeyString], [ALUserDefaultsHandler getDeviceKeyString],@"1"];

                    [self.session publishAndWaitData:[publishString dataUsingEncoding:NSUTF8StringEncoding] onTopic:MQTT_TOPIC_STATUS retain:NO qos:MQTTQosLevelAtMostOnce timeout:30];

                    ALSLog(ALLoggerSeverityInfo, @"MQTT : SUBSCRIBING TO CONVERSATION TOPICS");
                    if([ALUserDefaultsHandler getEnableEncryption] && [ALUserDefaultsHandler getUserEncryptionKey] ){
                        [self.session subscribeToTopic:[NSString stringWithFormat:@"%@%@",MQTT_ENCRYPTION_SUB_KEY, topic] atLevel:MQTTQosLevelAtMostOnce];
                    }else{
                        [self.session subscribeToTopic: topic atLevel:MQTTQosLevelAtMostOnce];
                    }
                    [ALUserDefaultsHandler setLoggedInUserSubscribedMQTT:YES];
                    [self.mqttConversationDelegate mqttDidConnected];
                    if(self.realTimeUpdate){
                        [self.realTimeUpdate onMqttConnected];
                    }
                }
            }];
        }
        @catch (NSException * e) {
            ALSLog(ALLoggerSeverityError, @"MQTT : EXCEPTION_IN_SUBSCRIBE :: %@", e.description);
        }
    });
}

- (void)session:(MQTTSession*)session newMessage:(NSData*)data onTopic:(NSString*)topic {
    ALSLog(ALLoggerSeverityInfo, @"MQTT: GOT_NEW_MESSAGE");
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{

    if(![ALUserDefaultsHandler getUserKeyString]){
        return;
    }

    NSString *fullMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if([ALUserDefaultsHandler getEnableEncryption] && [ALUserDefaultsHandler getUserEncryptionKey] && [topic hasPrefix:MQTT_ENCRYPTION_SUB_KEY]){

        ALSLog(ALLoggerSeverityInfo, @"Key : %@",  [ALUserDefaultsHandler getUserEncryptionKey]);
        NSData *base64DecodedData = [[NSData alloc] initWithBase64EncodedData:data options:0];
        NSData *theData = [base64DecodedData AES128DecryptedDataWithKey:[ALUserDefaultsHandler getUserEncryptionKey]];
        NSString * dataToString = [NSString stringWithUTF8String:[theData bytes]];
        ALSLog(ALLoggerSeverityInfo, @"Data to String : %@",  dataToString);
        data = [dataToString dataUsingEncoding:NSUTF8StringEncoding];

        ALSLog(ALLoggerSeverityInfo, @"MQTT_GOT_NEW_MESSAGE after decyption : %@", dataToString);
    }else{
        fullMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding ];
    }

    ALSLog(ALLoggerSeverityInfo, @"MQTT_GOT_NEW_MESSAGE : %@", fullMessage);

    if(!fullMessage){
        return;
    }

    NSError *error = nil;
    NSDictionary *theMessageDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSString *type = [theMessageDict objectForKey:@"type"];
    ALSLog(ALLoggerSeverityInfo, @"MQTT_NOTIFICATION_TYPE :: %@",type);
    NSString *notificationId = (NSString* )[theMessageDict valueForKey:@"id"];

    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground )
    {
        ALSLog(ALLoggerSeverityInfo, @"Returing coz Application State is Background OR Our View is NOT on Top");
        if ([topic hasPrefix:@"typing"])
        {
            [self subProcessTyping:fullMessage];
        }
        return;
    }

    if(notificationId && [ALUserDefaultsHandler isNotificationProcessd:notificationId])
    {
        ALSLog(ALLoggerSeverityInfo, @"MQTT : NOTIFICATION-ID ALREADY PROCESSED :: %@",notificationId);
        return;
    }

    if ([topic hasPrefix:@"typing"])
    {
        [self subProcessTyping:fullMessage];
    }
    else
    {
        if ([type isEqualToString: @"MESSAGE_RECEIVED"] || [type isEqualToString:@"APPLOZIC_01"])
        {

            ALPushAssist* assistant = [[ALPushAssist alloc] init];
            ALMessage *alMessage = [[ALMessage alloc] initWithDictonary:[theMessageDict objectForKey:@"message"]];


            if([alMessage isHiddenMessage])
            {
              ALSLog(ALLoggerSeverityInfo, @"< HIDDEN MESSAGE RECEIVED >");
                [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withDelegate:self.realTimeUpdate
                                           withCompletion:^(NSMutableArray *message, NSError *error) { }];
            }
            else
            {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setObject:[alMessage getNotificationText] forKey:@"alertValue"];
                [dict setObject:[NSNumber numberWithInt:APP_STATE_ACTIVE] forKey:@"updateUI"];

                if(alMessage.groupId){
                    ALChannelService *channelService = [[ALChannelService alloc] init];
                    [channelService  getChannelInformation:alMessage.groupId orClientChannelKey:nil withCompletion:^(ALChannel *alChannel) {

                        if(alChannel && alChannel.type == OPEN){
                            if(alMessage.deviceKey && [alMessage.deviceKey isEqualToString:[ALUserDefaultsHandler getDeviceKeyString]]) {
                                ALSLog(ALLoggerSeverityInfo, @"MQTT : RETURNING,GOT MY message");
                                return;
                            }

                            [ALMessageService addOpenGroupMessage:alMessage withDelegate:self.realTimeUpdate];
                            if(!assistant.isOurViewOnTop)
                            {
                                [assistant assist:[self getNotificationObjectFromMessage:alMessage] and:dict ofUser:alMessage.contactIds];
                                [dict setObject:@"mqtt" forKey:@"Calledfrom"];
                            }
                            else
                            {
                                [self.alSyncCallService syncCall:alMessage withDelegate:self.realTimeUpdate];
                                [self.mqttConversationDelegate syncCall:alMessage andMessageList:nil];
                            }
                        }else{

                            [self syncReceivedMessage: alMessage withNSMutableDictionary:dict];

                        }
                    }];
                } else{
                    [self syncReceivedMessage: alMessage withNSMutableDictionary:dict];

                }
            }
        }
        else if ([type isEqualToString:@"MESSAGE_SENT"] || [type isEqualToString:@"APPLOZIC_02"])
        {
            NSDictionary * message = [theMessageDict objectForKey:@"message"];
            ALMessage *alMessage = [[ALMessage alloc] initWithDictonary:message];

            ALSLog(ALLoggerSeverityInfo, @"ALMESSAGE's DeviceKey : %@ \n Current DeviceKey : %@", alMessage.deviceKey, [ALUserDefaultsHandler getDeviceKeyString]);
            if(alMessage.deviceKey && [alMessage.deviceKey isEqualToString:[ALUserDefaultsHandler getDeviceKeyString]]) {
                ALSLog(ALLoggerSeverityInfo, @"MQTT : RETURNING, SENT_BY_SELF_DEVICE");
                return;
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:observeSupportGroupMessage object:alMessage];

            [ALMessageService getMessageSENT:alMessage withDelegate: self.realTimeUpdate withCompletion:^(NSMutableArray * messageArray, NSError *error) {

                if(messageArray.count > 0)
                {
                    [self.alSyncCallService syncCall:alMessage];
                    [self.mqttConversationDelegate syncCall:alMessage andMessageList:nil];
                }
            }];

            NSString * key = [message valueForKey:@"pairedMessageKey"];
            NSString * contactID = [message valueForKey:@"contactIds"];
            [self.alSyncCallService updateMessageDeliveryReport:key withStatus:SENT];
            [self.mqttConversationDelegate delivered:key contactId:contactID withStatus:SENT];

        }
        else if ([type isEqualToString:@"MESSAGE_DELIVERED"] || [type isEqualToString:@"APPLOZIC_04"]) {

            NSArray *deliveryParts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@","];
            NSString * pairedKey = deliveryParts[0];
            NSString * contactId = (deliveryParts.count > 1) ? deliveryParts[1] : nil;

            [self.alSyncCallService updateMessageDeliveryReport:pairedKey withStatus:DELIVERED];
            [self.mqttConversationDelegate delivered:pairedKey contactId:contactId withStatus:DELIVERED];

            ALMessageDBService *messageDataBaseService = [[ALMessageDBService alloc] init];
            ALMessage *message = [messageDataBaseService getMessageByKey:pairedKey];
            if(message){
                [self.realTimeUpdate onMessageDelivered:message];
            }
        }
        else if([type isEqualToString:@"MESSAGE_DELETED"] || [type isEqualToString:@"APPLOZIC_05"])
        {
            NSString * messageKey = [[theMessageDict valueForKey:@"message"] componentsSeparatedByString:@","][0];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NOTIFY_MESSAGE_DELETED" object:messageKey];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onMessageDeleted:messageKey];
            }
        }
        else if ([type isEqualToString:@"MESSAGE_DELIVERED_READ"] || [type isEqualToString:@"APPLOZIC_08"])
        {
            NSArray  * deliveryParts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@","];
            NSString * pairedKey = deliveryParts[0];
            NSString * contactId = deliveryParts.count>1 ? deliveryParts[1]:nil;

            [self.alSyncCallService updateMessageDeliveryReport:pairedKey withStatus:DELIVERED_AND_READ];
            [self.mqttConversationDelegate delivered:pairedKey contactId:contactId withStatus:DELIVERED_AND_READ];
            if(self.realTimeUpdate){
                ALMessageDBService *messageDbService = [[ALMessageDBService alloc]init];
                ALMessage* message = [messageDbService getMessageByKey:pairedKey];
                if(message){
                    [self.realTimeUpdate onMessageDeliveredAndRead:message withUserId:contactId];
                }
            }
        }
        else if ([type isEqualToString:@"CONVERSATION_DELIVERED_AND_READ"] || [type isEqualToString:@"APPLOZIC_10"])
        {
            NSString *contactId = [theMessageDict objectForKey:@"message"];
            [self.alSyncCallService updateDeliveryStatusForContact: contactId withStatus:DELIVERED_AND_READ];
            [self.mqttConversationDelegate updateStatusForContact:contactId withStatus:DELIVERED_AND_READ];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onAllMessagesRead:contactId];
            }
        }
        else if ([type isEqualToString:@"USER_CONNECTED"]||[type isEqualToString: @"APPLOZIC_11"])
        {
            ALUserDetail *alUserDetail = [[ALUserDetail alloc] init];
            alUserDetail.userId = [theMessageDict objectForKey:@"message"];
            alUserDetail.lastSeenAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
            alUserDetail.connected = YES;
            [self.alSyncCallService updateConnectedStatus: alUserDetail];
            [self.mqttConversationDelegate updateLastSeenAtStatus: alUserDetail];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onUpdateLastSeenAtStatus: alUserDetail];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_12"])
        {
            NSArray *parts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@","];

            ALUserDetail *alUserDetail = [[ALUserDetail alloc] init];
            alUserDetail.userId = parts[0];
            alUserDetail.lastSeenAtTime = [NSNumber numberWithDouble:[parts[1] doubleValue]];
            alUserDetail.connected = NO;
            [self.alSyncCallService updateConnectedStatus: alUserDetail];
            [self.mqttConversationDelegate updateLastSeenAtStatus: alUserDetail];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onUpdateLastSeenAtStatus: alUserDetail];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_15"]) //Added or removed by admin
        {
            ALChannelService *channelService = [[ALChannelService alloc] init];
            [channelService syncCallForChannel];
            // TODO HANDLE
        }
        else if ([type isEqualToString:@"APPLOZIC_27"] || [type isEqualToString:@"CONVERSATION_DELETED"]){

            NSArray *parts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@","];
            NSString * contactID = parts[0];
            NSString * conversationID = parts[1];

            [self.alSyncCallService updateTableAtConversationDeleteForContact:contactID
                                                               ConversationID:conversationID
                                                                   ChannelKey:nil];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onConversationDelete:contactID withGroupId:nil];
            }

        }
        else if ( [type isEqualToString:@"GROUP_CONVERSATION_DELETED"] || [type isEqualToString:@"APPLOZIC_23"]){

            NSNumber * groupID = [NSNumber numberWithInt:[[theMessageDict objectForKey:@"message"] intValue]];
            [self.alSyncCallService updateTableAtConversationDeleteForContact:nil
                                                               ConversationID:nil
                                                                   ChannelKey:groupID];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onConversationDelete:nil withGroupId:groupID];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_16"])
        {
            [self processUserBlockNotification:theMessageDict andUserBlockFlag:YES];
        }
        else if ([type isEqualToString:@"APPLOZIC_17"])
        {
            [self processUserBlockNotification:theMessageDict andUserBlockFlag:NO];
        }
        else if ([type isEqualToString:@"APPLOZIC_30"])
        {
            //          FETCH USER DETAILS and UPDATE DB AND REAL-TIME
            NSString * userId = [theMessageDict objectForKey:@"message"];
            if(![userId isEqualToString:[ALUserDefaultsHandler getUserId]])
            {
                [self.mqttConversationDelegate updateUserDetail:userId];
            }
            if(self.realTimeUpdate){
                [ALUserService updateUserDetail:userId withCompletion:^(ALUserDetail *userDetail) {
                    [self.realTimeUpdate onUserDetailsUpdate:userDetail];
                }];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_31"])
        {
            // BROADCAST MESSAGE : MESSAGE_DELIVERED
        }
        else if ([type isEqualToString:@"APPLOZIC_32"])
        {
            // BROADCAST MESSAGE : MESSAGE_DELIVERED_AND_READ
        }
        else if( [type isEqualToString:@"APPLOZIC_33"]){ // MESSAGE_METADATA_UPDATE
            NSString* keyString;
            NSString* deviceKey;
            @try
            {
                NSDictionary * message = [theMessageDict objectForKey:@"message"];
                ALMessage *alMessage = [[ALMessage alloc] initWithDictonary:message];
                keyString = alMessage.key;
                deviceKey = alMessage.deviceKey;
            } @catch (NSException * exp) {
                ALSLog(ALLoggerSeverityError, @"Error while fetching message from dictionary : %@", exp.description);
                @try
                {
                    NSString * messageKey = [theMessageDict valueForKey:@"message"];
                    if(messageKey){
                        ALMessageDBService * messagedbService = [[ALMessageDBService alloc]init];
                        DB_Message * dbMessage  = (DB_Message *)[messagedbService getMessageByKey:@"key" value:messageKey];
                        if (dbMessage != nil) {
                            deviceKey = dbMessage.deviceKey;
                        }
                    }
                } @catch (NSException * exp) {
                    ALSLog(ALLoggerSeverityError, @"Error while fetching message from dictionary : %@", exp.description);
                }
            }
            if (deviceKey != nil && [deviceKey isEqualToString:[ALUserDefaultsHandler getDeviceKeyString]]) {
                return;
            }
            [ALMessageService syncMessageMetaData:[ALUserDefaultsHandler getDeviceKeyString] withCompletion:^(NSMutableArray *message, NSError *error) {
                ALSLog(ALLoggerSeverityInfo, @"Successfully updated message metadata");
            }];
        }
        else if([type isEqualToString:@"APPLOZIC_09"]){
            //Conversation read for user
            ALUserService *channelService = [[ALUserService alloc]init];
            NSString * userId = [theMessageDict objectForKey:@"message"];
            [channelService updateConversationReadWithUserId:userId withDelegate:self.realTimeUpdate];
            
        }
        else if([type isEqualToString:@"APPLOZIC_21"]){
            //Conversation read for channel
             ALChannelService *channelService = [[ALChannelService alloc]init];
             NSNumber * channelKey  = [NSNumber numberWithInt:[[theMessageDict objectForKey:@"message"] intValue]];
            [channelService updateConversationReadWithGroupId:channelKey withDelegate:self.realTimeUpdate];
        }
        
        else if([type isEqualToString:@"APPLOZIC_37"]){
            
            NSArray *parts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@":"];
            NSString * userId = parts[0];
            NSString * flag = parts[1];
            ALContactDBService *contactDataBaseService = [[ALContactDBService alloc] init];
            
            if([flag isEqualToString:@"0"]){
                ALUserDetail *userDetail =  [contactDataBaseService updateMuteAfterTime:0 andUserId:userId];
                if(self.realTimeUpdate){
                    [self.realTimeUpdate onUserMuteStatus:userDetail];
                }
                
            }else if([flag isEqualToString:@"1"]) {
                ALUserService *userService = [[ALUserService alloc]init];
                [userService getMutedUserListWithDelegate:self.realTimeUpdate withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                    
                }];
            }
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"MQTT NOTIFICATION \"%@\" IS NOT HANDLED",type);
        }
    }
}

-(void)subProcessTyping:(NSString *)fullMessage
{
    NSArray *typingParts = [fullMessage componentsSeparatedByString:@","];
    NSString *applicationKey = typingParts[0]; //Note: will get used once we support messaging from one app to another
    NSString *userId = typingParts[1];
    BOOL typingStatus = [typingParts[2] boolValue];
    if (![userId isEqualToString:[ALUserDefaultsHandler getUserId]])
    {
        [self.mqttConversationDelegate updateTypingStatus:applicationKey userId:userId status:typingStatus];
        if(self.realTimeUpdate){
            [self.realTimeUpdate onUpdateTypingStatus:userId status:typingStatus];
        }
    }
}

-(void)processUserBlockNotification:(NSDictionary *)theMessageDict andUserBlockFlag:(BOOL)flag
{
    NSArray *mqttMSGArray = [[theMessageDict valueForKey:@"message"] componentsSeparatedByString:@":"];
    NSString *BlockType = mqttMSGArray[0];
    NSString *userId = mqttMSGArray[1];
    ALContactDBService *dbService = [ALContactDBService new];
    if([BlockType isEqualToString:@"BLOCKED_BY"] || [BlockType isEqualToString:@"UNBLOCKED_BY"])
    {
        [dbService setBlockByUser:userId andBlockedByState:flag];
    } else if([BlockType isEqualToString:@"BLOCKED_TO"] || [BlockType isEqualToString:@"UNBLOCKED_TO"])
    {
        [dbService setBlockUser:userId andBlockedState:flag];
    } else {
        return;
    }

    [self.mqttConversationDelegate reloadDataForUserBlockNotification:userId andBlockFlag:flag];
    if(self.realTimeUpdate){
        [self.realTimeUpdate onUserBlockedOrUnBlocked:userId andBlockFlag:flag];
    }
}

- (void)subAckReceived:(MQTTSession *)session msgID:(UInt16)msgID grantedQoss:(NSArray *)qoss
{
    ALSLog(ALLoggerSeverityInfo, @"subscribed");
}

- (void)connected:(MQTTSession *)session {

}

- (void)connectionClosed:(MQTTSession *)session
{
    ALSLog(ALLoggerSeverityInfo, @"MQTT : CONNECTION CLOSED (MQTT DELEGATE)");
    [self.mqttConversationDelegate mqttConnectionClosed];
    if(self.realTimeUpdate){
        [self.realTimeUpdate onMqttConnectionClosed];
    }

    //Todo: inform controller about connection closed.
}

- (void)handleEvent:(MQTTSession *)session
              event:(MQTTSessionEvent)eventCode
              error:(NSError *)error {
}

-(void) sendTypingStatus:(NSString *) applicationKey userID:(NSString *) userId andChannelKey:(NSNumber *)channelKey typing: (BOOL) typing;
{
    if(!self.session){
        return;
    }
    ALSLog(ALLoggerSeverityInfo, @"Sending typing status %d to: %@", typing, userId);

    NSString * dataString = [NSString stringWithFormat:@"%@,%@,%i", [ALUserDefaultsHandler getApplicationKey],
                             [ALUserDefaultsHandler getUserId], typing ? 1 : 0];

    NSString * topicString = [NSString stringWithFormat:@"typing-%@-%@", [ALUserDefaultsHandler getApplicationKey], userId];

    if(channelKey)
    {
        topicString = [NSString stringWithFormat:@"typing-%@-%@", [ALUserDefaultsHandler getApplicationKey], channelKey];
    }
    ALSLog(ALLoggerSeverityInfo, @"MQTT_PUBLISH :: %@",topicString);

    NSData * data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.session publishData:data onTopic:topicString retain:NO qos:MQTTQosLevelAtMostOnce];
}

-(void) unsubscribeToConversation {
    NSString *userKey = [ALUserDefaultsHandler getUserKeyString];
    [self unsubscribeToConversation: userKey];
}

-(BOOL) unsubscribeToConversation: (NSString *) userKey
{
    return [self unsubscribeToConversationForUser: userKey WithTopic: [ALUserDefaultsHandler getUserKeyString]];
}

-(void) unsubscribeToConversationWithTopic:(NSString *)topic {
    NSString *userKey = [ALUserDefaultsHandler getUserKeyString];
    [self unsubscribeToConversationForUser: userKey WithTopic: topic];
}

-(BOOL) unsubscribeToConversationForUser:(NSString *) userKey WithTopic:(NSString *)topic {
    if (self.session == nil) {
        return NO;
    }

    [self.session publishAndWaitData:[[NSString stringWithFormat:@"%@,%@,%@",userKey, [ALUserDefaultsHandler getDeviceKeyString], @"0"] dataUsingEncoding:NSUTF8StringEncoding] onTopic:MQTT_TOPIC_STATUS retain:NO qos:MQTTQosLevelAtMostOnce timeout:30];

    if([ALUserDefaultsHandler getEnableEncryption] && [ALUserDefaultsHandler getUserEncryptionKey] ){
        [self.session unsubscribeTopic:[NSString stringWithFormat:@"%@%@",MQTT_ENCRYPTION_SUB_KEY, topic]];
    }else{
        [self.session unsubscribeTopic: topic];
    }
    [self.session closeWithDisconnectHandler:^(NSError *error) {
        if(error){
         ALSLog(ALLoggerSeverityError, @"MQTT : ERROR WHIlE DISCONNECTING FROM MQTT %@", error);
        }
         ALSLog(ALLoggerSeverityInfo, @"MQTT : DISCONNECTED FROM MQTT");
    }];
    return YES;
}

-(void)subscribeToChannelConversation:(NSNumber *)channelKey
{
    ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/USER_SUBSCRIBING");
    dispatch_async(dispatch_get_main_queue (),^{
        @try
        {
            if (!self.session && self.session.status == MQTTSessionStatusConnected) {
                ALSLog(ALLoggerSeverityInfo, @"MQTT_SESSION_NULL");
                return;
            }
            NSString * topicString = @"";
            if(channelKey)
            {
                topicString = [NSString stringWithFormat:@"typing-%@-%@", [ALUserDefaultsHandler getApplicationKey], channelKey];
            }
            else
            {
                topicString = [NSString stringWithFormat:@"typing-%@-%@", [ALUserDefaultsHandler getApplicationKey], [ALUserDefaultsHandler getUserId]];
                [ALUserDefaultsHandler setLoggedInUserSubscribedMQTT:YES];
            }
            [self.session subscribeToTopic:topicString atLevel:MQTTQosLevelAtMostOnce];
            ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/USER_SUBSCRIBING_COMPLETE");
        }
        @catch (NSException * exp) {
            ALSLog(ALLoggerSeverityError, @"Exception in subscribing channel :: %@", exp.description);
        }
    });
}

-(void)unSubscribeToChannelConversation:(NSNumber *)channelKey
{
    ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/USER_UNSUBSCRIBING");
    dispatch_async(dispatch_get_main_queue (), ^{

        if (!self.session) {
            ALSLog(ALLoggerSeverityInfo, @"MQTT_SESSION_NULL");
            return;
        }
        NSString * topicString = @"";
        if(channelKey)
        {
            topicString = [NSString stringWithFormat:@"typing-%@-%@", [ALUserDefaultsHandler getApplicationKey], channelKey];
        }else
        {
            topicString = [NSString stringWithFormat:@"typing-%@-%@", [ALUserDefaultsHandler getApplicationKey], [ALUserDefaultsHandler getUserId]];
            [ALUserDefaultsHandler setLoggedInUserSubscribedMQTT:NO];
        }
        [self.session unsubscribeTopic:topicString];
        ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/USER_UNSUBSCRIBED_COMPLETE");
    });
}

-(void)subscribeToOpenChannel:(NSNumber *)channelKey
{
    ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/OPEN_GROUP_SUBSCRIBING");
    dispatch_async(dispatch_get_main_queue (),^{
        @try
        {
            if (!self.session && self.session.status == MQTTSessionStatusConnected) {
                ALSLog(ALLoggerSeverityInfo, @"MQTT_SESSION_NULL");
                return;
            }
            NSString * openGroupString = @"";
            if(channelKey)
            {
                openGroupString = [NSString stringWithFormat:@"group-%@-%@", [ALUserDefaultsHandler getApplicationKey], channelKey];
            }

            [self.session subscribeToTopic:openGroupString atLevel:MQTTQosLevelAtMostOnce];
            ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/OPEN_GROUP_SUBSCRIBTION_COMPLETE");
        }
        @catch (NSException * exp) {
            ALSLog(ALLoggerSeverityError, @"Exception in subscribing channel :: %@", exp.description);
        }
    });
}

-(void)unSubscribeToOpenChannel:(NSNumber *)channelKey
{
    ALSLog(ALLoggerSeverityInfo, @"MQTT_/OPEN_GROUP_UNSUBSCRIBING");
    dispatch_async(dispatch_get_main_queue (), ^{

        if (!self.session) {
            ALSLog(ALLoggerSeverityInfo, @"MQTT_SESSION_NULL");
            return;
        }
        NSString * topicString = @"";
        if(channelKey)
        {
            topicString = [NSString stringWithFormat:@"group-%@-%@", [ALUserDefaultsHandler getApplicationKey], channelKey];
        }
        [self.session unsubscribeTopic:topicString];
        ALSLog(ALLoggerSeverityInfo, @"MQTT_CHANNEL/OPEN_GROUP_UNSUBSCRIBTION_COMPLETE");
    });
}

-(void) syncReceivedMessage :(ALMessage *)alMessage withNSMutableDictionary:(NSMutableDictionary*)nsMutableDictionary{

    ALPushAssist* assistant = [[ALPushAssist alloc] init];

    [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withDelegate:self.realTimeUpdate withCompletion:^(NSMutableArray *message, NSError *error) {

        ALSLog(ALLoggerSeverityInfo, @"ALMQTTConversationService SYNC CALL");
        if(!assistant.isOurViewOnTop)
        {
            [assistant assist:[self getNotificationObjectFromMessage:alMessage] and:nsMutableDictionary ofUser:alMessage.contactIds];
            [nsMutableDictionary setObject:@"mqtt" forKey:@"Calledfrom"];
        }
        else
        {
            [self.alSyncCallService syncCall:alMessage];
            [self.mqttConversationDelegate syncCall:alMessage andMessageList:nil];
        }

    }];
}

-(BOOL)shouldRetry {
    BOOL isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    return !isInBackground && [ALDataNetworkConnection checkDataNetworkAvailable];
}

- (void)retryConnection {
    if (![self shouldRetry]) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self subscribeToConversation];
    });
}

- (void)retryConnectionWithTopic:(NSString *)topic {
    if (![self shouldRetry]) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self subscribeToConversationWithTopic: topic];
    });
}

@end
