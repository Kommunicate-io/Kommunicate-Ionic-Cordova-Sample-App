//
//  ALContactMessageCell.h
//  Applozic
//
//  Created by devashish on 12/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//
/*********************************************************************
 TABLE CELL CUSTOM CLASS : THIS CLASS IS FOR CONTACT MESSSAGE 
 i.e SHARE CONTACT FROM PHONE CONTACTS
 **********************************************************************/

#import <UIKit/UIKit.h>
#import "ALMessage.h"
#import "ALContactMessageBaseCell.h"

@interface ALContactMessageCell : ALContactMessageBaseCell

-(instancetype)populateCell:(ALMessage *) alMessage viewSize:(CGSize)viewSize;

@end
