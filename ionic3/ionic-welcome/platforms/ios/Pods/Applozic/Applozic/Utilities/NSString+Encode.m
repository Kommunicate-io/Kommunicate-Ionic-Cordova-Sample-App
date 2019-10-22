//
//  NSString+Encode.m
//  Applozic
//
//  Created by Divjyot Singh on 21/04/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "NSString+Encode.h"

@implementation NSString (Encode)

-(NSString *)urlEncodeUsingNSUTF8StringEncoding {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}
@end
