//
//  ALInternalSettings.m
//  Applozic
//
//  Created by apple on 13/05/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALInternalSettings.h"

@implementation ALInternalSettings

+(void)setRegistrationStatusMessage:(NSString*)message{
    NSUserDefaults * userDefaults = ALInternalSettings.getUserDefaults;
    [userDefaults setValue:message forKey:REGISTRATION_STATUS_MESSAGE];
    [userDefaults synchronize];
}

+(NSString*)getRegistrationStatusMessage{

    NSUserDefaults * userDefaults = ALInternalSettings.getUserDefaults;
    NSString *pushRegistrationStatusMessage  =  [userDefaults valueForKey:REGISTRATION_STATUS_MESSAGE];
    return pushRegistrationStatusMessage  != nil ? pushRegistrationStatusMessage : AL_REGISTERED;
}

+(NSUserDefaults *)getUserDefaults{
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.com.applozic.share"];
}

@end
