//
//  ALLinkCell.m
//  Applozic
//
//  Created by apple on 22/11/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALLinkCell.h"

#import "UIImageView+WebCache.h"
#import "ALDBHandler.h"
#import "ALContact.h"
#import "ALContactDBService.h"
#import "ALApplozicSettings.h"
#import "ALMessageService.h"
#import "ALMessageDBService.h"
#import "ALUtilityClass.h"
#import "ALColorUtility.h"
#import "ALMessage.h"
#import "ALMessageInfoViewController.h"
#import "ALChatViewController.h"
#import "ALDataNetworkConnection.h"
#import "UIImage+MultiFormat.h"
#import "ALShowImageViewController.h"
#import "ALMessageClientService.h"
#import "ALConnectionQueueHandler.h"
#import "UIImage+animatedGIF.h"

// Constants
#define MT_INBOX_CONSTANT "4"
#define MT_OUTBOX_CONSTANT "5"

#define DOWNLOAD_RETRY_PADDING_X 45
#define DOWNLOAD_RETRY_PADDING_Y 20

#define MAX_WIDTH 150
#define MAX_WIDTH_DATE 130

#define IMAGE_VIEW_PADDING_X 5
#define IMAGE_VIEW_PADDING_Y 5
#define IMAGE_VIEW_PADDING_WIDTH 10
#define IMAGE_VIEW_PADDING_HEIGHT 10
#define IMAGE_VIEW_PADDING_HEIGHT_GRP 15

#define DATE_HEIGHT 20
#define DATE_PADDING_X 20

#define MSG_STATUS_WIDTH 20
#define MSG_STATUS_HEIGHT 20

#define IMAGE_VIEW_WITHTEXT_PADDING_Y 10

#define BUBBLE_PADDING_X 13
#define BUBBLE_PADDING_Y 120
#define BUBBLE_PADDING_WIDTH 120
#define BUBBLE_PADDING_HEIGHT 120
#define BUBBLE_PADDING_HEIGHT_GRP 100
#define BUBBLE_PADDING_X_OUTBOX 60
#define BUBBLE_PADDING_HEIGHT_TEXT 20

#define CHANNEL_PADDING_X 5
#define CHANNEL_PADDING_Y 5
#define CHANNEL_PADDING_WIDTH 30
#define CHANNEL_PADDING_HEIGHT 20
#define CHANNEL_PADDING_GRP 3



@implementation ALLinkCell
{
    CGFloat msgFrameHeight;
    NSURL * theUrl;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if(self)
    {
        self.mImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.mImageView];
    }
    return self;
}

-(instancetype)populateCell:(ALMessage *)alMessage viewSize:(CGSize)viewSize
{
    [super populateCell:alMessage viewSize:viewSize];

    self.mUserProfileImageView.alpha = 1;
    [self.replyParentView setHidden:YES];

    BOOL today = [[NSCalendar currentCalendar] isDateInToday:[NSDate dateWithTimeIntervalSince1970:[alMessage.createdAtTime doubleValue]/1000]];
    NSString * theDate = [NSString stringWithFormat:@"%@",[alMessage getCreatedAtTimeChat:today]];

    ALContactDBService *theContactDBService = [[ALContactDBService alloc] init];
    ALContact *alContact = [theContactDBService loadContactByKey:@"userId" value: alMessage.to];

    NSString *linkText = nil;

    if([alMessage.metadata  valueForKey:@"text"]){
        linkText = [alMessage.metadata  valueForKey:@"text"];
    }else{
        linkText = [alMessage.metadata  valueForKey:@"linkURL"];
    }

    NSString *receiverName = [alContact getDisplayName];

    self.mMessage = alMessage;

    CGSize theDateSize = [ALUtilityClass getSizeForText:theDate maxWidth:MAX_WIDTH
                                                   font:self.mDateLabel.font.fontName
                                               fontSize:self.mDateLabel.font.pointSize];

    CGSize theTextSize = [ALUtilityClass getSizeForText:linkText
                                               maxWidth:viewSize.width - MAX_WIDTH_DATE
                                                   font:self.imageWithText.font.fontName
                                               fontSize:self.imageWithText.font.pointSize];

    [self.mChannelMemberName setHidden:YES];
    [self.mNameLabel setHidden:YES];
    [self.imageWithText setHidden:YES];
    [self.mMessageStatusImageView setHidden:YES];

    UITapGestureRecognizer *tapForOpenChat = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processOpenChat)];
    tapForOpenChat.numberOfTapsRequired = 1;
    [self.mUserProfileImageView setUserInteractionEnabled:YES];
    [self.mUserProfileImageView addGestureRecognizer:tapForOpenChat];


    if ([alMessage isReceivedMessage]) { //@"4" //Recieved Message

        [self.contentView bringSubviewToFront:self.mChannelMemberName];

        if([ALApplozicSettings isUserProfileHidden])
        {
            self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X, 0, 0,
                                                          45);
        }
        else
        {
            self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X, 0,
                                                          45,45);
        }

        self.mBubleImageView.backgroundColor = [ALApplozicSettings getReceiveMsgColor];

        self.mNameLabel.frame = self.mUserProfileImageView.frame;

        [self.mNameLabel setText:[ALColorUtility getAlphabetForProfileImage:receiverName]];

        //Shift for message reply and channel name..

        CGFloat requiredHeight = viewSize.width - BUBBLE_PADDING_HEIGHT;
        CGFloat imageViewHeight = requiredHeight -IMAGE_VIEW_PADDING_HEIGHT;

        CGFloat imageViewY = self.mBubleImageView.frame.origin.y + IMAGE_VIEW_PADDING_Y;

        self.mBubleImageView.frame = CGRectMake(self.mUserProfileImageView.frame.size.width + BUBBLE_PADDING_X,
                                                0, viewSize.width - BUBBLE_PADDING_WIDTH, requiredHeight);

        self.mBubleImageView.layer.shadowOpacity = 0.3;
        self.mBubleImageView.layer.shadowOffset = CGSizeMake(0, 2);
        self.mBubleImageView.layer.shadowRadius = 1;
        self.mBubleImageView.layer.masksToBounds = NO;


        if(alMessage.getGroupId)
        {
            [self.mChannelMemberName setHidden:NO];
            [self.mChannelMemberName setText:receiverName];

            [self.mChannelMemberName setTextColor: [ALColorUtility getColorForAlphabet:receiverName colorCodes:self.alphabetiColorCodesDictionary]];


            self.mChannelMemberName.frame = CGRectMake(self.mBubleImageView.frame.origin.x + CHANNEL_PADDING_X,
                                                       self.mBubleImageView.frame.origin.y + CHANNEL_PADDING_Y,
                                                       self.mBubleImageView.frame.size.width, CHANNEL_PADDING_HEIGHT);

            requiredHeight = requiredHeight + self.mChannelMemberName.frame.size.height;
            imageViewY = imageViewY +  self.mChannelMemberName.frame.size.height;
        }


        if(alMessage.isAReplyMessage)
        {
            [self processReplyOfChat:alMessage andViewSize:viewSize];

            requiredHeight = requiredHeight + self.replyParentView.frame.size.height;
            imageViewY = imageViewY +  self.replyParentView.frame.size.height;

        }
        self.mBubleImageView.frame = CGRectMake(self.mUserProfileImageView.frame.size.width + BUBBLE_PADDING_X,
                                                0, viewSize.width - BUBBLE_PADDING_WIDTH, requiredHeight);
        self.mImageView.frame = CGRectMake(self.mBubleImageView.frame.origin.x + IMAGE_VIEW_PADDING_X,
                                           imageViewY,
                                           self.mBubleImageView.frame.size.width - IMAGE_VIEW_PADDING_WIDTH ,
                                           imageViewHeight);



        self.mDateLabel.textAlignment = NSTextAlignmentLeft;

        if(linkText.length > 0)
        {
            self.imageWithText.textColor = [ALApplozicSettings getReceiveMsgTextColor];

            self.mBubleImageView.frame = CGRectMake(self.mUserProfileImageView.frame.size.width + BUBBLE_PADDING_X,
                                                    0, viewSize.width - BUBBLE_PADDING_Y,
                                                    (viewSize.width - BUBBLE_PADDING_HEIGHT)
                                                    + theTextSize.height + BUBBLE_PADDING_HEIGHT_TEXT);

            self.imageWithText.frame = CGRectMake(self.mImageView.frame.origin.x,
                                                  self.mImageView.frame.origin.y + self.mImageView.frame.size.height + 5,
                                                  self.mImageView.frame.size.width, theTextSize.height);

            [self.imageWithText setHidden:NO];

            [self.contentView bringSubviewToFront:self.mDateLabel];
            [self.contentView bringSubviewToFront:self.mMessageStatusImageView];
        }
        else
        {
            [self.imageWithText setHidden:YES];
        }

        self.mDateLabel.frame = CGRectMake(self.mBubleImageView.frame.origin.x,
                                           self.mBubleImageView.frame.origin.y +
                                           self.mBubleImageView.frame.size.height,
                                           theDateSize.width,
                                           DATE_HEIGHT);

        self.mMessageStatusImageView.frame = CGRectMake(self.mDateLabel.frame.origin.x + self.mDateLabel.frame.size.width,
                                                        self.mDateLabel.frame.origin.y,
                                                        MSG_STATUS_WIDTH, MSG_STATUS_HEIGHT);


        if(alContact.contactImageUrl)
        {
            ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
            [messageClientService downloadImageUrlAndSet:alContact.contactImageUrl imageView:self.mUserProfileImageView defaultImage:@"ic_contact_picture_holo_light.png"];
        }
        else
        {
            [self.mUserProfileImageView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:nil options:SDWebImageRefreshCached];
            [self.mNameLabel setHidden:NO];
            self.mUserProfileImageView.backgroundColor = [ALColorUtility getColorForAlphabet:receiverName colorCodes:self.alphabetiColorCodesDictionary];
        }


    }
    else
    { //Sent Message

        self.mBubleImageView.backgroundColor = [ALApplozicSettings getSendMsgColor];

        self.mUserProfileImageView.frame = CGRectMake(viewSize.width - USER_PROFILE_PADDING_X_OUTBOX,
                                                      0, 0, USER_PROFILE_HEIGHT);

        self.mBubleImageView.frame = CGRectMake((viewSize.width - self.mUserProfileImageView.frame.origin.x + BUBBLE_PADDING_X_OUTBOX),
                                                0, viewSize.width - BUBBLE_PADDING_WIDTH, viewSize.width - BUBBLE_PADDING_HEIGHT);

        self.mBubleImageView.layer.shadowOpacity = 0.3;
        self.mBubleImageView.layer.shadowOffset = CGSizeMake(0, 2);
        self.mBubleImageView.layer.shadowRadius = 1;
        self.mBubleImageView.layer.masksToBounds = NO;

        CGFloat requiredHeight = viewSize.width - BUBBLE_PADDING_HEIGHT;
        CGFloat imageViewHeight = requiredHeight -IMAGE_VIEW_PADDING_HEIGHT;

        CGFloat imageViewY = self.mBubleImageView.frame.origin.y + IMAGE_VIEW_PADDING_Y;

        [self.mBubleImageView setFrame:CGRectMake((viewSize.width - self.mUserProfileImageView.frame.origin.x + 60),
                                                  0, viewSize.width - BUBBLE_PADDING_WIDTH, requiredHeight)];

        if(alMessage.isAReplyMessage)
        {
            [self processReplyOfChat:alMessage andViewSize:viewSize ];

            requiredHeight = requiredHeight + self.replyParentView.frame.size.height;
            imageViewY = imageViewY +  self.replyParentView.frame.size.height;

        }

        [self.mBubleImageView setFrame:CGRectMake((viewSize.width - self.mUserProfileImageView.frame.origin.x + 60),
                                                  0, viewSize.width - BUBBLE_PADDING_WIDTH, requiredHeight)];



        self.mImageView.frame = CGRectMake(self.mBubleImageView.frame.origin.x + IMAGE_VIEW_PADDING_X,
                                           imageViewY,
                                           self.mBubleImageView.frame.size.width - IMAGE_VIEW_PADDING_WIDTH,
                                           imageViewHeight);

        [self.mMessageStatusImageView setHidden:NO];

        if(linkText.length > 0)
        {


            [self.imageWithText setHidden:NO];
            self.imageWithText.backgroundColor = [UIColor clearColor];
            self.imageWithText.textColor = [ALApplozicSettings getSendMsgTextColor];;
            self.mBubleImageView.frame = CGRectMake((viewSize.width - self.mUserProfileImageView.frame.origin.x + BUBBLE_PADDING_X_OUTBOX),
                                                    0, viewSize.width - BUBBLE_PADDING_WIDTH,
                                                    viewSize.width - BUBBLE_PADDING_HEIGHT
                                                    + theTextSize.height + BUBBLE_PADDING_HEIGHT_TEXT);

            self.imageWithText.frame = CGRectMake(self.mBubleImageView.frame.origin.x + IMAGE_VIEW_PADDING_X,
                                                  self.mImageView.frame.origin.y + self.mImageView.frame.size.height + IMAGE_VIEW_WITHTEXT_PADDING_Y,
                                                  self.mImageView.frame.size.width, theTextSize.height);

            [self.contentView bringSubviewToFront:self.mDateLabel];
            [self.contentView bringSubviewToFront:self.mMessageStatusImageView];

        }
        else
        {
            [self.imageWithText setHidden:YES];
        }

        msgFrameHeight = self.mBubleImageView.frame.size.height;

        self.mDateLabel.textAlignment = NSTextAlignmentLeft;

        self.mDateLabel.frame = CGRectMake((self.mBubleImageView.frame.origin.x +
                                            self.mBubleImageView.frame.size.width) - theDateSize.width - DATE_PADDING_X,
                                           self.mBubleImageView.frame.origin.y + self.mBubleImageView.frame.size.height,
                                           theDateSize.width, DATE_HEIGHT);

        self.mMessageStatusImageView.frame = CGRectMake(self.mDateLabel.frame.origin.x + self.mDateLabel.frame.size.width,
                                                        self.mDateLabel.frame.origin.y,
                                                        MSG_STATUS_WIDTH, MSG_STATUS_HEIGHT);

    }

    if ([alMessage isSentMessage] && ((self.channel && self.channel.type != OPEN) || self.contact))
    {

        self.mMessageStatusImageView.hidden = NO;
        NSString * imageName;

        switch (alMessage.status.intValue) {
            case DELIVERED_AND_READ :{
                imageName = @"ic_action_read.png";
            }break;
            case DELIVERED:{
                imageName = @"ic_action_message_delivered.png";
            }break;
            case SENT:{
                imageName = @"ic_action_message_sent.png";
            }break;
            default:{
                imageName = @"ic_action_about.png";
            }break;
        }
        self.mMessageStatusImageView.image = [ALUtilityClass getImageFromFramworkBundle:imageName];

    }

    self.mDateLabel.text = theDate;

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:linkText];

    if (alMessage.metadata != NULL && [alMessage.metadata  valueForKey:@"linkURL"])
    {
        @try {

            NSRange foundRange = [[alMessage.metadata  valueForKey:@"text"] rangeOfString:[alMessage.metadata  valueForKey:@"text"]];

            if (foundRange.location != NSNotFound && [alMessage.metadata  valueForKey:@"linkURL"]) {
                [attributedString  addAttribute:NSLinkAttributeName value:[alMessage.metadata  valueForKey:@"linkURL"] range:foundRange];
            }

        }
        @catch (NSException *exception) {
        }
    }

    self.imageWithText.attributedText = attributedString;

    if (alMessage.metadata != NULL && [alMessage.metadata  valueForKey:@"link"])
    {
        [self setInImageView:[NSURL URLWithString:[alMessage.metadata  valueForKey:@"link"]]];
    }else{
        
        self.mImageView.hidden = YES ;
    }
    
    return self;

}

-(void) setInImageView:(NSURL*)url{
    NSString *stringUrl = url.absoluteString;
    if (stringUrl != nil && [stringUrl localizedCaseInsensitiveContainsString:@"gif"]) {
        UIImage *image = [UIImage animatedImageWithAnimatedGIFURL:url];
        [self.mImageView setImage: image];
        return;
    }
    [self.mImageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRefreshCached];

}

-(void)processOpenChat
{
    [self processKeyBoardHideTap];
    [self.delegate openUserChat:self.mMessage];
}

-(void) processKeyBoardHideTap
{
    [self.delegate handleTapGestureForKeyBoard];
}


-(void) delete:(id)sender
{
    //UI
    ALSLog(ALLoggerSeverityInfo, @"message to deleteUI %@",self.mMessage.message);
    [self.delegate deleteMessageFromView:self.mMessage];

    //serverCall
    [ALMessageService deleteMessage:self.mMessage.key andContactId:self.mMessage.contactIds withCompletion:^(NSString *string, NSError *error) {

        ALSLog(ALLoggerSeverityError, @"DELETE MESSAGE ERROR :: %@", error.description);
    }];
}

-(void) messageForward:(id)sender
{
    ALSLog(ALLoggerSeverityInfo, @"Message forward option is pressed");
    [self.delegate processForwardMessage:self.mMessage];

}


-(void) messageReply:(id)sender
{
    ALSLog(ALLoggerSeverityInfo, @"Message forward option is pressed");
    [self.delegate processMessageReply:self.mMessage];

}

-(void)openUserChatVC
{
    [self.delegate processUserChatView:self.mMessage];
}

- (void)msgInfo:(id)sender
{
    [self.delegate showAnimationForMsgInfo:YES];
    UIStoryboard *storyboardM = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALMessageInfoViewController *msgInfoVC = (ALMessageInfoViewController *)[storyboardM instantiateViewControllerWithIdentifier:@"ALMessageInfoView"];

    msgInfoVC.contentURL = theUrl;

    __weak typeof(ALMessageInfoViewController *) weakObj = msgInfoVC;
    [msgInfoVC setMessage:self.mMessage andHeaderHeight:msgFrameHeight withCompletionHandler:^(NSError *error) {

        if(!error)
        {
            [self.delegate loadViewForMedia:weakObj];
        }
        else
        {
            [self.delegate showAnimationForMsgInfo:NO];
        }
    }];
}

-(BOOL)isForwardMenuEnabled:(SEL) action;
{
    return ([ALApplozicSettings isForwardOptionEnabled] && action == @selector(messageForward:));
}

-(BOOL)isMessageReplyMenuEnabled:(SEL) action
{

    return ([ALApplozicSettings isReplyOptionEnabled] && action == @selector(messageReply:));

}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    ALSLog(ALLoggerSeverityInfo, @"Action: %@", NSStringFromSelector(action));

    if(self.mMessage.groupId){
        ALChannelService *channelService = [[ALChannelService alloc] init];
        ALChannel *channel =  [channelService getChannelByKey:self.mMessage.groupId];
        if(channel && channel.type == OPEN){
            return NO;
        }
    }

    if([self.mMessage isSentMessage] && self.mMessage.groupId)
    {
        return (self.mMessage.isDownloadRequired? (action == @selector(delete:) || action == @selector(msgInfo:)):(action == @selector(delete:)|| action == @selector(msgInfo:)|| action == @selector(messageForward:) || [self isMessageReplyMenuEnabled:action]));
    }

    return (self.mMessage.isDownloadRequired? (action == @selector(delete:)):(action == @selector(delete:)|| [self isForwardMenuEnabled:action] || [self isMessageReplyMenuEnabled:action] ));
}


@end
