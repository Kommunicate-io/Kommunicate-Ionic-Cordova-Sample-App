//
//  ALGroupDetailViewController.m
//  Applozic
//
//  Created by Divjyot Singh on 23/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//
#import "ALGroupDetailViewController.h"
#import "ALGroupDetailsMemberCell.h"
#import "ALChatViewController.h"
#import "ALChannel.h"
#import "ALApplozicSettings.h"
#import "UIImageView+WebCache.h"
#import "ALMessagesViewController.h"
#import "ALNotificationView.h"
#import "ALDataNetworkConnection.h"
#import "ALMQTTConversationService.h"
#import "ALGroupCreationViewController.h"
#import "ALPushAssist.h"
#import "ALChannelUser.h"
#import "ALMessageClientService.h"

@interface ALGroupDetailViewController () <ALGroupInfoDelegate>
{
    NSMutableOrderedSet *memberIds;
    CGFloat screenWidth;
    NSArray * colors;
    ALChannel *alchannel;
}

@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) ALMQTTConversationService * mqttObject;
@property (nonatomic, strong) ALChannel * alChannel;

@end

static NSString *const updateGroupMembersNotification = @"Updated_Group_Members";

@implementation ALGroupDetailViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.alChannel =[[ALChannelService new] getChannelByKey:self.channelKeyID];
    ALSLog(ALLoggerSeverityInfo, @"## self.alChannel :: %@", self.alChannel);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUser:) name:@"USER_DETAIL_OTHER_VC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupDetailsSyncCall:) name:updateGroupMembersNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAPNS:) name:@"pushNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMQTTNotification:) name:@"MQTT_APPLOZIC_01" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"USER_DETAIL_OTHER_VC" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:updateGroupMembersNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MQTT_APPLOZIC_01" object:nil];
}

-(void)updateUser:(NSNotification *)notifyObj
{
    [self.tableView reloadData];
}

-(void)showMQTTNotification:(NSNotification *)notifyObject
{
    ALMessage * alMessage = (ALMessage *)notifyObject.object;
    BOOL flag = (alMessage.groupId && [ALChannelService isChannelMuted:alMessage.groupId]);

    if (![alMessage.type isEqualToString:@"5"] && !flag && ![alMessage msgHidden])
    {
        ALNotificationView * alNotification = [[ALNotificationView alloc] initWithAlMessage:alMessage
                                                                           withAlertMessage:alMessage.message];
        [alNotification nativeNotification:self];
    }
}

-(void)handleAPNS:(NSNotification *)notification
{
    NSString * contactId = notification.object;
    ALSLog(ALLoggerSeverityInfo, @"GROUP_DETAIL_VC_NOTIFICATION_OBJECT : %@",contactId);
    NSDictionary *dict = notification.userInfo;
    NSNumber * updateUI = [dict valueForKey:@"updateUI"];
    NSString * alertValue = [dict valueForKey:@"alertValue"];

    NSArray * myArray = [contactId componentsSeparatedByString:@":"];
    NSNumber * channelKey = nil;
    if(myArray.count > 2)
    {
        channelKey = @([myArray[1] intValue]);
    }

    ALPushAssist *pushAssist = [ALPushAssist new];

    if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_ACTIVE]] && pushAssist.isGroupDetailViewOnTop)
    {
        ALMessage *alMessage = [[ALMessage alloc] init];
        alMessage.message = alertValue;
        NSArray *myArray = [alMessage.message componentsSeparatedByString:@":"];

        if(myArray.count > 1)
        {
            alertValue = [NSString stringWithFormat:@"%@", myArray[1]];
        }
        else
        {
            alertValue = myArray[0];
        }

        alMessage.message = alertValue;
        alMessage.contactIds = contactId;
        alMessage.groupId = channelKey;

        if ((alMessage.groupId && [ALChannelService isChannelMuted:alMessage.groupId]) || [alMessage msgHidden])
        {
            return;
        }

        ALNotificationView * alNotification = [[ALNotificationView alloc] initWithAlMessage:alMessage
                                                                           withAlertMessage:alMessage.message];
        [alNotification nativeNotification:self];
    }
    else if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_INACTIVE]])
    {
        ALSLog(ALLoggerSeverityInfo, @"######## GROUP DETAIL VC : APP_STATE_INACTIVE #########");

        ALGroupDetailViewController * groupDetailVC = self;
        ALMessagesViewController *msgVC = (ALMessagesViewController *)[self.navigationController.viewControllers objectAtIndex:0];

        if(channelKey)
        {
            msgVC.channelKey = channelKey;
        }
        else
        {
            msgVC.channelKey = nil;
        }

        ALChatViewController * chatVC = (ALChatViewController *)self.alChatViewController;
        NSMutableArray * viewsArray = [NSMutableArray arrayWithArray:msgVC.navigationController.viewControllers];
        [viewsArray removeObject:chatVC];
        msgVC.navigationController.viewControllers = viewsArray;
        [msgVC createDetailChatViewController:contactId];
        viewsArray = [NSMutableArray arrayWithArray:msgVC.navigationController.viewControllers];
        [viewsArray removeObject:groupDetailVC];
        msgVC.navigationController.viewControllers = viewsArray;
    }

}

-(void)setNavigationColor
{
    if([ALApplozicSettings getColorForNavigation] && [ALApplozicSettings getColorForNavigationItem])
    {
        //        self.navigationController.navigationBar.translucent = NO;
        [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                           NSForegroundColorAttributeName:[ALApplozicSettings getColorForNavigationItem],
                                                                           NSFontAttributeName: [UIFont fontWithName:[ALApplozicSettings getFontFace]
                                                                                                                size:18]
                                                                           }];

        [self.navigationController.navigationBar addSubview:[ALUtilityClass setStatusBarStyle]];
        [self.navigationController.navigationBar setBarTintColor:[ALApplozicSettings getColorForNavigation]];
        [self.navigationController.navigationBar setTintColor:[ALApplozicSettings getColorForNavigationItem]];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)setupView
{

    [self.tabBarController.tabBar setHidden:YES];
    [self.tableView setHidden:YES];
    [self setNavigationColor];
    [self setTitle: NSLocalizedStringWithDefaultValue(@"groupDetailsTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Group Details", @"")];

    ALChannelService * channnelService = [[ALChannelService alloc] init];
    self.alChannel = [channnelService getChannelByKey:self.channelKeyID];
    self.groupName = self.alChannel.name;
    colors = [[NSArray alloc] initWithObjects:@"#617D8A",@"#628B70",@"#8C8863",@"8B627D",@"8B6F62", nil];

    screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView.backgroundColor = [UIColor lightGrayColor];

    [self getChannelMembers];

}

-(void)getChannelMembers
{
    [[self activityIndicator] startAnimating];
    ALChannelDBService * channelDatabaseService = [[ALChannelDBService alloc ]init];
    [channelDatabaseService fetchChannelMembersAsyncWithChannelKey:self.channelKeyID witCompletion:^(NSMutableArray *membersArray) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->memberIds = [NSMutableOrderedSet orderedSetWithArray:membersArray];
            self.memberCount = self->memberIds.count;
            [self.tableView setHidden:NO];
            [self.tableView reloadData];
            [[self activityIndicator] stopAnimating];
        });
    }];
}

-(void)groupDetailsSyncCall:(NSNotification *) notification
{
    ALChannel *channel = notification.object;
    if(channel != nil && self.channelKeyID == channel.key){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupView];
        });
    }
}


//------------------------------------------------------------------------------------------------------------------
#pragma mark - Table View DataSource Methods
//------------------------------------------------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        {
            ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];

            ALChannelUserX *alChannelUserX =  [channelDBService loadChannelUserXByUserId:self.channelKeyID andUserId:[ALUserDefaultsHandler getUserId]];

            if(alChannelUserX.role.intValue != MEMBER && ![self isThisChannelLeft:self.channelKeyID] && [ALApplozicSettings getGroupMemberAddOption])
                return 3;
            else
                return 2;
        }break;
        case 1:
        {
            return memberIds.count;
        }break;
        case 2:
        {
            if([ALApplozicSettings getGroupExitOption])
            {
                return 1;
            }
            else
            {
                return 0;
            }
        }break;
        default:
        {
            return 0;
        }
    }
}




#pragma mark - Table Row Height
//================================
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 3)
    {
        return 100;
    }
    return 65.5;
}

#pragma mark - Table Row Select
//================================
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [self noDataNotificationView];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    switch (indexPath.section)
    {
        case 0:
        {
            if(indexPath.row == 0){

                [self updateGroupView];

            }
            if(indexPath.row == 1){

                if([self.alChannel isNotificationMuted])
                {
                    [self unmuteGroup];

                }else{

                    [self showActionSheet];
                }
            }
            else if(indexPath.row==2)
            {
                [self addNewMember];

            }
        }
            break;
        case 1:
        {
            ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
            ALChannelUserX *alChannelUserX =  [channelDBService loadChannelUserXByUserId:self.channelKeyID andUserId:[ALUserDefaultsHandler getUserId]];

            if(alChannelUserX.role.intValue != MEMBER
               && ![self isThisChannelLeft:self.channelKeyID]
               &&  [ALApplozicSettings getGroupMemberRemoveOption]){
                [self removeMember:indexPath.row];
            }
        }break;
        case 2:{
            //Exit group
            [self checkAndconfirm: NSLocalizedStringWithDefaultValue(@"confirmText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Confirm", @"")
                      withMessage:NSLocalizedStringWithDefaultValue(@"areYouSureText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Are you sure?", @"")
                 otherButtonTitle: NSLocalizedStringWithDefaultValue(@"yes", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Yes", @"")
             ];

        }break;

        default:break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Add New Member Methods
//==================================
-(void)addNewMember
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:self.class]];

    ALNewContactsViewController *contactsVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];

    contactsVC.contactsInGroup = [NSMutableArray arrayWithArray:[memberIds array]];
    contactsVC.forGroup = [NSNumber numberWithInt:GROUP_ADDITION];
    contactsVC.delegate = self;

    // check if this launch for subgroup
    ALChannelService * channelService = [[ALChannelService alloc] init];

    if([ALApplozicSettings getSubGroupLaunchFlag])
    {
        ALChannel *parentChannel = [channelService getChannelByKey:self.alChannel.parentKey ? self.alChannel.parentKey : self.alChannel.key];
        contactsVC.parentChannel = parentChannel;
        contactsVC.childChannels = [[NSMutableArray alloc] initWithArray:[channelService fetchChildChannelsWithParentKey:parentChannel.key]];
    }
    [self.navigationController pushViewController:contactsVC animated:YES];
}

-(void)addNewMembertoGroup:(ALContact *)alcontact withCompletion:(void(^)(NSError *error,ALAPIResponse *response))completion
{
    [[self activityIndicator] startAnimating];
    self.memberIdToAdd = alcontact.userId;
    ALChannelService * channelService = [[ALChannelService alloc] init];
    [channelService addMemberToChannel:self.memberIdToAdd andChannelKey:self.channelKeyID orClientChannelKey:nil
                        withCompletion:^(NSError *error, ALAPIResponse *response) {

                            if(!error && [response.status isEqualToString:@"success"])
                            {
                                [self->memberIds addObject:self.memberIdToAdd];
                                [self.tableView reloadData];

                            }
                            [[self activityIndicator] stopAnimating];
                            completion(error,response);
                        }];
}

-(NSString *)getLastSeenForMember:(NSString*)userID withLastSeenAtTime:(NSNumber*) lastSeenAtTime
{

    ALUserDetail * userDetails = [[ALUserDetail alloc] init];
    userDetails.userId = userID;
    userDetails.lastSeenAtTime = lastSeenAtTime;

    double value = userDetails.lastSeenAtTime.doubleValue;
    NSString * lastSeen;
    if(lastSeenAtTime == NULL){
        lastSeen = @" ";
    }else{
        lastSeen = [(ALChatViewController*)self.alChatViewController formatDateTime:userDetails andValue:value];
    }

    return lastSeen;
}

#pragma mark - Check and confirm
//================================
-(void)checkAndconfirm:(NSString*)title withMessage:(NSString*)message otherButtonTitle:(NSString*)buttonTitle
{

    UIAlertController * uiAlertController = [UIAlertController
                                             alertControllerWithTitle:title
                                             message:message
                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:NSLocalizedStringWithDefaultValue(@"okText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"OK" , @"")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {

                                   ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                   ALChannel *channel = [channelDBService loadChannelByKey:self.channelKeyID];
                                   if(![self isThisChannelLeft:self.channelKeyID] && !channel.isBroadcastGroup)
                                   {
                                       [self turnUserInteractivityForNavigationAndTableView:NO];
                                       ALChannelService * alchannelService = [[ALChannelService alloc] init];
                                       [alchannelService leaveChannel:self.channelKeyID andUserId:[ALUserDefaultsHandler getUserId]
                                                   orClientChannelKey:nil withCompletion:^(NSError *error) {

                                                       if(!error)
                                                       {
                                                           NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
                                                           for (UIViewController *viewController in allViewControllers)
                                                           {
                                                               if ([viewController isKindOfClass: [ALChatViewController class]])
                                                               {
                                                                   [self.navigationController popToViewController:viewController animated:YES];
                                                               }
                                                           }
                                                       }
                                                   }];
                                   }
                                   else
                                   {
                                       //DELETE CHANNEL CONVERSATION
                                       [ALMessageService deleteMessageThread:nil orChannelKey:self.channelKeyID withCompletion:^(NSString *string, NSError *error) {

                                           if(error)
                                           {
                                               ALSLog(ALLoggerSeverityError, @"DELETE FAILED: Unable to delete contact conversation : %@", error.description);
                                               [ALUtilityClass displayToastWithMessage:NSLocalizedStringWithDefaultValue(@"deleteFailed", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Delete failed!", @"")];
                                               return;
                                           }
                                           //DELETE CHANNEL FROM LOCAL AND BACK TO MAIN VIEW
                                           ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                           [channelDBService deleteChannel:self.channelKeyID];
                                           ALChatViewController *chatVC = (ALChatViewController *)self.alChatViewController;
                                           if(chatVC.individualLaunch)
                                           {
                                               [self dismissViewControllerAnimated:YES completion:nil];
                                           }
                                           else
                                           {
                                               NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
                                               for (UIViewController *viewController in allViewControllers)
                                               {
                                                   if ([ALPushAssist isViewObjIsMsgVC:viewController] || [ALPushAssist isViewObjIsMsgContainerVC:viewController])
                                                   {
                                                       [self.navigationController popToViewController:viewController animated:YES];
                                                   }
                                               }
                                           }
                                       }];
                                   }
                                   [self turnUserInteractivityForNavigationAndTableView:YES];
                               }];

    UIAlertAction* cancelButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedStringWithDefaultValue(@"cancelText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel" , @"")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {

                                   }];

    [uiAlertController addAction:okButton];
    [uiAlertController addAction:cancelButton];
    [self.navigationController presentViewController:uiAlertController animated:NO completion:nil];
}

-(BOOL)isThisChannelLeft:(NSNumber *)channelKey
{
    ALChannelService * alChannelService = [[ALChannelService alloc] init];
    BOOL flag = [alChannelService isChannelLeft:channelKey];
    return flag;
}


#pragma mark - Remove Memember (for admin)
//=======================================
-(void)removeMember:(NSInteger)row
{

    NSString* removeMemberID = [NSString stringWithFormat:@"%@",memberIds[row]];

    if([removeMemberID isEqualToString:[ALUserDefaultsHandler getUserId]])
    {
        return;
    }
    else
    {

        ALContactDBService *alContactDBService = [[ALContactDBService alloc]init];
        ALContact * alContact = [alContactDBService loadContactByKey:@"userId" value:removeMemberID];


        UIAlertController * theController = [UIAlertController alertControllerWithTitle:nil
                                                                                message:nil
                                                                         preferredStyle:UIAlertControllerStyleActionSheet];

        [ALUtilityClass setAlertControllerFrame:theController andViewController:self];

        [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];

        if ([ALApplozicSettings isChatOnTapUserProfile])
        {
            [theController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:[NSLocalizedStringWithDefaultValue(@"messageText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Message", @"") stringByAppendingString: @" %@"], [alContact getDisplayName]]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {

                                                                [self openChatThreadFor:removeMemberID];
            }]];

        }


        ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
        ALChannelUserX *alChannelUserX =  [channelDBService loadChannelUserXByUserId:self.channelKeyID andUserId:memberIds[row]];

        ALChannelUserX *alChannelUserXLoggedInUser =  [channelDBService loadChannelUserXByUserId:self.channelKeyID andUserId:[ALUserDefaultsHandler getUserId]];

        if(alChannelUserXLoggedInUser.isAdminUser){

            UIAlertAction *removeAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:[NSLocalizedStringWithDefaultValue(@"removeText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Remove", @"") stringByAppendingString: @" %@"], [alContact getDisplayName]]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {

                                                                     [self turnUserInteractivityForNavigationAndTableView:NO];
                                                                     ALChannelService * alchannelService = [[ALChannelService alloc] init];
                                                                     [alchannelService removeMemberFromChannel:removeMemberID andChannelKey:self.channelKeyID
                                                                                            orClientChannelKey:nil withCompletion:^(NSError *error, ALAPIResponse *response) {

                                                                                                if(!error)
                                                                                                {
                                                                                                    [self->memberIds removeObjectAtIndex:row];
                                                                                                    [self setupView];
                                                                                                    [self.tableView reloadData];
                                                                                                }

                                                                                                [self turnUserInteractivityForNavigationAndTableView:YES];
                                                                                            }];

                                                                 }];


            [removeAction setValue:[UIColor redColor] forKey:@"titleTextColor"];
            [theController addAction:removeAction];

        }

            ALChannel *channel = [channelDBService loadChannelByKey:self.channelKeyID];

            if(!alChannelUserX.isAdminUser  && !channel.isBroadcastGroup){

            [theController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:[NSLocalizedStringWithDefaultValue(@"makeAdminText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Make admin", @"") stringByAppendingString: @" %@"]
                                                                     , [alContact getDisplayName]]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {

                                                                ALChannelService *channelService = [ALChannelService new];
                                                                ALChannelUser * alChannelUsers = [ALChannelUser new];
                                                                alChannelUsers.role = [NSNumber numberWithInt:1];
                                                                alChannelUsers.userId = self->memberIds[row];
                                                                NSMutableArray * channelUsers = [NSMutableArray new];
                                                                [channelUsers addObject:alChannelUsers.dictionary];

                                                                [channelService updateChannel:self.channelKeyID andNewName:nil
                                                                                  andImageURL:nil orClientChannelKey:nil isUpdatingMetaData:NO metadata:nil orChildKeys:nil orChannelUsers: channelUsers withCompletion:^(NSError *error) {

                                                                                      if(!error)
                                                                                      {

                                                                                          [ALUtilityClass showAlertMessage: NSLocalizedStringWithDefaultValue(@"groupSuccessFullyUpdateInfo", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Group information successfully updated", @"") andTitle:NSLocalizedStringWithDefaultValue(@"responseText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Reponse", @"")];
                                                                                          [self setupView];
                                                                                          [self.tableView reloadData];
                                                                                      }
                                                                                  }];
                                                            }]];
        }



        [self presentViewController:theController animated:YES completion:nil];
    }
}

-(void)turnUserInteractivityForNavigationAndTableView:(BOOL)option{

    [self.view setUserInteractionEnabled:option];
    [[self tableView] setUserInteractionEnabled:option];
    [[[self navigationController] navigationBar] setUserInteractionEnabled:option];

    if(option == YES){
        [[self activityIndicator] stopAnimating];
    }
    else{
        [[self activityIndicator] startAnimating];
    }

}

-(void)updateTableView{
    [self.tableView reloadData];
}

-(void)openChatThreadFor:(NSString*) contactId {
    int index = 0;
    if([self.navigationController.viewControllers.firstObject
        isKindOfClass: [ALMessagesViewController class]]) {
        index = 1;
    }
    ALChatViewController *chatVC = (ALChatViewController *)[self.navigationController.viewControllers objectAtIndex:index];
    chatVC.contactIds = contactId;

    chatVC.channelKey = nil;
    [self.navigationController popViewControllerAnimated:true];
    chatVC.refresh = true;
}

#pragma mark - Table View Data Source
//========================
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALGroupDetailsMemberCell *memberCell = (ALGroupDetailsMemberCell*)[tableView dequeueReusableCellWithIdentifier:@"GroupMemberCell" forIndexPath:indexPath];

    [memberCell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];

    dispatch_async(dispatch_get_main_queue(), ^{

        [self setupCellItems:memberCell];
        [memberCell.lastSeenTimeLabel setHidden:YES];
        [memberCell.profileImageView setHidden:YES];
        [memberCell.nameLabel setTextColor:[UIColor blackColor]];
        [memberCell.nameLabel  setFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:15]];
        [memberCell.nameLabel setTextAlignment:NSTextAlignmentCenter];
        [memberCell.adminLabel setHidden:YES];
        [memberCell.lastSeenTimeLabel setHidden:YES];

        switch (indexPath.section)
        {
            case 0:
            {
                memberCell.nameLeftConstraint.constant = 0;
                if(indexPath.row == 0)
                {
                    [memberCell.nameLabel setFont:[UIFont boldSystemFontOfSize:18]];
                    memberCell.nameLabel.text = [NSString stringWithFormat:@"%@", self.groupName];
                }
                else if(indexPath.row==1)
                {

                    memberCell.nameLabel.text = [self.alChannel isNotificationMuted]
                    ? [NSString stringWithFormat: NSLocalizedStringWithDefaultValue(@"unMuteGroup", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Unmute Group", @"")]
                    : [NSString stringWithFormat: NSLocalizedStringWithDefaultValue(@"muteGroup", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Mute Group", @"") ];
                }
                else
                {
                    memberCell.nameLabel.textColor = self.view.tintColor;
                    memberCell.nameLabel.text = NSLocalizedStringWithDefaultValue(@"addNewMember", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Add New Member", @"");

                }
            }break;
            case 1:
            {
                [self setMemberIcon:indexPath.row withCell:memberCell];
            }break;
            case 2:
            {
                [memberCell.nameLabel setTextColor:[UIColor redColor]];

                ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                ALChannel *channel = [channelDBService loadChannelByKey:self.channelKeyID];
                NSString * labelTitle;
                if(channel.isBroadcastGroup){
                    labelTitle = NSLocalizedStringWithDefaultValue(@"deleteBroadcast", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Delete Broadcast", @"");
                }else{

                    labelTitle =  [self isThisChannelLeft:self.channelKeyID]?
                    NSLocalizedStringWithDefaultValue(@"deleteGroup", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Delete Group", @""):   NSLocalizedStringWithDefaultValue(@"exitGroup", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Exit Group", @"");

                }
                memberCell.nameLabel.text = labelTitle;
            }break;
            default:break;
        }
    });

    return memberCell;
}


-(void)setMemberIcon:(NSInteger)row withCell:(ALGroupDetailsMemberCell*)memberCell
{

    ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
    ALChannelUserX *alChannelUserX = [channelDBService loadChannelUserXByUserId:self.channelKeyID andUserId:memberIds[row]];

    ALContactDBService * alContactDBService = [[ALContactDBService alloc] init];
    ALContact * alContact = [alContactDBService loadContactByKey:@"userId" value:memberIds[row]];


    if(alChannelUserX.isAdminUser)
    {
        [memberCell.adminLabel setHidden:NO];
    }

    //    Member Name Label
    [memberCell.lastSeenTimeLabel setTextAlignment:NSTextAlignmentNatural];
    [memberCell.nameLabel setTextAlignment:NSTextAlignmentNatural];
    if([alContact.userId isEqualToString:[ALUserDefaultsHandler getUserId]]){
        memberCell.nameLabel.text = NSLocalizedStringWithDefaultValue(@"youText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"You", @"");
    }else{
        memberCell.nameLabel.text =  [alContact getDisplayName];
    }

    [memberCell.alphabeticLabel setHidden:YES];
    [memberCell.profileImageView setHidden:NO];

    if (![alContact.userId isEqualToString:[ALUserDefaultsHandler getUserId]])
    {
        [memberCell.lastSeenTimeLabel setHidden:NO];
        [memberCell.lastSeenTimeLabel setText:[self getLastSeenForMember:alContact.userId withLastSeenAtTime:alContact.lastSeenAt]];
    }

    if (alContact.localImageResourceName)
    {
        UIImage *someImage = [ALUtilityClass getImageFromFramworkBundle:alContact.localImageResourceName];
        [memberCell.profileImageView  setImage:someImage];
    }
    else if(alContact.contactImageUrl)
    {
        ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
        [messageClientService downloadImageUrlAndSet:alContact.contactImageUrl imageView:memberCell.profileImageView defaultImage:@"ic_contact_picture_holo_light.png"];
    }
    else
    {
        [memberCell.alphabeticLabel setHidden:NO];
        memberCell.alphabeticLabel.text = [[alContact getDisplayName] substringToIndex:1];
        NSUInteger randomIndex = random()% [colors count];
        memberCell.profileImageView.image = [ALColorUtility imageWithSize:CGRectMake(0,0,55,55) WithHexString:colors[randomIndex]];
    }
}

-(void)setupCellItems:(ALGroupDetailsMemberCell*)memberCell
{
    memberCell.profileImageView.clipsToBounds = YES;
    memberCell.profileImageView.layer.cornerRadius =  memberCell.profileImageView.frame.size.width/2;
    memberCell.alphabeticLabel.textColor = [UIColor whiteColor];
    [memberCell.adminLabel setText:NSLocalizedStringWithDefaultValue(@"adminText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Admin", @"")];
    memberCell.adminLabel.textColor = [UIColor blackColor];

}

#pragma mark Row Height
//===============================

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

#pragma mark - Display Header/Footer View
//======================================
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // For Header's Text View

}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.contentView.backgroundColor = [UIColor lightGrayColor];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

#pragma mark -  Header View
//===========================
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    if (section == 0)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:
                                  [ALUtilityClass getImageFromFramworkBundle:@"applozic_group_icon.png"]];

        ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
        [messageClientService downloadImageUrlAndSet:self.alChannel.channelImageURL imageView:imageView defaultImage:nil];

        imageView.frame = CGRectMake((screenWidth/2)-30, 20, 60, 60);
        imageView.backgroundColor = [UIColor blackColor];
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = imageView.frame.size.width/2;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 70)];
        view.backgroundColor = [ALApplozicSettings getColorForNavigation];

        [imageView setUserInteractionEnabled:YES];
        [view addSubview:imageView];
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(updateGroupView)];
        singleTap.numberOfTapsRequired = 1;
        [imageView addGestureRecognizer:singleTap];

        return view;
    }
    else if(section == 1)
    {
        UILabel * memberSectionHeaderTitle = [[UILabel alloc] init];
        memberSectionHeaderTitle.text = NSLocalizedStringWithDefaultValue(@"groupDetailsTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Group Details", @"");

        CGSize textSize = [memberSectionHeaderTitle.text sizeWithAttributes:@{NSFontAttributeName:memberSectionHeaderTitle.font}];

        memberSectionHeaderTitle.frame=CGRectMake([UIScreen mainScreen].bounds.origin.x + 5,
                                                  [UIScreen mainScreen].bounds.origin.y + 35,
                                                  textSize.width, textSize.height);

        [memberSectionHeaderTitle setTextAlignment:NSTextAlignmentLeft];
        [memberSectionHeaderTitle setTextColor:[UIColor colorWithWhite:0.3 alpha:0.7]];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(memberSectionHeaderTitle.frame.origin.x,
                                                                memberSectionHeaderTitle.frame.origin.y,
                                                                memberSectionHeaderTitle.frame.size.width,
                                                                memberSectionHeaderTitle.frame.size.height)];

        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
            [memberSectionHeaderTitle setTextAlignment:NSTextAlignmentRight];
            view.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            memberSectionHeaderTitle.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }else{
            [memberSectionHeaderTitle setTextAlignment:NSTextAlignmentLeft];
        }
        [view addSubview:memberSectionHeaderTitle];
        //        view.backgroundColor=[UIColor colorWithWhite:0.7 alpha:1];
        view.backgroundColor = [UIColor colorWithRed:245.0/255 green:245.0/255 blue:245.0/255 alpha:1];
        return view;

    }
    else{
        return nil;
    }
}

-(void)noDataNotificationView
{
    ALNotificationView * notification = [ALNotificationView new];
    [notification noDataConnectionNotificationView];
}

-(void)updateGroupView
{

    if([ALApplozicSettings isGroupInfoEditDisabled] || [ALChannelService isConversationClosed: alchannel.key] ){
        ALSLog(ALLoggerSeverityInfo, @"group edit is disabled");
        return;
    }

    ALChannelService *channelService = [ALChannelService new];
    if([channelService isChannelLeft:self.channelKeyID] || [ALChannelService isChannelDeleted:self.channelKeyID])
    {
        [ALUtilityClass showAlertMessage: NSLocalizedStringWithDefaultValue(@"yourNotAparticipantOfGroup", nil, [NSBundle mainBundle], @"You are not a participant of this group", @"")   andTitle:NSLocalizedStringWithDefaultValue(@"unableToProcess", nil, [NSBundle mainBundle], @"Unable process !!!", @"")];
        return;
    }

    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:[self class]]];
    ALGroupCreationViewController * grpUpdate = [storyBoard instantiateViewControllerWithIdentifier:@"ALGroupCreationViewController"];
    grpUpdate.isViewForUpdatingGroup = YES;
    grpUpdate.channelKey = self.channelKeyID;
    grpUpdate.grpInfoDelegate = self;
    grpUpdate.channelName = self.alChannel.name;
    grpUpdate.groupImageURL = self.alChannel.channelImageURL;
    [self.navigationController pushViewController:grpUpdate animated:YES];
}

-(void)updateGroupInformation
{
    [self.tableView reloadData];
}


-(void) showActionSheet
{

    UIAlertController * theController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [ALUtilityClass setAlertControllerFrame:theController andViewController:self];

    [theController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];


    [theController addAction:[UIAlertAction actionWithTitle:[@"8 " stringByAppendingString:NSLocalizedStringWithDefaultValue(@"hrs", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Hrs", @"")] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        [self sendMuteRequestWithButtonIndex:0];
    }]];


    [theController addAction:[UIAlertAction actionWithTitle: [@"1 " stringByAppendingString:NSLocalizedStringWithDefaultValue(@"week", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Week", @"")] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        [self sendMuteRequestWithButtonIndex:1];
    }]];


    [theController addAction:[UIAlertAction actionWithTitle: [@"1 " stringByAppendingString:NSLocalizedStringWithDefaultValue(@"year", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Year", @"")]  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        [self sendMuteRequestWithButtonIndex:2];
    }]];

    [self presentViewController:theController animated:YES completion:nil];

}

-(void)sendMuteRequestWithButtonIndex:(NSInteger)buttonIndex {

    long currentTimeStemp = [[NSNumber numberWithLong:([[NSDate date] timeIntervalSince1970]*1000)] longValue];


    NSNumber * notificationAfterTime =0;

    switch(buttonIndex){

        case 0:

            notificationAfterTime= [NSNumber numberWithLong:(currentTimeStemp + 8*60*60*1000)];
            break;

        case 1:
            notificationAfterTime= [NSNumber numberWithDouble:(currentTimeStemp + 7*24*60*60*1000)];
            break;

        case 2:
            notificationAfterTime= [NSNumber numberWithDouble:(currentTimeStemp + 365*24*60*60*1000)];
            break;

        default:break;
    }

    if(notificationAfterTime)
    {
        [self sendMuteRequestWithTime:notificationAfterTime];
    }

}


-(void) unmuteGroup {
    long secsUtc1970 = [[NSNumber numberWithDouble:[[NSDate date]timeIntervalSince1970] ] longValue ]*1000L;

    [self sendMuteRequestWithTime:[NSNumber numberWithLong:secsUtc1970]];
}


-(void) sendMuteRequestWithTime:(NSNumber*) time{

    ALMuteRequest * alMuteRequest = [ALMuteRequest new];
    alMuteRequest.id = self.channelKeyID;
    alMuteRequest.notificationAfterTime= time;
    ALChannelService *alChannelService = [[ALChannelService alloc]init];
    [[self activityIndicator] startAnimating];
    [alChannelService muteChannel:alMuteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {
        ALSLog(ALLoggerSeverityInfo, @"actionSheet response from server:: %@", response.status);
        [[self activityIndicator] stopAnimating];
        self.alChannel.notificationAfterTime= alMuteRequest.notificationAfterTime;
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];

    }];
}
@end
