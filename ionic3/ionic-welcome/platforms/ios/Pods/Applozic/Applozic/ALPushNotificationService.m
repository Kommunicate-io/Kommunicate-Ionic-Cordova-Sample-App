//
//  ALPushNotificationService.m
//  ChatApp
//
//  Created by devashish on 28/09/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALPushNotificationService.h"
#import "ALMessageDBService.h"
#import "ALUserDetail.h"
#import "ALUserDefaultsHandler.h"
#import "ALChatViewController.h"
//#import "LaunchChatFromSimpleViewController.h"
#import "ALMessagesViewController.h"
#import "ALPushAssist.h"
#import "ALUserService.h"
#import "ALNotificationView.h"
#import "ALRegisterUserClientService.h"
#import "ALAppLocalNotifications.h"
#import <Applozic/ApplozicClient.h>

@implementation ALPushNotificationService

+ (NSArray *)ApplozicNotificationTypes
{
    static NSArray *notificationTypes;
    if (!notificationTypes)
    {
        notificationTypes = [[NSArray alloc] initWithObjects:MT_SYNC, MT_CONVERSATION_READ, MT_DELIVERED,MT_SYNC_PENDING, MT_DELETE_MESSAGE, MT_DELETE_MULTIPLE_MESSAGE, MT_CONVERSATION_DELETED, MTEXTER_USER, MT_CONTACT_VERIFIED, MT_CONTACT_VERIFIED, MT_DEVICE_CONTACT_SYNC, MT_EMAIL_VERIFIED,MT_DEVICE_CONTACT_MESSAGE, MT_CANCEL_CALL, MT_MESSAGE,MT_MESSAGE_DELIVERED_AND_READ,MT_CONVERSATION_DELIVERED_AND_READ,MT_USER_BLOCK,MT_USER_UNBLOCK,TEST_NOTIFICATION,MT_MESSAGE_SENT,nil];
    }
    return notificationTypes;
}

-(BOOL) isApplozicNotification:(NSDictionary *)dictionary
{
    NSString *type = (NSString *)[dictionary valueForKey:@"AL_KEY"];
    ALSLog(ALLoggerSeverityInfo, @"APNs GOT NEW MESSAGE & NOTIFICATION TYPE :: %@", type);
    BOOL prefixCheck = ([type hasPrefix:APPLOZIC_PREFIX]) || ([type hasPrefix:@"MT_"]);
    return (type != nil && ([ALPushNotificationService.ApplozicNotificationTypes containsObject:type] || prefixCheck));
}

-(BOOL) processPushNotification:(NSDictionary *)dictionary updateUI:(NSNumber *)updateUI
{

    ALSLog(ALLoggerSeverityInfo, @"APNS_DICTIONARY :: %@",dictionary.description);
    ALSLog(ALLoggerSeverityInfo, @"UPDATE UI VALUE :: %@",updateUI);
    ALSLog(ALLoggerSeverityInfo, @"UPDATE UI :: %@", ([updateUI isEqualToNumber:[NSNumber numberWithInt:1]]) ? @"ACTIVE" : @"BACKGROUND/INACTIVE");

    if ([self isApplozicNotification:dictionary])
    {
        NSString * alertValue;
        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        alertValue = ([ALUserDefaultsHandler getNotificationMode] == NOTIFICATION_DISABLE ? @"" : [[dictionary valueForKey:@"aps"] valueForKey:@"alert"]);

        self.alSyncCallService = [[ALSyncCallService alloc] init];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:updateUI forKey:@"updateUI"];

        NSString *type = (NSString *)[dictionary valueForKey:@"AL_KEY"];
        NSString *alValueJson = (NSString *)[dictionary valueForKey:@"AL_VALUE"];

        NSData* data = [alValueJson dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error = nil;
        NSDictionary *theMessageDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSString *notificationMsg = [theMessageDict valueForKey:@"message"];
        NSDictionary * metadataDictionary =  [theMessageDict valueForKey:@"messageMetaData"];


        //CHECK for any special messages...
        if ([self processMetaData:theMessageDict withAlert:alertValue withUpdateUI:updateUI])
        {
            return true;
        }

        NSString *notificationId = (NSString *)[theMessageDict valueForKey:@"id"];
        if(notificationId && [ALUserDefaultsHandler isNotificationProcessd:notificationId])
        {
            ALSLog(ALLoggerSeverityInfo, @"Returning from ALPUSH because notificationId is already processed... %@",notificationId);
            BOOL isInactive = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive);
            if(isInactive && ([type isEqualToString:MT_SYNC] || [type isEqualToString:MT_MESSAGE_SENT]))
            {
                ALSLog(ALLoggerSeverityInfo, @"ALAPNs : APP_IS_INACTIVE");
                if([type isEqualToString:MT_MESSAGE_SENT] ){
                    if(([[notificationMsg componentsSeparatedByString:@":"][1] isEqualToString:[ALUserDefaultsHandler getDeviceKeyString]]))
                    {
                        ALSLog(ALLoggerSeverityInfo, @"APNS: Sent by self-device ignore");
                        return YES;
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self assitingNotificationMessage:notificationMsg andDictionary:dict withMetadata:metadataDictionary];
                });
            }
            else
            {
                ALSLog(ALLoggerSeverityInfo, @"ALAPNs : APP_IS_ACTIVE");
            }

            return true;
        }
        //TODO : check if notification is alreday received and processed...

        if ([type isEqualToString:MT_SYNC]) // APPLOZIC_01 //
        {
            [ALUserDefaultsHandler setMsgSyncRequired:YES];
            [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withDelegate:self.realTimeUpdate
                                       withCompletion:^(NSMutableArray *message, NSError *error) {


                                               ALSLog(ALLoggerSeverityInfo, @"ALPushNotificationService's SYNC CALL");
                                               [dict setObject:(alertValue ? alertValue : @"") forKey:@"alertValue"];
                                               [self assitingNotificationMessage:notificationMsg andDictionary:dict withMetadata:metadataDictionary];
                                       }];


        }
        else if ([type isEqualToString:@"MESSAGE_SENT"]||[type isEqualToString:@"APPLOZIC_02"])
        {

            ALSLog(ALLoggerSeverityInfo, @"APNS: APPLOZIC_02 ARRIVED");

            NSString *alValueJson = (NSString *)[dictionary valueForKey:@"AL_VALUE"];
            NSData* data = [alValueJson dataUsingEncoding:NSUTF8StringEncoding];

            NSError *error = nil;
            NSDictionary *theMessageDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            NSString*  notificationMsg = [theMessageDict valueForKey:@"message"];
            ALSLog(ALLoggerSeverityInfo, @"\nNotification Message:%@\n\nDeviceString:%@\n",notificationMsg,
                  [ALUserDefaultsHandler getDeviceKeyString]);

            if(([[notificationMsg componentsSeparatedByString:@":"][1] isEqualToString:[ALUserDefaultsHandler getDeviceKeyString]]))
            {
                ALSLog(ALLoggerSeverityInfo, @"APNS: Sent by self-device");
                return YES;
            }

            [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withDelegate:self.realTimeUpdate  withCompletion:^(NSMutableArray *message, NSError *error) {
              ALSLog(ALLoggerSeverityInfo, @"APPLOZIC_02 Sync Call Completed");
                  }];
        }
        else if ([type isEqualToString:@"MT_MESSAGE_DELIVERED"]||[type isEqualToString:MT_DELIVERED]){

            NSArray *deliveryParts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@","];
            NSString * pairedKey = deliveryParts[0];
            [self.alSyncCallService updateMessageDeliveryReport:pairedKey withStatus:DELIVERED];
            if(self.realTimeUpdate){
                ALMessage *message = [messageDBService getMessageByKey:pairedKey];
                if(message){
                    [self.realTimeUpdate onMessageDelivered:message];
                }
            }
            [[ NSNotificationCenter defaultCenter] postNotificationName:@"report_DELIVERED" object:deliveryParts[0] userInfo:dictionary];
        }
        else if ([type isEqualToString:@"MT_MESSAGE_DELIVERED_READ"]||[type isEqualToString:@"APPLOZIC_08"]){

            NSArray  * deliveryParts = [[theMessageDict objectForKey:@"message"] componentsSeparatedByString:@","];
            NSString * pairedKey = deliveryParts[0];
            NSString * contactId = deliveryParts.count>1 ? deliveryParts[1]:nil;

            [self.alSyncCallService updateMessageDeliveryReport:pairedKey withStatus:DELIVERED_AND_READ];
            [[ NSNotificationCenter defaultCenter] postNotificationName:@"report_DELIVERED_READ" object:deliveryParts[0] userInfo:dictionary];
            if(self.realTimeUpdate){
                ALMessageDBService *messageDbService = [[ALMessageDBService alloc]init];
                ALMessage* message = [messageDbService getMessageByKey:pairedKey];
                if(message){
                    [self.realTimeUpdate onMessageDeliveredAndRead:message withUserId:contactId];
                }
            }
        }
        else if ([type isEqualToString:MT_CONVERSATION_DELETED]){

            [messageDBService deleteAllMessagesByContact:notificationMsg orChannelKey:nil];
        }
        else if ([type isEqualToString:@"APPLOZIC_05"]){

            [messageDBService deleteMessageByKey: notificationMsg];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onMessageDeleted:notificationMsg];
            }
            /*
                NSString * messageKey = [[theMessageDict valueForKey:@"message"] componentsSeparatedByString:@","][0];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NOTIFY_MESSAGE_DELETED" object:messageKey];
            */
        }
        else if ([type isEqualToString:@"APPLOZIC_10"]){

            [self.alSyncCallService updateDeliveryStatusForContact:notificationMsg withStatus:DELIVERED_AND_READ];
            [[ NSNotificationCenter defaultCenter] postNotificationName:@"report_CONVERSATION_DELIVERED_READ" object:notificationMsg];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onAllMessagesRead:notificationMsg];
            }

        }
        else if ([type isEqualToString:@"APPLOZIC_11"]){

            ALUserDetail *alUserDetail = [[ALUserDetail alloc] init];
            alUserDetail.userId = notificationMsg;
            alUserDetail.lastSeenAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
            alUserDetail.connected = YES;
            [self.alSyncCallService updateConnectedStatus: alUserDetail];
            [[ NSNotificationCenter defaultCenter] postNotificationName:@"update_USER_STATUS" object:alUserDetail];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onUpdateLastSeenAtStatus: alUserDetail];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_12"]){

            NSArray *parts = [notificationMsg componentsSeparatedByString:@","];

            ALUserDetail *alUserDetail = [[ALUserDetail alloc] init];
            alUserDetail.userId = parts[0];
            alUserDetail.lastSeenAtTime = [NSNumber numberWithDouble:[parts[1] doubleValue]];
            alUserDetail.connected = NO;
            [self.alSyncCallService updateConnectedStatus: alUserDetail];
            [[ NSNotificationCenter defaultCenter] postNotificationName:@"update_USER_STATUS" object:alUserDetail];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onUpdateLastSeenAtStatus: alUserDetail];
            }

        }
        else if ([type isEqualToString:@"APPLOZIC_15"]){
            ALChannelService *channelService = [[ALChannelService alloc] init];
            [channelService syncCallForChannel];
            // TODO HANDLE
        }
        else if ([type isEqualToString:@"APPLOZIC_27"] || [type isEqualToString:@"CONVERSATION_DELETED"]){

            NSArray *parts = [notificationMsg componentsSeparatedByString:@","];
            NSString * contactID = parts[0];
            NSString * conversationID = parts[1];

            [self.alSyncCallService updateTableAtConversationDeleteForContact:contactID
                                                                ConversationID:conversationID
                                                                   ChannelKey:nil];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onConversationDelete:contactID withGroupId:0];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_23"] || [type isEqualToString:@"GROUP_CONVERSATION_DELETED"]){

            NSNumber * groupID = [NSNumber numberWithInt:[notificationMsg intValue]];
            [self.alSyncCallService updateTableAtConversationDeleteForContact:nil
                                                               ConversationID:nil
                                                                   ChannelKey:groupID];
            if(self.realTimeUpdate){
                [self.realTimeUpdate onConversationDelete:nil withGroupId:groupID];
            }
        }
        else if ([type isEqualToString:@"APPLOZIC_16"]){
//            NSLog(@"BLOCKED / BLOCKED BY");

            if([self processUserBlockNotification:theMessageDict andUserBlockFlag:YES])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"USER_BLOCK_NOTIFICATION" object:nil];
            }


        }
        else if ([type isEqualToString:@"APPLOZIC_17"])
        {
//            NSLog(@"UNBLOCKED / UNBLOCKED BY");
            if([self processUserBlockNotification:theMessageDict andUserBlockFlag:NO])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"USER_UNBLOCK_NOTIFICATION" object:nil];
            }

        }
        else if ([type isEqualToString:@"APPLOZIC_20"])
        {
            ALSLog(ALLoggerSeverityInfo, @"Process Push Notification APPLOZIC_20");
        }
        else if ([type isEqualToString:@"APPLOZIC_30"])
        {
            NSString * userId = notificationMsg;
            if(![userId isEqualToString:[ALUserDefaultsHandler getUserId]])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"USER_DETAILS_UPDATE_CALL" object:userId];
            }
            if(self.realTimeUpdate){
            [ALUserService updateUserDetail:userId withCompletion:^(ALUserDetail *userDetail) {
                [self.realTimeUpdate onUserDetailsUpdate:userDetail];
            }];
            }
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
        } else if([type isEqualToString:@"APPLOZIC_37"]){
            
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
        
        } else if( [type isEqualToString:@"APPLOZIC_33"]){
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
                return TRUE;
            }
            [ALMessageService syncMessageMetaData:[ALUserDefaultsHandler getDeviceKeyString] withCompletion:^(NSMutableArray *message, NSError *error) {
                ALSLog(ALLoggerSeverityInfo, @"Successfully updated message metadata");
            }];
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"APNs NOTIFICATION \"%@\" IS NOT HANDLED",type);
        }

        return TRUE;
    }

    return FALSE;
}

-(void)assitingNotificationMessage:(NSString*)notificationMsg andDictionary:(NSMutableDictionary*)dict withMetadata:(NSDictionary *)messageMetaData
{

    if([self isNotificationDisabled:messageMetaData]){
        return;
    }

    ALPushAssist* assistant = [[ALPushAssist alloc] init];
    if(!assistant.isOurViewOnTop)
    {
        [dict setObject:@"apple push notification.." forKey:@"Calledfrom"];
        [assistant assist:notificationMsg and:dict ofUser:notificationMsg];
    }
    else
    {
        ALSLog(ALLoggerSeverityInfo, @"ASSISTING : OUR_VIEW_IS_IN_TOP");
        // Message View Controller
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification"
                                                             object:notificationMsg
                                                           userInfo:dict];
        //Chat View Controller
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notificationIndividualChat"
                                                             object:notificationMsg
                                                           userInfo:dict];
    }

}

-(BOOL)isNotificationDisabled:(NSDictionary*)messageMetaData{

    if(!messageMetaData){
        return NO;
    }

    NSString * notificationFlag = [messageMetaData objectForKey:@"show"];
    return (messageMetaData && notificationFlag && [notificationFlag isEqualToString:@"false"]);
}

-(BOOL)processMetaData:(NSDictionary*)dict withAlert:alertValue withUpdateUI:(NSNumber *)updateUI
{

    NSDictionary * metadataDictionary =  [dict valueForKey:@"messageMetaData"];

    if( metadataDictionary && [metadataDictionary valueForKey:APPLOZIC_CATEGORY_KEY] && [[metadataDictionary valueForKey:APPLOZIC_CATEGORY_KEY] isEqualToString:CATEGORY_PUSHNNOTIFICATION] )
    {
        ALSLog(ALLoggerSeverityInfo, @" Puhs notification with category, just open app %@",[metadataDictionary valueForKey:APPLOZIC_CATEGORY_KEY]);
        if([updateUI intValue] == APP_STATE_ACTIVE)
        {
            [ALNotificationView showPromotionalNotifications:alertValue];
        }

        return true;
    }
    return false;
}

-(BOOL)processUserBlockNotification:(NSDictionary *)theMessageDict andUserBlockFlag:(BOOL)flag
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
        return NO;
    }

    if(self.realTimeUpdate){
        [self.realTimeUpdate onUserBlockedOrUnBlocked:userId andBlockFlag:flag];
    }
    return  YES;
}

-(void)notificationArrivedToApplication:(UIApplication*)application withDictionary:(NSDictionary *)userInfo
{
     if(application.applicationState == UIApplicationStateInactive)
     {
        /* 
        # App is transitioning from background to foreground (user taps notification), do what you need when user taps here!

        # SYNC AND PUSH DETAIL VIEW CONTROLLER
        ALSLog(ALLoggerSeverityInfo, @"APP_STATE_INACTIVE APP_DELEGATE");
         */
        [self processPushNotification:userInfo updateUI:[NSNumber numberWithInt:APP_STATE_INACTIVE]];
    }
    else if(application.applicationState == UIApplicationStateActive)
    {
        /*
         # App is currently active, can update badges count here

         # SYNC AND PUSH DETAIL VIEW CONTROLLER
         ALSLog(ALLoggerSeverityInfo, @"APP_STATE_ACTIVE APP_DELEGATE");
         */
        [self processPushNotification:userInfo updateUI:[NSNumber numberWithInt:APP_STATE_ACTIVE]];
    }
    else if(application.applicationState == UIApplicationStateBackground)
    {
        /* # App is in background, if content-available key of your notification is set to 1, poll to your backend to retrieve data and update your interface here

        # SYNC ONLY
        ALSLog(ALLoggerSeverityInfo, @"APP_STATE_BACKGROUND APP_DELEGATE");
        */
         [self processPushNotification:userInfo updateUI:[NSNumber numberWithInt:APP_STATE_BACKGROUND]];
    }
}

+(void)applicationEntersForeground
{
   [[NSNotificationCenter defaultCenter] postNotificationName:@"appCameInForeground" object:nil];
}

+(void)userSync
{
    ALUserService *userService = [ALUserService new];
    [userService blockUserSync: [ALUserDefaultsHandler getUserBlockLastTimeStamp]];
}

-(BOOL) checkForLaunchNotification:(NSDictionary *)dictionary
{
    [ALRegisterUserClientService isAppUpdated];

    ALAppLocalNotifications *localNotification = [ALAppLocalNotifications appLocalNotificationHandler];
    [localNotification dataConnectionNotificationHandler];

    if(dictionary != nil){

        NSDictionary *notification = [dictionary objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

        if(notification ){
            [self processPushNotification:notification updateUI:[NSNumber numberWithInt:APP_STATE_INACTIVE]];

        }

    }
    return false;
}
@end
