//
//  ALSyncCallService.h
//  Applozic
//
//  Created by Applozic Inc on 12/14/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessage.h"
#import "ALUserDetail.h"
#import "ALRealTimeUpdate.h"

@interface ALSyncCallService : NSObject

-(void) updateMessageDeliveryReport:(NSString *)messageKey withStatus:(int)status;

-(void) updateDeliveryStatusForContact:(NSString *)contactId withStatus:(int)status;

-(void) syncCall: (ALMessage *) alMessage;

-(void) syncCall: (ALMessage *) alMessage withDelegate:(id<ApplozicUpdatesDelegate>)theDelegate;

-(void) updateConnectedStatus: (ALUserDetail *) alUserDetail;

-(void)updateTableAtConversationDeleteForContact:(NSString*)contactID
                                  ConversationID:(NSString *)conversationID
                                      ChannelKey:(NSNumber *)channelKey;
@end
