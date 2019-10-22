
//
//  ALChatViewController.m
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//
#import "UIView+Toast.h"
#import <AVKit/AVKit.h>
#import "ALChatViewController.h"
#import "ALChatCell.h"
#import "ALMessageService.h"
#import "ALUtilityClass.h"
#import <CoreGraphics/CoreGraphics.h>
#import "ALJson.h"
#import <CoreData/CoreData.h>
#import "ALDBHandler.h"
#import "DB_Message.h"
#import "ALMessagesViewController.h"
#import "ALNewContactsViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+Utility.h"
#import "ALImageCell.h"
#import "ALFileMetaInfo.h"
#import "DB_FileMetaInfo.h"
#import "UIImageView+WebCache.h"
#import "ALConnectionQueueHandler.h"
#import "ALRequestHandler.h"
#import "ALUserDefaultsHandler.h"
#import "ALMessageDBService.h"
#import "ALImagePickerHandler.h"
#import "ALLocationManager.h"
#import "ALConstant.h"
#import "DB_Contact.h"
#import "ALMapViewController.h"
#import "ALNotificationView.h"
#import "ALUserService.h"
#import "ALMessageService.h"
#import "ALUserDetail.h"
#import "ALMQTTConversationService.h"
#import "ALContactDBService.h"
#import "ALDataNetworkConnection.h"
#import "ALAppLocalNotifications.h"
#import "ALChatLauncher.h"
#import "ALMessageClientService.h"
#import "ALContactService.h"
#import "ALMediaBaseCell.h"
#import "ALGroupDetailViewController.h"
#import "ALVideoCell.h"
#import "ALDocumentsCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ALConversationService.h"
#import "ALMultipleAttachmentView.h"
#import "ALPushAssist.h"
#import "ALLocationCell.h"
#import "ALContactMessageCell.h"
#import "ALCustomCell.h"
#import "ALVOIPCell.h"
#import "ALUIConstant.h"
#import "ALReceiverUserProfileVC.h"
#import "PSPDFTextView.h"
#import "ALChannelMsgCell.h"
#include <tgmath.h>
#import "ALAudioVideoBaseVC.h"
#import "ALVOIPNotificationHandler.h"
#import "ALChannelService.h"
#import "ALMultimediaData.h"
#import <Applozic/Applozic-Swift.h>
#import "UIImage+animatedGIF.h"
#import <Photos/Photos.h>
#import "ALImagePreviewController.h"
#import "ALLinkCell.h"
#import "ALDocumentPickerHandler.h"
#import "ALHTTPManager.h"
#import "ALUploadTask.h"
#import "ALDownloadTask.h"
#import "ALMyContactMessageCell.h"

#define MQTT_MAX_RETRY 3
#define NEW_MESSAGE_NOTIFICATION @"newMessageNotification"

NSString * const ThirdPartyDetailVCNotification = @"ThirdPartyDetailVCNotification";
NSString * const ThirdPartyDetailVCNotificationNavigationVC = @"ThirdPartyDetailVCNotificationNavigationVC";
NSString * const ThirdPartyDetailVCNotificationALContact = @"ThirdPartyDetailVCNotificationALContact";
NSString * const ThirdPartyDetailVCNotificationChannelKey = @"ThirdPartyDetailVCNotificationChannelKey";
NSString * const ThirdPartyProfileTapNotification = @"ThirdPartyProfileTapNotification";


@interface ALChatViewController ()<ALMediaBaseCellDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate, ALLocationDelegate, ALAudioRecorderViewProtocol, ALAudioRecorderProtocol,
                                    ALMQTTConversationDelegate, ALAudioAttachmentDelegate, UIPickerViewDelegate, UIPickerViewDataSource,
                                    UIAlertViewDelegate, ALMUltipleAttachmentDelegate, UIDocumentInteractionControllerDelegate,
                                     ALSoundRecorderProtocol, ALCustomPickerDelegate,ALImageSendDelegate,UIDocumentPickerDelegate,ApplozicAttachmentDelegate>

@property (nonatomic, assign) NSInteger startIndex;
@property (nonatomic, assign) int rp;
@property (nonatomic, assign) NSUInteger mTotalCount;
@property (nonatomic, retain) UIImagePickerController * mImagePicker;
@property (nonatomic, strong) ALLocationManager * alLocationManager;
@property (nonatomic, assign) BOOL showloadEarlierAction;
@property (nonatomic, weak) IBOutlet UIButton *loadEarlierAction;
@property (nonatomic, weak) NSIndexPath *indexPathofSelection;
@property (nonatomic, strong) ALMQTTConversationService *mqttObject;
@property (nonatomic) NSInteger  mqttRetryCount;
@property (nonatomic, strong) NSArray * pickerDataSourceArray;
@property (nonatomic, strong) NSMutableArray * pickerConvIdsArray;
@property (nonatomic, strong) NSMutableArray * conversationTitleList;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewSendMsgTextViewConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *typingLabelBottomConstraint;
@property (nonatomic, assign) BOOL comingFromBackground;
@property (nonatomic, strong) ALVideoCoder *videoCoder;
@property (strong, nonatomic)  NSMutableDictionary *alphabetiColorCodesDictionary;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nsLayoutconstraintAttachmentWidth;

//============Message Reply outlets====================================//

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewViewBottomConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *replyAttachmentPreview;
@property (weak, nonatomic) IBOutlet UIView *messageReplyView;
- (IBAction)cancelMessageReply:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewHeightConstraints;
@property (weak, nonatomic) IBOutlet UILabel *replyMessageText;
@property (nonatomic,assign) NSString* messageReplyId;
@property (nonatomic, weak) IBOutlet UIImageView *replyIcon;
@property (weak, nonatomic) IBOutlet UILabel *replyUserName;
//============Message Reply outlets END====================================//


- (IBAction)loadEarlierButtonAction:(id)sender;
-(void)processLoadEarlierMessages:(BOOL)flag;
-(void)markConversationRead;
-(void)fetchAndRefresh:(BOOL)flag;
-(void)serverCallForLastSeen;
-(void)freezeView:(BOOL)freeze;
-(BOOL)checkRestrictWords:(NSString *)msgText;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (nonatomic) BOOL isUserBlocked;
@property (nonatomic) BOOL isUserBlockedBy;

-(void)processAttachment:(NSString *)filePath andMessageText:(NSString *)textwithimage andContentType:(short)contentype;

@end

@implementation ALChatViewController
{
    NSString *messageId;
    BOOL typingStat;
    CGRect defaultTableRect;
    UIView * maskView;
    BOOL isPickerOpen;
    ALAudioRecorderView * soundRecordingView;
    ALSoundRecorderButton * soundRecording;
    ALTemplateMessagesView *templateMessageView;
    BOOL isMicButtonVisible;
    ALAudioRecordButton * micButton;
    BOOL isAudioRecordingEnabled;
    BOOL isNewAudioDesignEnabled;

    UIDocumentInteractionController * interaction;

    CGFloat TEXT_CELL_HEIGHT;
    CGFloat IMAGE_CELL_HEIGHT;
    CGFloat LOCATION_CELL_HEIGHT;
    CGFloat IMAGE_AND_TEXT_CELL_HEIGHT;
    CGFloat DOCUMENT_CELL_HEIGHT;
    CGFloat AUDIO_CELL_HEIGHT;
    CGFloat VIDEO_CELL_HEIGHT;
    CGFloat DATE_CELL_HEIGHT;
    CGFloat CONTACT_CELL_HEIGHT;

    UIButton * titleLabelButton;

    CGRect previousRect;
    CGRect maxHeight;
    CGRect minHeight;

    ALMessageDBService * dbService;
}


//==============================================================================================================================================
#pragma mark - VIEW LIFECYCLE
//==============================================================================================================================================

-(void)viewDidLoad
{
    [super viewDidLoad];

    // Setup quick recording if it's enabled in the settings
    if([ALApplozicSettings isQuickAudioRecordingEnabled]) {
        if (@available(iOS 9.0, *) && [ALApplozicSettings isNewAudioDesignEnabled]) {
            isNewAudioDesignEnabled = YES;
        } else {
            isNewAudioDesignEnabled = NO;
        }
        [self setUpSoundRecordingView];
        [self showMicButton];
        isAudioRecordingEnabled = YES;
    }



    [self initialSetUp];
    [self fetchMessageFromDB];
    [self loadChatView];
    self.placeHolderTxt = NSLocalizedStringWithDefaultValue(@"placeHolderText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Write a Message...", @"");
    self.sendMessageTextView.text = self.placeHolderTxt;
    self.defaultMessageViewHeight = 56.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVOIPMsg)
                                                 name:@"UPDATE_VOIP_MSG" object:nil];

    [self.attachmentOutlet setTintColor:[ALApplozicSettings getAttachmentIconColour]];
    [self.sendButton setTintColor:[ALApplozicSettings getSendIconColour]];
    self.alphabetiColorCodesDictionary = [ALApplozicSettings getUserIconFirstNameColorCodes];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view endEditing:YES];
    [self.loadEarlierAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loadEarlierAction setBackgroundColor:[UIColor grayColor]];
    [self markConversationRead];
    [self.loadEarlierAction setTitle:NSLocalizedStringWithDefaultValue(@"loadEarlierMessagesText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Load Earlier Messages", @"") forState:UIControlStateNormal];
    [[[self navigationController] interactivePopGestureRecognizer] setEnabled:NO];
    [UIView animateWithDuration:0.3 animations:^{
        [self subProcessTextViewDidChange:self.sendMessageTextView];
        [self.sendMessageTextView setScrollEnabled:YES];

    }];
    if(self.alMessage){
        [self handleMessageForward:self.alMessage];

    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isVisible = YES;

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(newMessageHandler:) name:NEW_MESSAGE_NOTIFICATION  object:nil];

    [self.tabBarController.tabBar setHidden: YES];

    if([ALApplozicSettings isTemplateMessageEnabled]) {
        [self setUpTeamplateView];
    }

    // In iOS 11, TableView by default starts estimating the row height. This setting will disable that.
    self.mTableView.estimatedRowHeight = 0;

    [self.label setHidden:NO];
    self.label.alpha = 1;
    [self.loadEarlierAction setHidden:YES];
    self.showloadEarlierAction = TRUE;
    self.typingLabel.hidden = YES;

    self.comingFromBackground = YES;
    [self.messageReplyView setHidden:YES];

    typingStat = NO;

    if([self isReloadRequired])
    {
        [self reloadView];

        NSString * key = self.channelKey ? [self.channelKey stringValue]: self.contactIds;

        if(![ALUserDefaultsHandler isServerCallDoneForMSGList:key])
        {
            //            [[self.alMessageWrapper getUpdatedMessageArray] removeAllObjects];
            //            self.startIndex =0;
            //            [self.mTableView reloadData];
            //            [self setTitle];
            [self processLoadEarlierMessages:true];
        }
        else
        {
            [self scrollTableViewToBottomWithAnimation:NO];
        }
        self.sendMessageTextView.text = @"";
    }

    if (self.refresh) {
        self.refresh = false;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(individualNotificationhandler:)
                                                 name:@"notificationIndividualChat" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeliveryStatus:)
                                                 name:@"report_DELIVERED" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReadReport:)
                                                 name:@"report_DELIVERED_READ" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReadReportForConversation:)
                                                 name:@"report_CONVERSATION_DELIVERED_READ" object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(updateLastSeenAtStatusPUSH:) name:@"update_USER_STATUS"  object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(checkUserBlockStatus) name:@"USER_BLOCK_NOTIFICATION" object:nil];

    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(checkUserBlockStatus) name:@"USER_UNBLOCK_NOTIFICATION" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageSendStatus:)
                                                 name:@"UPDATE_MESSAGE_SEND_STATUS" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEntersForeground:)
                                                 name:@"APP_ENTER_IN_FOREGROUND" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChannelName)
                                                 name:@"UPDATE_CHANNEL_NAME" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFreezeForAddingRemovingUser:)
                                                      name:@"UPDATE_USER_FREEZE_CHANNEL_ADD_REMOVING" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackGround)
                                                 name:@"APP_ENTER_IN_BACKGROUND" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageDeletedAPPLOZIC05Handler:)
                                                 name:@"NOTIFY_MESSAGE_DELETED" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCallForUser:)
                                                 name:@"USER_DETAILS_UPDATE_CALL" object:nil];

    self.mqttObject = [ALMQTTConversationService sharedInstance];

    if(self.individualLaunch)
    {
        ALSLog(ALLoggerSeverityInfo, @"INDIVIDUAL_LAUNCH :: SUBSCRIBING_MQTT");
        self.mqttObject.mqttConversationDelegate = self;
        if(self.mqttObject)
        {
            [self.mqttObject subscribeToConversation];
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"mqttObject is not found...");
        }
    }

    [self serverCallForLastSeen];
    [self handleAttachmentButtonVisibility];

    [self setTitle];

    if(self.text && !self.alMessageWrapper.getUpdatedMessageArray.count)
    {
        [self.sendMessageTextView setTextColor:[ALApplozicSettings getTextColorForMessageTextView]];
        self.sendMessageTextView.text = self.text;
    }
    else if ([self.sendMessageTextView.text isEqualToString:@""])
    {
        [self placeHolder:self.placeHolderTxt andTextColor:self.placeHolderColor];
        [self subProcessSetHeightOfTextViewDynamically];
    }

    [self.pickerView setHidden:YES];
    if(self.conversationId && [ALApplozicSettings getContextualChatOption])
    {
        [self setupPickerView];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        [self.pickerView reloadAllComponents];
    }

    if (self.channelKey) {
        [self checkIfChannelLeft];
    }else{
        self.typingMessageView.hidden = NO;
    }

    [self setCallButtonInNavigationBar];
    [self checkUserBlockStatus];
    if(self.contactIds ){
      [self checkUserDeleted];
    }
    [self showNoConversationLabel];
    [self hideKeyBoardOnEmptyList];

    previousRect = CGRectZero;

    maxHeight = [self getMaxSizeLines:[ALApplozicSettings getMaxTextViewLines]];
    minHeight = [self getMaxSizeLines:1]; //  Single Line Height

    [self subscrbingChannel];

    [self loadMessagesForOpenChannel];


}

-(void) handleAttachmentButtonVisibility
{
    BOOL hidden = NO; // Default don't hide.
    if (ALApplozicSettings.isAttachmentButtonHidden) { // Hide if setting is present
        hidden = YES;
    } else if (![self isGroup]) { // Else show for one-to-one chat
        hidden = NO;
    } else {
        ALChannelService * alChannelService  = [[ALChannelService alloc] init];
        ALChannel *alChannel = [alChannelService getChannelByKey:self.channelKey];
        hidden = (alChannel && alChannel.type == OPEN); // Else hide for open group only.
    }
    self.attachmentOutlet.hidden = hidden;
    self.nsLayoutconstraintAttachmentWidth.constant = hidden ? 0 : 40;
}

-(void)setFreezeForAddingRemovingUser:(NSNotification *)notifyObject
{
    NSMutableDictionary * dict = (NSMutableDictionary *)notifyObject.userInfo;
    NSNumber *numFlag = dict[@"FLAG_VALUE"];
    NSNumber *channelKey = dict[@"CHANNEL_KEY"];
    if(self.channelKey && [self.channelKey isEqualToNumber:channelKey])
    {
        [self freezeView:[numFlag boolValue]];
    }
    if([numFlag boolValue])
    {
        [self.mqttObject unSubscribeToChannelConversation:channelKey];
    }
    else
    {
        [self.mqttObject subscribeToChannelConversation:channelKey];
    }
}

-(void)messageDeletedAPPLOZIC05Handler:(NSNotification *)notification{

    NSString * messageKey = notification.object;

    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"key=%@",messageKey];
    NSArray *proccessfilterArray = [[self.alMessageWrapper getUpdatedMessageArray] filteredArrayUsingPredicate:predicate];
    if(proccessfilterArray.count != 0)
    {
        ALMessage *msg = [proccessfilterArray objectAtIndex:0];
        ALSLog(ALLoggerSeverityInfo, @"Messsage 05:%@",msg.message);
        msg.deleted = YES;

           [self deleteMessageFromView:msg]; // Removes message from U.I.

        [ALMessageService deleteMessage:messageKey andContactId:self.contactIds withCompletion:^(NSString * response, NSError * error) {

            ALSLog(ALLoggerSeverityInfo, @"Message Deleted upon APPLOZIC_05 and response: %@", response);

        }];
//        ALMessageDBService * almessageDBService = [[ALMessageDBService alloc] init];
//        DB_Message *dbMessage = (DB_Message*)[almessageDBService getMessageByKey:@"key" value:messageKey];
//        dbMessage.deletedFlag = [NSNumber numberWithBool:YES];
//        NSError *error;
//        if (![[dbMessage managedObjectContext] save:&error])
//        {
//            NSLog(@"Delete Flag Not Set under APPLOZIC_05");
//        }
//        [dbService deleteMessageByKey:messageKey];
    }

    [self.mTableView reloadData];

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.tabBarController.tabBar setHidden:YES];
    [self resetMessageReplyView];

    if([ALApplozicSettings isTemplateMessageEnabled]) {
        [templateMessageView setHidden:YES];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"notificationIndividualChat" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"report_DELIVERED" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"report_DELIVERED_READ" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"report_CONVERSATION_DELIVERED_READ" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"update_USER_STATUS" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEW_MESSAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"USER_BLOCK_NOTIFICATION" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"USER_UNBLOCK_NOTIFICATION" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UPDATE_MESSAGE_SEND_STATUS" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"appCameInForeground" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"APP_ENTER_IN_BACKGROUND" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UPDATE_USER_FREEZE_CHANNEL_ADD_REMOVING" object:nil];

    [self.sendMessageTextView resignFirstResponder];
    [self.label setHidden:YES];
    [[ALMediaPlayer sharedInstance] stopPlaying];

    if(self.individualLaunch)
    {
        ALSLog(ALLoggerSeverityInfo, @"ALChatVC: Individual launch ...unsubscribeToConversation to mqtt..");
        if(self.mqttObject)
        {
            [self.mqttObject unsubscribeToConversation];
            ALSLog(ALLoggerSeverityInfo, @"ALChatVC: In ViewWillDisapper .. MQTTObject in ==IF== now");
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"mqttObject is not found...");
        }
    }

    if(isPickerOpen)
    {
        [self donePicking:nil];
    }

    [[[self navigationController] interactivePopGestureRecognizer] setEnabled:YES];
    self.label.alpha = 0;
    [self unSubscrbingChannel];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"USER_DETAILS_UPDATE_CALL" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UPDATE_VOIP_MSG" object:nil];
}

-(void)updateVOIPMsg
{
    [self.mTableView reloadData];
    [self setRefreshMainView:YES];
    [self setRefresh:YES];
}

-(void)processSendTemplateMessage:(NSString *)messageText{

    if(!messageText){
        return;
    }
    // create message object
    ALMessage * theMessage = [self getMessageToPost];
    theMessage.message = messageText;
    // save msg to db
    theMessage.msgDBObjectId = [self saveMessageToDatabase:theMessage];

    [self sendMessage:theMessage ];
    [self.mTableView reloadData];
    [self setRefreshMainView:TRUE];
    [self scrollTableViewToBottomWithAnimation:YES];
}

-(void)markConversationRead
{
    BOOL isGroupNotification = (self.channelKey == nil ? false : true);
    if(self.channelKey && isGroupNotification)
    {
        [[ALChannelService sharedInstance] markConversationAsRead:self.channelKey withCompletion:^(NSString * string, NSError * error) {

            if(error)
            {
                ALSLog(ALLoggerSeverityError, @"Error while marking messages as read channel %@",self.channelKey);
            }
            else
            {
                ALUserService *userService = [[ALUserService alloc] init];
                [userService processResettingUnreadCount];

            }
        }];
    }

    if(self.contactIds && !self.isGroup)
    {
        [[ALUserService sharedInstance] markConversationAsRead:self.contactIds withCompletion:^(NSString * string, NSError *error) {
            if(error)
            {
                ALSLog(ALLoggerSeverityError, @"Error while marking messages as read for contact %@", self.contactIds);
            }
            else
            {
                ALUserService *userService = [[ALUserService alloc] init];
                [userService processResettingUnreadCount];

            }
        }];
    }
}

-(void)markSingleMessageRead:(ALMessage *)almessage
{
    if(almessage.groupId != NULL)
    {
        if([self.channelKey isEqualToNumber:almessage.groupId])
        {
            [ALUserService markMessageAsRead:almessage withPairedkeyValue:almessage.pairedMessageKey withCompletion:^(NSString * completion, NSError * error) {

                if(error)
                {
                    ALSLog(ALLoggerSeverityError, @"GROUP: Marking message read error:%@",error);
                }
            }];
        }
    }
    else
    {
        if([self.contactIds isEqualToString:almessage.contactIds])
        {
            [ALUserService markMessageAsRead:almessage withPairedkeyValue:almessage.pairedMessageKey withCompletion:^(NSString * completion, NSError * error) {

                if(error)
                {
                    ALSLog(ALLoggerSeverityError, @"Individual: Marking message read error:%@",error);
                }
            }];
        }
    }
}

//==============================================================================================================================================
#pragma mark - NAVIGATIN SETUP FOR IMAGE PICKER
//==============================================================================================================================================

-(void)navigationController:(UINavigationController *)navigationController
                             willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [navigationController.navigationBar setTitleTextAttributes: @{
                                                                  NSForegroundColorAttributeName:[ALApplozicSettings getColorForNavigationItem],
                                                                  NSFontAttributeName:[UIFont fontWithName:@"Helvetica-Bold" size:18]
                                                                  }];
    [navigationController.navigationBar setBarTintColor: [ALApplozicSettings getColorForNavigation]];
    [navigationController.navigationBar setTintColor:[ALApplozicSettings getColorForNavigationItem]];
}

//==============================================================================================================================================
#pragma mark - NO CONVERSATION LABEL HANDLER
//==============================================================================================================================================

-(void)showNoConversationLabel
{
    if(![self.alMessageWrapper getUpdatedMessageArray].count && [ALApplozicSettings getVisibilityNoConversationLabelChatVC])
    {
        [self.noConLabel setText:[ALApplozicSettings getEmptyConversationText]];
        [self.noConLabel setHidden:NO];

        return;
    }
    [self.noConLabel setHidden:YES];
}

//==============================================================================================================================================
#pragma mark - PHONE CALL HANDLER
//==============================================================================================================================================

-(void)phoneCallMethod
{
    [self makeCallContact];
}

-(void)makeCallContact
{
    NSURL * phoneNumber = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", self.alContact.contactNumber]];
    [[UIApplication sharedApplication] openURL:phoneNumber];
}

//==============================================================================================================================================
#pragma mark - CALL BUTTON HANDLER
//==============================================================================================================================================

-(void)setCallButtonInNavigationBar
{
    ALContactDBService * contactDB = [ALContactDBService new];
    self.alContact = [contactDB loadContactByKey:@"userId" value:self.contactIds];

    [self.navRightBarButtonItems removeObject:self.callButton];

    if(self.contactIds && !self.channelKey)
    {
        if(self.alContact.contactNumber && [ALApplozicSettings getCallOption])
        {
            [self.navRightBarButtonItems addObject:self.callButton];
        }


    }

    self.navigationItem.rightBarButtonItems = [self.navRightBarButtonItems mutableCopy];
}

-(void)updateChannelName
{
    if(self.channelKey)
    {
        [self setButtonTitle];
        [self channelDeleted];
    }
}

-(void)appEntersForeground:(id)notification
{
// Updating Last Seen via Server Call
    [self serverCallForLastSeen];
    self.comingFromBackground = YES;
    [self subscrbingChannel];
    [self markConversationRead];
    [self loadMessagesForOpenChannel];
}

-(void)loadMessagesForOpenChannel
{
    // WHEN APP ENTERS FOREGROUND SYNC CHANNEL MSGS (CHANNEL_TYPE = OPEN) AND LOGIN USER ISN'T A MEMEBER OF CHANNEL
    ALChannelService *channelService = [[ALChannelService alloc] init];
    self.alChannel = [channelService getChannelByKey:self.channelKey];
    if(self.alChannel.type == OPEN)
    {
        //FOR SYNC MESSAGES SEND LATEST MSG TIME STAMP
        MessageListRequest * messageListRequest = [MessageListRequest new];
        messageListRequest.channelKey = self.channelKey;

        ALMessage *lastMsg = (ALMessage *)[[self.alMessageWrapper getUpdatedMessageArray] lastObject];
        double doubleTime = ceil(lastMsg.createdAtTime.doubleValue);
        NSNumber *lastMsgTime = [NSNumber numberWithDouble:doubleTime];
        messageListRequest.startTimeStamp = lastMsgTime;

        [[ALMessageService sharedInstance] getMessageListForUser:messageListRequest withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {

            if(messages.count)
            {
                dispatch_async(dispatch_get_main_queue(), ^{

                    NSMutableArray *msgArray = [[NSMutableArray alloc] initWithArray:messages];
                    for(ALMessage *msg in messages)
                    {
                        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"key=%@",msg.key];
                        NSArray *filterArray = [[self.alMessageWrapper getUpdatedMessageArray] filteredArrayUsingPredicate:predicate];
                        if(filterArray.count)
                        {
                            [msgArray removeObject:msg];
                        }
                    }

                    [self addMessageToList:msgArray];
                });
            }
        }];
    }
}

//====================================================================================================================================
#pragma mark MQTT SUBSCRIBING CHANNEL : METHODS
//====================================================================================================================================

-(void)updateChannelSubscribing:(NSNumber *)oldChannelKey andNewChannel:(NSNumber *)newChannelKey
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.mqttObject unSubscribeToChannelConversation:oldChannelKey];
        [self.mqttObject subscribeToChannelConversation:newChannelKey];
    });
}

-(void)subscrbingChannel
{
    ALChannelService * alChannelService  = [[ALChannelService alloc] init];

    ALChannel *alChannel = [alChannelService getChannelByKey:self.channelKey];
    if(alChannel && alChannel.type == OPEN){
        [self.mqttObject subscribeToOpenChannel:self.channelKey];
    }

    if(![alChannelService isChannelLeft:self.channelKey] && ![ALChannelService isChannelDeleted:self.channelKey])
    {
        [self.mqttObject subscribeToChannelConversation:self.channelKey];
    }

    if([self isGroup] && [ALUserDefaultsHandler isUserLoggedInUserSubscribedMQTT])
    {
        [self.mqttObject unSubscribeToChannelConversation:nil];
    }
}



-(void)unSubscrbingChannel
{
    [self.mqttObject sendTypingStatus:[ALUserDefaultsHandler getApplicationKey]
                               userID:self.contactIds
                        andChannelKey:self.channelKey
                               typing:NO];
    if(self.channelKey){
        [self.mqttObject unSubscribeToChannelConversation:self.channelKey];
        [self.mqttObject unSubscribeToOpenChannel:self.channelKey];
    }

}

-(void)didEnterBackGround
{
    self.comingFromBackground = NO;
    [self unSubscrbingChannel];
}

//====================================================================================================================================
#pragma mark UPDATING OFFLINE MESSAGES
//====================================================================================================================================

-(void)updateMessageSendStatus:(NSNotification *)notification
{
    ALMessage *nfALmessage = (ALMessage *)notification.object;

    if(!nfALmessage.key)
    {
        return;
    }

    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"key=%@",nfALmessage.key];
    NSArray *proccessfilterArray = [[self.alMessageWrapper getUpdatedMessageArray] filteredArrayUsingPredicate:predicate];
    if(proccessfilterArray.count)
    {
        ALMessage *msg = [proccessfilterArray objectAtIndex:0];
        msg.sentToServer = YES;
    }
    [self reloadView];
    //    [self updateReportOfkeyString:notification.object reportStatus:SENT];

}

//==============================================================================================================================================
#pragma mark - CHECK VIEW IF RELOAD REQUIRE
//==============================================================================================================================================

-(BOOL)isReloadRequired
{
    if(self.refresh || [self.alMessageWrapper getUpdatedMessageArray].count == 0) // if refresh then obviously refresh!!
        return YES;

    BOOL noContactIdMatch = !([[[self.alMessageWrapper getUpdatedMessageArray][0] contactIds]  isEqualToString:self.contactIds]);

    NSNumber * currentChannelKey = self.channelKey ? self.channelKey : [NSNumber numberWithInt:0];

    NSNumber * tempChannelKey = [[self.alMessageWrapper getUpdatedMessageArray][0] groupId];

    NSNumber * actualChannelKey = tempChannelKey ? tempChannelKey : [NSNumber numberWithInt:0];

    BOOL noGroupIdMatch = !([actualChannelKey isEqualToNumber:currentChannelKey]);

//    BOOL noGroupIdMatch = !([[[self.alMessageWrapper getUpdatedMessageArray][0] groupId] isEqualToNumber:self.channelKey]);

    if(noGroupIdMatch){  // No group match return YES without doubt!
        return YES;
    }
    else if (self.channelKey==nil && noContactIdMatch){  // key is nil and incoming Contact don't match!
        return YES;
    }
    else
    {
        return NO; // group match or incoming contact match then no refresh
    }
}

-(void)checkUserBlockStatus
{
    ALContactDBService *dbservice = [ALContactDBService new];
    ALContact *contact = [dbservice loadContactByKey:@"userId" value:self.contactIds];
    self.isUserBlocked = contact.block;
    self.isUserBlockedBy = contact.blockBy;
    [self.label setHidden:NO];

    ALSLog(ALLoggerSeverityInfo, @"USER_STATE BLOCKED : %i AND BLOCKED BY : %i", contact.block, contact.blockBy);
    ALSLog(ALLoggerSeverityInfo, @"USER : %@", contact.userId);
    if((contact.blockBy || contact.block) && (self.alChannel.type == GROUP_OF_TWO || !self.channelKey))
    {
        [self.label setHidden:YES];
    }
}

-(void)checkUserDeleted
{
    ALContactService *cnService = [[ALContactService alloc] init];
    BOOL isUserDeleted = [cnService isUserDeleted:self.contactIds];
    [self freezeView:isUserDeleted];
    [self.label setHidden:isUserDeleted];
    if (isUserDeleted)
    {
        [ALNotificationView showLocalNotification:[ALApplozicSettings getUserDeletedText]];
    }
}

//==============================================================================================================================================
#pragma mark - USER BLOCK ALERT HANDLER
//==============================================================================================================================================
-(void)showBlockedAlert
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedStringWithDefaultValue(@"oppsText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"OOPS !!!", @"")
                                 message:
                                 NSLocalizedStringWithDefaultValue(@"userBlockedInfo", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"THIS USER IS BLOCKED BY YOU", @"")
                                 preferredStyle:UIAlertControllerStyleAlert];

    [ALUtilityClass setAlertControllerFrame:alert andViewController:self];

    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:
                         NSLocalizedStringWithDefaultValue(@"okText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Ok", @"")
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [self.sendMessageTextView setText:@""];
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];

    UIAlertAction* unblock = [UIAlertAction
                              actionWithTitle:NSLocalizedStringWithDefaultValue(@"unBlock", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"UNBLOCK", @"")
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  if(![ALDataNetworkConnection checkDataNetworkAvailable])
                                  {
                                      [self showNoDataNotification];
                                      return;
                                  }
                                  ALUserService *userService = [ALUserService new];
                                  [userService unblockUser:self.contactIds withCompletionHandler:^(NSError *error, BOOL userBlock) {

                                      if(userBlock)
                                      {

                                          self.isUserBlocked = NO;
                                          [self.label setHidden:self.isUserBlocked];

                                          NSString * unblokInfo = NSLocalizedStringWithDefaultValue(@"blockedSusccessFullyInfo", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"%@ is unblocked successfully", @"");

                                          NSString *alertText = [NSString stringWithFormat:unblokInfo,[self.alContact getDisplayName]] ;

                                          [alertText stringByAppendingString:unblokInfo];

                                          [ALUtilityClass showAlertMessage:alertText andTitle:   NSLocalizedStringWithDefaultValue(@"userUnBlock", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"USER UNBLOCK", @"")];
                                      }

                                  }];
                              }];

    [alert addAction:ok];
    if (![ALApplozicSettings isUnblockInChatDisabled]) {
        [alert addAction:unblock];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)checkIfChannelLeft
{
    [self.navRightBarButtonItems removeObject:self.closeButton];

    ALChannelService * alChannelService = [[ALChannelService alloc] init];
    if([alChannelService isChannelLeft:self.channelKey])
    {
        [self freezeView:YES];
        ALNotificationView * notification = [[ALNotificationView alloc] init];
        [notification showGroupLeftMessage];
    }
    else if ([ALChannelService isChannelDeleted:self.channelKey])
    {
        [self freezeView:YES];
        [ALNotificationView showLocalNotification:[ALApplozicSettings getGroupDeletedTitle]];
    }else if([ALChannelService isConversationClosed:self.channelKey]){
        [self freezeView:YES];
    }
    else
    {
        if(!self.contactIds && self.channelKey && [ALApplozicSettings isConversationCloseButtonEnabled]){
            [self.navRightBarButtonItems addObject:self.closeButton];
        }

        [self freezeView:NO];
    }

    if(self.alChannel.metadata != nil && [[self.alChannel.metadata valueForKey:@"AL_ADMIN_BROADCAST"] isEqualToString:@"true"] && ![[self.alChannel.metadata  valueForKey:@"AL_ADMIN_USERID"] isEqualToString:[ALUserDefaultsHandler getUserId]]){
        self.typingMessageView.hidden = YES;
    }else{
        self.typingMessageView.hidden = NO;
    }
}

//==============================================================================================================================================
#pragma mark FREEZE VIEW HANDLER USED FOR USER BLOCK
//==============================================================================================================================================

-(void)freezeView:(BOOL)freeze
{
    [self.sendMessageTextView setUserInteractionEnabled:!freeze];
    [self.sendButton setUserInteractionEnabled:!freeze];
    [self.attachmentOutlet setUserInteractionEnabled:!freeze];
    [self.navigationController.navigationItem.titleView setUserInteractionEnabled:!freeze];
}

-(void)showNoDataNotification
{
    ALNotificationView * notification = [ALNotificationView new];
    [notification noDataConnectionNotificationView];
}

-(void)closeConversation {

    if(self.channelKey && !self.contactIds){

        [ALChannelService closeGroupConverstion : self.channelKey withCompletion:^(NSError *error){

            if(!error){

                [self.navRightBarButtonItems removeObject:self.closeButton];
                self.navigationItem.rightBarButtonItems = [self.navRightBarButtonItems mutableCopy];
                [self freezeView:YES];
            }
        }];

    }

}

//==============================================================================================================================================
#pragma mark - SetUp/Theming
//==============================================================================================================================================

-(void)initialSetUp
{
    self.rp = 200;
    self.startIndex = 0;
    self.alMessageWrapper = [[ALMessageArrayWrapper alloc] init];
    self.mImagePicker = [[UIImagePickerController alloc] init];
    self.mImagePicker.delegate = self;

    [self.mTableView registerClass:[ALChatCell class] forCellReuseIdentifier:@"ChatCell"];
    [self.mTableView registerClass:[ALImageCell class] forCellReuseIdentifier:@"ImageCell"];
    [self.mTableView registerClass:[ALLinkCell class] forCellReuseIdentifier:@"ALLinkCell"];

    [self.mTableView registerClass:[ALAudioCell class] forCellReuseIdentifier:@"AudioCell"];
    [self.mTableView registerClass:[ALVideoCell class] forCellReuseIdentifier:@"VideoCell"];
    [self.mTableView registerClass:[ALDocumentsCell class] forCellReuseIdentifier:@"DocumentsCell"];
    [self.mTableView registerClass:[ALContactMessageCell class] forCellReuseIdentifier:@"ContactMessageCell"];
    [self.mTableView registerClass:[ALLocationCell class] forCellReuseIdentifier:@"LocationCell"];
    [self.mTableView registerClass:[ALCustomCell class] forCellReuseIdentifier:@"CustomCell"];
    [self.mTableView registerClass:[ALVOIPCell class] forCellReuseIdentifier:@"VOIPCell"];
    [self.mTableView registerClass:[ALChannelMsgCell class] forCellReuseIdentifier:@"ALChannelMsgCell"];

    [self.mTableView registerClass:[ALMyContactMessageCell class] forCellReuseIdentifier:@"MyContactMessageCell"];

    if([ALApplozicSettings getContextualChatOption])
    {
        self.pickerView.delegate = self;
        self.pickerView.dataSource = self;
//        self.pickerView.frame = CGRectMake(0, 40,[UIScreen mainScreen].bounds.size.width, 216);
    }

    defaultTableRect = self.mTableView.frame;
}

//==============================================================================================================================================
#pragma mark - PICKER VIEW METHOD
//==============================================================================================================================================

-(void)setupPickerView
{
    self.pickerConvIdsArray = [[NSMutableArray alloc] init];
    ALConversationService * alconversationService = [[ALConversationService alloc] init];
    NSMutableArray * conversationList;

    if(self.channelKey)
    {
        conversationList = [NSMutableArray arrayWithArray:[alconversationService
                                                    getConversationProxyListForChannelKey:self.channelKey]];
    }
    else
    {
        conversationList = [NSMutableArray arrayWithArray:[alconversationService
                                                    getConversationProxyListForUserID:self.contactIds]];
    }

    self.conversationTitleList = [[NSMutableArray alloc] init];

    if(conversationList.count == 0)
    {
        ALSLog(ALLoggerSeverityInfo, @"No conversation list ");
        return;
    }

    for(ALConversationProxy * conversation in conversationList)
    {
        ALTopicDetail * topicDetail = [[ALTopicDetail alloc] init];   //WithDictonary:conversation.topicDetailJson];
        topicDetail = conversation.getTopicDetail;

            if(conversation.getTopicDetail != nil && topicDetail.title != nil)
            {
                [self.conversationTitleList addObject:topicDetail.title];
                [self.pickerConvIdsArray addObject:conversation.Id];
            }
            else
            {
                ALSLog(ALLoggerSeverityError, @"<< ERROR: Topic Detail NILL >>");
            }
    }

    [self.pickerView setHidden:YES];
    self.pickerDataSourceArray = [NSArray arrayWithArray:self.conversationTitleList];

}

//==============================================================================================================================================
#pragma mark - NAVIGATION TITLE BUTTON METHODS
//==============================================================================================================================================

-(void) setTitle
{
    if(self.displayName)
    {
        ALContactService * contactService = [[ALContactService alloc] init];
        self.alContact = [contactService loadOrAddContactByKeyWithDisplayName:self.contactIds value: self.displayName];
    }
    else
    {
        ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
        self.alContact = [theDBHandler loadContactByKey:@"userId" value:self.contactIds];
    }

    titleLabelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    titleLabelButton.frame = CGRectMake(0, 0, 70, 44);
    [titleLabelButton addTarget:self action:@selector(didTapTitleView:) forControlEvents:UIControlEventTouchUpInside];
    titleLabelButton.userInteractionEnabled = YES;
    [titleLabelButton setTitleColor:[ALApplozicSettings getColorForNavigationItem] forState:UIControlStateNormal];

//    if(!(self.individualLaunch) || [ALUserDefaultsHandler isServerCallDoneForUserInfoForContact:[self.alContact userId]])
//    {
        [titleLabelButton setTitle:[self.alContact getDisplayName] forState:UIControlStateNormal];
//    }

    if([self isGroup])
    {
        [self setButtonTitle];
    }

    self.navigationItem.titleView = titleLabelButton;

    CGFloat COORDINATE_POINT_Y = titleLabelButton.frame.size.height - 17;
    [self.label setFrame: CGRectMake(0, COORDINATE_POINT_Y ,self.navigationController.navigationBar.frame.size.width, 20)];

    ALUserDetail *userDetail = [[ALUserDetail alloc] init];
    userDetail.connected = self.alContact.connected;
    userDetail.userId = self.alContact.userId;
    userDetail.lastSeenAtTime = self.alContact.lastSeenAt;
    userDetail.contactNumber = self.alContact.contactNumber;

    [self updateLastSeenAtStatus:userDetail];
}

-(void)channelDeleted
{
    if ([ALChannelService isChannelDeleted:self.channelKey])
    {
        [self freezeView:YES];
        [ALNotificationView showLocalNotification:[ALApplozicSettings getGroupDeletedTitle]];
    }
}

-(void)setButtonTitle
{
    ALChannelService *channelService = [[ALChannelService alloc] init];
    self.alChannel = [channelService getChannelByKey:self.channelKey];
    [titleLabelButton setTitle:self.alChannel.name forState:UIControlStateNormal];
    if([self.alChannel isConversationClosed]){
      [self freezeView:YES];
    }
    if(self.alChannel.type == GROUP_OF_TWO)
    {
        ALSLog(ALLoggerSeverityInfo, @"CURENT clientChannelKey :: %@",self.alChannel.clientChannelKey);
        ALContactService * contactService = [ALContactService new];
        self.alContact = [contactService loadContactByKey:@"userId" value:[self.alChannel getReceiverIdInGroupOfTwo]];
        [titleLabelButton setTitle:[self.alContact getDisplayName] forState:UIControlStateNormal];
    }
}

-(void)didTapTitleView:(id)sender
{
    if(self.contactIds && !self.channelKey)
    {
        [self getUserInformation];
    }
    else if (![ALApplozicSettings isGroupInfoDisabled] && (self.alChannel.type != GROUP_OF_TWO) && ![ALChannelService isChannelDeleted:self.channelKey] && ![ALChannelService isConversationClosed:self.channelKey])
    {
        if ([ALApplozicSettings getOptionToPushNotificationToShowCustomGroupDetalVC]) {

            [[NSNotificationCenter defaultCenter] postNotificationName:ThirdPartyDetailVCNotification object:nil userInfo:@{ThirdPartyDetailVCNotificationNavigationVC : self.navigationController,
                                                                                                                            ThirdPartyDetailVCNotificationChannelKey : self.channelKey
                                                                                                                            }];
        } else {

            UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:[self class]]];
            ALGroupDetailViewController * groupDetailViewController = (ALGroupDetailViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ALGroupDetailViewController"];
            groupDetailViewController.channelKeyID = self.channelKey;
            groupDetailViewController.alChatViewController = self;

            if([ALApplozicSettings isContactsGroupEnabled] && _contactsGroupId){
                [ALApplozicSettings setContactsGroupId:_contactsGroupId];
            }

            [self.navigationController pushViewController:groupDetailViewController animated:YES];
        }
    }
}

-(void)fetchMessageFromDB
{
    ALSLog(ALLoggerSeverityInfo, @"fetchMessageFromDB  called:: ");
    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate* predicate1;
    if(self.conversationId && [ALApplozicSettings getContextualChatOption])
    {
        predicate1 = [NSPredicate predicateWithFormat:@"conversationId = %d", [self.conversationId intValue]];

    }
    else if(self.isGroup)
    {
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %d", [self.channelKey intValue]];
    }
    else
    {
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil", self.contactIds];
    }

    NSPredicate* predicate2 = [NSPredicate predicateWithFormat:@"contentType != %i AND msgHidden == %@",ALMESSAGE_CONTENT_HIDDEN,@(NO)];
    NSPredicate* compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
    [theRequest setPredicate:compoundPredicate];

    self.mTotalCount = [theDbHandler.managedObjectContext countForFetchRequest:theRequest error:nil];
}

//This is just a test method
-(void)refreshTable:(id)sender
{
    if ([ALChannelService isChannelDeleted:self.channelKey])
    {
        return;
    }

    [self.sendMessageTextView resignFirstResponder];
    [self.view makeToast:
     NSLocalizedStringWithDefaultValue(@"syncMessagesInfo", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],@"Syncing messages with the server,\n it might take few mins!"
                                       , @"")  duration:1.0
                position:CSToastPositionBottom
                   title:nil];

    //TODO: get the user name, devicekey String and make server call...
    [self.mActivityIndicator startAnimating];
    [self fetchAndRefresh:YES];
    [self.mActivityIndicator stopAnimating];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)handleMessageForward:(ALMessage* )almessage{

    ALMessage * message = [self getMessageToPost];
    message.message  = almessage.message;
    message.metadata = almessage.metadata;
    message.fileMeta = almessage.fileMeta;
    message.imageFilePath = almessage.imageFilePath;
    message.fileMetaKey = almessage.fileMetaKey;
    message.contentType = almessage.contentType;

    if( message.imageFilePath ){
        [self processAttachment:message.imageFilePath andMessageText:message.message andContentType:almessage.contentType];
        self.alMessage=nil;
        [self showNoConversationLabel];
        return;
    }
    //SEND MESSAGE
    [[self.alMessageWrapper getUpdatedMessageArray] addObject:message];
    [self showNoConversationLabel];
    [self sendMessage:message];
    [self.mTableView reloadData];       //RELOAD MANUALLY SINCE NO NETWORK ERROR
    [self setRefreshMainView:TRUE];
    [self scrollTableViewToBottomWithAnimation:YES];
    self.alMessage=nil;
}


-(void)handleMessageForwardForChatView:(ALMessage* )almessage{

    ALMessage * message = [self getMessageToPost];
    message.message  = almessage.message;
    message.metadata = almessage.metadata;
    message.fileMeta = almessage.fileMeta;
    message.imageFilePath = almessage.imageFilePath;
    message.fileMetaKey = almessage.fileMetaKey;
    message.contentType = almessage.contentType;
    message.groupId = almessage.groupId;
    message.contactIds = almessage.contactIds;
    message.to = almessage.contactIds;
    message.sentToServer = FALSE;
    message.status = @1;

    if(message.isAReplyMessage){
        message.metadata = nil;
    }

    if( message.imageFilePath ){
        [self processAttachment:message.imageFilePath andMessageText:message.message andContentType:almessage.contentType];
        self.alMessage=nil;
        [self showNoConversationLabel];
        return;
    }
    //SEND MESSAGE
    [self.alMessageWrapper addALMessageToMessageArray:message];
    [self showNoConversationLabel];
    self.mTotalCount = self.mTotalCount+1;
    self.startIndex = self.startIndex + 1;

    [self sendMessage:message messageAtIndex: [[self.alMessageWrapper getUpdatedMessageArray] count]];


    [self.mTableView reloadData];       //RELOAD MANUALLY SINCE NO NETWORK ERROR
    [self setRefreshMainView:TRUE];
    [self scrollTableViewToBottomWithAnimation:YES];
    self.alMessage=nil;}


//==============================================================================================================================================
#pragma mark - ALMapViewController Delegate Methods
#pragma mark - ONLINE Location Message Sending
//==============================================================================================================================================

-(void)sendGoogleMap:(NSString *)latLongString withCompletion:(void(^)(NSString *message, NSError *error))completion
{
    if (latLongString.length != 0)
    {
        ALMessage * locationMessage = [self formLocationMessage:latLongString];
        [self sendLocationMessage:locationMessage withCompletion:^(NSString *message, NSError *error) {

            if(!error)
            {
                [self.alMessageWrapper addALMessageToMessageArray:locationMessage];
                [self.mTableView reloadData];
                [self scrollTableViewToBottomWithAnimation:YES];
                completion(message,error);
            }
        }];
    }
    else
    {
       [self googleLocationErrorAlert];
    }
}

-(void)sendLocationMessage:(ALMessage *)theMessage withCompletion:(void(^)(NSString *message, NSError *error))completion
{
    [[ALMessageService sharedInstance] sendMessages:theMessage withCompletion:^(NSString *message, NSError *error) {

        if(error)
        {
            ALSLog(ALLoggerSeverityError, @"SEND_MSG_ERROR :: %@", error.description);
            [[ALMessageService sharedInstance] handleMessageFailedStatus:theMessage];
            return;
        }
        completion(message, error);
        [self.mTableView reloadData];
        [self setRefreshMainView:TRUE];
    }];
}

//==============================================================================================================================================
#pragma OFFLINE Location Message Sending
//==============================================================================================================================================

-(void)sendGoogleMapOffline:(NSString*)latLongString
{
    if (latLongString.length != 0)
    {
        ALMessage * locationMessage = [self formLocationMessage:latLongString];
        [[self.alMessageWrapper getUpdatedMessageArray] addObject:locationMessage];
        [self sendMessage:locationMessage];
        [self.mTableView reloadData];       //RELOAD MANUALLY SINCE NO NETWORK ERROR
        [self setRefreshMainView:TRUE];
        [self scrollTableViewToBottomWithAnimation:YES];
    }
    else
    {
        [self googleLocationErrorAlert];
    }
}

//==============================================================================================================================================
#pragma mark - LOCATION MESSAGE FORMING METHOD
//==============================================================================================================================================

-(ALMessage *)formLocationMessage:(NSString*)latLongString
{
    ALMessage * theMessage = [self getMessageToPost];
    theMessage.contentType = ALMESSAGE_CONTENT_LOCATION;
    theMessage.message = latLongString;
    [self.sendMessageTextView setText:nil];
    self.mTotalCount = self.mTotalCount+1;
    self.startIndex = self.startIndex + 1;

    return theMessage;
}

//==============================================================================================================================================
#pragma mark - Location Fetch Error
//==============================================================================================================================================

-(void)googleLocationErrorAlert
{
    ALSLog(ALLoggerSeverityInfo, @"Google Map Length = ZERO");
    NSString * alertMsg = @"Unable to fetch current location. Try Again!!!";
    [ALUtilityClass showAlertMessage:alertMsg andTitle:@"Current Location"];
}

//==============================================================================================================================================
#pragma mark - UIMenuController Actions
//==============================================================================================================================================

//-(BOOL) canPerformAction:(SEL)action withSender:(id)sender {
//    return (action == @selector(copy:) || action == @selector(deleteAction:));
//}

// Default copy method
//- (void)copy:(id)sender {
//
//    NSLog(@"Copy in ALChatViewController, messageId: %@", messageId);
//    ALMessage * alMessage =  [self getMessageFromViewList:@"key" withValue:messageId ];
//
//    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
//    /*UITableViewCell *cell = [self.mTableView cellForRowAtIndexPath:self.indexPathofSelection];*/
//    if(alMessage.message!=NULL){
//
//    //[pasteBoard setString:cell.textLabel.text];
//    [pasteBoard setString:alMessage.message];
//    }
//    else{
//    [pasteBoard setString:@""];
//    }
//}
//
//
//-(void)deleteAction:(id)sender{
//    NSLog(@"Delete Menu item Pressed in AlChatViewController");
//    [ALMessageService deleteMessage:messageId andContactId:self.contactIds withCompletion:^(NSString* string,NSError* error){
//        if(!error ){
//            NSLog(@"No Error");
//        }
//        else{
//            NSLog(@"some error");
//        }
//    }];
//
//    [self.mMessageListArray removeObjectAtIndex:self.indexPathofSelection.row];
//    [UIView animateWithDuration:1.5 animations:^{
//        //      [self loadChatView];
//        [self.mTableView reloadData];
//    }];
//
//
//
//}

//==============================================================================================================================================
#pragma mark - CHECK ABUSE TEXT IN SEND MESSAGE
//==============================================================================================================================================

-(BOOL)checkRestrictWords:(NSString *)msgText
{
    NSString * actualMsg = [msgText lowercaseString];
    NSArray * msgParts = [actualMsg componentsSeparatedByString:@" "];

    for(NSString *tempWord in self.wordArray)
    {
        __strong NSString *word = [tempWord stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

        word = [word lowercaseString];

        if((msgParts.count && [msgParts containsObject:word]))
        {
            return YES;
        }
    }
    return NO;
}

//==============================================================================================================================================
#pragma mark - SEND MESSAGE ACTION
//==============================================================================================================================================

-(void)postMessage
{

    if(isMicButtonVisible) {
        return;
    }

    if(self.isUserBlocked)
    {
        [self showBlockedAlert];
        return;
    }

    if (!self.sendMessageTextView.text.length || [self.sendMessageTextView.text isEqualToString:self.placeHolderTxt])
    {
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"forgetToTypeMessageInfo", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Did you forget to type the message", @"")  andTitle:NSLocalizedStringWithDefaultValue(@"emptyText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Empty", @"")];
        return;
    }

    if([ALApplozicSettings getMessageAbuseMode] && [self checkRestrictWords:self.sendMessageTextView.text])
    {
        [ALUtilityClass showAlertMessage:[ALApplozicSettings getAbuseWarningText] andTitle:NSLocalizedStringWithDefaultValue(@"warningText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"WARNING", @"")];
        return;
    }


    if(self.channelKey){
        ALChannelDBService * channelDBService = [[ALChannelDBService alloc] init];

        ALChannel *channel = [channelDBService loadChannelByKey:self.channelKey];
        if(channel && channel.type == OPEN){

            if (![ALDataNetworkConnection checkDataNetworkAvailable])
            {
                [ALUtilityClass showAlertMessage:nil andTitle:NSLocalizedStringWithDefaultValue(@"noInternetMessage", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"No Internet Connectivity", @"")];

                return;
            }
        }

    }

    ALMessage * theMessage = [self getMessageToPost];
    [self.alMessageWrapper addALMessageToMessageArray:theMessage];
    [self.mTableView reloadData];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollTableViewToBottomWithAnimation:YES];
    });
    // save message to db
    [self showNoConversationLabel];
    [self.sendMessageTextView setText:nil];
    self.mTotalCount = self.mTotalCount + 1;
    self.startIndex = self.startIndex + 1;
    [self sendMessage:theMessage];

    if(isAudioRecordingEnabled) {
        [self showMicButton];
    }

    if(typingStat == YES)
    {
        typingStat = NO;
        [self.mqttObject sendTypingStatus:self.alContact.applicationId userID:self.contactIds
                            andChannelKey:self.channelKey typing:typingStat];
    }
}

- (IBAction)sendAction:(id)sender
{
    if(isMicButtonVisible) {
        [soundRecording show];
    }
    [super sendAction:sender];
}

-(void)setUpSoundRecordingView
{
    if (isNewAudioDesignEnabled) {
        soundRecordingView = [[ALAudioRecorderView alloc] initWithFrame:CGRectZero];
        [soundRecordingView setAudioRecViewDelegateWithRecorderDelegate:self];
        [self.view addSubview: soundRecordingView];
        [soundRecordingView setHidden:YES];
        soundRecordingView.translatesAutoresizingMaskIntoConstraints = false;
        [soundRecordingView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = true;
        [soundRecordingView.trailingAnchor constraintEqualToAnchor:self.sendMessageTextView.trailingAnchor].active = true;
        [soundRecordingView.topAnchor constraintEqualToAnchor:self.sendMessageTextView.topAnchor].active = true;
        [soundRecordingView.bottomAnchor constraintEqualToAnchor:self.sendMessageTextView.bottomAnchor].active = true;
    }else {
        soundRecording = [[ALSoundRecorderButton alloc] initWithFrame:CGRectZero];
        [soundRecording setSoundRecDelegateWithRecorderDelegate:self];
        [self.view addSubview:soundRecording];
        [soundRecording setHidden:YES];
        soundRecording.translatesAutoresizingMaskIntoConstraints = false;
        [soundRecording.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:7].active = true;
        [soundRecording.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-7].active = true;
        [soundRecording.topAnchor constraintEqualToAnchor:self.sendMessageTextView.topAnchor constant:-5].active = true;
        [soundRecording.bottomAnchor constraintEqualToAnchor:self.sendMessageTextView.bottomAnchor constant:5].active = true;
    }
}

-(void)setUpTeamplateView
{

    __weak typeof(self) weakSelf = self;
    NSMutableDictionary *data =  [ALApplozicSettings getTemplateMessages];
    NSMutableArray<ALTemplateMessageModel *> * messageTemplate = [[NSMutableArray alloc] init];
    NSArray *keys = [data allKeys];

    for (NSString* key in keys) {
        NSString *value = [data objectForKey:key];
        ALTemplateMessageModel* messageModel = [ALTemplateMessageModel alloc] ;
        messageModel.text = key;
        messageModel.identifier = value;
        [messageTemplate addObject:messageModel];
    }

    NSArray<ALTemplateMessageModel *> *array = [[NSArray alloc]initWithArray:messageTemplate];

    ALTemplateMessagesViewModel *model = [[ALTemplateMessagesViewModel alloc] initWithMessageTemplates:(array)];

    templateMessageView = [[ALTemplateMessagesView alloc]initWithFrame:CGRectZero viewModel:model];
    [self.view addSubview:templateMessageView ];
    templateMessageView.messageSelected = ^(NSString * vlaue) {
        [weakSelf processSendTemplateMessage:vlaue];
    };
    [templateMessageView setHidden:NO];
    [templateMessageView setUserInteractionEnabled:YES];
    templateMessageView.translatesAutoresizingMaskIntoConstraints = false;
    [templateMessageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:7].active = true;
    [templateMessageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-7].active = true;
    [templateMessageView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant: -10.0].active = true;
    [templateMessageView.heightAnchor constraintEqualToConstant:40].active = YES;
    [templateMessageView .bottomAnchor constraintEqualToAnchor:self.sendMessageTextView.topAnchor constant:-10].active = true;
    self.tableViewViewBottomConstraint.constant = 40;

}

-(void)showMicButton
{
    if(isNewAudioDesignEnabled){
        micButton = [[ALAudioRecordButton alloc] initWithFrame: CGRectZero];
        [micButton setAudioRecDelegateWithRecorderDelegate:self];
        [self.view addSubview: micButton];
        [micButton setHidden:NO];
        micButton.translatesAutoresizingMaskIntoConstraints = false;
        [micButton.leadingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor].active = true;
        [micButton.trailingAnchor constraintEqualToAnchor:self.sendButton.trailingAnchor].active = true;
        [micButton.topAnchor constraintEqualToAnchor:self.sendButton.topAnchor].active = true;
        [micButton.bottomAnchor constraintEqualToAnchor:self.sendButton.bottomAnchor].active = true;
        [self.sendButton setHidden: YES];
        isMicButtonVisible = YES;
    }else {
        UIImage* micImage = [ALUtilityClass getImageFromFramworkBundle:@"mic_icon.png"];
        [self.sendButton setImage:micImage forState:UIControlStateNormal];
        isMicButtonVisible = YES;
    }
}

-(void)showSoundRecordingView
{
    if(isNewAudioDesignEnabled) {
        [soundRecordingView setHidden: NO];
    }else {
        [soundRecording show];
    }
}

-(void)hideSoundRecordingView
{
    if(isNewAudioDesignEnabled) {
        [soundRecordingView setHidden: YES];
    }else {
        [soundRecording hide];
    }
}

-(void)showSendButton
{
    if(@available(ios 9.0, *)) {
        [micButton setHidden: YES];
        [self.sendButton setHidden: NO];
    }
    UIImage* sendImage = [ALUtilityClass getImageFromFramworkBundle:@"SendButton20.png"];
    [self.sendButton setImage:sendImage forState:UIControlStateNormal];
    isMicButtonVisible = NO;
}

//==============================================================================================================================================
#pragma mark - BROADCAST MESSAGE PROCESS
//==============================================================================================================================================

-(void)addBroadcastMessageToDB:(ALMessage *)alMessage {
    [ALMessageService addBroadcastMessageToDB:alMessage];
}

//==============================================================================================================================================
#pragma mark - TableView Datasource
//==============================================================================================================================================

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.alMessageWrapper getUpdatedMessageArray].count > 0 ? [self.alMessageWrapper getUpdatedMessageArray].count : 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    ALMessage * theMessage = [self.alMessageWrapper getUpdatedMessageArray][indexPath.row];

    if(theMessage.contentType == ALMESSAGE_CONTENT_LOCATION)
    {
        ALLocationCell *theCell = (ALLocationCell *)[tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
   else  if(theMessage.isLinkMessage)
    {
        ALLinkCell *theCell = (ALLinkCell *)[tableView dequeueReusableCellWithIdentifier:@"ALLinkCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
    else if([theMessage.fileMeta.contentType hasPrefix:@"image"])
    {
        ALImageCell *theCell = (ALImageCell *)[tableView dequeueReusableCellWithIdentifier:@"ImageCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
    else if ([theMessage.fileMeta.contentType hasPrefix:@"video"])
    {
        ALVideoCell *theCell = (ALVideoCell *)[tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
    else if ([theMessage.fileMeta.contentType hasPrefix:@"audio"])
    {
        ALAudioCell *theCell = (ALAudioCell *)[tableView dequeueReusableCellWithIdentifier:@"AudioCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
    else if (theMessage.contentType == ALMESSAGE_CONTENT_CUSTOM)
    {
        ALCustomCell * theCell = (ALCustomCell *)[tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.colourDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }

    else if (theMessage.contentType == AV_CALL_CONTENT_THREE)
    {
        ALVOIPCell * theCell = (ALVOIPCell *)[tableView dequeueReusableCellWithIdentifier:@"VOIPCell"];
        theCell.colourDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        return theCell;
    }
    else if(theMessage.contentType == ALMESSAGE_CHANNEL_NOTIFICATION)
    {
        ALChannelMsgCell * theCell = (ALChannelMsgCell *)[tableView dequeueReusableCellWithIdentifier:@"ALChannelMsgCell"];
        if ([theMessage isMsgHidden]){
            theCell.frame = CGRectZero;
            return theCell;
        }

        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.colourDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
    else if (theMessage.contentType == ALMESSAGE_CONTENT_DEFAULT)       // textCell
    {
        ALChatCell *theCell = (ALChatCell *)[tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.colourDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;

    }
    else if (theMessage.contentType == ALMESSAGE_CONTENT_VCARD)
    {
        
        if([theMessage isSentMessage]){
            ALMyContactMessageCell *theCell = (ALMyContactMessageCell *)[tableView dequeueReusableCellWithIdentifier:@"MyContactMessageCell"];
            theCell.tag = indexPath.row;
            theCell.delegate = self;
            theCell.channel = self.alChannel;
            theCell.contact = self.alContact;
            theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
            [theCell populateCell:theMessage viewSize:self.view.frame.size];
            [self.view layoutIfNeeded];
            return theCell;
        }else{
            ALContactMessageCell *theCell = (ALContactMessageCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactMessageCell"];
            theCell.tag = indexPath.row;
            theCell.delegate = self;
            theCell.channel = self.alChannel;
            theCell.contact = self.alContact;
            theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
            [theCell populateCell:theMessage viewSize:self.view.frame.size];
            [self.view layoutIfNeeded];
            return theCell;
        }

    }
    else
    {
        ALDocumentsCell *theCell = (ALDocumentsCell *)[tableView dequeueReusableCellWithIdentifier:@"DocumentsCell"];
        theCell.tag = indexPath.row;
        theCell.delegate = self;
        theCell.channel = self.alChannel;
        theCell.contact = self.alContact;
        theCell.alphabetiColorCodesDictionary = self.alphabetiColorCodesDictionary;
        [theCell populateCell:theMessage viewSize:self.view.frame.size];
        [self.view layoutIfNeeded];
        return theCell;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//==============================================================================================================================================
#pragma mark - TABELVIEW DELEGATE
//==============================================================================================================================================

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.sendMessageTextView resignFirstResponder];
    ALMessage *msgCell = self.alMessageWrapper.messageArray[indexPath.row];
    if([msgCell.type isEqualToString:@"100"])
    {
        return  nil;
    }
    else
    {
        return indexPath;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALMessage * theMessage = [self.alMessageWrapper getUpdatedMessageArray][indexPath.row];
    CGFloat cellHeight = [ALUIConstant getCellHeight:theMessage andCellFrame:self.view.frame];
    return cellHeight;
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALMessage *msgCell = self.alMessageWrapper.messageArray[indexPath.row];
    if([msgCell.type isEqualToString:@"100"] || msgCell.contentType ==(short)ALMESSAGE_CHANNEL_NOTIFICATION)
    {
        return  NO;
    }
    else
    {
        return YES;
    }
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
//    // required
//    if (action == @selector(copy:))
//    {
//        NSLog(@"COPY");
//        [self copy:NULL];
//    }
//    if (action == @selector(deleteAction:))
//    {
//        NSLog(@"DELETE ACTION");
//    }
}

+(UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

//==============================================================================================================================================
#pragma mark - Display Header/Footer View
//==============================================================================================================================================

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // For Header's Text View
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.contentView.backgroundColor = [UIColor lightGrayColor];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    ALChannelService * alChannelService = [ALChannelService new];
    ALChannel * alChannel = [alChannelService getChannelByKey:self.channelKey];
    if(self.conversationId && [ALApplozicSettings getContextualChatOption]){
        return self.getHeaderView.frame.size.height;
    }else if(alChannel.metadata !=nil && [alChannel isContextBasedChat]){
        return self.getContextBasedGroupView.frame.size.height;
    } else {
        return 0;
    }
}

//==============================================================================================================================================
#pragma mark -  HEADER VIEW FOR CONTEXT CHAT
//==============================================================================================================================================

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ALChannelService * alChannelService = [ALChannelService new];
    ALChannel * alChannel = [alChannelService getChannelByKey:self.channelKey];
    if(alChannel.metadata!=nil && [alChannel isContextBasedChat]){
        return self.getContextBasedGroupView;
    }else{
        return self.getHeaderView;
    }
}

-(UIView *)getContextBasedGroupView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 84)];

    ALChannelService * alChannelService = [ALChannelService new];

    ALChannel * alChannel = [alChannelService getChannelByKey:self.channelKey];

    // Image View ....
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL * url = [NSURL URLWithString: [alChannel.metadata valueForKey:@"link"]];
    [imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRefreshCached];

    imageView.frame = CGRectMake(5, 5, 70, 70);
    imageView.backgroundColor = [UIColor blackColor];
    [view addSubview:imageView];


    UILabel * priceUILabel = [[UILabel alloc] init];
    priceUILabel.text = [alChannel.metadata valueForKey:@"price"];

    priceUILabel.frame = CGRectMake( imageView.frame.size.width+ 10, imageView.frame.origin.y,
                                    (view.frame.size.width-imageView.frame.size.width)/2, 50);

    UILabel * titleUILabel = [[UILabel alloc] init];
    titleUILabel.text = [alChannel.metadata valueForKey:@"title"];


    titleUILabel.frame = CGRectMake(imageView.frame.size.width + 10, 58,
                                    (view.frame.size.width-imageView.frame.size.width)-20, 50);
    titleUILabel.numberOfLines = 1;
    [self setLabelViews:@[titleUILabel,priceUILabel] onView:view];

    return view;
}

-(UIView *)getHeaderView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 84)];
    ALConversationService * alconversationService = [[ALConversationService alloc]init];
    ALConversationProxy *alConversationProxy = [alconversationService getConversationByKey:self.conversationId];

    ALTopicDetail * topicDetail = [[ALTopicDetail alloc] init];//WithJSONString:alConversationProxy.topicDetailJson];
    topicDetail = alConversationProxy.getTopicDetail;
    if(topicDetail == nil){
        return  [[UIView alloc]init];
    }

    // Image View ....
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL * url = [NSURL URLWithString:topicDetail.link];
    [imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRefreshCached];

    imageView.frame = CGRectMake(5, 27, 50, 50);
    imageView.backgroundColor = [UIColor blackColor];
    [view addSubview:imageView];

    UILabel * topLeft = [[UILabel alloc] init];
    topLeft.text = topicDetail.title;
    topLeft.frame = CGRectMake(imageView.frame.size.width + 10,
                               25, (view.frame.size.width-imageView.frame.size.width)/2, 50);

    UILabel * bottomLeft = [[UILabel alloc] init];
    bottomLeft.text = topicDetail.subtitle;
    bottomLeft.frame = CGRectMake(imageView.frame.size.width + 10, 58,
                                  (view.frame.size.width-imageView.frame.size.width)/2, 50);
    bottomLeft.numberOfLines = 1;
    bottomLeft.preferredMaxLayoutWidth = 8;
    bottomLeft.adjustsFontSizeToFitWidth = YES;

    UILabel* topRight = [[UILabel alloc] init];
    topRight.text = [NSString stringWithFormat:@"%@:%@",topicDetail.key1,topicDetail.value1];
    topRight.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - topLeft.frame.size.width) + 10, 25,
                                [UIScreen mainScreen].bounds.size.width - topLeft.frame.size.width, 50);

    UILabel* bottomRight = [[UILabel alloc] init];
    bottomRight.text = [NSString stringWithFormat:@"%@:%@",topicDetail.key2,topicDetail.value2];
    bottomRight.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - bottomLeft.frame.size.width) + 10, 58,
                                   [UIScreen mainScreen].bounds.size.width - bottomLeft.frame.size.width, 50);

   [self setLabelViews:@[topLeft,bottomLeft,topRight,bottomRight] onView:view];

    if(topicDetail.title != nil)
    {
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showConversationPicker:)];
        [view addGestureRecognizer:singleFingerTap];
    }
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        view.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        topLeft.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        bottomLeft.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        topRight.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        bottomRight.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }

    return view;
}

-(void)setLabelViews:(NSArray*)labelArray onView:(UIView*)view
{
    view.backgroundColor = [ALApplozicSettings getColorForNavigation];
    view.layer.shadowColor = [[UIColor blackColor] CGColor];
    view.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    view.layer.shadowRadius = 3.0f;
    view.layer.shadowOpacity = 1.0f;

    for (UILabel * label in labelArray)
    {
        label.textColor = [ALApplozicSettings getColorForNavigationItem];
        label.font = [UIFont fontWithName:@"Helvetica" size:11.0];
        [self resizeLabels:label];
        [view addSubview:label];
    }
}

-(void)resizeLabels:(UILabel*)label{

//    CGSize maximumLabelSize = CGSizeMake(296, FLT_MAX);
    CGSize expectedLabelSize = [label.text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f]}];
    CGRect newFrame = label.frame;
    newFrame.size.height = expectedLabelSize.height;
    label.frame = newFrame;
}

//==============================================================================================================================================
#pragma mark - Picker View Delegate Datasource
//==============================================================================================================================================

// returns the number of 'columns' to display.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.pickerDataSourceArray.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return self.pickerDataSourceArray[row];
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    switch(component)
    {
        case 0:
            return 200.0f;
        case 1:
            return 20.0f;
    }
    return 0;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:)){
        return [UIPasteboard generalPasteboard].image ? YES : NO;
    }else{
        return [super canPerformAction:action withSender:sender];
    }
}


- (void)paste:(id)sender{

    UIImage  *image = [UIPasteboard generalPasteboard].image;
    if (image)
    {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
            NSString *filePath = [ALImagePickerHandler saveImageToDocDirectory:image];

            dispatch_async(dispatch_get_main_queue(), ^{
                ALImagePreviewController * imageViewController = [[ALImagePreviewController alloc]init];
                imageViewController.imageFilePath = filePath;
                imageViewController.image = image;
                imageViewController.messageKey = self.messageReplyId;
                imageViewController.imageSelectDelegate = self;
                [self.navigationController pushViewController:imageViewController animated:YES];

            });

        });
    } else {
        [super paste:sender];
    }
}


//==============================================================================================================================================
#pragma mark - PickerView Display Method
//==============================================================================================================================================

-(void)showConversationPicker:(UITapGestureRecognizer *)recognizer
{
    isPickerOpen = YES;
    NSNumber *iD= self.conversationId;
    NSInteger anIndex = 0;

    if(self.pickerConvIdsArray.count>0){
     anIndex = [self.pickerConvIdsArray indexOfObject:iD];
    }
    if(NSNotFound == anIndex) {
        ALSLog(ALLoggerSeverityInfo, @"PickerView Index not found %ld",(long)anIndex);
        return;
    }

    [self.pickerView selectRow:anIndex inComponent:0 animated:NO];
    [self setRightNavButtonToDone];
    [self.sendMessageTextView endEditing:YES];

    dispatch_queue_t queue = dispatch_queue_create("animateAndMask", NULL);
    dispatch_sync(queue, ^{

        [UIView animateWithDuration:0.4 animations:^{

            self.tableViewTop2Constraint.constant = self.pickerView.frame.size.height;
            self.mTableView.frame = CGRectMake(0,self.pickerView.frame.size.height,
                                               self->defaultTableRect.size.height,
                                               [UIScreen mainScreen].bounds.size.width);
            [self.view layoutIfNeeded];
            [self.pickerView setHidden:NO];

        }];
        [self disableRestView];
    });
}

//==============================================================================================================================================
#pragma mark - PickerView Display Navigation Buttons update Methods
//==============================================================================================================================================


-(void)setRightNavButtonToDone
{
    UIBarButtonItem *donePickerSelectionButton = [[UIBarButtonItem alloc]
                                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"doneText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"DONE", @"")
                                                  style:UIBarButtonItemStylePlain
                                                  target:self action:@selector(donePicking:)];

    self.navigationItem.rightBarButtonItem = donePickerSelectionButton;
}

-(void)setRightNavButtonToRefresh
{
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(refreshTable:)];

    self.navigationItem.rightBarButtonItem = refreshButton;
}

//==============================================================================================================================================
#pragma mark - Picker View Done and View Update Methods
//==============================================================================================================================================

-(void)donePicking:(id)sender
{
    self.tableViewBottomToAttachment.constant = 0;
    [UIView animateWithDuration:0.4 animations:^{


        self.mTableView.frame = CGRectMake(0,self->defaultTableRect.origin.y,
                                           self->defaultTableRect.size.height,
                                           [UIScreen mainScreen].bounds.size.width);

        self.tableViewTop2Constraint.constant = 0;
        self.mTableView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.2];
        [self.view layoutIfNeeded];
        [self.pickerView setHidden:YES];
    }];

    [self setRightNavButtonToRefresh];

    [self updateContextInView];
    isPickerOpen = NO;
}

//==============================================================================================================================================
#pragma mark - Update Table with new data according to context
//==============================================================================================================================================

-(void)updateContextInView
{
    if (self.pickerConvIdsArray.count == 0) {
        [self reloadView];
        return;
    }

    [self.mTableView setUserInteractionEnabled:YES];
    [self.sendMessageTextView setHidden:NO];

    NSInteger pickerRowSelected = (long)[self.pickerView selectedRowInComponent:0];

    if(self.conversationId != self.pickerConvIdsArray[pickerRowSelected] &&  self.pickerConvIdsArray[pickerRowSelected] != nil ){

        self.conversationId = self.pickerConvIdsArray[pickerRowSelected];

        [[self.alMessageWrapper messageArray] removeAllObjects];

        if(![ALUserDefaultsHandler isServerCallDoneForMSGList:[self.conversationId stringValue]])
        {
           [self processLoadEarlierMessages:YES];
        }
        else
        {
            [self reloadView];
        }
    }
}

//==============================================================================================================================================
#pragma mark - MASKS BACKGROUND WHEN PICKER SHOWN
//==============================================================================================================================================

-(void)disableRestView
{
    [self.mTableView setUserInteractionEnabled:NO];
    [self.sendMessageTextView setHidden:YES];
}

//==============================================================================================================================================
#pragma mark - GET ALMESSAGE OBJECT
//==============================================================================================================================================

-(ALMessage *)getMessageToPost
{
    ALMessage * theMessage = [ALMessage new];

    theMessage.type = @"5";
    theMessage.contactIds = self.contactIds;
    theMessage.to = self.contactIds;
    theMessage.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    theMessage.deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    theMessage.message = self.sendMessageTextView.text;
    theMessage.sendToDevice = NO;
    theMessage.shared = NO;
    theMessage.fileMeta = nil;
    theMessage.storeOnDevice = NO;
    theMessage.key = [[NSUUID UUID] UUIDString];
    theMessage.delivered = NO;
    theMessage.fileMetaKey = nil;//4
    theMessage.contentType = ALMESSAGE_CONTENT_DEFAULT;
    theMessage.groupId = self.channelKey;
    theMessage.conversationId  = self.conversationId;
    theMessage.source = SOURCE_IOS;
//    theMessage.metadata = [self getNewMetaDataDictionary]; // EXAMPLE FOR META DATA

    if(self.messageReplyId){
        NSMutableDictionary * metaData = [NSMutableDictionary new];
        [metaData  setValue:self.messageReplyId forKey:AL_MESSAGE_REPLY_KEY];
        theMessage.metadata = metaData;
    }
    return theMessage;
}

//-(NSMutableDictionary *)getNewMetaDataDictionary      // EXAMPLE FOR META DATA
//{
//    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//    [dict setObject:@"VALUE" forKey:@"KEY"];
//    return dict;
//}

//==============================================================================================================================================
#pragma mark - GET FILEMETA OBJECT
//==============================================================================================================================================

-(ALFileMetaInfo *)getFileMetaInfo
{
    ALFileMetaInfo *info = [ALFileMetaInfo new];

    info.blobKey = nil;
    info.thumbnailBlobKey=nil;
    info.contentType = @"";
    info.createdAtTime = nil;
    info.key = nil;
    info.name = @"";
    info.size = @"";
    info.userKey = @"";
    info.thumbnailUrl = @"";
    info.progressValue = 0;

    return info;
}

//==============================================================================================================================================
#pragma mark - VIEW HELPER METHODS
//==============================================================================================================================================

-(void)loadChatView
{
    [self setTitle];

    BOOL isLoadEarlierTapped = [self.alMessageWrapper getUpdatedMessageArray].count == 0 ? NO : YES ;
    ALDBHandler * theDbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest * theRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [theRequest setFetchLimit:self.rp];
    NSPredicate* predicate1;
    if(self.conversationId && [ALApplozicSettings getContextualChatOption])
    {
        predicate1 = [NSPredicate predicateWithFormat:@"conversationId = %d", [self.conversationId intValue]];
    }
    else if(self.isGroup)
    {
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %d", [self.channelKey intValue]];
    }
    else
    {
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil", self.contactIds];
    }

    self.mTotalCount = [theDbHandler.managedObjectContext countForFetchRequest:theRequest error:nil];

    NSPredicate* predicate2 = [NSPredicate predicateWithFormat:@"deletedFlag == NO AND msgHidden == %@",@(NO)];
    NSPredicate* predicate3 = [NSPredicate predicateWithFormat:@"contentType != %i",ALMESSAGE_CONTENT_HIDDEN];
    NSPredicate* compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2,predicate3]];
    [theRequest setPredicate:compoundPredicate];
    [theRequest setFetchOffset:self.startIndex];
    [theRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];

    NSArray * theArray = [theDbHandler.managedObjectContext executeFetchRequest:theRequest error:nil];
    ALMessageDBService* messageDBService = [[ALMessageDBService alloc]init];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];

    for (DB_Message * theEntity in theArray)
    {
        ALMessage * theMessage = [messageDBService createMessageEntity:theEntity];
        [tempArray insertObject:theMessage atIndex:0];
        //[self.mMessageListArrayKeyStrings insertObject:theMessage.key atIndex:0];
    }

    [self.alMessageWrapper addObjectToMessageArray:tempArray];
    [self.mTableView reloadData];

    if(isLoadEarlierTapped)
    {
        if ((theArray != nil && theArray.count < self.rp )|| [self.alMessageWrapper getUpdatedMessageArray].count == self.mTotalCount)
        {
//            self.mTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        }
        self.startIndex = self.startIndex + theArray.count;
        [self.mTableView reloadData];
        if (theArray.count != 0)
        {
            CGRect theFrame = [self.mTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:theArray.count-1 inSection:0]];
            [self.mTableView setContentOffset:CGPointMake(0, theFrame.origin.y-60)];
        }
    }
    else
    {
        if (theArray.count < self.rp || [self.alMessageWrapper getUpdatedMessageArray].count == self.mTotalCount)
        {
//            self.mTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        }
        else
        {
//            self.mTableView.tableHeaderView = self.mTableHeaderView;
        }
        self.startIndex = theArray.count;

        /*if (self.mMessageListArray.count != 0) {
         CGRect theFrame = [self.mTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:theArray.count-1 inSection:0]];
         [self.mTableView setContentOffset:CGPointMake(0, theFrame.origin.y)];
         }*/
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollTableViewToBottomWithAnimation:YES];
        });
    }

    self.refresh = YES;
    [self setBackGroundWallpaper];
}

//==============================================================================================================================================
#pragma mark - SET BACKGROUND WALLPAPER METHOD
//==============================================================================================================================================

-(void)setBackGroundWallpaper
{
    NSString * imagName = [ALApplozicSettings getChatWallpaperImageName];
    UIImage * backgroundImage = [UIImage imageNamed:imagName];
    if(backgroundImage)
    {
        [self.mTableView setBackgroundColor:[UIColor clearColor]];
        UIImageView * backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        backgroundImageView.image = backgroundImage;
        [self.view insertSubview:backgroundImageView atIndex:0];
        return;
    }

    [self.mTableView setBackgroundColor:[ALApplozicSettings getChatViewControllerBackgroundColor]];
    [self.mTableView.superview setBackgroundColor:[ALApplozicSettings getMessagesViewBackgroundColour]];
}

//==============================================================================================================================================
#pragma mark - CHAT CELL DELEGATE
//==============================================================================================================================================

-(void)deleteMessageFromView:(ALMessage *)message
{
    ALSLog(ALLoggerSeverityInfo, @"  deleteMessageFromView in controller...:: ");
    [self.alMessageWrapper removeALMessageFromMessageArray:message];
    [UIView animateWithDuration:1.5 animations:^{
        [self.mTableView reloadData];
    }];

    [self showNoConversationLabel];
}


//=================================================================================================================

#pragma mark - Clear messages from chat view

//=================================================================================================================

-(void)clearMessagesFromChatView
{
    [[self.alMessageWrapper getUpdatedMessageArray] removeAllObjects];
    [UIView animateWithDuration:1.5 animations:^{
        [self.mTableView reloadData];
    }];

    [self showNoConversationLabel];
}

#pragma mark - MEDIA DELEGATE : DOWNLOAD RETRY DELEGATES
//==============================================================================================================================================

-(void)downloadRetryButtonActionDelegate:(int)index andMessage:(ALMessage *)message
{

    if(message.msgDBObjectId){
        ALMediaBaseCell *imageCell = (ALMediaBaseCell *)[self.mTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        imageCell.progresLabel.alpha = 1;
        imageCell.mMessage.fileMeta.progressValue = 0;
        imageCell.mDowloadRetryButton.alpha = 0;
        imageCell.downloadRetryView.alpha = 0;
        imageCell.sizeLabel.alpha = 0;
        message.inProgress = YES;

        NSMutableArray * sessionArray = [[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue];

        for(NSURLSession *session in sessionArray){
            NSURLSessionConfiguration *config =  session.configuration;
            NSArray *array =  [config.identifier componentsSeparatedByString:@","];
            if(array && array.count>1){
                //Check if message key are same and first argumnent is not THUMBNAIL
                if(![array[0] isEqual: @"THUMBNAIL"] && [array[1] isEqualToString: message.key]){
                    ALSLog(ALLoggerSeverityInfo, @"Already task in proccess ignoring download retry for the key %@",message.key);
                    return;
                }
            }
        }

        if ([message.type isEqualToString:@"5"]&& !message.fileMeta.key) // upload
        {
            [self uploadImage:message];
        }
        else    //download
        {
            ALHTTPManager * manager =  [[ALHTTPManager alloc] init];
            manager.attachmentProgressDelegate = self;
            [manager processDownloadForMessage:message isAttachmentDownload:YES];
        }
    }else{
        ALSLog(ALLoggerSeverityInfo, @"Message is not in db ");
    }

}

-(void)stopDownloadForIndex:(int)index andMessage:(ALMessage *)message
{
    ALSLog(ALLoggerSeverityInfo, @"Called get image stopDownloadForIndex stopDownloadForIndex ####");

    ALMediaBaseCell *imageCell = (ALMediaBaseCell *)[self.mTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    imageCell.progresLabel.alpha = 0;
    imageCell.mDowloadRetryButton.alpha = 1;
    imageCell.downloadRetryView.alpha = 1;
    imageCell.sizeLabel.alpha = 1;
    message.inProgress = NO;
    [[ALMessageService sharedInstance] handleMessageFailedStatus:message];

    NSMutableArray * nsURLSessionArray = [[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue];

    for(NSURLSession *session in nsURLSessionArray){
        NSURLSessionConfiguration *config =  session.configuration;
        NSArray *array =  [config.identifier componentsSeparatedByString:@","];

        if(array && array.count>1){

            //Check if message key are same and first argumnent is not THUMBNAIL
            if(![array[0] isEqual: @"THUMBNAIL"] && [array[1] isEqualToString:message.key]){
                ALSLog(ALLoggerSeverityInfo, @"Already task in proccess cancel current task with key %@",message.key);
                [session invalidateAndCancel];
                [[[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue] removeObject:session];
                break;
            }
        }
    }
}

-(void)showFullScreen:(UIViewController*)uiController
{
    [self presentViewController:uiController animated:YES completion:nil];
}

-(void) thumbnailDownload:(NSString *) key{

    ALMessageDBService * messageDBService = [[ALMessageDBService alloc]init];
    ALHTTPManager * manager =  [[ALHTTPManager alloc] init];
    manager.attachmentProgressDelegate = self;
    [manager processDownloadForMessage:[messageDBService getMessageByKey:key] isAttachmentDownload:NO];
}

-(CGFloat)bytesConvertsToDegree:(CGFloat)totalBytesExpectedToWrite comingBytes:(CGFloat)totalBytesWritten
{
    CGFloat totalBytes = totalBytesExpectedToWrite;
    CGFloat writtenBytes = totalBytesWritten;
    CGFloat divergence = totalBytes/360;
    CGFloat degree = writtenBytes/divergence;

    return degree;
}

//==============================================================================================================================================
#pragma mark - IMAGE PICKER DELEGATES
//==============================================================================================================================================

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage * clickImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage * image = [ALUtilityClass getNormalizedImage:clickImage];
    image = [image getCompressedImageLessThanSize:5];

    if(image)
    {
        // SAVE IMAGE TO DOC.
        NSString * filePath = [ALImagePickerHandler saveImageToDocDirectory:image];
        [self processAttachment:filePath andMessageText:@"" andContentType:ALMESSAGE_CONTENT_ATTACHMENT];
    }

    // VIDEO ATTACHMENT
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    BOOL isMovie = UTTypeConformsTo((__bridge CFStringRef)mediaType, kUTTypeMovie) != 0;

    if(isMovie)
    {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];

        if (avAsset) {
            self.videoCoder = [[ALVideoCoder alloc] init];

            double start = [info[@"_UIImagePickerControllerVideoEditingStart"] doubleValue];
            double end = [info[@"_UIImagePickerControllerVideoEditingEnd"] doubleValue];

            double timescale = 600;
            CMTimeRange range = CMTimeRangeMake(CMTimeMake(start*timescale, timescale), CMTimeMake((end-start)*timescale, timescale));
            [self.videoCoder convertWithAvAssets:@[avAsset] range:range baseVC:self completion:^(NSArray<NSString *> * _Nullable paths) {
                NSString *videoFilePath = [paths firstObject];
                if (!videoFilePath) {
                    return;
                }
                // If 'save video to gallery' is enabled then save to gallery
                if([ALApplozicSettings isSaveVideoToGalleryEnabled]) {
                    UISaveVideoAtPathToSavedPhotosAlbum(videoFilePath, self, nil, nil);
                }
                [self processAttachment:videoFilePath andMessageText:@"" andContentType:ALMESSAGE_CONTENT_CAMERA_RECORDING];
            }];
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//==============================================================================================================================================
#pragma mark - PROCESSING & UPLOADING MEDIA ATTACHMENT
//==============================================================================================================================================

-(void)processAttachment:(NSString *)filePath andMessageText:(NSString *)textwithimage andContentType:(short)contentype
{
    // create message object
    ALMessage * theMessage = [self getMessageToPost];
    theMessage.contentType = contentype;
    theMessage.fileMeta = [self getFileMetaInfo];
    theMessage.message = textwithimage;
    theMessage.imageFilePath = filePath.lastPathComponent;

    theMessage.fileMeta.name = [NSString stringWithFormat:@"AUD-5-%@", filePath.lastPathComponent];
    if(self.contactIds)
    {
        theMessage.fileMeta.name = [NSString stringWithFormat:@"%@-5-%@",self.contactIds, filePath.lastPathComponent];
    }

    CFStringRef pathExtension = (__bridge_retained CFStringRef)[filePath pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);

    theMessage.fileMeta.contentType = mimeType;
    if( theMessage.contentType == ALMESSAGE_CONTENT_VCARD)
    {
        theMessage.fileMeta.contentType = @"text/x-vcard";
    }

    NSData *imageSize = [NSData dataWithContentsOfFile:filePath];
    theMessage.fileMeta.size = [NSString stringWithFormat:@"%lu",(unsigned long)imageSize.length];
    //theMessage.fileMetas.thumbnailUrl = filePath.lastPathComponent;

    // save msg to db
    theMessage.msgDBObjectId = [self saveMessageToDatabase:theMessage];

    [self.mTableView reloadData];
    [self scrollTableViewToBottomWithAnimation:NO];
    [self uploadImage:theMessage];
}


-(NSManagedObjectID *) saveMessageToDatabase: (ALMessage *) message{
    [self.alMessageWrapper addALMessageToMessageArray:message];
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    ALMessageDBService* messageDBService = [[ALMessageDBService alloc] init];
    DB_Message * theMessageEntity = [messageDBService createMessageEntityForDBInsertionWithMessage: message];
    [theDBHandler.managedObjectContext save:nil];
    return [theMessageEntity objectID];
}

-(void)uploadImage:(ALMessage *)theMessage
{
    if (theMessage.fileMeta && [theMessage.type isEqualToString:@"5"])
    {
        NSDictionary * userInfo = [theMessage dictionary];
//        [self.sendMessageTextView setText:nil];
        self.mTotalCount = self.mTotalCount+1;
        self.startIndex = self.startIndex + 1;

        ALMediaBaseCell* imageCell = [self getCell:theMessage.key];

        if(!imageCell)
        {
            ALSLog(ALLoggerSeverityInfo, @" not able to find the image cell for upload....");
            return;
        }

        imageCell.progresLabel.alpha = 1;
        imageCell.mMessage.fileMeta.progressValue = 0;
        imageCell.mDowloadRetryButton.alpha = 0;
        imageCell.downloadRetryView.alpha = 0;
        imageCell.sizeLabel.alpha = 0;

        imageCell.mMessage.inProgress = YES;
        if([theMessage.fileMeta.contentType hasPrefix:@"audio"])
        {
           [imageCell hidePlayButtonOnUploading];
        }
        ALMessageDBService  * msgdbService = [[ALMessageDBService alloc] init];
        DB_Message *dbMessage = (DB_Message*)[msgdbService getMessageByKey:@"key" value:theMessage.key];
        dbMessage.inProgress = [NSNumber numberWithBool:YES];
        dbMessage.isUploadFailed = [NSNumber numberWithBool:NO];
        [[ALDBHandler sharedInstance].managedObjectContext save:nil];

        // post image
        ALMessageClientService * clientService  = [[ALMessageClientService alloc]init];
        [clientService sendPhotoForUserInfo:userInfo withCompletion:^(NSString *url, NSError *error) {

            if (error)
            {
                ALSLog(ALLoggerSeverityError, @"%@",error);
                imageCell.progresLabel.alpha = 0;
                imageCell.mDowloadRetryButton.alpha = 1;
                imageCell.downloadRetryView.alpha = 1;
                imageCell.sizeLabel.alpha = 1;
                [[ALMessageService sharedInstance] handleMessageFailedStatus:theMessage];
                return;
            }

            ALHTTPManager *httpManager = [[ALHTTPManager alloc]init];
            httpManager.attachmentProgressDelegate = self;
            [httpManager processUploadFileForMessage:theMessage uploadURL:url];

        }];
    }
}

//==============================================================================================================================================
#pragma mark - MULTIPLE ATTACHMENT DELEGATE
//==============================================================================================================================================

-(void)multipleAttachmentProcess:(NSMutableArray *)attachmentPathArray andText:(NSString *)messageText
{
    for(ALMultimediaData * attachment in attachmentPathArray)
    {
        NSString *filePath = @"";
        NSURL * videoURL;
        switch (attachment.attachmentType) {
            case ALMultimediaTypeGif:
                filePath = [ALImagePickerHandler saveGifToDocDirectory:attachment.classImage withGIFData :attachment.dataGIF];
                [self processAttachment:filePath andMessageText:messageText andContentType:ALMESSAGE_CONTENT_ATTACHMENT];
                break;

            case ALMultimediaTypeImage:
                filePath = [ALImagePickerHandler saveImageToDocDirectory:attachment.classImage];
                [self processAttachment:filePath andMessageText:messageText andContentType:ALMESSAGE_CONTENT_ATTACHMENT];
                break;

            case ALMultimediaTypeVideo:
                videoURL = [NSURL fileURLWithPath:attachment.classVideoPath];
                [ALImagePickerHandler saveVideoToDocDirectory:videoURL handler:^(NSString * filePath){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self processAttachment:filePath andMessageText:messageText andContentType:ALMESSAGE_CONTENT_ATTACHMENT];
                    });
                }];
                break;
        }
    }
}

//==============================================================================================================================================
#pragma mark - AUDIO DELEGATE
//==============================================================================================================================================

-(void)audioAttachment:(NSString *)audioFilePath
{
    [self processAttachment:audioFilePath andMessageText:@"" andContentType:ALMESSAGE_CONTENT_AUDIO];
}

//==============================================================================================================================================
#pragma mark - ATTACHMENT BUTTON HANDLER
//==============================================================================================================================================

-(void)attachmentAction
{
    if(self.isUserBlocked)
    {
        [self showBlockedAlert];
        return;
    }
    [self showActionAlert];
}





-(void) showActionAlert
{
    UIAlertController * theController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [ALUtilityClass setAlertControllerFrame:theController andViewController:self];

    [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    if(![ALApplozicSettings isCameraOptionHidden]){

        [theController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"takePhotoText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Take photo", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openCamera];
        }]];
    }
    if(![ALApplozicSettings isLocationOptionHidden]){
        [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"currentLocationOption", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Current location", @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openLocationView];
        }]];
    }

    if(![ALApplozicSettings isSendAudioOptionHidden]){
        [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"sendAudioOption", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Send Audio", @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openAudioMic];
        }]];
    }

    if(![ALApplozicSettings isSendVideoOptionHidden]){
        [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"sendVideoOption", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],  @"Send Video", @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openVideoCamera];
        }]];
    }

    if(![ALApplozicSettings isDocumentOptionHidden]){
        [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"DocumentText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],  @"Document", @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            ALDocumentPickerHandler *documentPickerHandler = [[ALDocumentPickerHandler alloc]init];
            [documentPickerHandler showDocumentPickerViewController:self];
        }]];
    }

    if(((!self.channelKey && !self.conversationId) || (self.alChannel.type == GROUP_OF_TWO)) && ![ALApplozicSettings isBlockUserOptionHidden])
    {
        [theController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"blockUserOption", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"BLOCK USER", @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            if(![ALDataNetworkConnection checkDataNetworkAvailable])
            {
                [self showNoDataNotification];
                return;
            }

            ALUserService *userService = [ALUserService new];
            [userService blockUser:self.contactIds withCompletionHandler:^(NSError *error, BOOL userBlock) {

                if(userBlock)
                {

                    self.isUserBlocked = YES;
                    [self.label setHidden:self.isUserBlocked];

                    NSString *blockInfo = NSLocalizedStringWithDefaultValue(@"blockedSuccessfullyText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"%@ is blocked successfully", @"");

                    NSString * alertText = [NSString stringWithFormat:blockInfo,[self.alContact getDisplayName]];

                    [ALUtilityClass showAlertMessage:alertText andTitle:NSLocalizedStringWithDefaultValue(@"userBlock", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"USER BLOCK", @"")  ];
                }
            }];
        }]];
    }
    if(![ALApplozicSettings isShareContactOptionHidden]){
        [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"shareContact", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Share Contact", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openContactsView];
        }]];
    }



    if(![ALApplozicSettings isPhotoGalleryOptionHidden]){
        NSString *attachmentMenuDefaultText = nil;
        if([ALApplozicSettings videosHiddenInGallery] && [ALApplozicSettings imagesHiddenInGallery]){
            attachmentMenuDefaultText = @"Photos/Videos";
        }else if([ALApplozicSettings videosHiddenInGallery]){
            attachmentMenuDefaultText = @"Photos";
        }else if([ALApplozicSettings imagesHiddenInGallery]) {
            attachmentMenuDefaultText = @"Videos";
        }else {
            attachmentMenuDefaultText = @"Photos/Videos";
        }

        [theController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"photosOrVideoOption", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], attachmentMenuDefaultText , @"")  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if([ALApplozicSettings isMultiSelectGalleryViewDisabled]) {
                UIStoryboard* storyboardM = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
                ALMultipleAttachmentView *launchChat = (ALMultipleAttachmentView *)[storyboardM instantiateViewControllerWithIdentifier:@"collectionView"];
                launchChat.multipleAttachmentDelegate = self;
                [self.navigationController pushViewController:launchChat animated:YES];
            } else {
                ALBaseNavigationViewController *controller = [ALCustomPickerViewController makeInstanceWithDelegate:self];
                [self presentViewController:controller animated:NO completion:nil];
            }
        }]];
    }

    if((self.channelKey ||  self.contactIds) && [ALApplozicSettings isDeleteConversationOptionEnabled]){

        [theController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"deleteConversation", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Delete Conversation" , @"")
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                              [self deleteConversation];
                                                          }]];

    }

    if(!self.channelKey && !self.conversationId && [ALApplozicSettings isAudioVideoEnabled])
    {

        [theController addAction:[UIAlertAction actionWithTitle:  NSLocalizedStringWithDefaultValue(@"videoCall", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Video Call" , @"")
style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openCallView:NO];
        }]];

        [theController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"audioCall", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Audio Call" , @"")
 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

            [self openCallView:YES];
        }]];
    }

    [self presentViewController:theController animated:YES completion:nil];
}

//==============================================================================================================================================
#pragma mark - ABPEOPLE PICKER DELEGATE METHOD
//==============================================================================================================================================


-(void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact
{
    ALVCardClass *vcardClass = [[ALVCardClass alloc] init];
    NSString *contactFilePath = [vcardClass saveContactToDocDirectory:contact];
    [self processAttachment:contactFilePath andMessageText:@"" andContentType:ALMESSAGE_CONTENT_VCARD];
}

//==============================================================================================================================================
#pragma mark - ATTACHMENT HANDLERS FOR IMAGE/CONTACT/AUDIO/VIDEO && A/V CALL
//==============================================================================================================================================

-(void)openCamera
{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {

            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted)
                {
                    self.mImagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    self.mImagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeImage, nil];
                    [self presentViewController:self.mImagePicker animated:YES completion:nil];
                }
                else
                {
                    [ALUtilityClass permissionPopUpWithMessage:NSLocalizedStringWithDefaultValue(@"permissionPopMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable Camera Permission", @"") andViewController:self];
                }
            });
        }];
    }
    else
    {
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"permissionNotAvailableMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Camera is not Available !!!", @"") andTitle:@"OOPS !!!"];
    }
}

-(void)openVideoCamera
{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {

            dispatch_async(dispatch_get_main_queue(), ^{

                if (granted)
                {
                    self.mImagePicker.allowsEditing = YES;
                    self.mImagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    self.mImagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeMovie, nil];
                    self.mImagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                    if ([ALApplozicSettings is5MinVideoLimitInGalleryEnabled]) {
                        self.mImagePicker.videoMaximumDuration = 300;
                    }
                    [self presentViewController:self.mImagePicker animated:YES completion:nil];
                }
                else
                {
                    [ALUtilityClass permissionPopUpWithMessage:NSLocalizedStringWithDefaultValue(@"permissionPopMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable Camera Permission", @"") andViewController:self];
                }
            });
        }];
    }
    else
    {
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"permissionNotAvailableMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Camera is not Available !!!", @"") andTitle:NSLocalizedStringWithDefaultValue(@"oppsText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"OOPS !!!", @"")];
    }
}

-(void)openAudioMic
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {

        dispatch_async(dispatch_get_main_queue(), ^{

            if (granted)
            {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
                ALAudioAttachmentViewController *audioVC = (ALAudioAttachmentViewController *)[storyboard
                                                                                               instantiateViewControllerWithIdentifier:@"AudioAttachment"];
                audioVC.audioAttchmentDelegate = self;
                [self.navigationController pushViewController:audioVC animated:YES];
            }
            else
            {
                [ALUtilityClass permissionPopUpWithMessage:NSLocalizedStringWithDefaultValue(@"permissionPopMessageForMicroPhone", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable MicroPhone Permission", @"")  andViewController:self];
            }
        });
    }];
}

-(void)openContactsView
{

        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {

            dispatch_async(dispatch_get_main_queue(), ^{

                if (granted)
                {
                    CNContactPickerViewController *contactPicker = [CNContactPickerViewController new];
                    contactPicker.delegate = self;
                    [self presentViewController:contactPicker animated:YES completion:nil];
                }
                else
                {
                    [ALUtilityClass permissionPopUpWithMessage:NSLocalizedStringWithDefaultValue(@"permissionPopMessageForContacts", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable Contacts Permission", @"")  andViewController:self];
                }
            });
        }];

}


-(void)openLocationView
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALMapViewController *mapView = (ALMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"shareLoactionViewTag"];
    mapView.controllerDelegate = self;
    [self.navigationController pushViewController:mapView animated:YES];
}

-(void)openGallery
{
    self.mImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.mImagePicker.mediaTypes = [NSArray arrayWithObject: (NSString *)kUTTypeImage];
    [self presentViewController:self.mImagePicker animated:YES completion:nil];
}

-(void)openCallView:(BOOL)callForAudio
{
    if(![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [self showNoDataNotification];
        return;
    }

    NSString * roomID =  [NSString stringWithFormat:@"%@:%@",[ALUtilityClass getDevieUUID],
                          [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000]];

    ALVOIPNotificationHandler *voipHandler = [ALVOIPNotificationHandler sharedManager];
    [voipHandler launchAVViewController:self.contactIds
                           andLaunchFor:[NSNumber numberWithInt:AV_CALL_DIALLED]
                               orRoomId:roomID
                           andCallAudio:callForAudio
                      andViewController:self];
}

-(void)deleteConversation{

    NSString *userId;
    NSNumber *groupId;

    if(self.channelKey){
        groupId = self.channelKey;
    }else{
        userId = self.contactIds;
    }

    [ALMessageService deleteMessageThread:userId orChannelKey:groupId
                           withCompletion:^(NSString *string, NSError *error) {

                               if(error)
                               {
                                   [ALUtilityClass displayToastWithMessage:@"Delete failed"];
                                   return;
                               }

                               [self clearMessagesFromChatView];


                           }];
}


-(ALMediaBaseCell *)getCell:(NSString *)key
{
    NSIndexPath * path = [self getIndexPathForMessage:key];
    ALMediaBaseCell *cell = (ALMediaBaseCell *)[self.mTableView cellForRowAtIndexPath:path];

    return cell;
}

-(NSIndexPath*) getIndexPathForMessage:(NSString*)messageKey
{
    int index = (int)[[self.alMessageWrapper getUpdatedMessageArray] indexOfObjectPassingTest:^BOOL(id element,NSUInteger idx,BOOL *stop) {
        ALMessage *message = (ALMessage*)element;
        if([message.key isEqualToString:messageKey])
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    return path;
}


-(void)sendMessage:(ALMessage *)theMessage{
    [self sendMessage:theMessage messageAtIndex:0];
}

-(void)sendMessage:(ALMessage *)theMessage messageAtIndex:(NSUInteger) messageIndex{
    [self resetMessageReplyView];
    [[ALMessageService sharedInstance] sendMessages:theMessage withCompletion:^(NSString *message, NSError *error) {

        if(error)
        {
            ALSLog(ALLoggerSeverityError, @"SEND_MSG_ERROR :: %@",error.description);
            [[ALMessageService sharedInstance] handleMessageFailedStatus:theMessage];
            return;
        }

        if(messageIndex>0){
            [[self.alMessageWrapper getUpdatedMessageArray]replaceObjectAtIndex: messageIndex-1 withObject:theMessage];

        }

        [self.mTableView reloadData];
        [self setRefreshMainView:YES];
    }];
}



-(ALMessage *)getMessageFromViewList:(NSString *)key withValue:(id)value
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K == %@",key,value];
    NSArray * filteredArray = [[self.alMessageWrapper getUpdatedMessageArray] filteredArrayUsingPredicate:predicate];

    if (filteredArray.count > 0)
    {
        return filteredArray[0];
    }

    return nil;
}

-(void)fetchAndRefresh
{
    [self fetchAndRefresh:NO];
}

-(void)fetchAndRefresh:(BOOL)flag
{
    NSString *deviceKeyString = [ALUserDefaultsHandler getDeviceKeyString];

    ALPushAssist * alpushAssist = [ALPushAssist new];
    if(!alpushAssist.isChatViewOnTop)
    {
        return;
    }
    [ALMessageService getLatestMessageForUser:deviceKeyString withCompletion:^(NSMutableArray  *messageList, NSError *error) {

        if(error)
        {
            ALSLog(ALLoggerSeverityError, @"ERROR_GetLatestMessageForUser :: %@",error);
            return ;
        }
        else
        {
            if(messageList.count > 0)
            {
                if(flag)
                {
                    [self markConversationRead];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self scrollTableViewToBottomWithAnimation:YES];
                [self setTitle];
            });
            ALSLog(ALLoggerSeverityInfo, @"FETCH AND REFRESH METHOD");
        }
    }];
}

-(void)updateStatusReportForConversation:(int)status
{
    NSMutableArray * predicateArray = [[NSMutableArray alloc] init];
    NSPredicate * statusPred = [NSPredicate predicateWithFormat:@"status!=%i and sentToServer ==%@", DELIVERED_AND_READ, [NSNumber numberWithBool:YES]];
    [predicateArray addObject:statusPred];

    NSCompoundPredicate * compoundPred = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
    NSArray * filteredArray = [[self.alMessageWrapper getUpdatedMessageArray] filteredArrayUsingPredicate:compoundPred];

    ALSLog(ALLoggerSeverityInfo, @"Found Messages to update to DELIVERED_AND_READ in ChatView :%lu", (unsigned long)filteredArray.count);

    for(ALMessage * message in filteredArray)
    {
        message.status = [NSNumber numberWithInt:status];
    }

    [self.mTableView reloadData];
}

-(void)updateDeliveryReport:(NSString*)key withStatus:(int)status
{
    NSNumber * statusValue = [NSNumber numberWithInt:status];

    ALMessage * alMessage = [self getMessageFromViewList:@"key" withValue:key];
    if(alMessage)
    {
        alMessage.status = statusValue;
        [self.mTableView reloadData];
    }
    else
    {
        ALMessage* fetchMsg = [ALMessage new];
        fetchMsg=[ALMessageService getMessagefromKeyValuePair:@"key" andValue:key];

        //now find in list ...
        ALMessage * alMessage2 = [self getMessageFromViewList:@"msgDBObjectId" withValue:fetchMsg.msgDBObjectId];

        if (alMessage2)
        {
            alMessage2.status = statusValue;
            [self.mTableView reloadData];
        }
    }
}

-(void)individualNotificationhandler:(NSNotification *) notification
{
    ALMessage* alMessage  = [[ALMessage alloc] init];
    ALSLog(ALLoggerSeverityInfo, @" OUR Individual Notificationhandler ");
    [self setRefreshMainView:TRUE];
    // see if this view is visible or not...

    NSString * notificationObject = (NSString *)notification.object;
    NSDictionary *dict = notification.userInfo;
    NSNumber *updateUI = [dict valueForKey:@"updateUI"];
    NSString *alertValue = [dict valueForKey:@"alertValue"];
    ALSLog(ALLoggerSeverityInfo, @"Notification received by Individual chat list: %@", notificationObject);

    NSArray *componentsArray = [notificationObject componentsSeparatedByString:@":"];
    if (componentsArray.count > 2) {
        alMessage.groupId = @([ componentsArray[1] intValue]);
        alMessage.contactIds = componentsArray[2];
    } else if (componentsArray.count == 2) {
        alMessage.groupId = nil;
        alMessage.contactIds = componentsArray[0];
        alMessage.conversationId = @([componentsArray[1] intValue]);
    } else {
        alMessage.groupId = nil;
        alMessage.contactIds = componentsArray[0];
    }

    NSArray * componentsAlertValue = [alertValue componentsSeparatedByString:@":"];
    if(componentsAlertValue.count > 1)
    {
        alertValue = [NSString stringWithFormat:@"%@",componentsAlertValue[1]];
    }

    alMessage.message = alertValue;
    [self syncCall:alMessage updateUI:updateUI alertValue:alertValue];
}

-(void)syncCall:(ALMessage*)alMessage  updateUI:(NSNumber *)updateUI alertValue: (NSString *)alertValue
{
    [self setRefreshMainView:TRUE];
    bool isGroupNotification = (alMessage.groupId == nil ? false : true);

    if (self.isGroup && isGroupNotification && [self.channelKey isEqualToNumber:alMessage.groupId] &&
        (self.conversationId.intValue == alMessage.conversationId.intValue))
    {
        self.conversationId = alMessage.conversationId;
        self.contactIds=alMessage.contactIds;
        self.channelKey = alMessage.groupId;
    }
    else if (!self.isGroup && !isGroupNotification && [self.contactIds isEqualToString:alMessage.contactIds] &&
             (self.conversationId.intValue == alMessage.conversationId.intValue))
    {
        //Current Same Individual Contact thread is opened..
        self.conversationId = alMessage.conversationId;
        self.channelKey = nil;
        self.contactIds = alMessage.contactIds;
        //[self fetchAndRefresh:YES];
    }
    else if ([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_INACTIVE]])
    {
        ALSLog(ALLoggerSeverityInfo, @"it was in background, updateUI is false");
        self.conversationId = alMessage.conversationId;
        self.channelKey = alMessage.groupId;
        self.contactIds = alMessage.contactIds;
       // [self fetchAndRefresh:YES];
        [self reloadView];
        [self markConversationRead];
    }
    else
    {
        if(![alMessage.type isEqualToString:@"5"] && ![updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_BACKGROUND]])
        {
            ALSLog(ALLoggerSeverityInfo, @"SHOW_NOTIFICATION (OTHER_THREAD_IS_OPENED)");
            [self showNativeNotification:alMessage andAlert:alertValue];
        }
    }
}

-(void)showNativeNotification:(ALMessage *)alMessage andAlert:(NSString*)alertValue
{
    if ((alMessage.groupId && [ALChannelService isChannelMuted:alMessage.groupId]) || [alMessage isMsgHidden])
    {
        return;
    }
    ALNotificationView * alnotification = [[ALNotificationView alloc] initWithAlMessage:alMessage withAlertMessage:alertValue];
    [alnotification nativeNotification:self];
}

//===============================================================================================================================================
#pragma mark - Update Single Message Status : Local Notification Handlers
//===============================================================================================================================================

//DELIVERED
-(void)updateDeliveryStatus:(NSNotification *)notification
{
    [self updateReportOfkeyString:notification.object reportStatus:DELIVERED];
}
//DELIVERED_AND_READ
-(void)updateReadReport:(NSNotification *)notification
{
    [self updateReportOfkeyString:notification.object reportStatus:DELIVERED_AND_READ];
}

-(void)updateReportOfkeyString:(NSString *)notificationObject reportStatus:(int)status
{
    NSString * keyString = notificationObject;
    [self updateDeliveryReport:keyString withStatus:status];
}

//==============================================================================================================================================
#pragma mark - SET WHOLE CONVERSATION STATUS DELIVERED AND READ
//==============================================================================================================================================

-(void)updateReadReportForConversation:(NSNotification*)notificationObject
{
    [self updateStatusForContact:notificationObject.object withStatus:DELIVERED_AND_READ];
}

-(void)handleAddress:(NSDictionary *)dict
{
    if([dict valueForKey:@"error"])
    {
        //handlen error
        return;
    }
    else
    {
        NSString *  address = [dict valueForKey:@"address"];
        NSString *  googleurl = [dict valueForKey:@"googleurl"];
        NSString * finalString = [address stringByAppendingString:googleurl];
        [[self sendMessageTextView] setText:finalString];
    }
}

-(void)reloadView
{
    [[self.alMessageWrapper getUpdatedMessageArray] removeAllObjects];
    self.startIndex = 0;
    [self fetchMessageFromDB];
    [self loadChatView];
    [self setCallButtonInNavigationBar];
    [self showNoConversationLabel];
}

-(void)reloadViewfor3rdParty
{
    [[self.alMessageWrapper getUpdatedMessageArray] removeAllObjects];
    self.startIndex = 0;
    [self fetchMessageFromDB];
}

-(void)handleNotification:(UIGestureRecognizer *)gestureRecognizer
{
    ALNotificationView * notificationView = (ALNotificationView*)gestureRecognizer.view;
    self.contactIds = notificationView.contactId;
    [UIView animateWithDuration:0.5 animations:^{
        [self reloadView];

    }];
    [self markConversationRead];
    [UIView animateWithDuration:0.5 animations:^{
        [notificationView removeFromSuperview];
    }];
}

-(IBAction)loadEarlierButtonAction:(id)sender
{
    [self processLoadEarlierMessages:false];
}

-(void)processLoadEarlierMessages:(BOOL)isScrollToBottom
{
    NSNumber *time;
    if([self.alMessageWrapper getUpdatedMessageArray].count > 1 && [self.alMessageWrapper getUpdatedMessageArray] != NULL)
    {
        ALMessage * theMessage = [self.alMessageWrapper getUpdatedMessageArray][1];
        time = theMessage.createdAtTime;
    }
    else
    {
        ALSLog(ALLoggerSeverityInfo, @" time### %@ ",time);
        time = NULL;
    }

    [self.mActivityIndicator startAnimating];
    //preaper Message list request ....
    MessageListRequest * messageListRequest = [[MessageListRequest alloc] init];
    messageListRequest.userId = self.contactIds;
    messageListRequest.channelKey = self.channelKey;
    messageListRequest.endTimeStamp = time;

    if([ALApplozicSettings getContextualChatOption])
    {
        messageListRequest.conversationId = self.conversationId;
    }

    [[ALMessageService sharedInstance] getMessageListForUser:messageListRequest  withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {

        [self.mActivityIndicator stopAnimating];
        ALSLog(ALLoggerSeverityInfo, @"LIST_CALL_CALLED");
        if(self.conversationId && [ALApplozicSettings getContextualChatOption] && messages.count)
        {
            [self setupPickerView];
            [self.pickerView reloadAllComponents];
        }

        if(!error)
        {
            self.loadEarlierAction.hidden = YES;
            if(messages.count < 50)
            {
                if(self.conversationId && [ALApplozicSettings getContextualChatOption])
                {
                    [ALUserDefaultsHandler setShowLoadEarlierOption:NO forContactId:[self.conversationId stringValue]];
                }
                else
                {
                    NSString * IDs = (self.channelKey ? [self.channelKey stringValue] : self.contactIds);
                    [ALUserDefaultsHandler setShowLoadEarlierOption:NO forContactId:IDs];
                }
            }

            if(messages.count == 0)
            {
                if(self.conversationId && [ALApplozicSettings getContextualChatOption])
                {
                    [ALUserDefaultsHandler setShowLoadEarlierOption:NO forContactId:[self.conversationId stringValue]];
                }
                else
                {
                    NSString * IDs = (self.channelKey ? [self.channelKey stringValue] : self.contactIds);
                    [ALUserDefaultsHandler setShowLoadEarlierOption:NO forContactId:IDs];
                }

                return;
            }

            NSMutableArray * array = [self.alMessageWrapper getUpdatedMessageArray];

            if([array firstObject])
            {
                ALMessage *messgae = [array firstObject];
                if([messgae.type isEqualToString:@"100"])
                {
                    [array removeObjectAtIndex:0];
                }
            }
            for (ALMessage * msg in messages)
            {
                if([self.alMessageWrapper getUpdatedMessageArray].count > 0)
                {
                    ALMessage *msg1 = [[self.alMessageWrapper getUpdatedMessageArray] objectAtIndex:0];
                    if(msg1.createdAtTime.doubleValue <= msg.createdAtTime.doubleValue) {
                        ALSLog(ALLoggerSeverityInfo, @"ignoring as coming message has grater time..continue....");
                        continue;
                    }

                    if([self.alMessageWrapper checkDateOlder:msg.createdAtTime andNewer:msg1.createdAtTime])
                    {
                        ALMessage *dateCell = [self.alMessageWrapper getDatePrototype:self.alMessageWrapper.dateCellText andAlMessageObject:msg];
                        ALMessage *msg3 = [[self.alMessageWrapper getUpdatedMessageArray] objectAtIndex:0];
                        if(![msg3.type isEqualToString:@"100"] && ![msg3 isVOIPNotificationMessage])
                        {
                            [[self.alMessageWrapper getUpdatedMessageArray] insertObject:dateCell atIndex:0];
                        }
                    }
                }

                if( ![msg isHiddenMessage] )  // Filters Hidden Messages and VOIP Notifcation messages
                {
                    //ALSLog(ALLoggerSeverityInfo, @"insterting message at index 0 ::%@", msg.key);
                    [[self.alMessageWrapper getUpdatedMessageArray] insertObject:msg atIndex:0];
                    [self.noConLabel setHidden:YES];
                }
            }
            ALMessage * message = [array firstObject];
            if(message)
            {
                NSString * dateTxt = [self.alMessageWrapper msgAtTop:message];
                ALMessage * lastMsg = [self.alMessageWrapper getDatePrototype:dateTxt andAlMessageObject:message];
                [[self.alMessageWrapper getUpdatedMessageArray] insertObject:lastMsg atIndex:0];
            }
            //self.startIndex = self.startIndex + messages.count;

            CGFloat oldTableViewHeight = self.mTableView.contentSize.height;
            [self.mTableView reloadData];

            if(isScrollToBottom)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self scrollTableViewToBottomWithAnimation:NO];
                });
            }
            else
            {
                CGFloat newTableViewHeight = self.mTableView.contentSize.height;
                self.mTableView.contentOffset = CGPointMake(0, newTableViewHeight - oldTableViewHeight);
            }
        }
        else
        {
            self.loadEarlierAction.hidden = YES;
            ALSLog(ALLoggerSeverityError, @"some error");
        }
    }];
}

-(void)serverCallForLastSeen
{
    if([self isGroup] && self.alChannel.type != GROUP_OF_TWO)
    {
        return;
    }

    [ALUserService userDetailServerCall:self.contactIds withCompletion:^(ALUserDetail *alUserDetail)
    {
        if(alUserDetail)
        {
            [ALUserDefaultsHandler setServerCallDoneForUserInfo:YES ForContact:alUserDetail.userId];
            alUserDetail.unreadCount = 0;
            [[[ALContactDBService alloc] init] updateUserDetail:alUserDetail];
            [self setTitle];
            [self updateLastSeenAtStatus:alUserDetail];
            [self setCallButtonInNavigationBar];
            [self checkUserDeleted];
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"CHECK LAST_SEEN_SERVER CALL");
        }
    }];
}

-(void)updateLastSeenAtStatus: (ALUserDetail *) alUserDetail
{
    ALSLog(ALLoggerSeverityInfo, @"USER DET : %@",alUserDetail.userId);
    ALSLog(ALLoggerSeverityInfo, @"self.contactIds : %@",self.contactIds);
    [self setRefreshMainView:TRUE];

    double value = [alUserDetail.lastSeenAtTime doubleValue];
    ALContactService *cnService = [[ALContactService alloc] init];
    ALContact * contact = [cnService loadContactByKey:@"userId" value:alUserDetail.userId];
    if(self.channelKey != nil){
        if(contact.block || contact.blockBy){
            return;
        }
    }else{
        if(contact.block || contact.blockBy){
            [self.label setText:@""];
            return;
        }
    }


    if(self.channelKey != nil)
    {
        if(self.alChannel.type == GROUP_OF_TWO )
        {
            if(value > 0)
            {
                [self formatDateTime:alUserDetail andValue:value];
            }
            else
            {
                [self.label setText:@""];
            }
        }
        else if (self.alChannel.type != GROUP_OF_TWO)
        {
            [self.label setText:@""];

//            if([ALApplozicSettings isChannelMembersInfoInNavigationBarEnabled]){
//                [self.label setText:[channelService stringFromChannelUserList:self.channelKey]];
//            }else{
//                [self.label setText:@""];
//            }
        }
    }
    else if (value > 0)
    {
        if ([alUserDetail.userId isEqualToString:self.contactIds])
        {
            [self formatDateTime:alUserDetail andValue:value];
        }
    }
    else
    {
        [self.label setText:@""];
    }
    typingStat = NO;
}

-(void)updateLastSeenAtStatusPUSH:(NSNotification*)notification
{
    [self updateLastSeenAtStatus:notification.object];
}

//==============================================================================================================================================
#pragma mark - UPDATE USER STATUS HELPER METHOD
//==============================================================================================================================================

-(NSString *)formatDateTime:(ALUserDetail*)alUserDetail andValue:(double)value
{

    NSDate *current = [[NSDate alloc] init];
    NSDate *date  = [[NSDate alloc] initWithTimeIntervalSince1970:value/1000];

    NSTimeInterval difference = [current timeIntervalSinceDate:date];

    NSDate *today = [NSDate date];
    NSDate *yesterday = [today dateByAddingTimeInterval: -86400.0];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd/MM/yyyy"];
    NSString *todaydate = [format stringFromDate:current];
    NSString *yesterdaydate =[format stringFromDate:yesterday];
    NSString *serverdate =[format stringFromDate:date];


    if([serverdate compare:todaydate] == NSOrderedSame)
    {

        NSString *str = NSLocalizedStringWithDefaultValue(@"lastSeenLabelText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Last seen ", @"");

        double minutes = 2 * 60.00;
        if(alUserDetail.connected)
        {
            [self.label setText:NSLocalizedStringWithDefaultValue(@"onlineLabelText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Online", @"")];

        }
        else if(difference < minutes)
        {
            [self.label setText:NSLocalizedStringWithDefaultValue(@"lastSeenJustNowLabelText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Last seen Just Now ", @"")];

        }
        else
        {
            NSString *theTime;
            int hours =  difference / 3600;
            int minutes = (difference - hours * 3600 ) / 60;

            if(hours > 0)
            {
                theTime = [NSString stringWithFormat:@"%.2d:%.2d", hours, minutes];
                if([theTime hasPrefix:@"0"])
                {
                    theTime = [theTime substringFromIndex:[@"0" length]];
                }

                str = [str stringByAppendingString: [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"hrsAgo", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"%@ hrs ago", @""), theTime]];
            }
            else
            {
                theTime = [NSString stringWithFormat:@"%.2d", minutes];
                if([theTime hasPrefix:@"0"])
                {
                    theTime = [theTime substringFromIndex:[@"0" length]];
                }

                str = [str stringByAppendingString: [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"mins", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],@"%@ mins ago", @""), theTime]];

            }
            [self.label setText:str];
        }

    }
    else if ([serverdate compare:yesterdaydate] == NSOrderedSame)
    {

        NSString *str = NSLocalizedStringWithDefaultValue(@"lastSeenYesterday", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Last seen yesterday at %@", @"");
        [format setDateFormat:@"hh:mm a"];

        str = [NSString stringWithFormat:str,[format stringFromDate:date]];
        if([str hasPrefix:@"0"])
        {
            str = [str substringFromIndex:[@"0" length]];
        }
        [self.label setText:str];
    }
    else
    {
        [format setDateFormat:@"EE, MMM dd, yyy"];
        NSString *str = NSLocalizedStringWithDefaultValue(@"lastSeenLabelText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Last seen ", @"");

        str = [str stringByAppendingString:[format stringFromDate:date]];
        [self.label setText:str];
    }

    return self.label.text;
}
-(NSMutableArray *)getLastSeenForGroupDetails
{
    NSMutableArray * userDetailsArray = [[NSMutableArray alloc] init];
    ALContactService * contactDBService = [[ALContactService alloc] init];
    ALChannelDBService * channelDBService = [[ALChannelDBService alloc] init];

    NSMutableArray *memberIdArray= [NSMutableArray arrayWithArray:[channelDBService getListOfAllUsersInChannel:self.channelKey]];

    for (NSString * userID in memberIdArray)
    {
        ALContact * contact = [contactDBService loadContactByKey:@"userId" value:userID];
        ALUserDetail * userDetails = [[ALUserDetail alloc] init];
        userDetails.userId = userID;
        userDetails.lastSeenAtTime = contact.lastSeenAt;
        double value = contact.lastSeenAt.doubleValue;
        ALSLog(ALLoggerSeverityInfo, @"Contact :: %@ && Value :: %@", contact.userId, contact.lastSeenAt);
        if(contact.lastSeenAt == NULL)
        {
            [userDetailsArray addObject:@" "];
        }
        else
        {
            [userDetailsArray addObject:[self formatDateTime:userDetails andValue:value]];
        }
    }

    return userDetailsArray;
}

//==============================================================================================================================================
#pragma TEXT VIEW DELEGATE + PLUS HELPER METHODS
//==============================================================================================================================================

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if(self.alContact.applicationId == NULL)
    {
        self.alContact.applicationId = [ALUserDefaultsHandler getApplicationKey];
    }

    if ([textView.text isEqualToString:self.placeHolderTxt])
    {
        [self placeHolder:@"" andTextColor:[ALApplozicSettings getTextColorForMessageTextView]];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if(self.alContact.applicationId == NULL)
    {
        self.alContact.applicationId = [ALUserDefaultsHandler getApplicationKey];
    }
    if(typingStat == YES)
    {
        typingStat = NO;
        [self.mqttObject sendTypingStatus:self.alContact.applicationId userID:self.contactIds andChannelKey:self.channelKey typing:typingStat];
    }

    if ([textView.text isEqualToString:@""])
    {
        [self placeHolder:self.placeHolderTxt andTextColor:self.placeHolderColor];
    }
}

-(void)placeHolder:(NSString *)placeHolderText andTextColor:(UIColor *)textColor
{
    [self.sendMessageTextView setText:placeHolderText];
    [self.sendMessageTextView setTextColor:textColor];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrollOffset = scrollView.contentOffset.y;

    if(scrollView == self.sendMessageTextView)
    {
        return;
    }

    BOOL doneConversation =  NO;
    BOOL doneOtherwise = NO;

    if(self.conversationId && [ALApplozicSettings getContextualChatOption])
    {
        doneConversation = ([ALUserDefaultsHandler isShowLoadEarlierOption:[self.conversationId stringValue]]
                                 && [ALUserDefaultsHandler isServerCallDoneForMSGList:[self.conversationId stringValue]]);

    }
    else
    {
        NSString * IDs = (self.channelKey ? [self.channelKey stringValue] : self.contactIds);
        if(self.alChannel && self.alChannel.type == OPEN){
            doneOtherwise = ([ALUserDefaultsHandler isShowLoadEarlierOption:IDs]);
        }else{
            doneOtherwise = ([ALUserDefaultsHandler isShowLoadEarlierOption:IDs]
                             && [ALUserDefaultsHandler isServerCallDoneForMSGList:IDs]);
        }
    }

    if(scrollOffset == 0 && (doneConversation || doneOtherwise))
    {
        [self.loadEarlierAction setHidden:NO];
    }
    else
    {
        [self.loadEarlierAction setHidden:YES];
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
    if(self.isUserBlocked || self.isUserBlockedBy)
    {
        return;
    }
    if(typingStat == NO)
    {
        typingStat = YES;
        [self.mqttObject sendTypingStatus:self.alContact.applicationId userID:self.contactIds andChannelKey:self.channelKey typing:typingStat];
    }

    if ([[textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 && isAudioRecordingEnabled) {
        [self showMicButton];
    } else if(isAudioRecordingEnabled) {
        [self showSendButton];
//        [soundRecording hide];
        [self hideSoundRecordingView];
    }

    [self subProcessTextViewDidChange:textView];
}

-(void)subProcessTextViewDidChange:(UITextView *)textView
{
    CGRect textSize = [self sizeOfText:textView.text widthOfTextView:self.sendMessageTextView.textContainer.size.width
                              withFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:textView.font.pointSize]];

    if(minHeight.size.height == textSize.size.height)
    {
        if([textView.text isEqualToString:@""]|| [textView.text isEqualToString:self.placeHolderTxt])
        {
            [super setHeightOfTextViewDynamically:NO];
            self.textMessageViewHeightConstaint.constant = self.defaultMessageViewHeight;
        }
        //return;
    }

    if([textView.text isEqualToString:@""])
    {
        /*Incase user deletes the long text than animation is NOT required to set to default height!!*/
        [textView setScrollEnabled:NO];
        [super setHeightOfTextViewDynamically];
        //        NSLog(@"CASE EMPTY");
    }
    else if(textSize.size.height <= maxHeight.size.height)  //&& [self isNewLine:textView]
    {
        //Untill max rows are achieved than SCROLL
        [textView setScrollEnabled:NO];
        [UIView animateWithDuration:0.4 animations:^{
            [super setHeightOfTextViewDynamically:YES];
        }];
        //        NSLog(@"CASE INCRESE/DECREASE");
    }
    else
    {
        // If greater than MAX value Scroll instead of expanding the text view.
        if(self.sendMessageTextView.frame.size.height < maxHeight.size.height)
        {
            //  NSLog(@"MAX HIGHT");
            self.textMessageViewHeightConstaint.constant = TEXT_VIEW_TO_MESSAGE_VIEW_RATIO * maxHeight.size.height;
        }
        [textView setScrollEnabled:YES];
        //        NSLog(@"CASE SCROLL");
    }
}

-(CGRect)sizeOfText:(NSString *)textToMesure widthOfTextView:(CGFloat)width withFont:(UIFont*)font
{
    NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;

    NSDictionary *attr = @{
                           NSFontAttributeName:self.sendMessageTextView.font
                           };

    CGRect ts = [textToMesure boundingRectWithSize:CGSizeMake(width-20.0, FLT_MAX)
                               options:options
                            attributes:attr
                               context:nil];
    return ts;
}


-(BOOL)isNewLine:(UITextView *)textView
{
    BOOL flag = NO;
    UITextPosition *pos = textView.endOfDocument;   //explore others like beginningOfDocument if you want to customize the behaviour
    CGRect currentRect = [textView caretRectForPosition:pos];

    if (currentRect.origin.y != previousRect.origin.y)
    {
        //new line reached, write your code
        flag = YES;
    }
    previousRect = currentRect;
    return flag;
}

-(CGRect)getMaxSizeLines:(int)n
{
    NSString *saveText = self.sendMessageTextView.text, *newText = @"-";

    self.sendMessageTextView.delegate = nil;
    self.sendMessageTextView.hidden = YES;

    for (int i = 1; i < n; ++i)
        newText = [newText stringByAppendingString:@"\n|W|"];

    self.sendMessageTextView.text = newText;

    CGRect maximumHeight = [self sizeOfText:self.sendMessageTextView.text widthOfTextView:self.sendMessageTextView.textContainer.size.width
                                   withFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:self.sendMessageTextView.font.pointSize]];

    self.sendMessageTextView.text = saveText;
    self.sendMessageTextView.hidden = NO;
    self.sendMessageTextView.delegate = self;

    return maximumHeight;
}

//==============================================================================================================================================
#pragma mark - MQTT Service delegate methods
//==============================================================================================================================================

-(void)syncCall:(ALMessage *) alMessage andMessageList:(NSMutableArray*)messageArray
{
    [self syncCall:alMessage updateUI:[NSNumber numberWithInt:APP_STATE_ACTIVE] alertValue:alMessage.message];
}

//Message Delivered/Read
-(void)delivered:(NSString *)messageKey contactId:(NSString *)contactId withStatus:(int)status
{
   // if([[self contactIds] isEqualToString: contactId])
    //{
        [self updateDeliveryReport:messageKey withStatus:status];
    //}
}

//Conversation Delivered/Read
-(void)updateStatusForContact:(NSString *)contactId withStatus:(int)status
{
    if([[self contactIds] isEqualToString: contactId])
    {
        [self updateStatusReportForConversation:status];
    }
}

-(void)mqttDidConnected {

    ALSLog(ALLoggerSeverityInfo, @"MQTT_CONNECTED : CALL BACK COMES ALCHATVC");
    if (self.individualLaunch) {
        [self subscrbingChannel];
    }
}

//==============================================================================================================================================
#pragma mark - (MQTT + APNs) :UPDATING USER DETAILS (WHEN USER CHANGE ITS IMAGE/DISPLAY NAME)
//==============================================================================================================================================

-(void)updateUserDetail:(NSString *)userId  // MQTT DELEGATE
{
    ALSLog(ALLoggerSeverityInfo, @"ALCHATVC : USER_DETAIL_CHANGED_CALL_UPDATE");

    [ALUserService updateUserDetail:userId withCompletion:^(ALUserDetail *userDetail) {

        [[NSNotificationCenter defaultCenter] postNotificationName:@"USER_DETAIL_OTHER_VC" object:userDetail];
        [self subProcessDetailUpdate:userDetail];
    }];
}

-(void)subProcessDetailUpdate:(ALUserDetail *)userDetail  // (COMMON METHOD CALL FROM SELF and ALMSGVC)
{
    ALSLog(ALLoggerSeverityInfo, @"ALCHATVC : USER_DETAIL_SUB_PROCESS");
    if(![self isGroup] && [userDetail.userId isEqualToString:self.contactIds])
    {
        ALContactService *contactService = [ALContactService new];
        self.alContact = [contactService loadContactByKey:@"userId" value:userDetail.userId];
        [titleLabelButton setTitle:[self.alContact getDisplayName] forState:UIControlStateNormal];
    }
    [self.mTableView reloadData];
}

-(void)updateCallForUser:(NSNotification *)notifyObj // APNs HANDLER
{
    NSString *userID = (NSString *)notifyObj.object;
    [self updateUserDetail:userID];
}

-(void)reloadDataForUserBlockNotification:(NSString *)userId andBlockFlag:(BOOL)flag
{
    [self checkUserBlockStatus];
}

//==============================================================================================================================================
#pragma mark - UPDATING TYPING STATUS
//==============================================================================================================================================

-(void)showTypingLabel:(BOOL)flag userId:(NSString *)userId
{
    ALContactService *cntService = [ALContactService new];
    ALContact *contact = [cntService loadContactByKey:@"userId" value:userId];
    if(contact.block || contact.blockBy){
        return;
    }

    if(flag)
    {
        NSString * typingText = @"";
        if(self.channelKey)
        {
            typingText = [NSString stringWithFormat:@"%@ %@", [contact getDisplayName], NSLocalizedStringWithDefaultValue(@"userTyping", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],@"is typing...", @"")];
        }
        else
        {
            typingText = [NSString stringWithFormat:@"%@", NSLocalizedStringWithDefaultValue(@"userTyping", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],@"is typing...", @"")];
        }
        [self.label setHidden:NO];
        [self.label setText:typingText];
    }
    else
    {
        ALUserDetail *userDetail = [[ALUserDetail alloc] init];
        userDetail.connected = contact.connected;
        userDetail.userId = contact.userId;
        userDetail.lastSeenAtTime = contact.lastSeenAt;
        userDetail.contactNumber = contact.contactNumber;
        [self updateLastSeenAtStatus:userDetail];

    }
}

-(void)updateTypingStatus:(NSString *)applicationKey userId:(NSString *)userId status:(BOOL)status
{
    ALSLog(ALLoggerSeverityInfo, @"==== (CHAT_VC) Received typing status %d for: %@ ====", status, userId);
    if ([self.contactIds isEqualToString:userId] || self.channelKey)
    {
        [self showTypingLabel:status userId:userId];
    }
}

-(void)mqttConnectionClosed
{
    if(self.mqttRetryCount > MQTT_MAX_RETRY|| !(self.isViewLoaded && self.view.window))
    {
        return;
    }

    UIApplication *app = [UIApplication sharedApplication];
    BOOL isBackgroundState = (app.applicationState == UIApplicationStateBackground);

    if([ALDataNetworkConnection checkDataNetworkAvailable] && !isBackgroundState)
    {
        ALSLog(ALLoggerSeverityInfo, @"MQTT connection closed, subscribing again: %lu", (long)_mqttRetryCount);
        [self.mqttObject subscribeToConversation];
        [self subscrbingChannel];
        self.mqttRetryCount++;
    }
}

-(void)appWillEnterForegroundInChat:(NSNotification *)notification
{
    ALSLog(ALLoggerSeverityInfo, @"will enter foreground notification");
    // [self syncCall:self.contactIds updateUI:nil alertValue:nil];
}

-(void)addMessageToList:(NSMutableArray  *)messageList
{
    NSCompoundPredicate *compoundPredicate;
    NSPredicate * contentPredicate = [NSPredicate predicateWithFormat:@"contentType != %i", AV_CALL_CONTENT_TWO];

    if(self.isGroup)
    {
        NSPredicate * groupP = [NSPredicate predicateWithFormat:@"groupId = %@",self.channelKey];
        compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[groupP,contentPredicate]];
    }
    else
    {  //self.channelKey not Nil
        NSPredicate *groupPredicate=[NSPredicate predicateWithFormat:@"groupId == %d or groupId == nil",0];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"contactIds == %@",self.contactIds];
        compoundPredicate=[NSCompoundPredicate andPredicateWithSubpredicates:@[groupPredicate,predicate,contentPredicate]];
    }

    NSArray * theFilteredArray = [messageList filteredArrayUsingPredicate:compoundPredicate];
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
    NSArray *sortedArray = [theFilteredArray sortedArrayUsingDescriptors:descriptors];
    if(sortedArray.count==0){
        ALSLog(ALLoggerSeverityInfo, @"No message for contact .....%@",self.contactIds);
        return;
    }
    [self setTitle];

//    if([[self.alMessageWrapper getUpdatedMessageArray] count ] == 0 )
//    {
//        [self reloadView];
//    }
//    else
//    {
        [self.alMessageWrapper addLatestObjectToArray:[NSMutableArray arrayWithArray:sortedArray]];
        [self.mTableView reloadData];
        [self scrollTableViewToBottomWithAnimation:YES];

    if (self.comingFromBackground) {
        [self markConversationRead];
    }
    //}
}

-(void)newMessageHandler:(NSNotification *)notification
{
    ALSLog(ALLoggerSeverityInfo, @" newMessageHandler called ::#### ");
    NSMutableArray * messageArray = notification.object;

    [self addMessageToList:messageArray];
//    for (ALMessage * almessage in messageArray)
//    {
//        [self markSingleMessageRead:almessage];
//    }
    [self showNoConversationLabel];

}

-(void)appWillResignActive
{
    if(typingStat == YES)
    {
        typingStat = NO;
        [self.mqttObject sendTypingStatus:self.alContact.applicationId userID:self.contactIds andChannelKey:self.channelKey typing:typingStat];
    }
}

-(BOOL)isGroup
{
    return !(self.channelKey == nil || [self.channelKey intValue] == 0 || self.channelKey == NULL);
}

//==============================================================================================================================================
#pragma mark - DOCUMENT INTERACTION DELEGATE METHODS
//==============================================================================================================================================

-(void)showSuggestionView:(NSURL *)fileURL andFrame:(CGRect)frame
{
//    NSLog(@"CALL_GESTURE_SELECTOR_TO_DELEGATE_&_FILE_URL : %@", fileURL);
    interaction = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    interaction.delegate = self;

    // IF OPENING IN SAME VIEW
//   BOOL selfFlag = [interaction presentPreviewAnimated:YES];

    //IF NEED SUGGESTION MENU : IT WILL RUN ON DEVICE ONLY
   [interaction presentOpenInMenuFromRect:frame inView:self.view animated:YES];

}

-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

-(void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    interaction = nil;
}

//==============================================================================================================================================
#pragma mark - HANDLING ACTIVITY INDICATOR && PUSH VIEW CONTROLLER VIA DELEGATES
//==============================================================================================================================================

-(void)showAnimationForMsgInfo:(BOOL)flag
{
    [self startActivityAnimation:flag];
}

-(void)showAnimation:(BOOL)flag
{
    [self startActivityAnimation:flag];
}

-(void)startActivityAnimation:(BOOL)flag
{
    if([ALDataNetworkConnection checkDataNetworkAvailable] && flag)
    {
        [self.mActivityIndicator startAnimating];
    }
    else
    {
         [self.mActivityIndicator stopAnimating];
    }
}

-(void)showVideoFullScreen:(AVPlayerViewController *)fullView
{
    [self presentViewController:fullView animated:YES completion:^{
        [fullView.player play];
    }];
}

-(void)loadView:(UIViewController *)launch
{
    [self commonCodeForMsgInfo:launch];
}

-(void)loadViewForMedia:(UIViewController *)launch
{
    [self commonCodeForMsgInfo:launch];
}

-(void)commonCodeForMsgInfo:(UIViewController *)launch
{
    [self.mActivityIndicator stopAnimating];
    [self.navigationController pushViewController:launch animated:YES];
}

//==============================================================================================================================================
#pragma mark - CHAT CELL DELEGATE CALLED BY TAP GESTURE
//==============================================================================================================================================

-(void)processALMessage:(ALMessage *)message
{
    [self.chatViewDelegate handleCustomActionFromChatVC:self andWithMessage:message];
}

-(void)openUserChatOnTap:(NSString *)userId
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ThirdPartyProfileTapNotification
     object:nil
     userInfo:@{ThirdPartyDetailVCNotificationNavigationVC : self.navigationController,
                ThirdPartyDetailVCNotificationALContact : userId}
     ];
    BOOL tapFlag = ([ALApplozicSettings isChatOnTapUserProfile] && [self isGroup]);

    if (!tapFlag)
    {
        return;
    }

    [UIView transitionWithView:self.view duration:0.1
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{

                        self.channelKey = nil;
                        self.contactIds = userId;
                        self.conversationId = nil;
                        [self reloadView];
                        if(![ALUserDefaultsHandler isServerCallDoneForMSGList:userId])
                        {
                            [self processLoadEarlierMessages:YES];
                        }
                        [self markConversationRead];
                    }
                    completion:NULL];
}

-(void)openUserChat:(ALMessage *)alMessage
{
    [self openUserChatOnTap:alMessage.to];
}

-(void) processUserChatView:(ALMessage *)alMessage
{
    [self openUserChatOnTap:alMessage.to];
}



//================================================================================================================================
#pragma mark - FORWARD MESSAGE CALL
//================================================================================================================================

-(void) processForwardMessage:(ALMessage *) message
{

    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALNewContactsViewController *contactVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contactVC.directContactVCLaunchForForward = YES;
    contactVC.alMessage = message;
    contactVC.forwardDelegate = self;
    UINavigationController *conversationViewNavController = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [self presentViewController:conversationViewNavController animated:YES completion:nil];

}


//================================================================================================================================
#pragma mark - REPLY MESSAGE CALL
//================================================================================================================================


-(void) processMessageReply:(ALMessage *) message
{

    self.viewHeightConstraints.constant=50;
    self.messageReplyView.hidden =0;
    if([ALApplozicSettings isTemplateMessageEnabled]) {
        [templateMessageView setHidden:YES];
    }

    if(message.groupId != 0){
        if([[ALUserDefaultsHandler getUserId] isEqualToString:message.to] || message.to == nil){
            self.replyUserName.text = @"You";

        }else{
            ALContactDBService  *aLContactDBService = [ALContactDBService new];
            ALContact * contact = [aLContactDBService loadContactByKey:@"userId" value:message.to];
            self.replyUserName.text = contact.getDisplayName;
        }

    }else{

        if([message.type isEqualToString:OUT_BOX]){
            self.replyUserName.text = @"You";
        }else{
            ALContactDBService  *aLContactDBService = [ALContactDBService new];
            ALContact * contact = [aLContactDBService loadContactByKey:@"userId" value:message.to];
            self.replyUserName.text = contact.getDisplayName;
        }
    }
    self.messageReplyId = message.key;

    if(message.fileMeta){
        [self.replyAttachmentPreview setHidden:NO];
        [self.replyIcon setHidden:NO];

        if([message.fileMeta.contentType hasPrefix:@"audio"])
        {
            if([message.message length] != 0){
                self.replyMessageText.text = message.message;

            }else{
                self.replyMessageText.text = @"Audio";
            }

            [self.replyAttachmentPreview setHidden:YES];
            [self.replyIcon setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_mic.png"]];

        }else if([message.fileMeta.contentType hasPrefix:@"image"]){
            if([message.message length] != 0){
                self.replyMessageText.text = message.message;
            }else{
                self.replyMessageText.text = @"Image";
            }

            if (message.imageFilePath != NULL)
            {

                NSURL * theUrl;
                NSString * docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

                NSString * filePath = [docDirPath stringByAppendingPathComponent:message.imageFilePath];

                if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                    NSURL *docAppGroupURL = ALUtilityClass.getAppsGroupDirectory;
                    if(docAppGroupURL != nil){
                     [docAppGroupURL URLByAppendingPathComponent:message.imageFilePath];
                        theUrl = [NSURL fileURLWithPath:docAppGroupURL.path];
                    }
                }else{
                    theUrl = [NSURL fileURLWithPath:filePath];
                }
                [self showImage: theUrl];
            }
            else
            {
                ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
                [messageClientService downloadImageUrl:message.fileMeta.thumbnailBlobKey withCompletion:^(NSString *fileURL, NSError *error) {
                    if(error)
                    {
                        ALSLog(ALLoggerSeverityError, @"ERROR GETTING DOWNLOAD URL : %@", error);
                        return;
                    }
                    ALSLog(ALLoggerSeverityInfo, @"ATTACHMENT DOWNLOAD URL : %@", fileURL);
                    [self showImage: [NSURL URLWithString:fileURL]];
                }];

            }

        }else if([message.fileMeta.contentType hasPrefix:@"video"]){
            UIImage * globalThumbnail = [UIImage new];

            NSURL *theUrl;
            NSString * docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

            NSString * filePath = [docDirPath stringByAppendingPathComponent:message.imageFilePath];
            if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                NSURL *docAppGroupURL = [[ALUtilityClass getAppsGroupDirectory] URLByAppendingPathComponent:message.imageFilePath];
                if(docAppGroupURL != nil){
                    theUrl = [NSURL fileURLWithPath:docAppGroupURL.path];
                }
            }else{
                theUrl = [NSURL fileURLWithPath:filePath];
            }

            globalThumbnail = [ALUtilityClass subProcessThumbnail:theUrl];

            if([message.message length] != 0){
                self.replyMessageText.text = message.message;

            }else{
                self.replyMessageText.text = @"Video";
            }

            [self.replyAttachmentPreview setImage:globalThumbnail];
            [self.replyIcon setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_action_video.png"]];

        }
        else if(message.contentType == ALMESSAGE_CONTENT_VCARD)
        {

            if([message.message length] != 0){
                self.replyMessageText.text = message.message;
            }else{
                self.replyMessageText.text = @"Contact";
            }
            [self.replyAttachmentPreview setHidden:YES];
            [self.replyIcon setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_person.png"]];

        }else{
            [self.replyAttachmentPreview setHidden:YES];
            if([message.message length] != 0){
                self.replyMessageText.text = message.message;
            }else{
                self.replyMessageText.text = @"Attachment";
            }
            [self.replyIcon setImage:[ALUtilityClass getImageFromFramworkBundle:@"documentReceive.png"]];
        }
    }else  if(message.contentType == ALMESSAGE_CONTENT_LOCATION){

        [self.replyAttachmentPreview setHidden:NO];
        self.replyMessageText.text = @"Location";
        [self.replyIcon setHidden:NO];

        NSURL *theUrl = nil;
        if([ALDataNetworkConnection checkDataNetworkAvailable])
        {
            NSString * finalURl = [ALUtilityClass getLocationUrl:message];
            theUrl = [NSURL URLWithString:finalURl];
            [self.replyAttachmentPreview sd_setImageWithURL:theUrl];
        }
        else
        {
            [self.replyAttachmentPreview setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_map_no_data.png"]];
        }

        [self.replyIcon setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_location_on.png"]];

    }else{
        [self.replyAttachmentPreview setHidden:YES];
        [self.replyIcon setHidden:YES];
        self.replyMessageText.text = message.message;
    }

    ALMessageDBService* messageDBService = [[ALMessageDBService alloc]init];
    [messageDBService updateMessageReplyType:message.key replyType:[NSNumber numberWithInt:AL_A_REPLY]];

}

-(void) showImage:(NSURL *)url{
    [self.replyAttachmentPreview sd_setImageWithURL:url];
    [self.replyIcon setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_action_camera.png"]];
}

-(void) scrollToReplyMessage:(ALMessage *)alMessage
{
    //get reply type Id::
    NSString * messageReplyKey = [alMessage.metadata valueForKey:AL_MESSAGE_REPLY_KEY];
    NSIndexPath * indexPath=  [self getIndexPathForMessage:messageReplyKey];
    if(indexPath.row < self.alMessageWrapper.messageArray.count)
    {
        [self.mTableView scrollToRowAtIndexPath:indexPath
                               atScrollPosition:UITableViewScrollPositionTop
                                       animated:YES];
    }
    else
    {
        ALSLog(ALLoggerSeverityInfo, @"Reply cell not found..");
    }

}



//==============================================================================================================================================
#pragma mark - MEDIA BASE CELL DELEGATE CALLED BY TAP GESTURE
//==============================================================================================================================================

-(void) processTapGesture:(ALMessage *)alMessage
{
    [self.chatViewDelegate handleCustomActionFromChatVC:self andWithMessage:alMessage];
}

//==============================================================================================================================================
#pragma mark - RECEIVER USER INFOMATION HANDLER
//==============================================================================================================================================

-(void)getUserInformation
{
    if(![ALApplozicSettings getReceiverUserProfileOption])
    {
        return;
    }

    if ([ALApplozicSettings getOptionToPushNotificationToShowCustomGroupDetalVC]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ThirdPartyDetailVCNotification object:nil userInfo:@{ThirdPartyDetailVCNotificationNavigationVC : self.navigationController,
                                                                                                                        ThirdPartyDetailVCNotificationALContact : self.alContact
                                                                                                                        }];
    } else {
        [self.mActivityIndicator startAnimating];

        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Applozic"
                                                              bundle:[NSBundle bundleForClass:[self class]]];

        ALReceiverUserProfileVC * receiverUserProfileVC =
        (ALReceiverUserProfileVC *)[storyboard instantiateViewControllerWithIdentifier:@"ALReceiverUserProfile"];

        receiverUserProfileVC.alContact = self.alContact;
        [self.mActivityIndicator stopAnimating];
        [self.navigationController pushViewController:receiverUserProfileVC animated:YES];
    }
}

//==============================================================================================================================================
#pragma mark - TAP GESTURE TO RESIGN KEYBOARD WHEN TABLE HAVE LIMITED MESSAGES
//==============================================================================================================================================

-(void)hideKeyBoardOnEmptyList
{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handleTapGestureForKeyBoard)];

    tap.cancelsTouchesInView = NO;
    [self.mTableView addGestureRecognizer:tap];
}

-(void)handleTapGestureForKeyBoard
{

        if([self.sendMessageTextView isFirstResponder])
        {
            [self.sendMessageTextView resignFirstResponder];
        }

}

-(void)proccessReloadAndForwardMessage:(ALMessage *)alMessage{

    self.channelKey = alMessage.groupId;
    self.contactIds = alMessage.contactIds;
    [self reloadView];
    [self handleMessageForwardForChatView:alMessage];
}

-(void)saveVideoToGallery:(NSString *)filePath; {
    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, nil, nil);
}

#pragma mark - ALSoundRecorderProtocol

-(void) finishRecordingAudioWithFileUrl:(NSString *)fileURL {
    [self processAttachment:fileURL andMessageText:@"" andContentType:ALMESSAGE_CONTENT_AUDIO];
    [soundRecording hide];
}

-(void) startRecordingAudio {
    [soundRecording show];
}

-(void) cancelRecordingAudio {
    [soundRecording hide];
}

-(void) permissionNotGrant {
    [soundRecording hide];
}


- (IBAction)cancelMessageReply:(id)sender
{
    [self resetMessageReplyView];

}

-(void)resetMessageReplyView
{
    self.viewHeightConstraints.constant=0;
    self.messageReplyView.hidden =1;
    self.messageReplyId=nil;
    if([ALApplozicSettings isTemplateMessageEnabled]) {
        [templateMessageView setHidden:NO];
    }
}

#pragma mark - ALCustomPickerDelegate

- (void)multimediaSelected:(NSArray<ALMultimediaData *> *)list{
    NSMutableArray * multimediaList = [[NSMutableArray alloc]initWithArray: list];
    [self multipleAttachmentProcess:multimediaList andText:@""];
}

#pragma mark - ALAudioRecorderViewDelegate

- (void)cancelAudioRecording {
    [micButton cancelAudioRecord];
    [self cancelAudioRecord];
}

#pragma mark - ALAudioRecorderProtocol

- (void)moveButtonWithLocation:(CGPoint)location{
    [soundRecordingView moveViewWithLocation:location];
}

- (void)finishRecordingAudioWithFilePath:(NSString *)filePath {
    if ([soundRecordingView isRecordingTimeSufficient]) {
        [self processAttachment:filePath andMessageText:@"" andContentType:ALMESSAGE_CONTENT_AUDIO];
    }
    [soundRecordingView userDidStopRecording];
    [soundRecordingView setHidden:YES];
}

- (void)startAudioRecord {
    [soundRecordingView setHidden:NO];
    [soundRecordingView userDidStartRecording];
}

- (void)cancelAudioRecord {
    [soundRecordingView userDidStopRecording];
    [soundRecordingView setHidden:YES];
}

- (void)permissionNotGranted {
    [self hideSoundRecordingView];
}

- (void)onSendButtonClick:(NSString * _Nullable)filePath withReplyMessageKey:(NSString *)messageKey{

    self.messageReplyId = messageKey;
    [self processAttachment:filePath andMessageText:nil andContentType:ALMESSAGE_CONTENT_ATTACHMENT];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{

    if(urls != nil && urls.count){
        NSURL *filePath =  urls.firstObject;
        NSString *filePathString = [ALDocumentPickerHandler saveFile:filePath];
        [self processAttachment:filePathString andMessageText:@"" andContentType:ALMESSAGE_CONTENT_ATTACHMENT];
    }
}


- (void)onDownloadCompleted:(ALMessage *)alMessage {

    if(alMessage)
    {

        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath * path = [self getIndexPathForMessage:alMessage.key];
            if(path.row < [self.alMessageWrapper getUpdatedMessageArray].count){
                [self.alMessageWrapper getUpdatedMessageArray][path.row] = alMessage;
                [self.mTableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
            }

        });
    }
}

- (void)onDownloadFailed:(ALMessage *)alMessage {
    dispatch_async(dispatch_get_main_queue(), ^{

    ALMediaBaseCell * imageCell=  [self getCell:alMessage.key];
    imageCell.progresLabel.alpha = 0;
    imageCell.mDowloadRetryButton.alpha = 1;
    imageCell.downloadRetryView.alpha = 1;
    imageCell.sizeLabel.alpha = 1;
            });
}

- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)alMessage {
    ALMediaBaseCell*  cell=  [self getCell:alMessage.key];
    cell.progresLabel.endDegree = [self bytesConvertsToDegree:[alMessage.fileMeta.size floatValue] comingBytes:(CGFloat)bytesReceived];
}

- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)alMessage {

    ALMediaBaseCell*  cell =  [self getCell:alMessage.key];

    NSString * docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * filePath = [docDir  stringByAppendingPathComponent:alMessage.imageFilePath];

    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    cell.progresLabel.endDegree = [self bytesConvertsToDegree:(CGFloat)fileSize comingBytes:(CGFloat)bytesSent];
}

- (void)onUploadCompleted:(ALMessage *)alMessage withOldMessageKey:(NSString *)oldMessageKey{

    if(alMessage != nil){

           NSIndexPath * path = [self getIndexPathForMessage:oldMessageKey];
            if(path.row < [self.alMessageWrapper getUpdatedMessageArray].count){
            [self.alMessageWrapper getUpdatedMessageArray][path.row] = alMessage;
            [self.mTableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
          }
    }
}

- (void)onUploadFailed:(ALMessage *)alMessage {
    ALMediaBaseCell * imageCell=  [self getCell:alMessage.key];
    imageCell.progresLabel.alpha = 0;
    imageCell.mDowloadRetryButton.alpha = 1;
    imageCell.downloadRetryView.alpha = 1;
    imageCell.sizeLabel.alpha = 1;
}

@end
