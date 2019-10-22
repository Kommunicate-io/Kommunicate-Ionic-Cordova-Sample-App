//
//  ALContactMessageCell.m
//  Applozic
//
//  Created by devashish on 12/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

// Constants

#import "ALContactMessageCell.h"
#import "ALUtilityClass.h"
#import "UIImageView+WebCache.h"
#import "ALApplozicSettings.h"
#import "ALConstant.h"
#import "ALContact.h"
#import "ALColorUtility.h"
#import "ALContactDBService.h"
#import "ALMessageService.h"
#import "ALMessageInfoViewController.h"
#import "ALChatViewController.h"
#import "ALVCardClass.h"
#import "ALMessageClientService.h"

@interface ALContactMessageCell ()

@end

@implementation ALContactMessageCell
{
    NSURL *theUrl;
}
-(instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if(self)
    {

        self.addContactButton = [[UIButton alloc] init];
        [self.addContactButton setTitle: NSLocalizedStringWithDefaultValue(@"addContactButtonText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"ADD CONTACT", @"") forState:UIControlStateNormal];
        [self.addContactButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.addContactButton.titleLabel setFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:14]];
        [self.addContactButton addTarget:self action:@selector(addButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self.addContactButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.contentView addSubview:self.addContactButton];
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
            self.contactPerson.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }
    }
    return self;
}

-(instancetype)populateCell:(ALMessage *) alMessage viewSize:(CGSize)viewSize
{
    [super populateCell:alMessage viewSize:viewSize];

    [self.addContactButton setEnabled:NO];

    BOOL today = [[NSCalendar currentCalendar] isDateInToday:[NSDate dateWithTimeIntervalSince1970:[alMessage.createdAtTime doubleValue]/1000]];

    NSString * theDate = [NSString stringWithFormat:@"%@",[alMessage getCreatedAtTimeChat:today]];

    CGSize theDateSize = [ALUtilityClass getSizeForText:theDate maxWidth:150 font:self.mDateLabel.font.fontName fontSize:self.mDateLabel.font.pointSize];


    if ([alMessage isReceivedMessage])
    {
        [self.contactPerson setTextColor:[ALApplozicSettings getReceivedContactMsgLabelColor]];
        [self.userContact setTextColor:[ALApplozicSettings getReceivedContactMsgLabelColor]];
        [self.emailId setTextColor:[ALApplozicSettings getReceivedContactMsgLabelColor]];

        if([ALApplozicSettings isUserProfileHidden])
        {
            self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X, 0, 0, USER_PROFILE_HEIGHT);
        }
        else
        {
            self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X, 0,
                                                          USER_PROFILE_WIDTH, USER_PROFILE_HEIGHT);
        }

        self.mBubleImageView.backgroundColor = [ALApplozicSettings getReceiveMsgColor];

        self.mNameLabel.frame = self.mUserProfileImageView.frame;

        [self.mNameLabel setText:[ALColorUtility getAlphabetForProfileImage:alMessage.to]];
        ALContactDBService *theContactDBService = [[ALContactDBService alloc] init];
        ALContact *alContact = [theContactDBService loadContactByKey:@"userId" value: alMessage.to];
        NSString * receiverName = [alContact getDisplayName];
        if(alContact.contactImageUrl)
        {
            ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
            [messageClientService downloadImageUrlAndSet:alContact.contactImageUrl imageView:self.mUserProfileImageView defaultImage:@"ic_contact_picture_holo_light.png"];
        }
        else
        {
            [self.mUserProfileImageView sd_setImageWithURL:[NSURL URLWithString:@""]];
            [self.mNameLabel setHidden:NO];
            self.mUserProfileImageView.backgroundColor = [ALColorUtility getColorForAlphabet:alMessage.to colorCodes:self.alphabetiColorCodesDictionary];
        }

        //Shift for message reply and channel name..

        CGFloat requiredHeight = viewSize.width -BUBBLE_PADDING_HEIGHT;

        CGFloat imageViewY =  self.mBubleImageView.frame.origin.y + CNT_PROFILE_Y;

        CGFloat contactProfileViewY = 0.0;
        [self.mBubleImageView setFrame:CGRectMake(self.mUserProfileImageView.frame.size.width + BUBBLE_PADDING_X , 0,
                                                  viewSize.width - BUBBLE_PADDING_WIDTH, requiredHeight)];
        if(alMessage.groupId)
        {
            [self.mChannelMemberName setHidden:NO];
            [self.mChannelMemberName setText:receiverName];
            [self.mChannelMemberName setTextColor: [ALColorUtility getColorForAlphabet:receiverName colorCodes:self.alphabetiColorCodesDictionary]];
            self.mChannelMemberName.frame = CGRectMake(self.mBubleImageView.frame.origin.x + CHANNEL_PADDING_X,
                                                       self.mBubleImageView.frame.origin.y + CHANNEL_PADDING_Y,
                                                       self.mBubleImageView.frame.size.width + CHANNEL_PADDING_WIDTH, CHANNEL_PADDING_HEIGHT);

            requiredHeight = requiredHeight + self.mChannelMemberName.frame.size.height;
            imageViewY = imageViewY +  self.mChannelMemberName.frame.size.height;
            
            contactProfileViewY =  self.mChannelMemberName.frame.origin.x-AL_CONTACT_PADDING_Y;

        }
        
        if(alMessage.isAReplyMessage)
        {
            [self processReplyOfChat:alMessage andViewSize:viewSize];

            requiredHeight = requiredHeight + self.replyParentView.frame.size.height;
            imageViewY = imageViewY +  self.replyParentView.frame.size.height;

        }


        [self.mBubleImageView setFrame:CGRectMake(self.mUserProfileImageView.frame.size.width + BUBBLE_PADDING_X , 0,viewSize.width - BUBBLE_PADDING_WIDTH, requiredHeight)];
        
        if(!alMessage.groupId){
            contactProfileViewY =  self.mUserProfileImageView.frame.origin.x + 20;
        }
        
        [self.contactProfileImage setFrame:CGRectMake(self.mBubleImageView.frame.origin.x + CNT_PROFILE_X,
                                                      contactProfileViewY,
                                                      CNT_PROFILE_WIDTH, CNT_PROFILE_HEIGHT)];
        
        CGFloat widthName = self.mBubleImageView.frame.size.width - (self.contactProfileImage.frame.size.width + 25);

        [self.contactPerson setFrame:CGRectMake(self.contactProfileImage.frame.origin.x + self.contactProfileImage.frame.size.width + CNT_PERSON_X,
                                                contactProfileViewY, widthName, CNT_PERSON_HEIGHT)];

        [self.userContact setFrame:CGRectMake(self.contactPerson.frame.origin.x,
                                              contactProfileViewY + self.contactPerson.frame.size.height + USER_CNT_Y,
                                              widthName, USER_CNT_HEIGHT)];

        [self.emailId setFrame:CGRectMake(self.userContact.frame.origin.x,
                                          contactProfileViewY + self.userContact.frame.size.height + EMAIL_Y,
                                          widthName, EMAIL_HEIGHT)];

        [self.addContactButton setFrame:CGRectMake(self.contactProfileImage.frame.origin.x,
                                                   self.mBubleImageView.frame.origin.y + self.mBubleImageView.frame.size.height - BUTTON_Y,
                                                   self.mBubleImageView.frame.size.width - BUTTON_WIDTH, BUTTON_HEIGHT)];

        self.mDateLabel.frame = CGRectMake(self.mBubleImageView.frame.origin.x ,
                                           self.mBubleImageView.frame.origin.y + self.mBubleImageView.frame.size.height,
                                           theDateSize.width , DATE_HEIGHT);

        self.mDateLabel.textAlignment = NSTextAlignmentLeft;

        self.mMessageStatusImageView.frame = CGRectMake(self.mDateLabel.frame.origin.x + self.mDateLabel.frame.size.width,
                                                        self.mDateLabel.frame.origin.y, 20, 20);

        [self.addContactButton setBackgroundColor:[UIColor grayColor]];

    }

    [self.contactProfileImage setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_contact_picture_holo_light.png"]];
    self.contactProfileImage.layer.cornerRadius = self.contactProfileImage.frame.size.width/2;
    self.contactProfileImage.layer.masksToBounds = YES;

    self.mDateLabel.text = theDate;
    theUrl  = nil;
    self.vCardClass = nil;

    if (alMessage.imageFilePath != NULL)
    {
        NSString * docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString * filePath = [docDir stringByAppendingPathComponent:alMessage.imageFilePath];
        theUrl = [NSURL fileURLWithPath:filePath];

        self.vCardClass = [[ALVCardClass alloc] init];
        [self.vCardClass vCardParser:filePath];

        [self.contactPerson setText:self.vCardClass.fullName];
        if(self.vCardClass.contactImage)
        {
            [self.contactProfileImage setImage:self.vCardClass.contactImage];
        }
        [self.emailId setText:self.vCardClass.userEMAIL_ID];
        [self.userContact setText:self.vCardClass.userPHONE_NO];
        [self.addContactButton setEnabled:YES];
    }

    return self;
}

-(void)addButtonAction
{
    @try
    {
        [self.vCardClass addContact:self.vCardClass];
    } @catch (NSException *exception) {
        
        ALSLog(ALLoggerSeverityInfo, @"CONTACT_EXCEPTION :: %@", exception.description);
    }
}

@end
