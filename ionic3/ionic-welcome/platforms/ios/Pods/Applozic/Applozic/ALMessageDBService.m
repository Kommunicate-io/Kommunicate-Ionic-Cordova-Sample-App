//
//  ALMessageDBService.m
//  ChatApp
//
//  Created by Devashish on 21/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALMessageDBService.h"
#import "ALContact.h"
#import "ALDBHandler.h"
#import "DB_Message.h"
#import "ALUserDefaultsHandler.h"
#import "ALMessage.h"
#import "DB_FileMetaInfo.h"
#import "ALMessageService.h"
#import "ALContactService.h"
#import "ALMessageClientService.h"
#import "ALApplozicSettings.h"
#import "ALAudioVideoBaseVC.h"
#import "ALChannelService.h"
#import "ALChannel.h"
#import "ALUserService.h"
#import "ALUtilityClass.h"

@implementation ALMessageDBService

//Add message APIS
-(NSMutableArray *) addMessageList:(NSMutableArray*) messageList
{
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];

    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    for (ALMessage * theMessage in messageList) {

        NSManagedObject *message = [self getMessageByKey:@"key" value:theMessage.key];
        if(message==nil && ![theMessage isPushNotificationMessage] )
        {
            theMessage.sentToServer = YES;

            DB_Message * theMessageEntity = [self createMessageEntityForDBInsertionWithMessage:theMessage];
            theMessage.msgDBObjectId = theMessageEntity.objectID;

            [messageArray addObject:theMessage];

        }
    }
    NSError * error;
    if(![theDBHandler.managedObjectContext save:&error]){
        ALSLog(ALLoggerSeverityError, @"Unable to save error :%@",error);

    }
    return messageArray;
}


-(DB_Message*)addMessage:(ALMessage*) message
{
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    DB_Message* dbMessag = [self createMessageEntityForDBInsertionWithMessage:message];
    [theDBHandler.managedObjectContext save:nil];
    message.msgDBObjectId = dbMessag.objectID;

    if([message.status isEqualToNumber:[NSNumber numberWithInt:SENT]]){
        dbMessag.status = [NSNumber numberWithInt:READ];
    }
  if(message.isAReplyMessage)
    {
        NSString * messageReplyId = [message.metadata valueForKey:AL_MESSAGE_REPLY_KEY];
        DB_Message * replyMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageReplyId];
        replyMessage.replyMessageType = [NSNumber numberWithInt:AL_A_REPLY];
        [theDBHandler.managedObjectContext save:nil];

    }    return dbMessag;
}

-(NSManagedObject *)getMeesageById:(NSManagedObjectID *)objectID
                             error:(NSError **)error{

   ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
   NSManagedObject *obj =  [theDBHandler.managedObjectContext existingObjectWithID:objectID error:error];
   return obj;
}


-(void)updateDeliveryReportForContact:(NSString *)contactId withStatus:(int)status{

    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_Message" inManagedObjectContext:dbHandler.managedObjectContext];

    NSMutableArray * predicateArray = [[NSMutableArray alloc] init];

    NSPredicate * predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@",contactId];
    [predicateArray addObject:predicate1];


    NSPredicate * predicate3 = [NSPredicate predicateWithFormat:@"status != %i and sentToServer ==%@",
                                DELIVERED_AND_READ,[NSNumber numberWithBool:YES]];
    [predicateArray addObject:predicate3];


    NSCompoundPredicate * resultantPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:resultantPredicate];

    NSError *fetchError = nil;

    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    ALSLog(ALLoggerSeverityInfo, @"Found Messages to update to DELIVERED_AND_READ in DB :%lu",(unsigned long)result.count);
    for (DB_Message *message in result) {
        [message setStatus:[NSNumber numberWithInt:status]];
    }

    NSError *Error = nil;

    BOOL success = [dbHandler.managedObjectContext save:&Error];

    if (!success) {
        ALSLog(ALLoggerSeverityInfo, @"Unable to save STATUS OF managed objects.");
        ALSLog(ALLoggerSeverityError, @"%@, %@", Error, Error.localizedDescription);
    }

}


//update Message APIS
-(void)updateMessageDeliveryReport:(NSString*)messageKeyString withStatus:(int)status{

    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];

    NSManagedObject* message = [self getMessageByKey:@"key"  value:messageKeyString];
    [message setValue:@(status) forKey:@"status"];

    NSError *error = nil;
    if ( ![dbHandler.managedObjectContext save:&error] && message){
        ALSLog(ALLoggerSeverityError, @"Error in updating Message Delivery Report");
    }
    else{
        ALSLog(ALLoggerSeverityInfo, @"updateMessageDeliveryReport DB update Success %@", messageKeyString);
    }

}


-(void)updateMessageSyncStatus:(NSString*) keyString{

    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];

    NSManagedObject* message = [self getMessageByKey:@"keyString" value:keyString];
    [message setValue:@"1" forKey:@"isSent"];
    NSError *error = nil;
    if ( [dbHandler.managedObjectContext save:&error]){
        ALSLog(ALLoggerSeverityInfo, @"message found and maked as deliverd");
    } else {
       // NSLog(@"message not found with this key");
    }
}


//Delete Message APIS

-(void) deleteMessage{

}

-(void) deleteMessageByKey:(NSString*) keyString {


    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];

    NSManagedObject* message = [self getMessageByKey:@"key" value:keyString];

    if(message){
                [dbHandler.managedObjectContext deleteObject:message];

        NSError *error = nil;
        if ( [dbHandler.managedObjectContext save:&error]){
            ALSLog(ALLoggerSeverityInfo, @"message found ");
        }
    }
    else{
         ALSLog(ALLoggerSeverityInfo, @"message not found with this key");
    }

}

-(void) deleteAllMessagesByContact: (NSString*) contactId orChannelKey:(NSNumber *)key
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_Message" inManagedObjectContext:dbHandler.managedObjectContext];
    NSPredicate *predicate;
    if(key != nil)
    {
        predicate = [NSPredicate predicateWithFormat:@"groupId = %@",key];
        [ALChannelService setUnreadCountZeroForGroupID:key];
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"contactId = %@ AND groupId = %@",contactId,nil];
        [ALUserService setUnreadCountZeroForContactId:contactId];
    }

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];

    NSError *fetchError = nil;

    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];

    for (DB_Message *message in result) {
        [dbHandler.managedObjectContext deleteObject:message];
    }

    NSError *deleteError = nil;

   BOOL success = [dbHandler.managedObjectContext save:&deleteError];

    if (!success) {
        ALSLog(ALLoggerSeverityInfo, @"Unable to save managed object context.");
        ALSLog(ALLoggerSeverityError, @"%@, %@", deleteError, deleteError.localizedDescription);
    }

}

//Generic APIS
-(BOOL) isMessageTableEmpty{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_Message" inManagedObjectContext:dbHandler.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];
    NSError *error = nil;
    NSUInteger count = [ dbHandler.managedObjectContext countForFetchRequest: fetchRequest error: &error];
    if(error == nil ){
        return !(count >0);
    }else{
         ALSLog(ALLoggerSeverityError, @"Error fetching count :%@",error);
    }
    return true;
}

- (void)deleteAllObjectsInCoreData
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSArray *allEntities = dbHandler.managedObjectModel.entities;
    for (NSEntityDescription *entityDescription in allEntities)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entityDescription];

        fetchRequest.includesPropertyValues = NO;
        fetchRequest.includesSubentities = NO;

        NSError *error;
        NSArray *items = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&error];

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error requesting items from Core Data: %@", [error localizedDescription]);
        }

        for (NSManagedObject *managedObject in items) {
            [dbHandler.managedObjectContext deleteObject:managedObject];
        }

        if (![dbHandler.managedObjectContext save:&error]) {
            ALSLog(ALLoggerSeverityError, @"Error deleting %@ - error:%@", entityDescription, [error localizedDescription]);
        }
    }
}

- (NSManagedObject *)getMessageByKey:(NSString *) key value:(NSString*) value{


    //Runs at MessageList viewing/opening...ONLY FIRST TIME AND if delete an msg
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_Message" inManagedObjectContext:dbHandler.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@",key,value];
//    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"deletedFlag == NO"];
    NSPredicate * resultPredicate=[NSCompoundPredicate andPredicateWithSubpredicates:@[predicate]];//,predicate3]];

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:resultPredicate];

    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (result.count > 0) {
        NSManagedObject* message = [result objectAtIndex:0];

        return message;
    } else {
      //  NSLog(@"message not found with this key");
        return nil;
    }
}

//------------------------------------------------------------------------------------------------------------------
    #pragma mark - ALMessagesViewController DB Operations.
//------------------------------------------------------------------------------------------------------------------

-(void)getMessages:(NSMutableArray *)subGroupList
{
    if ([self isMessageTableEmpty] || [ALApplozicSettings getCategoryName])  // db is not synced
    {
        [self fetchAndRefreshFromServer:subGroupList];
        [self syncConactsDB];
    }
    else // db is synced
    {
        //fetch data from db
        if(subGroupList && [ALApplozicSettings getSubGroupLaunchFlag])  // case for sub group
        {
            [self fetchSubGroupConversations:subGroupList];
        }
        else
        {
           [self fetchConversationsGroupByContactId];
        }
    }
}

-(void)fetchAndRefreshFromServer:(NSMutableArray *)subGroupList
{
    [self syncConverstionDBWithCompletion:^(BOOL success, NSMutableArray * theArray) {

        if (success) {
            // save data into the db
            [self addMessageList:theArray];
            // set yes to userdefaults
            [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
            // add default contacts
            //fetch data from db
            if(subGroupList && [ALApplozicSettings getSubGroupLaunchFlag])
            {
                [self fetchSubGroupConversations:subGroupList];
            }
            else
            {
                [self fetchConversationsGroupByContactId];
            }
        }
    }];
}

-(void)fetchAndRefreshQuickConversationWithCompletion:(void (^)( NSMutableArray *, NSError *))completion{
    NSString * deviceKeyString = [ALUserDefaultsHandler getDeviceKeyString];

    [ALMessageService getLatestMessageForUser:deviceKeyString withCompletion:^(NSMutableArray *messageArray, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"GetLatestMsg Error%@",error);
            return ;
        }
        [self.delegate updateMessageList:messageArray];

        completion (messageArray,error);
    }];

}
//------------------------------------------------------------------------------------------------------------------
    #pragma mark -  Helper methods
//------------------------------------------------------------------------------------------------------------------

-(void)syncConverstionDBWithCompletion:(void(^)(BOOL success , NSMutableArray * theArray)) completion
{
    [ALMessageService getMessagesListGroupByContactswithCompletionService:^(NSMutableArray *messages, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"%@",error);
            completion(NO,nil);
            return ;
        }
        completion(YES, messages);
    }];
}


-(void)getLatestMessagesWithCompletion:(void(^)( NSMutableArray * theArray,NSError *error)) completion
{
    [ALMessageService getMessagesListGroupByContactswithCompletionService:^(NSMutableArray *messages, NSError *error) {
        completion(messages, error);
    }];
}


-(void)syncConactsDB
{
//    ALContactService *contactservice = [[ALContactService alloc] init];
   // [contactservice insertInitialContacts];
}

-(NSArray*)getMessageList:(int)messageCount
                messageTypeOnlyReceived:(BOOL)received
{

    // Get the latest record
    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [theRequest setResultType:NSDictionaryResultType];
    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    if(received) {
        // Load messages with type received
        [theRequest setPredicate:[NSPredicate predicateWithFormat:@"type == %@ AND deletedFlag == %@ AND contentType != %i AND msgHidden == %@",@"4",@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
    } else {
        // No type restriction
        [theRequest setPredicate:[NSPredicate predicateWithFormat:@"deletedFlag == %@ AND contentType != %i AND msgHidden == %@",@(NO), ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
    }
    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    // Trim the message list
    NSArray *updatedList = [theArray subarrayWithRange:NSMakeRange(0, MIN(messageCount, theArray.count))];
    return updatedList;

}

-(void)fetchConversationsGroupByContactId
{
    [self fetchLatestConversationsGroupByContactId :NO];
}


-(NSMutableArray*)fetchLatestConversationsGroupByContactId :(BOOL) isFetchOnCreatedAtTime {

    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    // get all unique contacts
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [theRequest setResultType:NSDictionaryResultType];
    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [theRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"groupId", nil]];
    [theRequest setReturnsDistinctResults:YES];

    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    // get latest record
    NSMutableArray *messagesArray = [NSMutableArray new];
    for (NSDictionary * theDictionary in theArray) {
        NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
        if([theDictionary[@"groupId"] intValue]==0){
            continue;
        }
        if([ALApplozicSettings getCategoryName]){
            ALChannel* channel=  [[ALChannelService new] getChannelByKey:[NSNumber numberWithInt:[theDictionary[@"groupId"] intValue]]];
            if(![channel isPartOfCategory:[ALApplozicSettings getCategoryName]])
            {
                continue;
            }

        }
        [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
        [theRequest setPredicate:[NSPredicate predicateWithFormat:@"groupId==%d AND deletedFlag == %@ AND contentType != %i AND msgHidden == %@",
                                  [theDictionary[@"groupId"] intValue],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
        [theRequest setFetchLimit:1];

        NSArray * groupMsgArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
        DB_Message * theMessageEntity = groupMsgArray.firstObject;
        if(groupMsgArray.count)
        {
            ALMessage * theMessage = [self createMessageEntity:theMessageEntity];
            [messagesArray addObject:theMessage];
        }
    }
    // Find all message only have contact ...
    NSFetchRequest * theRequest1 = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [theRequest1 setResultType:NSDictionaryResultType];
    [theRequest1 setPredicate:[NSPredicate predicateWithFormat:@"groupId=%d OR groupId=nil",0]];
    [theRequest1 setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [theRequest1 setPropertiesToFetch:[NSArray arrayWithObjects:@"contactId", nil]];
    [theRequest1 setReturnsDistinctResults:YES];
    NSArray * userMsgArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest1 error:nil];

    for (NSDictionary * theDictionary in userMsgArray) {

        NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
        [theRequest setPredicate:[NSPredicate predicateWithFormat:@"contactId = %@ and groupId=nil and deletedFlag == %@ AND contentType != %i AND msgHidden == %@",theDictionary[@"contactId"],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];

        [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
        [theRequest setFetchLimit:1];

        NSArray * fetchArray =  [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
        DB_Message * theMessageEntity = fetchArray.firstObject;
        if(fetchArray.count)
        {
            ALMessage * theMessage = [self createMessageEntity:theMessageEntity];
            [messagesArray addObject:theMessage];
        }

    }
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSMutableArray *sortedArray = [[messagesArray sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];

    if (self.delegate && [self.delegate respondsToSelector:@selector(getMessagesArray:)]) {
        [self.delegate getMessagesArray:sortedArray];
    }

    return sortedArray;
}


-(DB_Message *) createMessageEntityForDBInsertionWithMessage:(ALMessage *) theMessage
{

    //Runs at MessageList viewing/opening... ONLY FIRST TIME
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];

    DB_Message * theMessageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"DB_Message" inManagedObjectContext:theDBHandler.managedObjectContext];

    theMessageEntity.contactId = theMessage.contactIds;
    theMessageEntity.createdAt =  theMessage.createdAtTime;
    theMessageEntity.deviceKey = theMessage.deviceKey;
    theMessageEntity.status = [NSNumber numberWithInt:([theMessageEntity.type isEqualToString:@"5"] ? READ
                                                       : theMessage.status.intValue)];

//    theMessageEntity.isSent = [NSNumber numberWithBool:theMessage.sent];
    theMessageEntity.isSentToDevice = [NSNumber numberWithBool:theMessage.sendToDevice];
    theMessageEntity.isShared = [NSNumber numberWithBool:theMessage.shared];
    theMessageEntity.isStoredOnDevice = [NSNumber numberWithBool:theMessage.storeOnDevice];
    theMessageEntity.key = theMessage.key;
    theMessageEntity.messageText = theMessage.message;
    theMessageEntity.userKey = theMessage.userKey;
    theMessageEntity.to = theMessage.to;
    theMessageEntity.type = theMessage.type;
    theMessageEntity.delivered = [NSNumber numberWithBool:theMessage.delivered];
    theMessageEntity.sentToServer = [NSNumber numberWithBool:theMessage.sentToServer];
    theMessageEntity.filePath = theMessage.imageFilePath;
    theMessageEntity.inProgress = [NSNumber numberWithBool:theMessage.inProgress];
    theMessageEntity.isUploadFailed=[ NSNumber numberWithBool:theMessage.isUploadFailed];
    theMessageEntity.contentType = theMessage.contentType;
    theMessageEntity.deletedFlag=[NSNumber numberWithBool:theMessage.deleted];
    theMessageEntity.conversationId = theMessage.conversationId;
    theMessageEntity.pairedMessageKey = theMessage.pairedMessageKey;
    theMessageEntity.metadata = theMessage.metadata.description;
    theMessageEntity.msgHidden = [NSNumber numberWithBool:[theMessage isHiddenMessage]];
    theMessageEntity.replyMessageType = theMessage.messageReplyType;
    theMessageEntity.source = theMessage.source;

    if(theMessage.getGroupId)
    {
        theMessageEntity.groupId = theMessage.groupId;
    }
    if(theMessage.fileMeta != nil) {
        DB_FileMetaInfo *  fileInfo =  [self createFileMetaInfoEntityForDBInsertionWithMessage:theMessage.fileMeta];
        theMessageEntity.fileMetaInfo = fileInfo;
    }

    return theMessageEntity;
}

-(DB_FileMetaInfo *) createFileMetaInfoEntityForDBInsertionWithMessage:(ALFileMetaInfo *) fileInfo
{
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    DB_FileMetaInfo * fileMetaInfo = [NSEntityDescription insertNewObjectForEntityForName:@"DB_FileMetaInfo" inManagedObjectContext:theDBHandler.managedObjectContext];

    fileMetaInfo.blobKeyString = fileInfo.blobKey;
    fileMetaInfo.thumbnailBlobKeyString = fileInfo.thumbnailBlobKey;
    fileMetaInfo.contentType = fileInfo.contentType;
    fileMetaInfo.createdAtTime = fileInfo.createdAtTime;
    fileMetaInfo.key = fileInfo.key;
    fileMetaInfo.name = fileInfo.name;
    fileMetaInfo.size = fileInfo.size;
    fileMetaInfo.suUserKeyString = fileInfo.userKey;
    fileMetaInfo.thumbnailUrl = fileInfo.thumbnailUrl;
    fileMetaInfo.url = fileInfo.url;
    return fileMetaInfo;
}

-(ALMessage *) createMessageEntity:(DB_Message *) theEntity
{
    ALMessage * theMessage = [ALMessage new];

    theMessage.msgDBObjectId = [theEntity objectID];
    theMessage.key = theEntity.key;
    theMessage.deviceKey = theEntity.deviceKey;
    theMessage.userKey = theEntity.userKey;
    theMessage.to = theEntity.to;
    theMessage.message = theEntity.messageText;
//    theMessage.sent = theEntity.isSent.boolValue;
    theMessage.sendToDevice = theEntity.isSentToDevice.boolValue;
    theMessage.shared = theEntity.isShared.boolValue;
    theMessage.createdAtTime = theEntity.createdAt;
    theMessage.type = theEntity.type;
    theMessage.contactIds = theEntity.contactId;
    theMessage.storeOnDevice = theEntity.isStoredOnDevice.boolValue;
    theMessage.inProgress =theEntity.inProgress.boolValue;
    theMessage.status = theEntity.status;
    theMessage.imageFilePath = theEntity.filePath;
    theMessage.delivered = theEntity.delivered.boolValue;
    theMessage.sentToServer = theEntity.sentToServer.boolValue;
    theMessage.isUploadFailed = theEntity.isUploadFailed.boolValue;
    theMessage.contentType = theEntity.contentType;

    theMessage.deleted=theEntity.deletedFlag.boolValue;
    theMessage.groupId = theEntity.groupId;
    theMessage.conversationId = theEntity.conversationId;
    theMessage.pairedMessageKey = theEntity.pairedMessageKey;
    theMessage.metadata = [theMessage getMetaDataDictionary:theEntity.metadata];
    theMessage.msgHidden = [theEntity.msgHidden boolValue];
    theMessage.source = [theEntity source];

    // file meta info
    if(theEntity.fileMetaInfo){
        ALFileMetaInfo * theFileMeta = [ALFileMetaInfo new];
        theFileMeta.blobKey = theEntity.fileMetaInfo.blobKeyString;
        theFileMeta.thumbnailBlobKey = theEntity.fileMetaInfo.thumbnailBlobKeyString;
        theFileMeta.contentType = theEntity.fileMetaInfo.contentType;
        theFileMeta.createdAtTime = theEntity.fileMetaInfo.createdAtTime;
        theFileMeta.key = theEntity.fileMetaInfo.key;
        theFileMeta.name = theEntity.fileMetaInfo.name;
        theFileMeta.size = theEntity.fileMetaInfo.size;
        theFileMeta.userKey = theEntity.fileMetaInfo.suUserKeyString;
        theFileMeta.thumbnailUrl = theEntity.fileMetaInfo.thumbnailUrl;
        theFileMeta.thumbnailFilePath = theEntity.fileMetaInfo.thumbnailFilePath;
        theFileMeta.url = theEntity.fileMetaInfo.url;
        theMessage.fileMeta = theFileMeta;
    }
    return theMessage;
}

-(void) updateFileMetaInfo:(ALMessage *) almessage
{
    NSError *error=nil;
    DB_Message * db_Message = (DB_Message*)[self getMeesageById:almessage.msgDBObjectId error:&error];
    almessage.fileMetaKey = almessage.fileMeta.key;

    db_Message.fileMetaInfo.blobKeyString = almessage.fileMeta.blobKey;
    db_Message.fileMetaInfo.thumbnailBlobKeyString = almessage.fileMeta.thumbnailBlobKey;
    db_Message.fileMetaInfo.contentType = almessage.fileMeta.contentType;
    db_Message.fileMetaInfo.createdAtTime = almessage.fileMeta.createdAtTime;
    db_Message.fileMetaInfo.key = almessage.fileMeta.key;
    db_Message.fileMetaInfo.name = almessage.fileMeta.name;
    db_Message.fileMetaInfo.size = almessage.fileMeta.size;
    db_Message.fileMetaInfo.suUserKeyString = almessage.fileMeta.userKey;
    db_Message.fileMetaInfo.url = almessage.fileMeta.url;
    [[ALDBHandler sharedInstance].managedObjectContext save:nil];

}



-(NSMutableArray *)getMessageListForContactWithCreatedAt:(MessageListRequest *)messageListRequest
{
    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate1;

    if([ALApplozicSettings getContextualChatOption] && messageListRequest.conversationId && messageListRequest.conversationId != 0){
        if(messageListRequest.channelKey){
            predicate1 = [NSPredicate predicateWithFormat:@"groupId = %@ && conversationId = %i",messageListRequest.channelKey,messageListRequest.conversationId];
        }
        else{
            predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && conversationId = %i",messageListRequest.userId,messageListRequest.conversationId];
        }
    }else if(messageListRequest.channelKey){
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %@",messageListRequest.channelKey];
    } else{
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil ",messageListRequest.userId];
    }

    NSPredicate* predicateDeletedCheck=[NSPredicate predicateWithFormat:@"deletedFlag == NO"];

    NSPredicate *predicateForHiddenMessages = [NSPredicate predicateWithFormat:@"msgHidden == %@", @(NO)];

    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"createdAt < 0"];

    NSCompoundPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2, predicateDeletedCheck,predicateForHiddenMessages]];;

    if(messageListRequest.endTimeStamp){
        NSPredicate *predicateForEndTimeStamp= [NSPredicate predicateWithFormat:@"createdAt < %@",messageListRequest.endTimeStamp];
        compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicateForEndTimeStamp, predicateDeletedCheck,predicateForHiddenMessages]];
    }

    if(messageListRequest.startTimeStamp){
        NSPredicate *predicateCreatedAtForStartTime  = [NSPredicate predicateWithFormat:@"createdAt >= %@",messageListRequest.startTimeStamp];
      compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicateCreatedAtForStartTime, predicateDeletedCheck,predicateForHiddenMessages]];
    }
    theRequest.predicate = compoundPredicate;

    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    theRequest.fetchLimit = 200;
    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    NSMutableArray * msgArray =  [[NSMutableArray alloc]init];
    for (DB_Message * theEntity in theArray) {
        ALMessage * theMessage = [self createMessageEntity:theEntity];
        [msgArray addObject:theMessage];
    }
    return msgArray;
}

-(NSMutableArray *)getAllMessagesWithAttachmentForContact:(NSString *)contactId
                                            andChannelKey:(NSNumber *)channelKey
                                onlyDownloadedAttachments: (BOOL )onlyDownloaded
{
    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate1;

    if(channelKey){
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %@",channelKey];
    }
    else{
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@",contactId];
    }

    NSPredicate* predicateDeletedCheck=[NSPredicate predicateWithFormat:@"deletedFlag == NO"];

    NSPredicate *predicateForFileMeta = [NSPredicate predicateWithFormat:@"fileMetaInfo != nil"];
    NSMutableArray* predicates = [[NSMutableArray alloc] initWithArray: @[predicate1, predicateDeletedCheck, predicateForFileMeta]];

    if(onlyDownloaded) {
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"filePath != nil"];
        [predicates addObject:predicate2];
    }

    theRequest.predicate =[NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    NSMutableArray * msgArray =  [[NSMutableArray alloc]init];
    for (DB_Message * theEntity in theArray) {
        ALMessage * theMessage = [self createMessageEntity:theEntity];
        [msgArray addObject:theMessage];
    }
    return msgArray;
}


-(NSMutableArray *)getPendingMessages
{

    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    theRequest.predicate = [NSPredicate predicateWithFormat:@"sentToServer = %@ and type= %@ and deletedFlag = %@",@"0",@"5",@(NO)];

    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    NSMutableArray * msgArray = [[NSMutableArray alloc]init];

    for (DB_Message * theEntity in theArray)
    {
        ALMessage * theMessage = [self createMessageEntity:theEntity];
        if([theMessage.groupId isEqualToNumber:[NSNumber numberWithInt:0]])
        {
            ALSLog(ALLoggerSeverityInfo, @"groupId is coming as 0..setting it null" );
            theMessage.groupId = NULL;
        }
        [msgArray addObject:theMessage]; ALSLog(ALLoggerSeverityInfo, @"Pending Message status:%@",theMessage.status);
    }

    ALSLog(ALLoggerSeverityInfo, @" get pending messages ...getPendingMessages ..%lu",(unsigned long)msgArray.count);
    return msgArray;
}

-(NSUInteger)getMessagesCountFromDBForUser:(NSString *)userId
{
    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil",userId];
    [theRequest setPredicate:predicate];
    NSUInteger count = [theDbHandler.managedObjectContext countForFetchRequest:theRequest error:nil];
    return count;

}

//============================================================================================================
#pragma mark ADD BROADCAST MESSAGE TO DB
//============================================================================================================

+(void)addBroadcastMessageToDB:(ALMessage *)alMessage {

    ALChannelService *channelService = [[ALChannelService alloc] init];
    ALChannel *alChannel = [channelService getChannelByKey:alMessage.groupId];
    if (alChannel.type == BROADCAST)
    {
        ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
        NSMutableArray * memberList = [channelService getListOfAllUsersInChannel:alMessage.groupId];
        [memberList removeObject:[ALUserDefaultsHandler getUserId]];
        NSManagedObjectContext * MOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        MOC.persistentStoreCoordinator = dbHandler.persistentStoreCoordinator;
        [MOC performBlock:^{

            for (NSString *userId in memberList)
            {
                ALSLog(ALLoggerSeverityInfo, @"BROADCAST_CHANNEL_MEMBER : %@",userId);
                DB_Message * dbMsgEntity = [NSEntityDescription insertNewObjectForEntityForName:@"DB_Message"
                                                                         inManagedObjectContext:dbHandler.managedObjectContext];
                dbMsgEntity.contactId = userId;
                dbMsgEntity.createdAt = alMessage.createdAtTime;
                dbMsgEntity.deviceKey = alMessage.deviceKey;
                dbMsgEntity.status = alMessage.status;
                dbMsgEntity.isSentToDevice = [NSNumber numberWithBool:alMessage.sendToDevice];
                dbMsgEntity.isShared = [NSNumber numberWithBool:alMessage.shared];
                dbMsgEntity.isStoredOnDevice = [NSNumber numberWithBool:alMessage.storeOnDevice];
                dbMsgEntity.key = [NSString stringWithFormat:@"%@-%@", alMessage.key, userId];
                dbMsgEntity.messageText = alMessage.message;
                dbMsgEntity.userKey = alMessage.userKey;
                dbMsgEntity.to = userId;
                dbMsgEntity.type = alMessage.type;
                dbMsgEntity.delivered = [NSNumber numberWithBool:alMessage.delivered];
                dbMsgEntity.sentToServer = [NSNumber numberWithBool:alMessage.sentToServer];
                dbMsgEntity.filePath = alMessage.imageFilePath;
                dbMsgEntity.inProgress = [NSNumber numberWithBool:alMessage.inProgress];
                dbMsgEntity.isUploadFailed = [NSNumber numberWithBool:alMessage.isUploadFailed];
                dbMsgEntity.contentType = alMessage.contentType;
                dbMsgEntity.deletedFlag = [NSNumber numberWithBool:alMessage.deleted];
                dbMsgEntity.conversationId = alMessage.conversationId;
                dbMsgEntity.pairedMessageKey = alMessage.pairedMessageKey;
                dbMsgEntity.metadata = alMessage.metadata.description;
                dbMsgEntity.msgHidden = [NSNumber numberWithBool:[alMessage isHiddenMessage]];

                if(alMessage.fileMeta != nil)
                {
                    ALMessageDBService * classSelf = [[self alloc] init];
                    DB_FileMetaInfo * fileInfo = [classSelf createFileMetaInfoEntityForDBInsertionWithMessage:alMessage.fileMeta];
                    dbMsgEntity.fileMetaInfo = fileInfo;
                }

                NSError * error;
                BOOL flag = [dbHandler.managedObjectContext save:&error];
                ALSLog(ALLoggerSeverityError, @"ERROR(IF_ANY) BROADCAST MSG : %@ and flag : %i",error.description, flag);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BROADCAST_MSG_UPDATE" object:nil];
        }];
    }
}

//============================================================================================================
#pragma mark GET LATEST MESSAGE FOR USER/CHANNEL
//============================================================================================================

-(ALMessage *)getLatestMessageForUser:(NSString *)userId
{
    ALDBHandler *dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId = %@ and groupId = nil and deletedFlag = %@",userId,@(NO)];
    [request setPredicate:predicate];
    [request setFetchLimit:1];

    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    NSArray *messagesArray = [dbHandler.managedObjectContext executeFetchRequest:request error:nil];

    if(messagesArray.count)
    {
        DB_Message * dbMessage = [messagesArray objectAtIndex:0];
        ALMessage * alMessage = [self createMessageEntity:dbMessage];
        return alMessage;
    }

    return nil;
}

-(ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey excludeChannelOperations:(BOOL)flag
{
    ALDBHandler *dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupId = %@ and deletedFlag = %@",channelKey,@(NO)];

    if(flag)
    {
        predicate = [NSPredicate predicateWithFormat:@"groupId = %@ and deletedFlag = %@ and contentType != %i",channelKey,@(NO),ALMESSAGE_CHANNEL_NOTIFICATION];
    }

    [request setPredicate:predicate];
    [request setFetchLimit:1];

    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    NSArray *messagesArray = [dbHandler.managedObjectContext executeFetchRequest:request error:nil];

    if(messagesArray.count)
    {
        DB_Message * dbMessage = [messagesArray objectAtIndex:0];
        ALMessage * alMessage = [self createMessageEntity:dbMessage];
        return alMessage;
    }

    return nil;
}


/////////////////////////////  FETCH CONVERSATION WITH PAGE SIZE  /////////////////////////////

-(void)fetchConversationfromServerWithCompletion:(void(^)(BOOL flag))completionHandler
{
    [self syncConverstionDBWithCompletion:^(BOOL success, NSMutableArray * theArray) {

        if (!success)
        {
            completionHandler(success);
            return;
        }

        [self addMessageList:theArray];
        [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
        [self fetchConversationsGroupByContactId];

        completionHandler(success);

    }];

}

/************************************
FETCH LATEST MESSSAGE FOR SUB GROUPS
************************************/

-(void)fetchSubGroupConversations:(NSMutableArray *)subGroupList
{
    NSMutableArray * subGroupMsgArray = [NSMutableArray new];

    for(ALChannel * alChannel in subGroupList)
    {
        ALMessage * alMessage = [self getLatestMessageForChannel:alChannel.key excludeChannelOperations:NO];
        if(alMessage)
        {
            [subGroupMsgArray addObject:alMessage];
            if(alChannel.type == GROUP_OF_TWO)
            {
                NSMutableArray * array = [[alChannel.clientChannelKey componentsSeparatedByString:@":"] mutableCopy];

                if(![array containsObject:[ALUserDefaultsHandler getUserId]])
                {
                    [subGroupMsgArray removeObject:alMessage];
                }
            }
        }
    }

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSMutableArray *sortedArray = [[subGroupMsgArray sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];

    if ([self.delegate respondsToSelector:@selector(getMessagesArray:)]) {
        [self.delegate getMessagesArray:sortedArray];
    }
}


-(void) updateMessageReplyType:(NSString*)messageKeyString replyType : (NSNumber *) type {

    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];

    DB_Message * replyMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageKeyString];

    replyMessage.replyMessageType = type;

    NSError *Error = nil;

    BOOL success = [dbHandler.managedObjectContext save:&Error];

    if (!success) {
        ALSLog(ALLoggerSeverityInfo, @"Unable to save replytype .");
        ALSLog(ALLoggerSeverityError, @"%@, %@", Error, Error.localizedDescription);
    }
}


-(ALMessage*) getMessageByKey:(NSString*)messageKey{
    DB_Message * dbMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageKey];
    return  [self createMessageEntity:dbMessage];

}

-(void) updateMessageSentDetails:(NSString*)messageKeyString withCreatedAtTime : (NSNumber *) createdAtTime withDbMessage:(DB_Message *) dbMessage {

    if(!dbMessage){
        return;
    }

          ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
            dbMessage.key = messageKeyString;
            dbMessage.inProgress = [NSNumber numberWithBool:NO];
            dbMessage.isUploadFailed = [NSNumber numberWithBool:NO];
            dbMessage.createdAt =createdAtTime;

            dbMessage.sentToServer=[NSNumber numberWithBool:YES];
            dbMessage.status = [NSNumber numberWithInt:SENT];
            [theDBHandler.managedObjectContext save:nil];

}

-(void) getLatestMessages:(BOOL)isNextPage withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion{

    if(!isNextPage){

        if ([self isMessageTableEmpty])  // db is not synced
        {
            [self fetchAndRefreshFromServerWithCompletion:^(NSMutableArray * theArray,NSError *error) {
                completion(theArray,error);
            }];
        }else{
            completion([self fetchLatestConversationsGroupByContactId:NO],nil);
        }
    }else{
        [self fetchAndRefreshFromServerWithCompletion:^(NSMutableArray * theArray,NSError *error) {
            completion(theArray,error);

        }];
    }
}

-(void)fetchAndRefreshFromServerWithCompletion :(void(^)(NSMutableArray * theArray,NSError *error)) completion{

    if(![ALUserDefaultsHandler getFlagForAllConversationFetched]){
        [self getLatestMessagesWithCompletion:^(NSMutableArray * theArray,NSError *error) {

            if (!error) {
                // save data into the db
                [self addMessageList:theArray];
                // set yes to userdefaults
                [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
                // add default contacts
                //fetch data from db
                completion([self fetchLatestConversationsGroupByContactId:YES],error);
                return ;
            }else{
                completion(nil,error);
            }
        }];
    }else{
        completion(nil,nil);
    }
}


-(void) getLatestMessages:(BOOL)isNextPage withOnlyGroups:(BOOL)isGroup withCompletionHandler: (void(^)(NSMutableArray * messageList, NSError *error)) completion{

    if(!isNextPage){

        if ([self isMessageTableEmpty])  // db is not synced
        {
            [self fetchLatestMesssagesFromServer:isGroup withCompletion:^(NSMutableArray * theArray,NSError *error) {
                completion(theArray,error);
            }];
        }else{
            completion([self fetchLatestMesssagesFromDb:isGroup],nil);
        }
    }else{
        [self fetchLatestMesssagesFromServer:isGroup withCompletion:^(NSMutableArray * theArray,NSError *error) {
            completion(theArray,error);

        }];
    }
}

-(void)fetchLatestMesssagesFromServer:(BOOL) isGroupMesssages withCompletion:(void(^)(NSMutableArray * theArray,NSError *error)) completion{

    if(![ALUserDefaultsHandler getFlagForAllConversationFetched]){
        [self getLatestMessagesWithCompletion:^(NSMutableArray * theArray,NSError *error) {

            if (!error) {
                // save data into the db
                [self addMessageList:theArray];
                // set yes to userdefaults
                [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
                // add default contacts
                //fetch data from db
                completion([self fetchLatestMesssagesFromDb:isGroupMesssages],error);
                return ;
            }else{
                completion(nil,error);
            }
        }];
    }else{
        completion(nil,nil);
    }
}

-(NSMutableArray*)fetchLatestMesssagesFromDb :(BOOL) isGroupMessages {

    NSMutableArray *messagesArray = [NSMutableArray new];

    if(isGroupMessages){
        messagesArray =  [self getLatestMessagesForGroup];
    }else{
        messagesArray = [self getLatestMessagesForContact];
    }

    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSMutableArray *sortedArray = [[messagesArray sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];

    return sortedArray;
}

-(NSMutableArray *) getLatestMessagesForContact{

    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSMutableArray *messagesArray = [NSMutableArray new];

    // Find all message only have contact ...
    NSFetchRequest * theRequest1 = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [theRequest1 setResultType:NSDictionaryResultType];
    [theRequest1 setPredicate:[NSPredicate predicateWithFormat:@"groupId=%d OR groupId=nil",0]];
    [theRequest1 setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [theRequest1 setPropertiesToFetch:[NSArray arrayWithObjects:@"contactId", nil]];
    [theRequest1 setReturnsDistinctResults:YES];
    NSArray * userMsgArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest1 error:nil];

    for (NSDictionary * theDictionary in userMsgArray) {

        NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
        [theRequest setPredicate:[NSPredicate predicateWithFormat:@"contactId = %@ and groupId=nil and deletedFlag == %@ AND contentType != %i AND msgHidden == %@",theDictionary[@"contactId"],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];

        [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
        [theRequest setFetchLimit:1];

        NSArray * fetchArray =  [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
        DB_Message * theMessageEntity = fetchArray.firstObject;
        if(fetchArray.count)
        {
            ALMessage * theMessage = [self createMessageEntity:theMessageEntity];
            [messagesArray addObject:theMessage];
        }

    }

    return messagesArray;

}

-(NSMutableArray*) getLatestMessagesForGroup{

    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSMutableArray *messagesArray = [NSMutableArray new];

    // get all unique contacts
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [theRequest setResultType:NSDictionaryResultType];
    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [theRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"groupId", nil]];
    [theRequest setReturnsDistinctResults:YES];

    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    // get latest record
    for (NSDictionary * theDictionary in theArray) {
        NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];

        if([theDictionary[@"groupId"] intValue]==0){
            continue;
        }

        if([ALApplozicSettings getCategoryName]){
            ALChannel* channel=  [[ALChannelService new] getChannelByKey:[NSNumber numberWithInt:[theDictionary[@"groupId"] intValue]]];
            if(![channel isPartOfCategory:[ALApplozicSettings getCategoryName]])
            {
                continue;
            }

        }
        [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
        [theRequest setPredicate:[NSPredicate predicateWithFormat:@"groupId==%d AND deletedFlag == %@ AND contentType != %i AND msgHidden == %@",
                                  [theDictionary[@"groupId"] intValue],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
        [theRequest setFetchLimit:1];

        NSArray * groupMsgArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
        DB_Message * theMessageEntity = groupMsgArray.firstObject;
        if(groupMsgArray.count)
        {
            ALMessage * theMessage = [self createMessageEntity:theMessageEntity];
            [messagesArray addObject:theMessage];
        }
    }

    return messagesArray;

}

-(ALMessage *)handleMessageFailedStatus:(ALMessage *)message
{
    if(!message.msgDBObjectId){
        return nil;
    }
    message.inProgress = NO;
    message.isUploadFailed = YES;
    message.sentToServer = NO;
    DB_Message *dbMessage = (DB_Message*)[self getMessageByKey:@"key" value:message.key];
    dbMessage.inProgress = [NSNumber numberWithBool:NO];
    dbMessage.isUploadFailed = [NSNumber numberWithBool:YES];
    dbMessage.sentToServer= [NSNumber numberWithBool:NO];;

    [[ALDBHandler sharedInstance].managedObjectContext save:nil];

    return message;
}

-(ALMessage*)writeDataAndUpdateMessageInDb:(NSData*)data withMessageKey:(NSString *)messageKey withFileFlag:(BOOL)isFile{

    DB_Message * messageEntity = (DB_Message*)[self getMessageByKey:@"key" value:messageKey];
    NSData *imageData;
    if (![messageEntity.fileMetaInfo.contentType hasPrefix:@"image"]) {
        imageData = data;
    } else {
        imageData = [ALUtilityClass compressImage: data];
    }

    NSString * docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *componentsArray = [messageEntity.fileMetaInfo.name componentsSeparatedByString:@"."];
    NSString *fileExtension = [componentsArray lastObject];

    NSString * filePath;

    if(isFile){

        filePath = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_local.%@",messageKey,fileExtension]];

        // If 'save video to gallery' is enabled then save to gallery
        if([ALApplozicSettings isSaveVideoToGalleryEnabled]) {
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, nil, nil);
        }

        messageEntity.inProgress = [NSNumber numberWithBool:NO];
        messageEntity.isUploadFailed=[NSNumber numberWithBool:NO];
        messageEntity.filePath = [NSString stringWithFormat:@"%@_local.%@",messageKey,fileExtension];
    }else{
        filePath  = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_thumbnail_local.%@",messageKey,fileExtension]];

        messageEntity.fileMetaInfo.thumbnailFilePath = [NSString stringWithFormat:@"%@_thumbnail_local.%@",messageKey,fileExtension];
    }

    [imageData writeToFile:filePath atomically:YES];

    [[ALDBHandler sharedInstance].managedObjectContext save:nil];

    ALMessage * almessage = [[ALMessageDBService new ] createMessageEntity:messageEntity];

    return almessage;
}


-(DB_Message*)addAttachmentMessage:(ALMessage*)message{

    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    ALMessageDBService* messageDBService = [[ALMessageDBService alloc] init];
    DB_Message * theMessageEntity = [messageDBService createMessageEntityForDBInsertionWithMessage:message];

    [theDBHandler.managedObjectContext save:nil];
    message.msgDBObjectId = [theMessageEntity objectID];
    theMessageEntity.inProgress = [NSNumber numberWithBool:YES];
    theMessageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
    [[ALDBHandler sharedInstance].managedObjectContext save:nil];

    return theMessageEntity;
}

- (void)updateMessageMetadataOfKey:(NSString *)messageKey withMetadata:(NSMutableDictionary *)metadata
{
    ALSLog(ALLoggerSeverityInfo, @"Updating message metadata in local db for key : %@", messageKey);
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];

    DB_Message * dbMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageKey];
    dbMessage.metadata = metadata.description;
    if(metadata != nil && [metadata objectForKey:@"hiddenStatus"] != nil){
        dbMessage.msgHidden = [NSNumber numberWithBool: [[metadata objectForKey:@"hiddenStatus"] isEqualToString:@"true"]];
    }

    NSError *error = nil;
    BOOL success = [dbHandler.managedObjectContext save:&error];

    if (!success) {
        ALSLog(ALLoggerSeverityError, @"Unable to save metadata in local db : %@", error);
    } else {
        ALSLog(ALLoggerSeverityInfo, @"Message metadata has been updated successfully in local db");
    }
}

@end
