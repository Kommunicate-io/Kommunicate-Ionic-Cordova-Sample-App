//
//  ALChannelService.m
//  Applozic
//
//  Created by devashish on 04/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALChannelService.h"
#import "ALMessageClientService.h"
#import "ALConversationService.h"
#import "ALChannelUser.h"
#import "ALMuteRequest.h"
#import "ALAPIResponse.h"
#import "ALContactService.h"
#import "ALRealTimeUpdate.h"

@implementation ALChannelService

+(ALChannelService *)sharedInstance
{
    static ALChannelService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALChannelService alloc] init];
    });
    return sharedInstance;
}

-(void)callForChannelServiceForDBInsertion:(NSString *)theJson
{
    ALChannelFeed *alChannelFeed = [[ALChannelFeed alloc] initWithJSONString:theJson];

    ALChannelDBService *alChannelDBService = [[ALChannelDBService alloc] init];
    [alChannelDBService insertChannel:alChannelFeed.channelFeedsList];

    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];

    for(ALChannel *channel in alChannelFeed.channelFeedsList)
    {

        if(channel.membersName == nil){
            channel.membersName = channel.membersId;
        }
        [alChannelDBService saveDataInBackgroundWithContext:theDBHandler.privateContext withChannel: channel];

        [self processChildGroups:channel];
        [alChannelDBService addedMembersArray:channel.membersName andChannelKey:channel.key];
        [alChannelDBService removedMembersArray:channel.removeMembers andChannelKey:channel.key];

    }

    //callForChannelProxy inserting in DB...
    ALConversationService *alConversationService = [[ALConversationService alloc] init];
    [alConversationService addConversations:alChannelFeed.conversationProxyList];

}


-(void)processChildGroups:(ALChannel *)alChannel {
    //Get INFO of Child
    for(NSNumber *channelKey in alChannel.childKeys){
        [self getChannelInformation:channelKey orClientChannelKey:nil withCompletion:^(ALChannel *alChannel3) {
            
        }];
    }
    
}


-(ALChannelUserX *)loadChannelUserX:(NSNumber *)channelKey{
    ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
    return [channelDBService loadChannelUserX:channelKey];
}


-(void)getChannelInformation:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void (^)(ALChannel *alChannel3)) completion
{
    ALChannel *alChannel1;
    if (clientChannelKey) {
        alChannel1 = [self fetchChannelWithClientChannelKey:clientChannelKey];
    }else{
        alChannel1 = [self getChannelByKey:channelKey];
    }
    
    if(alChannel1)
    {
        completion (alChannel1);
    }
    else
    {
        [ALChannelClientService getChannelInfo:channelKey orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, ALChannel *alChannel2) {
            
            if(!error)
            {
                ALChannelDBService *dbService = [[ALChannelDBService alloc] init];
                [dbService createChannel:alChannel2];
            }
            completion (alChannel2);
        }];
    }
}

+(BOOL)isConversationClosed:(NSNumber *)groupId
{
    ALChannelDBService *dbSerivce = [[ALChannelDBService alloc] init];
    return [dbSerivce isConversaionClosed:groupId];
}

+(BOOL)isChannelDeleted:(NSNumber *)groupId
{
    ALChannelDBService *dbSerivce = [[ALChannelDBService alloc] init];
    BOOL flag = [dbSerivce isChannelDeleted:groupId];
    return flag;
}

+(BOOL)isChannelMuted:(NSNumber *)groupId
{
    ALChannelService * channelService = [[ALChannelService alloc] init];
    ALChannel *channel = [channelService getChannelByKey:groupId];
    return [channel isNotificationMuted];
}

-(BOOL)isChannelLeft:(NSNumber *)groupID
{
    ALChannelDBService *dbSerivce = [[ALChannelDBService alloc] init];
    BOOL flag = [dbSerivce isChannelLeft:groupID];
    return flag;
}

-(ALChannel *)getChannelByKey:(NSNumber *)channelKey
{
    ALChannelDBService * dbSerivce = [[ALChannelDBService alloc] init];
    ALChannel *channel = [dbSerivce loadChannelByKey:channelKey];
    return channel;
}

-(NSMutableArray *)getListOfAllUsersInChannel:(NSNumber *)channelKey
{
    ALChannelDBService *ob = [[ALChannelDBService alloc] init];
    return [ob getListOfAllUsersInChannel:channelKey];
}

-(NSString *)stringFromChannelUserList:(NSNumber *)key
{
    ALChannelDBService *ob = [[ALChannelDBService alloc] init];
    return [ob stringFromChannelUserList: key];
}

-(NSNumber *)getOverallUnreadCountForChannel
{
    ALChannelDBService *ob = [[ALChannelDBService alloc] init];
    return [ob getOverallUnreadCountForChannelFromDB];
}

-(ALChannel *)fetchChannelWithClientChannelKey:(NSString *)clientChannelKey
{
    ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
    ALChannel * channel = [channelDB loadChannelByClientChannelKey:clientChannelKey];
    return channel;
}

-(BOOL)isLoginUserInChannel:(NSNumber *)channelKey
{
    NSMutableArray * memberList = [NSMutableArray arrayWithArray:[self getListOfAllUsersInChannel:channelKey]];
    return ([memberList containsObject:[ALUserDefaultsHandler getUserId]]);
}

-(NSMutableArray *)getAllChannelList
{
    ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
    return [channelDB getAllChannelKeyAndName];
}

+(void)closeGroupConverstion :(NSNumber *) groupId  withCompletion:(void(^)(NSError *error))completion {

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setObject:@"CLOSE" forKey:CHANNEL_CONVERSATION_STATUS];
    
    ALChannelService *channelService = [ALChannelService new];
    [channelService updateChannel:groupId andNewName:nil
                      andImageURL:nil orClientChannelKey:nil isUpdatingMetaData:YES
                         metadata:metadata orChildKeys:nil orChannelUsers:nil  withCompletion:^(NSError *error) {
                             completion(error);
                         }];
    
    
}


//==========================================================================================================================================
#pragma mark PARENT AND SUB GROUPS METHODS
//==========================================================================================================================================

-(NSMutableArray *)fetchChildChannelsWithParentKey:(NSNumber *)parentGroupKey
{
    ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
    return [channelDB fetchChildChannels:parentGroupKey];
}

-(void)addChildKeyList:(NSMutableArray *)childKeyList andParentKey:(NSNumber *)parentKey withCompletion:(void(^)(id json, NSError *error))completion
{
    ALSLog(ALLoggerSeverityInfo, @"ADD_CHILD :: PARENT_KEY : %@ && CHILD_KEYs : %@",parentKey,childKeyList.description);
    if(parentKey)
    {
        [ALChannelClientService addChildKeyList:childKeyList andParentKey:parentKey withCompletion:^(id json, NSError *error) {
            
            if(!error)
            {
                ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
                for(NSNumber *childKey in childKeyList)
                {
                    [channelDB updateChannelParentKey:childKey andWithParentKey:parentKey isAdding:YES];
                }
            }
            completion(json, error);
            
        }];
    }
}

-(void)removeChildKeyList:(NSMutableArray *)childKeyList andParentKey:(NSNumber *)parentKey withCompletion:(void(^)(id json, NSError *error))completion
{
    ALSLog(ALLoggerSeverityInfo, @"REMOVE_CHILD :: PARENT_KEY : %@ && CHILD_KEYs : %@",parentKey,childKeyList.description);
    if(parentKey)
    {
        [ALChannelClientService removeChildKeyList:childKeyList andParentKey:parentKey withCompletion:^(id json, NSError *error) {
            
            if(!error)
            {
                ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
                for(NSNumber *childKey in childKeyList)
                {
                    [channelDB updateChannelParentKey:childKey andWithParentKey:parentKey isAdding:NO];
                }
            }
            completion(json, error);
            
        }];
    }
}

//=================================================
#pragma mark ADD/REMOVING VIA CLIENT KEYS
//=================================================

-(void)addClientChildKeyList:(NSMutableArray *)clientChildKeyList andParentKey:(NSString *)clientParentKey
              withCompletion:(void(^)(id json, NSError *error))completion
{
    ALSLog(ALLoggerSeverityInfo, @"ADD_CHILD :: PARENT_KEY : %@ && CHILD_KEYs (VIA_CLIENT) : %@",clientParentKey,clientChildKeyList.description);
    if(clientParentKey)
    {
        [ALChannelClientService addClientChildKeyList:clientChildKeyList andClientParentKey:clientParentKey withCompletion:^(id json, NSError *error) {
            
            if(!error)
            {
                ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
                for(NSString *childKey in clientChildKeyList)
                {
                    [channelDB updateClientChannelParentKey:childKey andWithClientParentKey:clientParentKey isAdding:YES];
                }
            }
            completion(json, error);
            
        }];
    }
}

-(void)removeClientChildKeyList:(NSMutableArray *)clientChildKeyList andParentKey:(NSString *)clientParentKey
                 withCompletion:(void(^)(id json, NSError *error))completion
{
    ALSLog(ALLoggerSeverityInfo, @"REMOVE_CHILD :: PARENT_KEY : %@ && CHILD_KEYs (VIA_CLIENT) : %@",clientParentKey,clientChildKeyList.description);
    if(clientParentKey)
    {
        [ALChannelClientService removeClientChildKeyList:clientChildKeyList andClientParentKey:clientParentKey withCompletion:^(id json, NSError *error) {
            
            if(!error)
            {
                ALChannelDBService * channelDB = [[ALChannelDBService alloc] init];
                for(NSString *childKey in clientChildKeyList)
                {
                    [channelDB updateClientChannelParentKey:childKey andWithClientParentKey:clientParentKey isAdding:NO];
                }
            }
            completion(json, error);
            
        }];
    }
}


//==========================================================================================================================================
#pragma mark CHANNEL API
//==========================================================================================================================================

//===========================================================================================================================
#pragma mark CREATE CHANNEL
//===========================================================================================================================

-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink
      withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion
{
    
    /* GROUP META DATA DICTIONARY
     
     NSMutableDictionary *metaData = [self getChannelMetaData];
     
     NOTE : IF GROUP META DATA REQUIRE THEN REPLACE nil BY metaData
     */
    
    [self createChannel:channelName orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:PUBLIC
            andMetaData:nil withCompletion:^(ALChannel *alChannel, NSError *error) {
                
                completion(alChannel, error);
            }];
}

-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion
{
    
    [self createChannel:channelName orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:nil withCompletion:^(ALChannel *alChannel, NSError *error) {
        completion(alChannel, error);
    }];
    
    
}


-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData adminUser:(NSString *)adminUserId withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion
{
    if(channelName != nil)
    {
        [self createChannel:channelName orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:adminUserId withGroupUsers:nil   withCompletion:^(ALChannel *alChannel, NSError *error) {
            completion(alChannel, error);
        }];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"ERROR : CHANNEL NAME MISSING");
        return;
    }
}


-(void)createChannel:(NSString *)channelName orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData adminUser:(NSString *)adminUserId withGroupUsers : (NSMutableArray*) groupRoleUsers withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion
{
    if(channelName != nil)
    {
        [ALChannelClientService createChannel:channelName andParentChannelKey:nil orClientChannelKey:(NSString *)clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:(short)type
                                  andMetaData:metaData adminUser:adminUserId withGroupUsers:groupRoleUsers withCompletion:^(NSError *error, ALChannelCreateResponse *response) {
                                      
                                      if(!error)
                                      {
                                          response.alChannel.adminKey = [ALUserDefaultsHandler getUserId];
                                          ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                          [channelDBService createChannel:response.alChannel];
                                          completion(response.alChannel, error);
                                      }
                                      else
                                      {
                                          ALSLog(ALLoggerSeverityError, @"ERROR_IN_CHANNEL_CREATING :: %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"ERROR : CHANNEL NAME MISSING");
        return;
    }
}


-(void)createBroadcastChannelWithMembersList:(NSMutableArray *)memberArray
                                 andMetaData:(NSMutableDictionary *)metaData
                              withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion {
    
    if (memberArray.count)
    {
        NSMutableArray * nameArray = [NSMutableArray new];
        ALContactService *cnService = [ALContactService new];
        
        for (NSString *userId in memberArray)
        {
            ALContact *alContact = [cnService loadContactByKey:@"userId" value:userId];
            [nameArray addObject:[alContact getDisplayName]];
        }
        NSString *broadcastName = @"";
        if (nameArray.count > 10)
        {
            NSArray *subArray = [nameArray subarrayWithRange:NSMakeRange(0, 10)];
            broadcastName = [subArray componentsJoinedByString:@","];
        }
        else
        {
            broadcastName = [nameArray componentsJoinedByString:@","];
        }
        
        [self createChannel:broadcastName orClientChannelKey:nil andMembersList:memberArray
               andImageLink:nil
                channelType:BROADCAST
                andMetaData:metaData
             withCompletion:^(ALChannel *alChannel, NSError *error) {
                 completion(alChannel, error);
             }];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"EMPTY_BROADCAST_MEMBER_LIST");
        NSError *failError = [NSError errorWithDomain:@"EMPTY BROADCAST MEMBER LIST" code:0 userInfo:nil];
        completion(nil, failError);
    }
}

-(NSMutableDictionary *)getChannelMetaData
{
    NSMutableDictionary *grpMetaData = [NSMutableDictionary new];
    
    [grpMetaData setObject:@":adminName created group" forKey:AL_CREATE_GROUP_MESSAGE];
    [grpMetaData setObject:@":userName removed" forKey:AL_REMOVE_MEMBER_MESSAGE];
    [grpMetaData setObject:@":userName added" forKey:AL_ADD_MEMBER_MESSAGE];
    [grpMetaData setObject:@":userName joined" forKey:AL_JOIN_MEMBER_MESSAGE];
    [grpMetaData setObject:@"Group renamed to :groupName" forKey:AL_GROUP_NAME_CHANGE_MESSAGE];
    [grpMetaData setObject:@":groupName icon changed" forKey:AL_GROUP_ICON_CHANGE_MESSAGE];
    [grpMetaData setObject:@":userName left" forKey:AL_GROUP_LEFT_MESSAGE];
    [grpMetaData setObject:@":groupName deleted" forKey:AL_DELETED_GROUP_MESSAGE];
    [grpMetaData setObject:@(NO) forKey:@"HIDE"];
    
    return grpMetaData;
}

/************************************
 #pragma mark : SUB GROUP CREATION
 *************************************/
-(void)createChannel:(NSString *)channelName andParentChannelKey:(NSNumber *)parentChannelKey orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion
{
    
    [self createChannel:channelName andParentChannelKey:parentChannelKey orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:nil withCompletion:^(ALChannel *alChannel, NSError *error) {
        
        completion(alChannel, error);
    }];
    
}


-(void)createChannel:(NSString *)channelName andParentChannelKey:(NSNumber *)parentChannelKey orClientChannelKey:(NSString *)clientChannelKey
      andMembersList:(NSMutableArray *)memberArray andImageLink:(NSString *)imageLink channelType:(short)type
         andMetaData:(NSMutableDictionary *)metaData  adminUser:(NSString *)adminUserId withCompletion:(void(^)(ALChannel *alChannel, NSError *error))completion
{
    if(channelName != nil)
    {
        [ALChannelClientService createChannel:channelName andParentChannelKey:parentChannelKey orClientChannelKey:clientChannelKey
                               andMembersList:memberArray andImageLink:imageLink channelType:(short)type
                                  andMetaData:metaData adminUser:adminUserId withCompletion:^(NSError *error, ALChannelCreateResponse *response) {
                                      
                                      if(!error)
                                      {
                                          response.alChannel.adminKey = [ALUserDefaultsHandler getUserId];
                                          ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                          [channelDBService createChannel:response.alChannel];
                                          completion(response.alChannel, error);
                                      }
                                      else
                                      {
                                          ALSLog(ALLoggerSeverityError, @"ERROR_IN_CHANNEL_CREATING :: %@",error);
                                          completion(nil, error);
                                      }
                                  }];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"ERROR : CHANNEL NAME MISSING");
        return;
    }
}

//===========================================================================================================================
#pragma mark ADD NEW MEMBER TO CHANNEL
//===========================================================================================================================

-(void)addMemberToChannel:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey
           withCompletion:(void(^)(NSError *error,ALAPIResponse *response))completion
{
    if((channelKey != nil || clientChannelKey != nil) && userId != nil)
    {
        [ALChannelClientService addMemberToChannel:userId orClientChannelKey:clientChannelKey
                                     andChannelKey:channelKey withCompletion:^(NSError *error, ALAPIResponse *response) {
                                         
                                         if([response.status isEqualToString:@"success"])
                                         {
                                             ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                             if(clientChannelKey != nil)
                                             {
                                                 ALChannel *alChannel = [channelDBService loadChannelByClientChannelKey:clientChannelKey];
                                                 [channelDBService addMemberToChannel:userId andChannelKey:alChannel.key];
                                             }
                                             else
                                             {
                                                 [channelDBService addMemberToChannel:userId andChannelKey:channelKey];
                                             }
                                         }
                                         completion(error,response);
                                     }];
    }
}

//===========================================================================================================================
#pragma mark REMOVE MEMBER FROM CHANNEL
//===========================================================================================================================

-(void)removeMemberFromChannel:(NSString *)userId andChannelKey:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey
                withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion
{
    if((channelKey != nil || clientChannelKey != nil) && userId != nil)
    {
        [ALChannelClientService removeMemberFromChannel:userId orClientChannelKey:clientChannelKey
                                          andChannelKey:channelKey withCompletion:^(NSError *error, ALAPIResponse *response) {
                                              
                                              if([response.status isEqualToString:@"success"])
                                              {
                                                  ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                                  if(clientChannelKey != nil)
                                                  {
                                                      ALChannel *alChannel = [channelDBService loadChannelByClientChannelKey:clientChannelKey];
                                                      [channelDBService removeMemberFromChannel:userId andChannelKey:alChannel.key];
                                                  }
                                                  else
                                                  {
                                                      [channelDBService removeMemberFromChannel:userId andChannelKey:channelKey];
                                                  }
                                              }
                                              completion(error,response);
                                          }];
    }
}

//===========================================================================================================================
#pragma mark DELETE CHANNEL
//===========================================================================================================================

-(void)deleteChannel:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey
      withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion
{
    if(channelKey != nil || clientChannelKey != nil)
    {
        [ALChannelClientService deleteChannel:channelKey orClientChannelKey:clientChannelKey
                               withCompletion:^(NSError *error, ALAPIResponse *response) {
                                   
                                   if([response.status isEqualToString:@"success"])
                                   {
                                       ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                       if(clientChannelKey != nil)
                                       {
                                           ALChannel *alChannel = [channelDBService loadChannelByClientChannelKey:clientChannelKey];
                                           [channelDBService deleteChannel:alChannel.key];
                                       }
                                       else
                                       {
                                           [channelDBService deleteChannel:channelKey];
                                       }
                                   }
                                   completion(error, response);
                               }];
    }
}

-(BOOL)checkAdmin:(NSNumber *)channelKey
{
    ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
    ALChannel *channel = [channelDBService loadChannelByKey:channelKey];
    
    return [channel.adminKey isEqualToString:[ALUserDefaultsHandler getUserId]];
}

//===========================================================================================================================
#pragma mark LEAVE CHANNEL
//===========================================================================================================================

-(void)leaveChannel:(NSNumber *)channelKey andUserId:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey
     withCompletion:(void(^)(NSError *error))completion
{
    if((channelKey != nil || clientChannelKey != nil) && userId != nil)
    {
        [ALChannelClientService leaveChannel:channelKey orClientChannelKey:clientChannelKey
                                  withUserId:(NSString *)userId andCompletion:^(NSError *error, ALAPIResponse *response) {
                                      [self proccessLeaveResponse:channelKey andUserId:userId orClientChannelKey:clientChannelKey withResponse:response withError:error];
                                      completion(error);
                                  }];
    }
}

-(void) proccessLeaveResponse:(NSNumber *)channelKey andUserId:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey withResponse:(ALAPIResponse *) response  withError:(NSError*)error{
    
    if([response.status isEqualToString:@"success"])
    {
        ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
        if(clientChannelKey != nil)
        {
            ALChannel *alChannel = [channelDBService loadChannelByClientChannelKey:clientChannelKey];
            [channelDBService removeMemberFromChannel:userId andChannelKey:alChannel.key];
            [channelDBService setLeaveFlag:YES forChannel:alChannel.key];
        }
        else
        {
            [channelDBService removeMemberFromChannel:userId andChannelKey:channelKey];
            [channelDBService setLeaveFlag:YES forChannel:channelKey];
        }
        
    }
}

-(void)leaveChannelWithChannelKey:(NSNumber *)channelKey andUserId:(NSString *)userId orClientChannelKey:(NSString *)clientChannelKey
                   withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion
{
    if((channelKey != nil || clientChannelKey != nil) && userId != nil)
    {
        [ALChannelClientService leaveChannel:channelKey orClientChannelKey:clientChannelKey
                                  withUserId:(NSString *)userId andCompletion:^(NSError *error, ALAPIResponse *response) {
                                      [self proccessLeaveResponse:channelKey andUserId:userId orClientChannelKey:clientChannelKey withResponse:response withError:error];
                                      completion(error,response);
                                  }];
    }
    
}
    

//===========================================================================================================================
#pragma mark UPDATE CHANNEL (FROM DEVICE SIDE)
//===========================================================================================================================

-(void)addMultipleUsersToChannel:(NSMutableArray* )channelKeys channelUsers:(NSMutableArray *)channelUsers andCompletion:(void(^)(NSError * error))completion
{
    if(channelKeys != nil && channelUsers != nil) {
        [ALChannelClientService addMultipleUsersToChannel:channelKeys channelUsers:channelUsers andCompletion:^(NSError *error, ALAPIResponse *response) {
            if([response.status isEqualToString:@"success"])
            {
                ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                for(int i=0;i<[channelUsers count];i++) {
                    [channelDBService addMemberToChannel:channelUsers[i] andChannelKey:channelKeys.firstObject];
                }
            }
            completion(error);
        }];
    }
}

-(void)updateChannel:(NSNumber *)channelKey andNewName:(NSString *)newName andImageURL:(NSString *)imageURL orClientChannelKey:(NSString *)clientChannelKey
  isUpdatingMetaData:(BOOL)flag metadata:(NSMutableDictionary *)metaData orChildKeys:(NSMutableArray *)childKeysList orChannelUsers:(NSMutableArray *)channelUsers withCompletion:(void(^)(NSError *error))completion
{
    if(channelKey != nil || clientChannelKey != nil)
    {
        [ALChannelClientService updateChannel:channelKey orClientChannelKey:clientChannelKey andNewName:newName andImageURL:imageURL metadata:metaData orChildKeys:childKeysList  orChannelUsers:(NSMutableArray *)channelUsers andCompletion:^(NSError *error, ALAPIResponse *response) {
            
            [self proccessUpdateChannelResponse:channelKey andNewName:newName andImageURL:imageURL orClientChannelKey:clientChannelKey isUpdatingMetaData:flag metadata:metaData orChildKeys:childKeysList orChannelUsers:channelUsers withResponse:response];
            completion(error);
        }];
    }
}

-(void)updateChannelWithChannelKey:(NSNumber *)channelKey andNewName:(NSString *)newName andImageURL:(NSString *)imageURL orClientChannelKey:(NSString *)clientChannelKey
  isUpdatingMetaData:(BOOL)flag metadata:(NSMutableDictionary *)metaData orChildKeys:(NSMutableArray *)childKeysList orChannelUsers:(NSMutableArray *)channelUsers withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion
{
    if(channelKey != nil || clientChannelKey != nil)
    {
        [ALChannelClientService updateChannel:channelKey orClientChannelKey:clientChannelKey andNewName:newName andImageURL:imageURL metadata:metaData orChildKeys:childKeysList  orChannelUsers:(NSMutableArray *)channelUsers andCompletion:^(NSError *error, ALAPIResponse *response) {
            
            [self proccessUpdateChannelResponse:channelKey andNewName:newName andImageURL:imageURL orClientChannelKey:clientChannelKey isUpdatingMetaData:flag metadata:metaData orChildKeys:childKeysList orChannelUsers:channelUsers withResponse:response];
            completion(error,response);
        }];
    }
}

-(void)proccessUpdateChannelResponse:(NSNumber *)channelKey andNewName:(NSString *)newName andImageURL:(NSString *)imageURL orClientChannelKey:(NSString *)clientChannelKey isUpdatingMetaData:(BOOL)flag metadata:(NSMutableDictionary *)metaData orChildKeys:(NSMutableArray *)childKeysList orChannelUsers:(NSMutableArray *)channelUsers withResponse :(ALAPIResponse *) response{
    
    if([response.status isEqualToString:@"success"])
    {
        ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
        if(clientChannelKey != nil)
        {
            ALChannel *alChannel = [channelDBService loadChannelByClientChannelKey:clientChannelKey];
            [channelDBService updateChannel:alChannel.key andNewName:newName orImageURL:imageURL orChildKeys:childKeysList isUpdatingMetaData:flag orChannelUsers:channelUsers];
        }
        else
        {
            ALChannel *alChannel = [channelDBService loadChannelByKey:channelKey];
            [channelDBService updateChannel:alChannel.key andNewName:newName orImageURL:imageURL orChildKeys:childKeysList isUpdatingMetaData:flag orChannelUsers:channelUsers];
        }
        
    }
}


-(void)updateChannelMetaData:(NSNumber *)channelKey
          orClientChannelKey:(NSString *)clientChannelKey
                    metadata:(NSMutableDictionary *)metaData
              withCompletion:(void(^)(NSError *error))completion{
    
    if(channelKey != nil || clientChannelKey != nil){
        [ALChannelClientService updateChannelMetaData:channelKey orClientChannelKey:clientChannelKey metadata:metaData andCompletion:^(NSError *error, ALAPIResponse *response){
            if([response.status isEqualToString:@"success"]){
                ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                if(clientChannelKey != nil){
                    ALChannel *alChannel = [channelDBService loadChannelByClientChannelKey:clientChannelKey];
                    [channelDBService updateChannelMetaData:alChannel.key metaData:metaData];
                }
                else if(channelKey !=nil){
                    [channelDBService updateChannelMetaData:channelKey metaData:metaData];
                }
            }
            completion(error);
        }];
    }
}

//===========================================================================================================================
#pragma mark CHANNEL SYNCHRONIZATION
//===========================================================================================================================
-(void)syncCallForChannel
{
    [self syncCallForChannelWithDelegate:nil];
}

-(void)syncCallForChannelWithDelegate:(id<ApplozicUpdatesDelegate>)delegate{

    NSNumber *updateAt = [ALUserDefaultsHandler getLastSyncChannelTime];

    [ALChannelClientService syncCallForChannel:updateAt andCompletion:^(NSError *error, ALChannelSyncResponse *response) {

        if([response.status isEqualToString:@"success"])
        {
            ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
            [channelDBService createChannelsAndUpdateInfo:response.alChannelArray withDelegate:delegate];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_CHANNEL_NAME" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_CHANNEL_METADATA" object:nil];
        }
        if(!error){
            [ALUserDefaultsHandler setLastSyncChannelTime:response.generatedAt];
        }
    }];

}


//===========================================================================================================================
#pragma mark MARK READ FOR GROUP
//===========================================================================================================================

-(void)markConversationAsRead:(NSNumber *)channelKey withCompletion:(void (^)(NSString *, NSError *))completion
{
    [ALChannelService setUnreadCountZeroForGroupID:channelKey];
    
    ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
    NSUInteger count = [channelDBService markConversationAsRead:channelKey];
    ALSLog(ALLoggerSeverityInfo, @"Found %ld messages for marking as read.", (unsigned long)count);
    
    if(count == 0){
        return;
    }
    
    ALChannelClientService * clientService = [[ALChannelClientService alloc] init];
    [clientService markConversationAsRead:channelKey withCompletion:^(NSString *response, NSError * error) {
        completion(response,error);
    }];
    
}

+(void)setUnreadCountZeroForGroupID:(NSNumber *)channelKey
{
    ALChannelDBService *channelDBService = [ALChannelDBService new];
    [channelDBService  updateUnreadCountChannel:channelKey unreadCount:[NSNumber numberWithInt:0]];
    
    ALChannel * channel = [channelDBService loadChannelByKey:channelKey];
    channel.unreadCount = [NSNumber numberWithInt:0];
}

-(void)muteChannel:(ALMuteRequest *)muteRequest withCompletion:(void(^)(ALAPIResponse * response, NSError *error))completion
{
    ALChannelClientService * clientService = [[ALChannelClientService alloc] init];
    [clientService muteChannel:muteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {
        ALChannelDBService * dbService = [ALChannelDBService new];
        [dbService updateMuteAfterTime:muteRequest.notificationAfterTime andChnnelKey:muteRequest.id];
        completion(response,error);
        
    }];
}



-(void)getChannelInfoByIdsOrClientIds:(NSMutableArray*)channelIds
                   orClinetChannelIds:(NSMutableArray*) clientChannelIds
                       withCompletion:(void(^)(NSMutableArray* channelInfoList, NSError *error))completion
{
    
    
    ALChannelClientService * clientService = [[ALChannelClientService alloc] init];
    
    [clientService getChannelInfoByIdsOrClientIds:channelIds orClinetChannelIds:clientChannelIds
     
                                   withCompletion:^( NSMutableArray *channelInfoList, NSError *error)
     {
         
         ALChannelDBService * dbService = [ALChannelDBService new];
         for(ALChannel * channel in channelInfoList )
         {
             [dbService createChannel:channel];
         }
         completion(channelInfoList,error);
     }];
    
}

-(void)getChannelListForCategory:(NSString*)category
                  withCompletion:(void(^)(NSMutableArray * channelInfoList, NSError * error))completion

{
    ALChannelClientService * clientService = [[ALChannelClientService alloc] init];
    
    [clientService getChannelListForCategory:category                           withCompletion:^( NSMutableArray *channelInfoList, NSError *error)
     {
         
         ALChannelDBService * dbService = [ALChannelDBService new];
         for(ALChannel * channel in channelInfoList )
         {
             [dbService createChannel:channel];
         }
         completion(channelInfoList,error);
     }];
}

-(void)getAllChannelsForApplications:(NSNumber*)endTime withCompletion:(void(^)(NSMutableArray * channelInfoList, NSError * error))completion{
    
    
    ALChannelClientService * clientService = [[ALChannelClientService alloc] init];
    
    [clientService getAllChannelsForApplications:endTime withCompletion:^(NSMutableArray *channelInfoList, NSError *error) {
        
        ALChannelDBService * dbService = [ALChannelDBService new];
        for(ALChannel * channel in channelInfoList )
        {
            [dbService createChannel:channel];
        }
        completion(channelInfoList,error);
    }];
}


+(void) addMemberToContactGroupOfType:(NSString*) contactsGroupId withMembers: (NSMutableArray *)membersArray withGroupType :(short) groupType withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion
{
    
    [ALChannelClientService addMemberToContactGroupOfType:contactsGroupId withMembers:membersArray withGroupType:groupType withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        completion(response, error);
        
    }];
    
}


+(void) addMemberToContactGroup:(NSString*) contactsGroupId withMembers:(NSMutableArray *)membersArray  withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion
{
    [ALChannelClientService addMemberToContactGroup:contactsGroupId withMembers:membersArray withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        completion(response, error);
    }];
    
}


+(void) getMembersFromContactGroupOfType:(NSString *)contactsGroupId  withGroupType :(short) groupType withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion
{
    
    if(contactsGroupId){
        [ALChannelClientService getMembersFromContactGroupOfType: contactsGroupId  withGroupType:groupType withCompletion:^(NSError *error, ALChannel *channel) {
            
            if(!error && channel)
            {
                ALChannelDBService * dbService = [ALChannelDBService new];
                [dbService createChannel:channel];
                completion(error,channel);
            }else{
                completion(error,nil);
            }
        }];
    }
}


-(NSMutableArray *)getListOfAllUsersInChannelByNameForContactsGroup:(NSString *)channelName{
    
    if(channelName == nil){
        return nil;
    }
    ALChannelDBService * dbService = [ALChannelDBService new];
    return [dbService getListOfAllUsersInChannelByNameForContactsGroup:channelName];
}


+(void) removeMemberFromContactGroup:(NSString*) contactsGroupId withUserId :(NSString*) userId  withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion
{
    
    [ALChannelClientService removeMemberFromContactGroup:contactsGroupId withUserId:userId withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        completion(response, error);
        
    }];
    
}


+(void) removeMemberFromContactGroupOfType:(NSString*) contactsGroupId  withGroupType:(short) groupType withUserId :(NSString*) userId  withCompletion:(void(^)(ALAPIResponse * response, NSError * error))completion
{
    
    [ALChannelClientService removeMemberFromContactGroupOfType:contactsGroupId withGroupType:groupType withUserId:userId withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        if(!error && response && [response.status isEqualToString:@"success"])
        {
            ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
            
            DB_CHANNEL *dbChannel = [channelDBService getContactsGroupChannelByName:contactsGroupId];
            
            if(dbChannel != nil){
                [channelDBService removeMemberFromChannel:userId andChannelKey:dbChannel.channelKey];
            }
            
        }
        completion(response, error);
        
    }];
    
}

+(void)getMembersIdsForContactGroups:(NSArray*)contactGroupIds withCompletion:(void(^)(NSError *error, NSArray *membersArray)) completion
{
    NSMutableArray * memberUserIds = [NSMutableArray new];
    
    if(contactGroupIds )
    {
        ALChannelClientService* channelService = [ALChannelClientService new];
        
        [channelService getMultipleContactGroup:contactGroupIds withCompletion:^(NSError *error, NSArray *channels) {
            
            if(channels)
            {
                for (ALChannel * channel in channels)
                {
                    ALChannelDBService * dbService = [ALChannelDBService new];
                    [dbService createChannel:channel];
                    [memberUserIds addObjectsFromArray:channel.membersId];
                }
                
                
                completion(nil,memberUserIds);
            }
            else
            {
                completion(error,nil);
            }
        }];
        
    }
    
}

-(void)getChannelInformationByResponse:(NSNumber *)channelKey orClientChannelKey:(NSString *)clientChannelKey withCompletion:(void (^)(NSError *error,ALChannel *alChannel3,AlChannelFeedResponse *channelResponse)) completion
{
    ALChannel *alChannel1;
    if (clientChannelKey) {
        alChannel1 = [self fetchChannelWithClientChannelKey:clientChannelKey];
    }else{
        alChannel1 = [self getChannelByKey:channelKey];
    }
    
    if(alChannel1)
    {
        completion (nil,alChannel1,nil);
    }
    else
    {
        
        [ALChannelClientService getChannelInformationResponse:channelKey orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, AlChannelFeedResponse *response) {
            
            if(!error && [response.status isEqualToString: RESPONSE_SUCCESS] )
            {
                ALChannelDBService *dbService = [[ALChannelDBService alloc] init];
                [dbService createChannel:response.alChannel];
                completion (nil,response.alChannel,nil);
            }else{
                completion (error,nil,response);
            }
        }];
        
    }
}

- (NSDictionary *)metadataToTurnOffActionMessagesNotifications {
    return [self metadataToTurnOffActionMessagesNotificationsAndhideMessages:NO];
}

- (NSDictionary *)metadataToHideActionMessagesAndTurnOffNotifications {
    return [self metadataToTurnOffActionMessagesNotificationsAndhideMessages:YES];
}

-(NSDictionary *)metadataToTurnOffActionMessagesNotificationsAndhideMessages:(BOOL)hideMessages {

    // In case of just turning off the notifications, only 'Alert' key needs to be false and empty string for action messages.

    NSDictionary *basicMetadata = @{@"CREATE_GROUP_MESSAGE":@"",
                                    @"REMOVE_MEMBER_MESSAGE":@"",
                                    @"ADD_MEMBER_MESSAGE":@"",
                                    @"JOIN_MEMBER_MESSAGE":@"",
                                    @"GROUP_NAME_CHANGE_MESSAGE":@"",
                                    @"GROUP_ICON_CHANGE_MESSAGE":@"",
                                    @"GROUP_LEFT_MESSAGE":@"",
                                    @"DELETED_GROUP_MESSAGE":@"",
                                    @"Alert":@"false"
                                    };
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:basicMetadata];
    if(!hideMessages) {
        return metadata;
    }
    metadata[@"hide"] = @"true";
    return metadata;
}

-(void)createChannelWithChannelInfo:(ALChannelInfo*)channelInfo withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion {
    
    if(!channelInfo.type){
        channelInfo.type = PUBLIC;
    }
    
    if(!channelInfo.groupMemberList){
        NSError *memberError = [NSError errorWithDomain:@"ALChannelService"
                                                    code:2
                                                userInfo:@{NSLocalizedDescriptionKey : @"Nil in member list"}];
        
        completion(nil,memberError);
        return;
    }
    
    [ALChannelClientService createChannel:channelInfo.groupName andParentChannelKey:nil orClientChannelKey:channelInfo.clientGroupId andMembersList:channelInfo.groupMemberList andImageLink:channelInfo.imageUrl channelType:channelInfo.type
                              andMetaData:channelInfo.metadata adminUser:channelInfo.admin withGroupUsers:channelInfo.groupRoleUsers withCompletion:^(NSError *error, ALChannelCreateResponse *response) {
                                  
                                  if(!error)
                                  {
                                      response.alChannel.adminKey = [ALUserDefaultsHandler getUserId];
                                      ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                      [channelDBService createChannel:response.alChannel];
                                      completion(response, error);
                                  }
                                  else
                                  {
                                      ALSLog(ALLoggerSeverityError, @"ERROR_IN_CHANNEL_CREATING :: %@",error);
                                      completion(nil, error);
                                  }
                              }];
    
}


-(void)updateConversationReadWithGroupId:(NSNumber *)channelKey withDelegate: (id<ApplozicUpdatesDelegate>)delegate{
    
    [ALChannelService setUnreadCountZeroForGroupID:channelKey];
    if(delegate){
        [delegate conversationReadByCurrentUser:nil withGroupId:channelKey];
    }
    NSDictionary *dict = @{@"channelKey":channelKey};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_unread_count" object:dict];
}

@end
