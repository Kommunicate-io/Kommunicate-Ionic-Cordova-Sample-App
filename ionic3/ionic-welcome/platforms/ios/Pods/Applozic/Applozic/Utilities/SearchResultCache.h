//
//  SearchResultCache.h
//  Applozic
//
//  Created by Shivam Pokhriyal on 02/07/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALChannel.h"
#import "ALContact.h"
#import "ALUserDetail.h"

@interface SearchResultCache : NSObject

+ (SearchResultCache *) shared;

-(void) saveChannels: (NSMutableArray<ALChannel *> *) channels;
-(void) saveUserDetails: (NSMutableArray<ALUserDetail *> *) userDetails;

-(ALChannel *) getChannelWithId: (NSNumber *) key;
-(ALContact *) getContactWithId: (NSString *) key;

@end
