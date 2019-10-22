
//  ALAPIResponse.m
//  Applozic
//
//  Created by devashish on 19/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"

@implementation ALAPIResponse

-(id)initWithJSONString:(NSString *)JSONString
{
    [self parseMessage:JSONString];
    return self;
}

-(void)parseMessage:(id) json;
{
    self.status = [self getStringFromJsonValue:json[@"status"]];
    self.generatedAt = [self getNSNumberFromJsonValue:json[@"generatedAt"]];
    self.response =  [json valueForKey:@"response"];
    self.actualresponse = json;
    ALSLog(ALLoggerSeverityInfo, @"self.generatedAt : %@",self.generatedAt);
    ALSLog(ALLoggerSeverityInfo, @"self.status : %@",self.status);

}


@end
