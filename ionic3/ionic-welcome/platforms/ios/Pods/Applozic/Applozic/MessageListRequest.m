//
//  MessageListRequest.m
//  Applozic
//
//  Created by Devashish on 29/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "MessageListRequest.h"
#import "ALUserDefaultsHandler.h"
#import "NSString+Encode.h"


#define DEFAULT_PAGE_SIZE @"50";
#define DEFAULT_START_INDEX @"0"

@implementation MessageListRequest

-( NSString* )getParamString{
    
    NSString * paramString;
    
    if(!self.pageSize){
        self.pageSize = DEFAULT_PAGE_SIZE;
    }
    if(!self.startIndex){
        self.startIndex = DEFAULT_START_INDEX;
    }
    
    if(self.channelKey != nil)
    {
        paramString = [NSString stringWithFormat:@"groupId=%@&startIndex=%@&pageSize=%@",self.channelKey,self.startIndex,self.pageSize];
    }else{
        paramString = [NSString stringWithFormat:@"userId=%@&startIndex=%@&pageSize=%@",[self.userId urlEncodeUsingNSUTF8StringEncoding],self.startIndex,self.pageSize];
    }
    
    if(self.endTimeStamp!=nil){
        
        paramString = [paramString stringByAppendingFormat:@"&endTime=%@",self.endTimeStamp.stringValue];
    }
    
    if( self.isFirstCall )
    {
        self.startTimeStamp=[NSNumber numberWithInteger:1];
    }
    
    if(self.startTimeStamp != nil )
    {
         paramString = [paramString stringByAppendingFormat:@"&startTime=%@",self.startTimeStamp.stringValue];
    }
    
   
    
    if(self.conversationId){
        
        paramString = [paramString stringByAppendingFormat:@"&conversationId=%@",self.conversationId];
    }
    
    
    //If first time call add conversationRequire = true;
    
    if(![ALUserDefaultsHandler isServerCallDoneForMSGList:self.userId]){
        paramString = [paramString stringByAppendingString:@"&conversationReq=true"];
        ALSLog(ALLoggerSeverityInfo, @"adding conversationRequired true :theParamString :%@",paramString );
    }
    
    if(self.skipRead){
        paramString = [paramString stringByAppendingFormat:@"&skipRead=true"];
    }
    
    return paramString;
}

-(BOOL)isFirstCall{
    
    NSString * key = self.channelKey ? [self.channelKey stringValue]: self.userId;
    return (![ALUserDefaultsHandler isServerCallDoneForMSGList:key]);
}


@end
