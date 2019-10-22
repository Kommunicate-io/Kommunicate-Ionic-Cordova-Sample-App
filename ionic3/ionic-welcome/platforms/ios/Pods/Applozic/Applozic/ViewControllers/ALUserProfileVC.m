//
//  ALUserProfileVC.m
//  Applozic
//
//  Created by devashish on 30/06/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+Utility.h"
#import "ALUserProfileVC.h"
#import "ALApplozicSettings.h"
#import "ALUtilityClass.h"
#import "ALConnectionQueueHandler.h"
#import "ALUserDefaultsHandler.h"
#import "ALImagePickerHandler.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALNotificationView.h"
#import "ALDataNetworkConnection.h"
#import "ALUserService.h"
#import "ALRegisterUserClientService.h"
#import "UIImageView+WebCache.h"
#import "ALContactService.h"
#import "ALConstant.h"
#import "ALMessagesViewController.h"
#import "ALPushAssist.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserService.h"
#import "ALUserDetail.h"
#import "ALHTTPManager.h"

@interface ALUserProfileVC ()

@property (nonatomic, retain) UIImagePickerController * mImagePicker;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UISwitch *notificationToggle;
@property (strong, nonatomic) IBOutlet UILabel *userStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel *profileStatus;

@property (strong, nonatomic) IBOutlet UILabel *notificationTitle;
@property (strong, nonatomic) IBOutlet UILabel *mobileNotification;
@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UISwitch *onlineToggleSwitch;

- (IBAction)editButtonAction:(id)sender;
@end

@implementation ALUserProfileVC
{
    NSString *mainFilePath;
    NSString *imageLinkFromServer;
    
    ALContact * myContact;
    ALContactService * alContactService;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Scales down the switch
    self.notificationToggle.transform = CGAffineTransformMakeScale(0.75, 0.75);
    self.onlineToggleSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
    
    [self.profileMainImage setBackgroundColor:[ALApplozicSettings getProfileMainColour]];
    [self.profileMainView setBackgroundColor:[ALApplozicSettings getProfileSubColour]];
    [self.mobileNotification setTextColor:[ALApplozicSettings getProfileMainColour]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showMQTTNotification:)
                                                 name:@"MQTT_APPLOZIC_01"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAPNS:)
                                                 name:@"pushNotification"
                                               object:nil];
    
    self.mImagePicker = [UIImagePickerController new];
    self.mImagePicker.delegate = self;
    self.mImagePicker.allowsEditing = YES;
    
    if([ALApplozicSettings getColorForNavigation] && [ALApplozicSettings getColorForNavigationItem])
    {
        self.navigationController.navigationBar.translucent = NO;
        [self commonNavBarTheme:self.navigationController];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width/2;
        self.profileImage.layer.masksToBounds = YES;
        
        self.uploadImageButton.layer.cornerRadius = self.uploadImageButton.frame.size.width/2;
        self.uploadImageButton.layer.masksToBounds = YES;
    });
    
    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"profileTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Profile", @"");
    
    [self.profileImage setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_contact_picture_holo_light.png"]];
    NSData *imageData = [NSData dataWithContentsOfFile:[ALUserDefaultsHandler getProfileImageLink]];
    NSURL *serverImageURL = [NSURL URLWithString:[ALUserDefaultsHandler getProfileImageLinkFromServer]];
    if(imageData)
    {
        UIImage *imageFile = [UIImage imageWithData:imageData];
        [self.profileImage setImage:imageFile];
    }
    else if(serverImageURL)
    {
        [self.profileImage sd_setImageWithURL:serverImageURL];
    }
    
    alContactService = [[ALContactService alloc] init];
    myContact = [alContactService loadContactByKey:@"userId" value:[ALUserDefaultsHandler getUserId]];
    self.userNameLabel.text = [myContact getDisplayName];
    self.userDesignationLabel.text = @"";
    [self.userStatusLabel setText:[ALUserDefaultsHandler getLoggedInUserStatus] ? [ALUserDefaultsHandler getLoggedInUserStatus] :     NSLocalizedStringWithDefaultValue(@"emptyLabelProfileText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Profile Status", @"")];
    
    
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        self.userView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.userNameLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.profileImage.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.userStatusLabel.textAlignment = NSTextAlignmentRight;
        self.profileStatus.textAlignment = NSTextAlignmentRight;
        self.notificationTitle.textAlignment = NSTextAlignmentRight;
        self.mobileNotification.textAlignment = NSTextAlignmentRight;
    }
    
    [self.profileStatus setText: NSLocalizedStringWithDefaultValue(@"profileStatusTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Profile Status", @"")];
    [self.notificationTitle setText:NSLocalizedStringWithDefaultValue(@"notificationsTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Notifications", @"")];
    
    [self.mobileNotification setText:NSLocalizedStringWithDefaultValue(@"mobileNotificationsTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Mobile Notifications", @"")];
    
    
    BOOL checkMode = ([ALUserDefaultsHandler getNotificationMode] == NOTIFICATION_DISABLE);
    [self.notificationToggle setOn:(!checkMode) animated:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MQTT_APPLOZIC_01" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
}

-(void)commonNavBarTheme:(UINavigationController *)navigationController
{
    [navigationController.navigationBar setTitleTextAttributes: @{
                                                                  NSForegroundColorAttributeName:[ALApplozicSettings getColorForNavigationItem],
                                                                  NSFontAttributeName:[UIFont fontWithName:[ALApplozicSettings getFontFace]
                                                                                                      size:18]
                                                                  }];
    
    [navigationController.navigationBar setBarTintColor: [ALApplozicSettings getColorForNavigation]];
    [navigationController.navigationBar setTintColor:[ALApplozicSettings getColorForNavigationItem]];
    [navigationController.navigationBar addSubview:[ALUtilityClass setStatusBarStyle]];
}

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self commonNavBarTheme:navigationController];
}

-(void)showMQTTNotification:(NSNotification *)notifyObject
{
    ALMessage * alMessage = (ALMessage *)notifyObject.object;
    
    BOOL flag = (alMessage.groupId && [ALChannelService isChannelMuted:alMessage.groupId]);
    
    if (![alMessage.type isEqualToString:@"5"] && !flag && ![alMessage isMsgHidden])
    {
        ALNotificationView * alNotification = [[ALNotificationView alloc] initWithAlMessage:alMessage
                                                                           withAlertMessage:alMessage.message];
        
        [alNotification nativeNotification:self];
    }
}

-(void)handleAPNS:(NSNotification *)notification
{
    NSString * contactId = notification.object;
    ALSLog(ALLoggerSeverityInfo, @"USER_PROFILE_VC_NOTIFICATION_OBJECT : %@",contactId);
    NSDictionary *dict = notification.userInfo;
    NSNumber * updateUI = [dict valueForKey:@"updateUI"];
    NSString * alertValue = [dict valueForKey:@"alertValue"];
    
    ALPushAssist *pushAssist = [ALPushAssist new];
    
    NSArray * myArray = [contactId componentsSeparatedByString:@":"];
    NSNumber * channelKey = nil;
    if(myArray.count > 2)
    {
        channelKey = @([myArray[1] intValue]);
    }
    
    if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_ACTIVE]] && pushAssist.isUserProfileVCOnTop)
    {
        ALSLog(ALLoggerSeverityInfo, @"######## USER PROFILE VC : APP_STATE_ACTIVE #########");
        
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
        
        if ((channelKey && [ALChannelService isChannelMuted:alMessage.groupId]) || [alMessage isMsgHidden])
        {
            return;
        }
        
        ALNotificationView * alNotification = [[ALNotificationView alloc] initWithAlMessage:alMessage
                                                                           withAlertMessage:alMessage.message];
        [alNotification nativeNotification:self];
    }
    else if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_INACTIVE]])
    {
        ALSLog(ALLoggerSeverityInfo, @"######## USER PROFILE VC : APP_STATE_INACTIVE #########");
        
        [self.tabBarController setSelectedIndex:0];
        UINavigationController *navVC = (UINavigationController *)self.tabBarController.selectedViewController;
        ALMessagesViewController *msgVC = (ALMessagesViewController *)[[navVC viewControllers] objectAtIndex:0];
        if(channelKey)
        {
            msgVC.channelKey = channelKey;
        }
        else
        {
            msgVC.channelKey = nil;
        }
        [msgVC createDetailChatViewController:contactId];
    }
}

//#pragma mark - Table view data source   [newContactCell.contactPersonImageView sd_setImageWithURL:[NSURL URLWithString:contact.contactImageUrl]];
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)uploadImageAction:(id)sender {
    [self uploadImage];
}

- (IBAction)notificationToggle:(id)sender {
    
    BOOL flag = [self.notificationToggle isOn];
    if([ALDataNetworkConnection noInternetConnectionNotification])
    {
        [self.notificationToggle setOn:(!flag) animated:YES];
        return;
    }
    
    [self.activityIndicator startAnimating];
    
    short modeValue = 2;
    if(flag)
    {
        modeValue = 0;
    }
    
    [ALRegisterUserClientService updateNotificationMode:modeValue withCompletion:^(ALRegistrationResponse *response, NSError *error) {
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE :: %@",response.message);
        ALSLog(ALLoggerSeverityError, @"RESPONSE_ERROR :: %@",error.description);
        if(!error)
        {
            
            [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"notificationStatusUpdateText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Notification setting updated!!!", @"") andTitle:NSLocalizedStringWithDefaultValue(@"alertText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Alert", @"")];
            [ALUserDefaultsHandler setNotificationMode:modeValue];
            [self.notificationToggle setOn:flag animated:YES];
        }
        else
        {
            [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"unableToUpdateText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Unable to update!!!", @"") andTitle:NSLocalizedStringWithDefaultValue(@"alertText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Alert", @"")];
            [self.notificationToggle setOn:(!flag) animated:YES];
        }
        [self.activityIndicator stopAnimating];
    }];
}

-(void)uploadImage
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    [ALUtilityClass setAlertControllerFrame:alertController andViewController:self];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"photoLibraryText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Photo Library", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self uploadByPhotos];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"takePhotoText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Take Photo", @"")
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                            
                                                            [self uploadByCamera];
                                                        }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)uploadByPhotos
{
    self.mImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.mImagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
    [self presentViewController:self.mImagePicker animated:YES completion:nil];
}

-(void)uploadByCamera
{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (granted)
                {
                    self.mImagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    self.mImagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                    [self presentViewController:self.mImagePicker animated:YES completion:nil];
                }
                else
                {
                    [ALUtilityClass permissionPopUpWithMessage:
                     NSLocalizedStringWithDefaultValue(@"permissionPopMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable Camera Permission", @"")
                                             andViewController:self];
                }
            });
        }];
    }
    else
    {
        
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"permissionNotAvailableMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Camera is not Available !!!", @"") andTitle:@"OOPS !!!"];
    }
}

//==============================================================================================================================
#pragma IMAGE PICKER DELEGATES
//==============================================================================================================================

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    
    UIImage * rawImage = [info valueForKey:UIImagePickerControllerEditedImage];
    UIImage * normalImage = [ALUtilityClass getNormalizedImage:rawImage];
    [self.profileImage setImage:normalImage];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    mainFilePath = [self getImageFilePath:normalImage];
    [self confirmUserForProfileImage:normalImage];
}


-(void)confirmUserForProfileImage:(UIImage *)image
{
    
    image = [image getCompressedImageLessThanSize:1];
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle: NSLocalizedStringWithDefaultValue(@"confirmationText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Confirmation" , @"") message:NSLocalizedStringWithDefaultValue(@"areYouSureText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Are you sure?" , @"")
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [ALUtilityClass setAlertControllerFrame:alert andViewController:self];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"CANCEL" , @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction* upload = [UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"uploadOption", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Upload" , @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        if(![ALDataNetworkConnection checkDataNetworkAvailable])
        {
            [self showNoDataNotification];
            return;
        }
        
        NSString * uploadUrl = [KBASE_URL stringByAppendingString:IMAGE_UPLOAD_URL];

        ALHTTPManager * manager = [[ALHTTPManager alloc]init];
        [manager uploadProfileImage:image withFilePath:self->mainFilePath uploadURL:uploadUrl withCompletion:^(NSData * _Nullable data, NSError *error) {

            if(error == nil){
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *imageLinkFromServer = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    ALSLog(ALLoggerSeverityInfo, @"PROFILE IMAGE URL :: %@",imageLinkFromServer);
                    self->imageLinkFromServer = imageLinkFromServer;
                    ALUserService *userService = [ALUserService new];
                    [userService updateUserDisplayName:@"" andUserImage:imageLinkFromServer userStatus:@"" withCompletion:^(id theJson, NSError *error) {

                        ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_IMAGE_UPDATE :: %@",(NSString *)theJson);
                        ALSLog(ALLoggerSeverityError, @"ERROR :: %@",error.description);
                        if(!error)
                        {
                            ALSLog(ALLoggerSeverityInfo, @"IMAGE_UPDATED_SUCCESSFULLY");

                            [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"imageUpdateText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Image Updated Successfully!!!" , @"")  andTitle:NSLocalizedStringWithDefaultValue(@"alertText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Alert" , @"") ];
                            [ALUserDefaultsHandler setProfileImageLinkFromServer:self->imageLinkFromServer];

                        }
                    }];
                });
            }

         dispatch_async(dispatch_get_main_queue(), ^{
             [self.activityIndicator stopAnimating];
            });
        }];

    }];

    
    [alert addAction:cancel];
    [alert addAction:upload];
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(void)showNoDataNotification
{
    ALNotificationView * notification = [ALNotificationView new];
    [notification noDataConnectionNotificationView];
}

-(NSString *)getImageFilePath:(UIImage *)image
{
    NSString *filePath = [ALImagePickerHandler saveImageToDocDirectory:image];
    [ALUserDefaultsHandler setProfileImageLink:filePath];
    return filePath;
}

-(IBAction)editButtonAction:(id)sender
{
    [self alertViewForStatus];
}

-(void)alertViewForStatus
{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedStringWithDefaultValue(@"yorStatusAlertTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Your Status" , @"")
                                                                             message:
                                          NSLocalizedStringWithDefaultValue(@"maxCharForStatus", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"(Max 256 characters)" , @"")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [ALUtilityClass setAlertControllerFrame:alertController andViewController:self];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        textField.placeholder = NSLocalizedStringWithDefaultValue(@"alertProfileStatusMessage", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Write status here..." , @"");
        
        
        
    }];
    
    
    [alertController addAction:[UIAlertAction actionWithTitle:  NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"CANCEL" , @"")
                                
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"okText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"OK" , @"")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          
                                                          UITextField *statusField = alertController.textFields.firstObject;
                                                          if(statusField.text.length && ![statusField.text isEqualToString:self.userStatusLabel.text])
                                                          {
                                                              
                                                              NSString * statusText = statusField.text;
                                                              if(statusText.length >= 256)
                                                              {
                                                                  statusText = [statusText substringToIndex:255];
                                                              }
                                                              
                                                              [self.activityIndicator startAnimating];
                                                              
                                                              ALUserService *userService = [ALUserService new];
                                                              [userService updateUserDisplayName:self.userNameLabel.text
                                                                                    andUserImage:@""
                                                                                      userStatus:statusText
                                                                                  withCompletion:^(id theJson, NSError *error) {
                                                                                      
                                                                                      ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_STATUS_UPDATE :: %@", (NSString *)theJson);
                                                                                      ALSLog(ALLoggerSeverityError, @"ERROR :: %@",error.description);
                                                                                      
                                                                                      if(!error)
                                                                                      {
                                                                                          ALSLog(ALLoggerSeverityInfo, @"USER_STATUS_UPDATED_SUCCESSFULLY");
                                                                                          self->myContact.userStatus = statusText;
                                                                                          ALSLog(ALLoggerSeverityInfo, @"USER_STATUS_UPDATED_SUCCESSFULLY  %@", self->myContact.userStatus);
                                                                                          [self->alContactService updateContact:self->myContact];
                                                                                          [self.userStatusLabel setText: statusText];
                                                                                          [ALUserDefaultsHandler setLoggedInUserStatus:statusText];
                                                                                          
                                                                                      }
                                                                                      
                                                                                      [self.activityIndicator stopAnimating];
                                                                                      
                                                                                  }];
                                                          }
                                                          
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}


@end
