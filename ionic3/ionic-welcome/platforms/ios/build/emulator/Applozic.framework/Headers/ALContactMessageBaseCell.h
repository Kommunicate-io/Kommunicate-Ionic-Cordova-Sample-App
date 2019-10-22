//
//  ALContactMessageBaseCell.h
//  Applozic
//
//  Created by Sunil on 26/06/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//


static int  const BUBBLE_PADDING_X = 13;
static int  const BUBBLE_PADDING_X_OUTBOX = 60;
static int  const BUBBLE_PADDING_WIDTH = 120;
static int  const BUBBLE_PADDING_HEIGHT = 190;
static int  const BUBBLE_PADDING_HEIGHT_OUTBOX = 180;

static int  const DATE_PADDING_X = 20;
static int  const DATE_PADDING_WIDTH = 20;
static int  const DATE_HEIGHT = 20;
static int  const DATE_WIDTH = 80;

static int  const MSG_STATUS_WIDTH = 20;
static int  const MSG_STATUS_HEIGHT = 20;

static int  const CNT_PROFILE_X = 10;
static int  const CNT_PROFILE_Y = 10;
static int  const CNT_PROFILE_HEIGHT = 50;
static int  const CNT_PROFILE_WIDTH = 50;
static int  const CNT_PERSON_X = 10;
static int  const CNT_PERSON_HEIGHT = 20;

static int  const USER_CNT_Y = 5;
static int  const USER_CNT_HEIGHT = 50;

static int  const EMAIL_Y = 5;
static int  const EMAIL_HEIGHT = 50;

static int  const BUTTON_Y = 50;
static int  const BUTTON_WIDTH = 20;
static int  const BUTTON_HEIGHT = 40;

static int  const CHANNEL_PADDING_X = 5;
static int  const CHANNEL_PADDING_Y = 2;
static int  const CHANNEL_PADDING_WIDTH = 5;
static int  const CHANNEL_HEIGHT = 20;
static int  const CHANNEL_PADDING_HEIGHT = 20;
static int  const AL_CONTACT_PADDING_Y = 20;
static int  const AL_CONTACT_ADD_BUTTON_HEIGHT_PADDING = 230;

#import <UIKit/UIKit.h>
#import "ALMediaBaseCell.h"
#import "ALVCardClass.h"
#import "ALMessage.h"

@interface ALContactMessageBaseCell : ALMediaBaseCell

@property (nonatomic, strong) UIImageView * contactProfileImage;
@property (nonatomic, strong) UILabel * userContact;
@property (nonatomic, strong) UILabel * contactPerson;
@property (nonatomic, strong) UILabel * emailId;
@property (nonatomic, strong) UIButton * addContactButton;
@property (nonatomic) CGFloat msgFrameHeight;
@property (nonatomic, strong) ALVCardClass *vCardClass;

-(instancetype)populateCell:(ALMessage *) alMessage viewSize:(CGSize)viewSize;

@end


