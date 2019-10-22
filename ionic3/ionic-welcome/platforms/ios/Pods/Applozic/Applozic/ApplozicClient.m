//
//  ApplozicClient.m
//  Applozic
//
//  Created by Sunil on 12/03/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ApplozicClient.h"
#import "ALAttachmentService.h"

@implementation ApplozicClient
{
    ALMQTTConversationService *alMQTTConversationService;
    ALAttachmentService *alAttachmentService;
    ALPushNotificationService *alPushNotificationService;
}

NSString * const ApplozicClientDomain = @"ApplozicClient";

/**
 This is for initialization the applicationKey

 @param applicationKey pass applicationKey you will get applicationKey from applozic.com
 @return return will be Class object
 */
-(instancetype)initWithApplicationKey:(NSString *)applicationKey
{
    self = [super init];
    if (self)
    {
        [ALUserDefaultsHandler setApplicationKey:applicationKey];
        [self setUpServices];
    }
    return self;
}


/**
 This is for initialization the applicationKey

 @param applicationKey pass applicationKey you will get applicationKey from applozic.com
 @param delegate ApplozicUpdatesDelegate is for  subscribing/unSubscribing MQTT updates
 @return self

 */
-(instancetype)initWithApplicationKey:(NSString *)applicationKey withDelegate:(id<ApplozicUpdatesDelegate>) delegate
{
    self = [super init];
    if (self)
    {
        [ALUserDefaultsHandler setApplicationKey:applicationKey];
        alPushNotificationService = [[ALPushNotificationService alloc] init];
        self.delegate = delegate;
        alPushNotificationService.realTimeUpdate = delegate;
        alMQTTConversationService = [ALMQTTConversationService sharedInstance];
        alMQTTConversationService.realTimeUpdate = delegate;
        [self setUpServices];
    }
    return self;
}

-(void)setUpServices {

    //TO-DO move this call later to a differnt method
    [ALApplozicSettings setupSuiteAndMigrate];

    _messageService = [ALMessageService sharedInstance];
    _messageService.delegate = self.delegate;
    _messageDbService = [ALMessageDBService new];
    _userService = [ALUserService sharedInstance];
    _channelService = [ALChannelService sharedInstance];
    alAttachmentService = [ALAttachmentService sharedInstance];
}

//==============================================================================================================================================
#pragma mark - Login method
//==============================================================================================================================================


/**
 Login user to apploizc using this method once login success then you can perform other tasks

 @param alUser ALUser object  which will be having deatils about user like userId, displayName and other
 @param completion will have ALRegistrationResponse which will be having details about user
 */

-(void)loginUser:(ALUser *)alUser withCompletion:(void(^)(ALRegistrationResponse *registrationResponse, NSError *error))completion
{

    if(![ALUserDefaultsHandler getApplicationKey]){
        NSError *applicationKeyNilError = [NSError errorWithDomain:@"applicationKey is nil its not passed" code:0 userInfo:nil];
        completion(nil, applicationKeyNilError);
    } else if(!alUser){
        NSError *alUserNullError = [NSError errorWithDomain:@"ALUser object is nil" code:0 userInfo:nil];
        completion(nil, alUserNullError);
        return;
    }else if(!alUser.userId){
        NSError *userIdnillError = [NSError errorWithDomain:@"UserId is nil" code:0 userInfo:nil];
        completion(nil, userIdnillError);
        return;
    }

    [alUser setApplicationId:[ALUserDefaultsHandler getApplicationKey]];
    [alUser setAppModuleName:[ALUserDefaultsHandler getAppModuleName]];

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService initWithCompletion:alUser withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {

        NSLog(@"USER_REGISTRATION_RESPONSE :: %@", rResponse);
        if(error)
        {
            NSLog(@"ERROR_USER_REGISTRATION :: %@",error.description);
            completion(nil, error);
            return;
        }

        if(![rResponse isRegisteredSuccessfully])
        {
            NSError *passError = [NSError errorWithDomain:rResponse.message code:0 userInfo:nil];
            completion(rResponse, passError);
            return;
        }
        completion(rResponse, error);
    }];
}


//==============================================================================================================================================
#pragma mark - Logout method
//==============================================================================================================================================

/**
 This method is Logout user from applozic

 @param completion ALAPIResponse will be having a complete response like status  else it NSError
 */
-(void)logoutUserWithCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion{

    ALRegisterUserClientService * alUserClientService = [[ALRegisterUserClientService alloc] init];

    if([ALUserDefaultsHandler getDeviceKeyString])
    {
        [alUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
            completion(error,response);
        }];
    }
}


//==============================================================================================================================================
#pragma mark - Updte APNS device token  method
//==============================================================================================================================================

/**
 This method is for updating APNS  device token  applozic server for sending a APNS push notification to iphone device

 @param apnDeviceToken apnDeviceToken  is and apple device token which is required for sending for APNS push notification to device
 @param completion completion it as ALRegistrationResponse which will be havign user deatils response
 */

-(void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken withCompletion:(void(^)(ALRegistrationResponse *registrationResponse, NSError *error))completion
{
    if(![ALUserDefaultsHandler getApplicationKey]){
        NSError *applicationKeyNilError = [NSError errorWithDomain:@"applicationKey is nil its not passed" code:0 userInfo:nil];
        completion(nil, applicationKeyNilError);
    }
    else if(!apnDeviceToken){
        NSError *apnsTokenError = [NSError errorWithDomain:@"APNS device token is nil" code:0 userInfo:nil];
        completion(nil, apnsTokenError);
        return;
    }


    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateApnDeviceTokenWithCompletion:apnDeviceToken withCompletion:^(ALRegistrationResponse *response, NSError *error) {

        if (error)
        {
            NSLog(@"REGISTRATION ERROR :: %@",error.description);
            completion(nil, error);
            return;
        }
        NSLog(@"Registration response from server : %@", response);
        completion(response, error);

    }];

}


//==============================================================================================================================================
#pragma mark - Messages list and indivaul chat   methods
//==============================================================================================================================================



/**
 This getLatestMessages method is for  getting latest messages list  of user and group, Grouped by latest  messages with createdAtTime of the messages

 @param isNextPage  is send YES or true in case if you want to fetch next set of messaages else Make NO or false to load first set of messages
 @param completion NSMutableArray will have list of ALMessage object, NSError if any error comes
 */

-(void) getLatestMessages:(BOOL)isNextPage withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion{
    [_messageDbService getLatestMessages:isNextPage withCompletionHandler:^(NSMutableArray *messageListArray, NSError *error) {
        completion(messageListArray,error);
    }];
}


/**
 This getMessages method will give user or group deatils

 @param messageListRequest MessageListRequest it has parameters for
 @param completion completion description
 */
-(void) getMessages:(MessageListRequest *)messageListRequest withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion{
    [_messageService getMessageListForUser:messageListRequest  withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {
        completion(messages,error);
    }];
}



//==============================================================================================================================================
#pragma mark - Converstion read mark methods
//==============================================================================================================================================

/**
 This method is for mark conversation as read for group chat where unread count will be there that will be marked as read

 @param groupId  Pass groupId where you want to mark conversation as read
 @param completion as response and error, response is will have success or error response string else it will have NSError
 */
-(void)markConversationReadForGroup : (NSNumber *) groupId withCompletion:(void(^)(NSString *response, NSError *error)) completion
{
    if(groupId && groupId != 0)
    {
        [_channelService markConversationAsRead:groupId withCompletion:^(NSString * conversationResponse, NSError * error) {

            if(error)
            {
                NSLog(@"Error while marking messages as read channel %@",groupId);
                completion(conversationResponse,error);

            }
            else
            {
                [self->_userService processResettingUnreadCount];
                completion(conversationResponse,nil);
            }
        }];
    }
}


/**
 This method is for mark conversation as read for one to one chat where unread count will be there that will be marked as read

 @param userId Pass userId where you want to mark conversation as read
 @param completion  as response and error, response is will have success or error response string else it will have NSError
 */
-(void)markConversationReadForOnetoOne :(NSString*) userId withCompletion:(void(^)(NSString *response, NSError *error)) completion{

    if(userId)
    {
        [_userService markConversationAsRead:userId withCompletion:^(NSString * conversationResponse, NSError *error) {
            if(error)
            {
                NSLog(@"Error while marking messages as read for contact %@", userId);
                completion(nil,error);
            }
            else
            {
                [self->_userService processResettingUnreadCount];
                completion(conversationResponse,nil);
            }
        }];
    }
}

//==============================================================================================================================================
#pragma mark - Send  text message method
//==============================================================================================================================================

/**
 This method is used for sending a text messages to group or one to one chat

 @param message it accept ALMessage object
 @param completion it has resonse where the messagekey is updated and it as createdAtTime of message which is created in our server else it as NSError
 */

-(void)sendTextMessage:(ALMessage*) alMessage withCompletion:(void(^)(ALMessage *message, NSError *error))completion{

    if(!alMessage){
        NSError *messageError = [NSError errorWithDomain:ApplozicClientDomain
                                                    code:MessageNotPresent
                                                userInfo:@{NSLocalizedDescriptionKey : @"Empty message passed"}];

        completion(nil,messageError);
    }

    [_messageService sendMessages:alMessage withCompletion:^(NSString *message, NSError *error) {
        if(error)
        {
            NSLog(@"SEND_MSG_ERROR :: %@",error.description);
            completion(nil,error);
            return;
        }
        if(self.delegate){
            [self.delegate onMessageSent:alMessage];
        }
        completion(alMessage,error);
    }];

}

//==============================================================================================================================================
#pragma mark - Send  Attachment message method
//==============================================================================================================================================

/**
 This method is for sending an Attachment message in chat

 @param attachmentMessage it as groupId and userId where you can send to group or one to one chat and pass the message text string,file path of file
 */

-(void)sendMessageWithAttachment:(ALMessage*) attachmentMessage{
    
    if(!attachmentMessage || !attachmentMessage.imageFilePath){
                return;
    }
    [alAttachmentService sendMessageWithAttachment:attachmentMessage withDelegate:self.delegate withAttachmentDelegate:self.attachmentProgressDelegate];
}

//==============================================================================================================================================
#pragma mark - Download  Attachment message method
//==============================================================================================================================================

/**
 downloadMessageAttachment  method is for downloading an Attachment in chat
 @param alMessage pass ALMessage object which you want to download the attachment from  server
 */

-(void)downloadMessageAttachment:(ALMessage*)alMessage{
    if(!alMessage){
        return;
    }
    [alAttachmentService downloadMessageAttachment:alMessage withDelegate:self.attachmentProgressDelegate];
}

//==============================================================================================================================================
#pragma mark - Channel/Group methods
//==============================================================================================================================================

/**
 createChannelWithChannelInfo  This method is for creating a group like public group,open group group,private group

 PRIVATE = 1,
 PUBLIC = 2,
 BROADCAST = 5,
 OPEN = 6,
 GROUP_OF_TWO = 7
 
 @param channelInfo pass information about group deatils
 @param completion  it will be having complete  deatils about channel and status, if its error or success else NSError
 */

-(void)createChannelWithChannelInfo:(ALChannelInfo*)channelInfo withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion{

    ALChannelService *channelService = [[ALChannelService alloc] init];
    [channelService createChannelWithChannelInfo:channelInfo withCompletion:^(ALChannelCreateResponse *response, NSError *error) {
        completion(response,error);
    }];
}


/**
 This method is used for removing a member from group
 @param userId Pass userId whom you want to remove from group/channel
 @param channelKey its channelKey for the group you want to remove a member
 @param clientChannelKey if you your own client channelKey then you can pass it
 @param completion ALAPIResponse will be having a complete response like status and when user is removed else it NSError
 */
-(void) removeMemberFromChannelWithUserId:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    ALChannelService * alchannelService = [[ALChannelService alloc] init];
    [alchannelService removeMemberFromChannel:userId andChannelKey:channelKey
                           orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, ALAPIResponse *response) {
                               completion(error,response);
                           }];
}

/**
 This method for leave member from group/channel

 @param userId Pass login userId here to leave from group
 @param channelKey will be channelkey of group you want to leave from
 @param clientChannelKey pass here the client channelKey which you have stored at your end or passed during group/channel create
 @param completion  ALAPIResponse will be having a complete response like status and when user is removed else it NSError

 */
-(void) leaveMemberFromChannelWithUserId:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    ALChannelService * alchannelService = [[ALChannelService alloc] init];
    [alchannelService leaveChannelWithChannelKey:channelKey andUserId:userId orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error,response);
    }];

}


/**
 This method for add  member from group/channel

 @param userId Pass userId that you want to add in group/channel
 @param channelKey it's  channelkey of group/channel you want to add in the group/channel
 @param clientChannelKey pass here the client channelKey which you have stored at your end or passed during group/channel create
 @param completion ALAPIResponse will be having a complete response like status and when user is removed else it NSError
 */
-(void) addMemberToChannelWithUserId:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    ALChannelService * alchannelService = [[ALChannelService alloc] init];
    [alchannelService addMemberToChannel:userId andChannelKey:channelKey orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error,response);
    }];

}

/**
 This method is used for updating channel/group

 @param channelKey Pass channelKey which you wan to update
 @param newName Pass if you want to change the group name then pass new name here
 @param imageURL Pass image url if you want to update group/channel image
 @param clientChannelKey clientChannelKey description
 @param flag if you are updating metadata of group then pass YES else NO
 @param metaData meta data can be extra information you want to pass in group/channel and use it later when its required
 @param channelUsers if you want to update group users role like admin, member
 @param completion  ALAPIResponse will be having a complete response like status and when user is updated else it NSError
 */

-(void)updateChannelWithChannelKey:(NSNumber *)channelKey andNewName:(NSString *)newName andImageURL:(NSString *)imageURL orClientChannelKey:(NSString *)clientChannelKey
                isUpdatingMetaData:(BOOL)flag metadata:(NSMutableDictionary *)metaData orChannelUsers:(NSMutableArray *)channelUsers withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion{
    ALChannelService * alchannelService = [[ALChannelService alloc] init];

    [alchannelService updateChannelWithChannelKey:channelKey andNewName:newName andImageURL:imageURL orClientChannelKey:clientChannelKey isUpdatingMetaData:flag metadata:metaData orChildKeys:nil orChannelUsers:channelUsers withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error,response);
    }];

}


/**
 This method is for getting channel/group information

 @param channelKey Pass channelKey for the group/channel you want a deatils of
 @param clientChannelKey if you have stored the client channelKey else pass nil
 @param completion ALChannel object will have complete details of channel/group and AlChannelFeedResponse if any error API error comes in group then check channelResponse else check NSError
 */
-(void)getChannelInformationWithChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *) clientChannelKey withCompletion:(void(^)(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse))completion{

    ALChannelService * channelService = [[ALChannelService alloc]init];
    [channelService getChannelInformationByResponse:channelKey orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse) {
        completion(error,alChannel,channelResponse);
    }];

}


//==============================================================================================================================================
#pragma mark - User block or unblock method
//==============================================================================================================================================

/**
 This method blockUserWithUserId is used for to a block user

 @param userId Pass userId whom you want to block
 @param completion BOOL userBlock if its YES or true then its unblocked else NO or false
 */
-(void)blockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userBlock))completion{

    [_userService blockUser:userId withCompletionHandler:^(NSError *error, BOOL userBlock) {
        completion(error,userBlock);
    }];
}

/**
 This method unBlockUserWithUserId is used for unblocking user which is already blocked

 @param userId Pass userId whom you want to unblock
 @param completion BOOL userUnblock if its YES or true then its unblocked else NO or false
 */

-(void)unBlockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userUnblock))completion{

    [_userService unblockUser:userId withCompletionHandler:^(NSError *error, BOOL userUnblock) {
        completion(error,userUnblock);
    }];
}


//==============================================================================================================================================
#pragma mark - Mute/unmute Group method
//==============================================================================================================================================

/**
 This method is for mute and unmute a group/channel based on time and channelKey

 @param channelKey Pass channelkey which you want to mute or unmute a group/channel
 @param notificationTime Pass time you want to mute or unmute group/chanel
 @param completion ALAPIResponse will have status else NSError
 */

-(void)muteChannelOrUnMuteWithChannelKey:(NSNumber *)channelKey andTime:(NSNumber *)notificationTime withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion{

    ALMuteRequest * alMuteRequest = [ALMuteRequest new];
    alMuteRequest.id = channelKey;
    alMuteRequest.notificationAfterTime= notificationTime;

    ALChannelService *alChannelService = [[ALChannelService alloc]init];
    [alChannelService muteChannel:alMuteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {
        completion(response,error);
    }];

}



//==============================================================================================================================================
#pragma mark - SubscribeToConversation/UnsubscribeToConversation for updates
//==============================================================================================================================================


/**
 This method is for handing the APNS or VOIP push notification messages

 @param application UIApplication is required to pass
 @param userInfo NSDictionary its notification data Dictionary
 */
-(void)notificationArrivedToApplication:(UIApplication*)application withDictionary:(NSDictionary *)userInfo{

    if(alPushNotificationService){
        [alPushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
    }
}

/**
 This method subscribeToConversation  is used for subscribing  to mqtt conversation
 */

-(void)subscribeToConversation
{
    if(alMQTTConversationService){
        [alMQTTConversationService  subscribeToConversation];
    }
}

/**
 This method unsubscribeToConversation  is used for unSubscribing  to mqtt conversation
 */
-(void)unsubscribeToConversation
{    if(alMQTTConversationService){
    [alMQTTConversationService  unsubscribeToConversation];
}
}

/**
 This method subscribeToTypingStatusForOneToOne is used subscribing to one to one typing status events
 */
-(void)subscribeToTypingStatusForOneToOne
{
    if(alMQTTConversationService){
        [alMQTTConversationService subscribeToChannelConversation:nil];
    }
}

/**
 This method subscribeToTypingStatusForGroup is used subscribing to group/channel typing status events

 @param channelKey Pass channel/group channelKey which your looking for typing events
 */
-(void)subscribeToTypingStatusForChannel:(NSNumber *) channelKey
{
    if(alMQTTConversationService){
        [alMQTTConversationService  subscribeToChannelConversation:channelKey];
    }
}

/**
 This method unSubscribeToTypingStatusForOneToOne is used for unSubscribing the typing status events for one to one

 */
-(void)unSubscribeToTypingStatusForOneToOne
{
    if(alMQTTConversationService){
        [alMQTTConversationService unSubscribeToChannelConversation:nil];
    }
}

/**
 This method unSubscribeToTypingStatusForChannel is used for

 @param chanelKey Pass channelKey of group/channel that you want to unSubscribe
 */

-(void)unSubscribeToTypingStatusForChannel:(NSNumber *)chanelKey
{
    if(alMQTTConversationService){
        [alMQTTConversationService unSubscribeToChannelConversation:chanelKey];
    }
}

/**
 This method  sendTypingStatusForChannelKey is  used for for channel/group sending typing status

 @param chanelKey its channelKey for group/channel which you want to send typing status
 @param isTyping if your typing pass YES in isTyping else on stop pass NO to stop the typing
 */
-(void)sendTypingStatusForChannelKey:(NSNumber *)chanelKey withTyping:(BOOL) isTyping
{
    if(alMQTTConversationService){
        [alMQTTConversationService sendTypingStatus:nil userID:nil andChannelKey:chanelKey typing:isTyping];
    }
}

/**
 This method  sendTypingStatusForUserId is  used for for one to one sending typing status

 @param userId Pass userId for one to one which you want to send a typing status
 @param isTyping if your typing pass YES else on stop pass NO to stop the typing
 */
-(void)sendTypingStatusForUserId:(NSString *)userId withTyping:(BOOL) isTyping
{
    if(alMQTTConversationService){
        [alMQTTConversationService sendTypingStatus:nil userID:userId andChannelKey:nil typing:isTyping];
    }
}

/**
 This method sendTypingStatusForUserId method is for sending a typing status in one to one or group/channel chat

 @param userId if its one to one chat  then pass your userId else pass nil
 @param channelKey its channelKey for group/channel which you want to send typing status else psas nil
 @param isTyping if your typing pass YES in isTyping else on stop pass NO to stop the typing

 */


-(void)sendTypingStatusForUserId:(NSString *)userId orForGroupId:(NSNumber*)channelKey withTyping:(BOOL) isTyping
{
    if(channelKey){
        [self sendTypingStatusForChannelKey:channelKey withTyping:isTyping];
    }else if (userId){
        [self sendTypingStatusForUserId:userId withTyping:isTyping];
    }
}

-(void) getLatestMessages:(BOOL)isNextPage withOnlyGroups:(BOOL)isGroup withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion{

    ALMessageService *messageService = [[ALMessageService alloc] init];
    [messageService getLatestMessages:isNextPage withOnlyGroups:isGroup withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
        completion(messageList,error);

    }];

}

@end
