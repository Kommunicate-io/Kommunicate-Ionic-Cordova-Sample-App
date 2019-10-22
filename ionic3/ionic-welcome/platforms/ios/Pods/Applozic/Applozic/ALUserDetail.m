//
//  ALUserDetail.m
//  Applozic
//
//  Created by devashish on 26/11/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALUserDetail.h"

@interface ALUserDetail ()

@end

@implementation ALUserDetail

- (id)initWithJSONString:(NSString *)JSONResponse {
    
    [self setUserDetails:JSONResponse];
    return self;
}


-(void)setUserDetails:(NSString *)JSONString
{
    self.userId = [JSONString valueForKey:@"userId"];
    
    self.connected = [[NSString stringWithFormat:@"%@",[JSONString valueForKey:@"connected"]] intValue];
    
    self.lastSeenAtTime = [JSONString valueForKey:@"lastSeenAtTime"];
    
    //self.lastSeenAtTime = [self getNSNumberFromJsonValue:[JSONString valueForKey:@"lastSeenAtTime"]];
    
    self.unreadCount = [JSONString valueForKey:@"unreadCount"];
    
    self.imageLink = [JSONString valueForKey:@"imageLink"];
    
    self.contactNumber = [JSONString valueForKey:@"phoneNumber"];
    
    self.userStatus = [JSONString valueForKey:@"statusMessage"];
    self.userTypeId = [JSONString valueForKey:@"userTypeId"];
    
    self.deletedAtTime = [JSONString valueForKey:@"deletedAtTime"];
    self.metadata = [JSONString valueForKey:@"metadata"];
    self.roleType = [JSONString valueForKey:@"roleType"];
    self.notificationAfterTime = [JSONString valueForKey:@"notificationAfterTime"];
    self.email = [JSONString valueForKey:@"email"];
}

-(void)userDetail
{
    
}

-(id)initWithDictonary:(NSDictionary *)messageDictonary{
    [self parseMessage:messageDictonary];
    return self;
}

-(void)parseMessage:(id) json;
{
    self.userId = [self getStringFromJsonValue:json[@"userId"]];
    self.connected = [self getBoolFromJsonValue:json[@"connected"]];
    self.lastSeenAtTime = [self getNSNumberFromJsonValue:json[@"lastSeenAtTime"]];
    self.displayName = [self getStringFromJsonValue:json[@"displayName"]];
    self.unreadCount = [self getNSNumberFromJsonValue:json[@"unreadCount"]];
    self.imageLink  = [self getStringFromJsonValue:json[@"imageLink"]];
    self.contactNumber = [self getStringFromJsonValue:json[@"phoneNumber"]];
    self.userStatus = [self getStringFromJsonValue:json[@"statusMessage"]];
    self.deletedAtTime = [self getNSNumberFromJsonValue:json[@"deletedAtTime"]];
    self.metadata = [[NSMutableDictionary  alloc] initWithDictionary:json[@"metadata"]];
    self.roleType = [self getNSNumberFromJsonValue:json[@"roleType"]];
    self.notificationAfterTime = [self getNSNumberFromJsonValue:json[@"notificationAfterTime"]];
    self.email = [self getStringFromJsonValue: json[@"email"]];

}

-(NSString *)getDisplayName
{
    return (self.displayName && ![self.displayName isEqualToString:@""]) ? self.displayName : self.userId;
}

-(void)parsingDictionaryFromJSON:(NSDictionary *)JSONDictionary
{
    self.userIdString = nil;
    NSString * tempString = @"";
    self.keyArray = [NSArray arrayWithArray:[JSONDictionary allKeys]];
    self.valueArray = [NSArray arrayWithArray:[JSONDictionary allValues]];
    
    for(NSString *str in self.keyArray)
    {
        tempString = [tempString stringByAppendingString:[NSString stringWithFormat:@"&userIds=%@",str]];
    }
    
    if(self.keyArray.count)
    {
        self.userIdString = [tempString substringFromIndex:1];
    }
}

-(BOOL)isNotificationMuted{
    
    long secsUtc1970 = [[NSNumber numberWithDouble:[[NSDate date]timeIntervalSince1970] ] longValue ]*1000L;
    return (_notificationAfterTime && [_notificationAfterTime longValue]> secsUtc1970);
}

@end
