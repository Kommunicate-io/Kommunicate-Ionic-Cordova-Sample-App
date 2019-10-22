//
//  ALConversationService.m
//  Applozic
//
//  Created by Devashish on 27/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALConversationService.h"
#import "ALConversationProxy.h"
#import "ALConversationDBService.h"
#import "DB_ConversationProxy.h"
#import "ALConversationClientService.h"

@implementation ALConversationService

-(ALConversationProxy *) getConversationByKey:(NSNumber*)conversationKey{
    
    ALConversationDBService * conversationDBService =  [[ALConversationDBService alloc]init];
    DB_ConversationProxy * dbConversation =    [conversationDBService getConversationProxyByKey:conversationKey];
    if(dbConversation == nil){
        return nil;
    }
    return [self convertAlConversationProxy:dbConversation];;
}

-(void)addConversations:(NSMutableArray *)conversations{
    ALConversationDBService * conversationDBService =  [[ALConversationDBService alloc]init];
    [conversationDBService insertConversationProxy:conversations];
}

-(void)addTopicDetails:(NSMutableArray*)conversations{

    ALConversationDBService * conversationDBService =  [[ALConversationDBService alloc]init];
    [conversationDBService insertConversationProxyTopicDetails:conversations];
}

-(ALConversationProxy *) convertAlConversationProxy:(DB_ConversationProxy *) dbConversation{
    
    ALConversationProxy *alConversationProxy =  [[ALConversationProxy alloc]init];
    alConversationProxy.groupId=dbConversation.groupId;
    alConversationProxy.userId=dbConversation.userId;
    alConversationProxy.topicDetailJson=dbConversation.topicDetailJson;
    alConversationProxy.topicId=dbConversation.topicId;
    alConversationProxy.Id =dbConversation.iD;
    return alConversationProxy;
}

-(NSMutableArray*)getConversationProxyListForUserID:(NSString*)userId{
    
    ALConversationDBService * conversationDBService =  [[ALConversationDBService alloc]init];
    NSMutableArray * result = [[NSMutableArray alloc] init];
    NSArray * list = [conversationDBService getConversationProxyListFromDBForUserID:userId];
    if(!list.count)
    {
        return result;
    }
    for (DB_ConversationProxy* object in list) {
        ALConversationProxy * conversation = [[ALConversationProxy alloc] init];
        conversation = [self convertAlConversationProxy:object];
        [result addObject:conversation];
    }
    
    return result;
}

-(NSMutableArray*)getConversationProxyListForUserID:(NSString*)userId andTopicId:(NSString*)topicId{
    
    ALConversationDBService * conversationDBService =  [[ALConversationDBService alloc]init];
    NSMutableArray * result = [[NSMutableArray alloc] init];
    NSArray * list = [conversationDBService getConversationProxyListFromDBForUserID:userId andTopicId:topicId];
    if(!list.count)
    {
        return result;
    }
    for (DB_ConversationProxy* object in list) {
        ALConversationProxy * conversation = [[ALConversationProxy alloc] init];
        conversation = [self convertAlConversationProxy:object];
        [result addObject:conversation];
    }
    return result;
}

-(NSMutableArray*)getConversationProxyListForChannelKey:(NSNumber*)channelKey{
    ALConversationDBService * conversationDBService =  [[ALConversationDBService alloc]init];
   NSMutableArray * result = [[NSMutableArray alloc] init];
    NSArray * list = [conversationDBService getConversationProxyListFromDBWithChannelKey:channelKey];
    
    for (DB_ConversationProxy* object in list) {
        ALConversationProxy * conversation = [[ALConversationProxy alloc] init];
        conversation = [self convertAlConversationProxy:object];
        [result addObject:conversation];
    }
    
    return  result;

}

-(void)createConversation:(ALConversationProxy *)alConversationProxy withCompletion:(void(^)(NSError *error,ALConversationProxy * proxy ))completion{
    

    NSArray * conversationArray  = [[NSArray alloc] initWithArray:[self getConversationProxyListForUserID:alConversationProxy.userId andTopicId:alConversationProxy.topicId]];

    
    if (conversationArray.count != 0) {
        ALConversationProxy * conversationProxy = conversationArray[0];
        ALSLog(ALLoggerSeverityInfo, @"Conversation Proxy List Found In DB :%@",conversationProxy.topicDetailJson);
        completion(nil,conversationProxy);
    }
    else{
        
        [ALConversationClientService createConversation:alConversationProxy withCompletion:^(NSError *error, ALConversationCreateResponse *response) {
            
            if(!error){
                NSMutableArray * proxyArr = [[NSMutableArray alloc] initWithObjects:response.alConversationProxy, nil];
                [self addConversations:proxyArr];
            }
            else{
                ALSLog(ALLoggerSeverityError, @"ALConversationService : Error creatingConversation ");
            }
            completion(error,response.alConversationProxy);
        }];
    }

}


-(void)fetchTopicDetails:(NSNumber *)alConversationProxyID withCompletion:(void(^)(NSError *error,ALConversationProxy * alConversationProxy ))completion {

    ALConversationProxy *alConversationProxy = [self getConversationByKey:alConversationProxyID];

    if (alConversationProxy != nil){
        ALSLog(ALLoggerSeverityInfo, @"Conversation/Topic Alerady exists");
        completion(nil,alConversationProxy);
        return;
    }

    [ALConversationClientService fetchTopicDetails:alConversationProxyID andCompletion:^(NSError * error, ALAPIResponse * response) {
        
        if(!error){
           ALSLog(ALLoggerSeverityInfo, @"ALAPIResponse: FETCH TOPIC DEATIL  %@",response);

            ALConversationProxy * conversationProxy = [[ALConversationProxy alloc] initWithDictonary:response.response];
             NSMutableArray * proxyArray = [[NSMutableArray alloc] initWithObjects:conversationProxy, nil];
            [self addConversations:proxyArray];
            completion(nil,conversationProxy);
        }
        else{
            ALSLog(ALLoggerSeverityError, @"ALAPIResponse : Error FETCHING TOPIC DEATILS ");
            completion(error,nil);
        }
    }];
}
@end
