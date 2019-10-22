//
//  ALApplicationInfo.m
//  Applozic
//
//  Created by Mukesh Thawani on 05/06/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALApplicationInfo.h"
#import "ALUtilityClass.h"
#import "ALUserDefaultsHandler.h"
#import "ALConstant.h"

@implementation ALApplicationInfo


-(BOOL)isChatSuspended
{
    BOOL debugflag = [ALUtilityClass isThisDebugBuild];

    if(debugflag)
    {
        return NO;
    }
    if([ALUserDefaultsHandler getUserPricingPackage] == CLOSED
       || [ALUserDefaultsHandler getUserPricingPackage] == BETA
       || [ALUserDefaultsHandler getUserPricingPackage] == SUSPENDED)
    {
        return YES;
    }
    return NO;
}

-(BOOL)showPoweredByMessage
{
    BOOL debugflag = [ALUtilityClass isThisDebugBuild];
    if(debugflag) {
        return NO;
    }
    if([ALUserDefaultsHandler getUserPricingPackage] == STARTER) {
        return YES;
    }
    return NO;
}

@end
