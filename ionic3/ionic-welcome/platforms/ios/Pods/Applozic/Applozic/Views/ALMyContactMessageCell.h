//
//  MyContactMessageCell.h
//  Applozic
//
//  Created by apple on 06/06/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ALMessage.h"
#import "ALContactMessageBaseCell.h"

@interface ALMyContactMessageCell : ALContactMessageBaseCell

-(instancetype)populateCell:(ALMessage *) alMessage viewSize:(CGSize)viewSize;

@end
