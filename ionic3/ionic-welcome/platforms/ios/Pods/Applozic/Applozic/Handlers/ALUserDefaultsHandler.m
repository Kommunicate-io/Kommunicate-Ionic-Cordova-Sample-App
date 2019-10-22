//
//  ALUserDefaultsHandler.m
//  ChatApp
//
//  Created by shaik riyaz on 12/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALUserDefaultsHandler.h"

@implementation ALUserDefaultsHandler

+(void) setConversationContactImageVisibility:(BOOL)visibility
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:visibility forKey:CONVERSATION_CONTACT_IMAGE_VISIBILITY];
    [userDefaults synchronize];
}

+(BOOL) isConversationContactImageVisible
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:CONVERSATION_CONTACT_IMAGE_VISIBILITY];
}

+(void) setBottomTabBarHidden:(BOOL)visibleStatus
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:visibleStatus forKey:BOTTOM_TAB_BAR_VISIBLITY];
    [userDefaults synchronize];
}

+(BOOL) isBottomTabBarHidden
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    BOOL flag = [userDefaults boolForKey:BOTTOM_TAB_BAR_VISIBLITY];
    if(flag)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

+(void) setNavigationRightButtonHidden:(BOOL)flagValue
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flagValue forKey:LOGOUT_BUTTON_VISIBLITY];
    [userDefaults synchronize];
}

+(BOOL) isNavigationRightButtonHidden
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:LOGOUT_BUTTON_VISIBLITY];
}

+(void) setBackButtonHidden:(BOOL)flagValue
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flagValue forKey:BACK_BTN_VISIBILITY_ON_CON_LIST];
    [userDefaults synchronize];
}

+(BOOL) isBackButtonHidden
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:BACK_BTN_VISIBILITY_ON_CON_LIST];
}

+(void) setApplicationKey:(NSString *)applicationKey
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:applicationKey forKey:APPLICATION_KEY];
    [userDefaults synchronize];
}

+(NSString *) getApplicationKey
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:APPLICATION_KEY];
}

+(BOOL) isLoggedIn
{
    return [ALUserDefaultsHandler getDeviceKeyString] != nil;
}

+(void) clearAll
{
    ALSLog(ALLoggerSeverityInfo, @"CLEARING_USER_DEFAULTS");
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSDictionary * dictionary = [userDefaults dictionaryRepresentation];
    NSArray * keyArray = [dictionary allKeys];
    for(NSString * defaultKeyString in keyArray)
    {
        if([defaultKeyString hasPrefix:KEY_PREFIX] && ![defaultKeyString isEqualToString:APN_DEVICE_TOKEN])
        {
            [userDefaults removeObjectForKey:defaultKeyString];
            [userDefaults synchronize];
        }
    }
}

+(void) setApnDeviceToken:(NSString *)apnDeviceToken
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:apnDeviceToken forKey:APN_DEVICE_TOKEN];
    [userDefaults synchronize];
}

+(NSString*) getApnDeviceToken
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:APN_DEVICE_TOKEN];
}

+(void) setEmailVerified:(BOOL)value
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:value forKey:EMAIL_VERIFIED];
    [userDefaults synchronize];
}

+(void) getEmailVerified
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults boolForKey: EMAIL_VERIFIED];
}

// isConversationDbSynced

+(void)setBoolForKey_isConversationDbSynced:(BOOL)value
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:value forKey:CONVERSATION_DB_SYNCED];
    [userDefaults synchronize];
}

+(BOOL)getBoolForKey_isConversationDbSynced
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:CONVERSATION_DB_SYNCED];
}

+(void)setEmailId:(NSString *)emailId
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:emailId forKey:EMAIL_ID];
    [userDefaults synchronize];
}

+(NSString *)getEmailId
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:EMAIL_ID];
}
    

+(void)setDisplayName:(NSString *)displayName
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:displayName forKey:DISPLAY_NAME];
    [userDefaults synchronize];
}

+(NSString *)getDisplayName
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:DISPLAY_NAME];
}

//deviceKey String
+(void)setDeviceKeyString:(NSString *)deviceKeyString
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:deviceKeyString forKey:DEVICE_KEY_STRING];
    [userDefaults synchronize];
}

+(NSString *)getDeviceKeyString{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:DEVICE_KEY_STRING];
}

+(void)setUserKeyString:(NSString *)suUserKeyString
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:suUserKeyString forKey:USER_KEY_STRING];
    [userDefaults synchronize];
}

+(NSString *)getUserKeyString
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:USER_KEY_STRING];
}

//LOGIN USER ID
+(void)setUserId:(NSString *)userId
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:userId forKey:USER_ID];
    [userDefaults synchronize];
}

+(NSString *)getUserId
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:USER_ID];
}

//LOGIN USER PASSWORD
+(void)setPassword:(NSString *)password
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:password forKey:USER_PASSWORD];
    [userDefaults synchronize];
}

+(NSString *)getPassword
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:USER_PASSWORD];
}

//last sync time
+(void)setLastSyncTime :( NSNumber *) lstSyncTime
{

    lstSyncTime = @([lstSyncTime doubleValue] + 1);
    ALSLog(ALLoggerSeverityInfo, @"saving last Sync time in the preference ...%@" ,lstSyncTime);
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[lstSyncTime doubleValue] forKey:LAST_SYNC_TIME];
    [userDefaults synchronize];
}

+(NSNumber *)getLastSyncTime
{
   // NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:LAST_SYNC_TIME];
}


+(void)setServerCallDoneForMSGList:(BOOL) value forContactId:(NSString*)contactId
{
    if(!contactId)
    {
        return;
    }
    
    NSString * key = [MSG_LIST_CALL_SUFIX stringByAppendingString: contactId];
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:true forKey:key];
    [userDefaults synchronize];
}

+(BOOL)isServerCallDoneForMSGList:(NSString *)contactId
{
    if(!contactId)
    {
        return true;
    }
    NSString * key = [MSG_LIST_CALL_SUFIX stringByAppendingString: contactId];
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:key];
}

+(void) setProcessedNotificationIds:(NSMutableArray*)arrayWithIds
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setObject:arrayWithIds forKey:PROCESSED_NOTIFICATION_IDS];
}

+(NSMutableArray*) getProcessedNotificationIds
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [[userDefaults objectForKey:PROCESSED_NOTIFICATION_IDS] mutableCopy];
}

+(BOOL)isNotificationProcessd:(NSString*)withNotificationId
{
    NSMutableArray * mutableArray = [self getProcessedNotificationIds];
    
    if(mutableArray == nil)
    {
        mutableArray = [[NSMutableArray alloc]init];
    }
    
    BOOL isTheObjectThere = [mutableArray containsObject:withNotificationId];
    
    if (isTheObjectThere){
       // [mutableArray removeObject:withNotificationId];
    }else {
        [mutableArray addObject:withNotificationId];
    }
    //WE will just store 20 notificationIds for processing...
    if(mutableArray.count > 20)
    {
        [mutableArray removeObjectAtIndex:0];
    }
    [self setProcessedNotificationIds:mutableArray];
    return isTheObjectThere;
    
}

+(void) setLastSeenSyncTime :(NSNumber*) lastSeenTime
{
    ALSLog(ALLoggerSeverityInfo, @"saving last seen time in the preference ...%@" ,lastSeenTime);
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[lastSeenTime doubleValue] forKey:LAST_SEEN_SYNC_TIME];
    [userDefaults synchronize];
}

+(NSNumber *) getLastSeenSyncTime
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSNumber * timeStamp = [userDefaults objectForKey:LAST_SEEN_SYNC_TIME];
    return timeStamp ? timeStamp : [NSNumber numberWithInt:0];
}

+(void)setShowLoadEarlierOption:(BOOL) value forContactId:(NSString*)contactId
{
    if(!contactId)
    {
        return;
    }
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString *key = [SHOW_LOAD_ERLIER_MESSAGE stringByAppendingString:contactId];
    [userDefaults setBool:value forKey:key];
    [userDefaults synchronize];
}

+(BOOL)isShowLoadEarlierOption:(NSString *)contactId
{
    if(!contactId)
    {
        return NO;
    }
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString *key = [SHOW_LOAD_ERLIER_MESSAGE stringByAppendingString:contactId];
    if ([userDefaults valueForKey:key])
    {
        return [userDefaults boolForKey:key];
    }
    else
    {
        return YES;
    }
    
}
//Notification settings...

+(void)setNotificationTitle:(NSString *)notificationTitle
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:notificationTitle forKey:NOTIFICATION_TITLE_KEY];
    [userDefaults synchronize];
}

+(NSString *)getNotificationTitle
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:NOTIFICATION_TITLE_KEY];
}

+(void)setLastSyncChannelTime:(NSNumber *)lastSyncChannelTime
{
    lastSyncChannelTime = @([lastSyncChannelTime doubleValue] + 1);
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[lastSyncChannelTime doubleValue] forKey:LAST_SYNC_CHANNEL_TIME];
    [userDefaults synchronize];
}

+(NSNumber *)getLastSyncChannelTime
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:LAST_SYNC_CHANNEL_TIME];
}

+(void)setUserBlockLastTimeStamp:(NSNumber *)lastTimeStamp
{
    lastTimeStamp = @([lastTimeStamp doubleValue] + 1);
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[lastTimeStamp doubleValue] forKey:USER_BLOCK_LAST_TIMESTAMP];
    [userDefaults synchronize];
}

+(NSNumber *)getUserBlockLastTimeStamp
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSNumber * lastSyncTimeStamp = [userDefaults valueForKey:USER_BLOCK_LAST_TIMESTAMP];
    if(!lastSyncTimeStamp)                      //FOR FIRST TIME USER
    {
        lastSyncTimeStamp = [NSNumber numberWithInt:1000];
    }
    
    return lastSyncTimeStamp;
}

//App Module Name
+(void )setAppModuleName:(NSString *)appModuleName
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:appModuleName forKey:APP_MODULE_NAME_ID];
    [userDefaults synchronize];
}

+(NSString *)getAppModuleName
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:APP_MODULE_NAME_ID];
}

+(void) setContactViewLoadStatus:(BOOL)status
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:status forKey:CONTACT_VIEW_LOADED];
    [userDefaults synchronize];
}

+(BOOL) getContactViewLoaded
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:CONTACT_VIEW_LOADED];
}

+(void)setServerCallDoneForUserInfo:(BOOL)value ForContact:(NSString *)contactId
{
    if(!contactId)
    {
        return;
    }
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString * key = [USER_INFO_API_CALLED_SUFFIX stringByAppendingString:contactId];
    [userDefaults setBool:value forKey:key];
    [userDefaults synchronize];
}

+(BOOL)isServerCallDoneForUserInfoForContact:(NSString *)contactId
{
    if(!contactId)
    {
        return true;
    }

    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString * key = [USER_INFO_API_CALLED_SUFFIX stringByAppendingString:contactId];
    return [userDefaults boolForKey:key];
}


+(void)setBASEURL:(NSString *)baseURL
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:baseURL forKey:APPLOZIC_BASE_URL];
    [userDefaults synchronize];
}

+(NSString *)getBASEURL
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString * kBaseUrl = [userDefaults valueForKey:APPLOZIC_BASE_URL];
    return (kBaseUrl && ![kBaseUrl isEqualToString:@""]) ? kBaseUrl : @"https://apps.applozic.com";
}

+(void)setMQTTURL:(NSString *)mqttURL
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:mqttURL forKey:APPLOZIC_MQTT_URL];
    [userDefaults synchronize];
}

+(NSString *)getMQTTURL
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString * kMqttUrl = [userDefaults valueForKey:APPLOZIC_MQTT_URL];
    return (kMqttUrl && ![kMqttUrl isEqualToString:@""]) ? kMqttUrl : @"apps.applozic.com";
}

+(void)setFILEURL:(NSString *)fileURL
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:fileURL forKey:APPLOZIC_FILE_URL];
    [userDefaults synchronize];
}

+(NSString *)getFILEURL
{
    if([ALApplozicSettings isS3StorageServiceEnabled]){
        return [self getBASEURL];
    }

    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString * kFileUrl = [userDefaults valueForKey:APPLOZIC_FILE_URL];
    return (kFileUrl && ![kFileUrl isEqualToString:@""]) ? kFileUrl : @"https://applozic.appspot.com";
}

+(void)setMQTTPort:(NSString *)portNumber
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:portNumber forKey:APPLOZIC_MQTT_PORT];
    [userDefaults synchronize];
}

+(NSString *)getMQTTPort
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSString * kPortNumber = [userDefaults valueForKey:APPLOZIC_MQTT_PORT];
    return (kPortNumber && ![kPortNumber isEqualToString:@""]) ? kPortNumber : @"1883";
}

+(void)setUserTypeId:(short)type
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:type forKey:USER_TYPE_ID];
    [userDefaults synchronize];
}

+(short)getUserTypeId{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults integerForKey:USER_TYPE_ID];
}

+(void)setLastMessageListTime:(NSNumber *)lastTime
{
    lastTime = @([lastTime doubleValue] + 1);
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[lastTime doubleValue] forKey:MESSSAGE_LIST_LAST_TIME];
    [userDefaults synchronize];
}

+(NSNumber *)getLastMessageListTime
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:MESSSAGE_LIST_LAST_TIME];
}

+(void)setFlagForAllConversationFetched:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:ALL_CONVERSATION_FETCHED];
    [userDefaults synchronize];
}

+(BOOL)getFlagForAllConversationFetched
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:ALL_CONVERSATION_FETCHED];
}

+(void)setFetchConversationPageSize:(NSInteger)limit
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:limit forKey:CONVERSATION_FETCH_PAGE_SIZE];
    [userDefaults synchronize];
}

+(NSInteger)getFetchConversationPageSize
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    NSInteger maxLimit = [userDefaults integerForKey:CONVERSATION_FETCH_PAGE_SIZE];
    return maxLimit ? maxLimit : 60;
}

+(void)setNotificationMode:(short)mode
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:mode forKey:NOTIFICATION_MODE];
    [userDefaults synchronize];
}

+(short)getNotificationMode
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults integerForKey:NOTIFICATION_MODE];
}

+(void)setUserAuthenticationTypeId:(short)type
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:type forKey:USER_AUTHENTICATION_TYPE_ID];
    [userDefaults synchronize];
}

+(short)getUserAuthenticationTypeId
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    short type = [userDefaults integerForKey:USER_AUTHENTICATION_TYPE_ID];
    return type ? type : 0;
}

+(void)setUnreadCountType:(short)mode
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:mode forKey:UNREAD_COUNT_TYPE];
    [userDefaults synchronize];
}

+(short)getUnreadCountType
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    short type = [userDefaults integerForKey:UNREAD_COUNT_TYPE];
    return type ? type : 0;
}

+(void)setMsgSyncRequired:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:MSG_SYN_CALL];
    [userDefaults synchronize];
}

+(BOOL)isMsgSyncRequired
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:MSG_SYN_CALL];
}

+(void)setDebugLogsRequire:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:DEBUG_LOG_FLAG];
    [userDefaults synchronize];
}

+(BOOL)isDebugLogsRequire
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:DEBUG_LOG_FLAG];
}

+(void)setLoginUserConatactVisibility:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:LOGIN_USER_CONTACT];
    [userDefaults synchronize];
}

+(BOOL)getLoginUserConatactVisibility
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:LOGIN_USER_CONTACT];
}

+(void)setProfileImageLink:(NSString *)imageLink
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:imageLink forKey:LOGIN_USER_PROFILE_IMAGE];
    [userDefaults synchronize];
}

+(NSString *)getProfileImageLink
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:LOGIN_USER_PROFILE_IMAGE];
}

+(void)setProfileImageLinkFromServer:(NSString *)imageLink
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:imageLink forKey:LOGIN_USER_PROFILE_IMAGE_SERVER];
    [userDefaults synchronize];
}

+(NSString *)getProfileImageLinkFromServer
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:LOGIN_USER_PROFILE_IMAGE_SERVER];
}

+(void)setLoggedInUserStatus:(NSString *)status
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:status forKey:LOGGEDIN_USER_STATUS];
    [userDefaults synchronize];
}

+(NSString *)getLoggedInUserStatus
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:LOGGEDIN_USER_STATUS];
}

+(BOOL)isUserLoggedInUserSubscribedMQTT
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
     return [userDefaults boolForKey:LOGIN_USER_SUBSCRIBED_MQTT];
}

+(void)setLoggedInUserSubscribedMQTT:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:LOGIN_USER_SUBSCRIBED_MQTT];
    [userDefaults synchronize];
}

+(NSString *)getEncryptionKey
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:USER_ENCRYPTION_KEY];
}

+(void)setEncryptionKey:(NSString *)encrptionKey
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:encrptionKey forKey:USER_ENCRYPTION_KEY];
    [userDefaults synchronize];
}

+(void)setUserPricingPackage:(short)pricingPackage
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:pricingPackage forKey:USER_PRICING_PACKAGE];
    [userDefaults synchronize];
}

+(short)getUserPricingPackage
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults integerForKey:USER_PRICING_PACKAGE];
}

+(void)setEnableEncryption:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:DEVICE_ENCRYPTION_ENABLE];
    [userDefaults synchronize];
}

+(BOOL)getEnableEncryption
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:DEVICE_ENCRYPTION_ENABLE];
}

+(void)setGoogleMapAPIKey:(NSString *)googleMapAPIKey
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:googleMapAPIKey forKey:GOOGLE_MAP_API_KEY];
    [userDefaults synchronize];
}

+(NSString*)getGoogleMapAPIKey
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:GOOGLE_MAP_API_KEY];
}

+(NSString*)getNotificationSoundFileName
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:NOTIFICATION_SOUND_FILE_NAME];
}


+(void)setNotificationSoundFileName:(NSString *)notificationSoundFileName
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:notificationSoundFileName forKey:NOTIFICATION_SOUND_FILE_NAME];
    [userDefaults synchronize];
}

+(void)setContactServerCallIsDone:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:AL_CONTACT_SERVER_CALL_IS_DONE];
    [userDefaults synchronize];
}

+(BOOL)isContactServerCallIsDone
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:AL_CONTACT_SERVER_CALL_IS_DONE];
}

+(void)setContactScrollingIsInProgress:(BOOL)flag
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setBool:flag forKey:AL_CONTACT_SCROLLING_DONE];
    [userDefaults synchronize];
}

+(BOOL)isContactScrollingIsInProgress
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults boolForKey:AL_CONTACT_SCROLLING_DONE];
}

+(void) setLastGroupFilterSyncTime: (NSNumber *) lastSyncTime
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[lastSyncTime doubleValue] forKey:GROUP_FILTER_LAST_SYNC_TIME];
    [userDefaults synchronize];
}
+(NSNumber *)getLastGroupFilterSyncTIme
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:GROUP_FILTER_LAST_SYNC_TIME];

}

+(void)setUserRoleType:(short)type{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:type forKey:AL_USER_ROLE_TYPE];
    [userDefaults synchronize];
}

+(short)getUserRoleType{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    short roleType = [userDefaults integerForKey:AL_USER_ROLE_TYPE];
    return roleType ? roleType : 3;
    
}

+(void)setPushNotificationFormat:(short)format{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setInteger:format forKey:AL_USER_PUSH_NOTIFICATION_FORMATE];
    [userDefaults synchronize];
}

+(short)getPushNotificationFormat{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    short pushNotificationFormat = [userDefaults integerForKey:AL_USER_PUSH_NOTIFICATION_FORMATE];
    return pushNotificationFormat ? pushNotificationFormat : 0;
}

+(void)setUserEncryption:(NSString*)encryptionKey{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setValue:encryptionKey forKey:USER_MQTT_ENCRYPTION_KEY];
    [userDefaults synchronize];
}

+(NSString*)getUserEncryptionKey{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:USER_MQTT_ENCRYPTION_KEY];
}

+(void)setLastSyncTimeForMetaData :( NSNumber *) metaDataLastSyncTime
{
    metaDataLastSyncTime = @([metaDataLastSyncTime doubleValue] + 1);
    NSLog(@"saving last Sync time for meta data in the preference ...%@" ,metaDataLastSyncTime);
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    [userDefaults setDouble:[metaDataLastSyncTime doubleValue] forKey:LAST_SYNC_TIME_FOR_META_DATA];
    [userDefaults synchronize];
}

+(NSNumber *)getLastSyncTimeForMetaData
{
    NSUserDefaults *userDefaults = ALUserDefaultsHandler.getUserDefaults;
    return [userDefaults valueForKey:LAST_SYNC_TIME_FOR_META_DATA];
}

+(NSUserDefaults *)getUserDefaults{
    return [[NSUserDefaults alloc] initWithSuiteName:AL_DEFAULT_APP_GROUP];
}



@end
