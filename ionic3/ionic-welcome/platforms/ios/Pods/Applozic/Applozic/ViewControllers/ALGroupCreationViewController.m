//
//  ALGroupCreationViewController.m
//  Applozic
//
//  Created by Divjyot Singh on 13/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

//groupNameInput
//groupIcon
#define DEFAULT_GROUP_ICON_IMAGE ([UIImage imageNamed:@"applozic_group_icon.png"])

#import "ALGroupCreationViewController.h"
#import "ALNewContactsViewController.h"
#import "ALChatViewController.h"
#import "ALConnectionQueueHandler.h"
#import "UIImage+Utility.h"
#import "ALApplozicSettings.h"
#import "ALUtilityClass.h"
#import "ALUserDefaultsHandler.h"
#import "ALImagePickerHandler.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALNotificationView.h"
#import "ALDataNetworkConnection.h"
#import "ALRegisterUserClientService.h"
#import "UIImageView+WebCache.h"
#import "ALContactService.h"
#import "ALVOIPNotificationHandler.h"
#import "ALHTTPManager.h"

@interface ALGroupCreationViewController ()

@property (nonatomic,strong) UIImagePickerController * mImagePicker;
@property (nonatomic,strong) NSString * mainFilePath;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation ALGroupCreationViewController
{
    UIBarButtonItem *nextContacts;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    nextContacts = [[UIBarButtonItem alloc] init];
    [nextContacts setStyle:UIBarButtonItemStylePlain];
    [nextContacts setTarget:self];

    self.navigationItem.rightBarButtonItem = nextContacts;
    
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        self.groupNameInput.textAlignment = NSTextAlignmentRight;
    }
    
    
    self.groupNameInput.placeholder = NSLocalizedStringWithDefaultValue(@"groupNameTextField", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Type your group name", @"");
    
    [self.descriptionTextView setText: NSLocalizedStringWithDefaultValue(@"descriptionTextForGroup", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Please provide group name", @"")];
    
    if(self.isViewForUpdatingGroup)
    {
        [self setTitle:NSLocalizedStringWithDefaultValue(@"groupUpdateViewText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Group Update", @"")];
        [nextContacts setTitle:NSLocalizedStringWithDefaultValue(@"updateUiButtonText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Update", @"")];
        [nextContacts setAction:@selector(updateGroupInfo:)];
        self.groupNameInput.text = self.channelName;
        [self setProfileImage];
    }
    else
    {   [self setTitle:NSLocalizedStringWithDefaultValue(@"groupTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Create Group", @"")];
        [nextContacts setTitle:NSLocalizedStringWithDefaultValue(@"nextUiButtonText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Next", @"")];
        [nextContacts setAction:@selector(launchContactSelection:)];
    }
    
    
    self.automaticallyAdjustsScrollViewInsets = NO; //setting to NO helps show UITextView's text at view load
    [self setupGroupIcon];
    
    self.mImagePicker = [[UIImagePickerController alloc] init];
    self.mImagePicker.delegate = self;
    self.mImagePicker.allowsEditing = YES;
    
    [self.activityIndicator setHidesWhenStopped:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.groupNameInput becomeFirstResponder];
    self.descriptionTextView.hidden = NO;
    self.descriptionTextView.userInteractionEnabled = NO;
    [self.tabBarController.tabBar setHidden:YES];
    // self.alNewContactViewController.delegateGroupCreation = self;
}

-(void)setProfileImage
{
    NSURL *imageURL = [NSURL URLWithString:self.groupImageURL];
    if(imageURL.path.length)
    {
        [self.groupIconView sd_setImageWithURL:imageURL placeholderImage:nil options:SDWebImageRefreshCached];
    }
    else
    {
        [self.groupIconView setImage:DEFAULT_GROUP_ICON_IMAGE];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

//=========================================================================================================================================
#pragma mark - NAVIGATION RIGHT BUTTON SELECTORS : CREATION/UPDATE
//=========================================================================================================================================

- (void)launchContactSelection:(id)sender
{
    //Check if group name text is empty
    if([self.groupNameInput.text isEqualToString:@""])
    {
        
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle: NSLocalizedStringWithDefaultValue(@"groupNameInfo", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Group Name", @"")
                                              message: NSLocalizedStringWithDefaultValue(@"groupNameEmptyAlertMessage", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Please give the group name.", @"")
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [ALUtilityClass setAlertControllerFrame:alertController andViewController:self];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedStringWithDefaultValue(@"okText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"OK", @"")                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       ALSLog(ALLoggerSeverityInfo, @"OK action");
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    //Moving forward to member selection
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic"
                                                         bundle:[NSBundle bundleForClass:ALGroupCreationViewController.class]];
    ALNewContactsViewController *contactsVC = [storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    
    //Setting groupName and forGroup flag
    contactsVC.forGroup = [NSNumber numberWithInt:GROUP_CREATION];
    contactsVC.groupName = self.groupNameInput.text;
    contactsVC.groupImageURL = self.groupImageURL;
    
    if([ALApplozicSettings getSubGroupLaunchFlag])
    {
        ALChannelService *channelService = [ALChannelService new];
        ALChannel *parentChannel = [channelService getChannelByKey:self.parentChannelKey];
        contactsVC.parentChannel = parentChannel;
        contactsVC.childChannels = [[NSMutableArray alloc] initWithArray:[channelService fetchChildChannelsWithParentKey:parentChannel.key]];
    }
    
    //Moving to contacts view for group member selection
    [self.navigationController pushViewController:contactsVC animated:YES];
}

- (void)updateGroupInfo:(id)sender
{
    if(!self.groupNameInput.text.length)
    {
        [ALUtilityClass showAlertMessage:
         NSLocalizedStringWithDefaultValue(@"youHaveNotUpdatedAnything", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"You haven't update anything", @"")  andTitle:NSLocalizedStringWithDefaultValue(@"wait", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Wait!!!", @"")];
        return;

    }
    [self.loadingIndicator startAnimating];
    
    ALChannelService *channelService = [ALChannelService new];
    
    NSString* changedName;
    
    if(self.channelName != nil && [self.groupNameInput.text isEqualToString:self.channelName]){
        changedName = nil;
    }else{
        changedName = self.groupNameInput.text;
    }
    ALChannel *oldChannel =  [channelService getChannelByKey:self.channelKey ];
    BOOL isIngoreUpdating = NO;
    if(oldChannel != nil && oldChannel.channelImageURL != NULL && [oldChannel.channelImageURL isEqualToString:self.groupImageURL]){
        self.groupImageURL = nil;
        isIngoreUpdating = YES;
    }
    
    [channelService updateChannel:self.channelKey andNewName:changedName
                      andImageURL:self.groupImageURL orClientChannelKey:nil isUpdatingMetaData:isIngoreUpdating
                         metadata:nil orChildKeys:nil orChannelUsers:nil  withCompletion:^(NSError *error) {
        
          if(!error)
          {
        
              ALSLog(ALLoggerSeverityInfo, @"ALGroupCreationViewController updated the group info");
              [self.navigationController popViewControllerAnimated:YES];
              [self.grpInfoDelegate updateGroupInformation];
          }
          [self.loadingIndicator stopAnimating];
    }];
}

//=========================================================================================================================================
#pragma mark - GROUP ICON VIEW SETUP
//=========================================================================================================================================

-(void)setupGroupIcon
{
    dispatch_async(dispatch_get_main_queue(), ^{
          self.groupIconView.layer.cornerRadius = self.groupIconView.frame.size.width/2;
          self.groupIconView.layer.masksToBounds = YES;
          self.groupIconView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    });
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(uploadImage)];
    singleTap.numberOfTapsRequired = 1;
    [self.groupIconView addGestureRecognizer:singleTap];
}


-(void)uploadImage
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [ALUtilityClass setAlertControllerFrame:alertController andViewController:self];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"photoLibraryText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Photo Library", @"")style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self uploadByPhotos];
    }]];
    
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"takePhotoText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Take Photo", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [self uploadByCamera];
    }]];
    
    if(self.isViewForUpdatingGroup && self.groupImageURL.length)
    {
        UIAlertAction * removeAction = [UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"removePhoto", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Remove Photo", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            self.groupImageURL = @"";
            [self setProfileImage];
        }];
        
        [removeAction setValue:[UIColor redColor] forKey:@"titleTextColor"];
        [alertController addAction:removeAction];
    }
    
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
                    
                    [ALUtilityClass permissionPopUpWithMessage:NSLocalizedStringWithDefaultValue(@"permissionPopMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable Camera Permission", @"") andViewController:self];
                }
            });
        }];
    }
    else
    {
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"permissionNotAvailableMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Camera is not Available !!!", @"") andTitle:NSLocalizedStringWithDefaultValue(@"oppsText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"OPPS !!", @"")];
        
        
    }
}


//=========================================================================================================================================
#pragma mark - IMAGE PICKER DELEGATES
//=========================================================================================================================================

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage * rawImage = [info valueForKey:UIImagePickerControllerEditedImage];
    UIImage * normalizedImage = [ALUtilityClass getNormalizedImage:rawImage];
    [self.groupIconView setImage:normalizedImage];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.mainFilePath = [self getImageFilePath:normalizedImage];
    [self confirmUserForGroupImage:normalizedImage];
}

-(NSString *)getImageFilePath:(UIImage *)image
{
    NSString *filePath = [ALImagePickerHandler saveImageToDocDirectory:image];
    return filePath;
}

-(void)confirmUserForGroupImage:(UIImage *)image
{
    image = [image getCompressedImageLessThanSize:1];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringWithDefaultValue(@"confirmationText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Confirmation!", @"")
                                                                    message:NSLocalizedStringWithDefaultValue(@"areYouSureForUploadText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Are you sure to upload?!", @"")
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [ALUtilityClass setAlertControllerFrame:alert andViewController:self];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel!", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self.groupIconView setImage:DEFAULT_GROUP_ICON_IMAGE];
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction* upload = [UIAlertAction actionWithTitle: NSLocalizedStringWithDefaultValue(@"upload", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Upload!", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

        [self.activityIndicator startAnimating];

        if(![ALDataNetworkConnection checkDataNetworkAvailable])
        {
            ALNotificationView * notification = [ALNotificationView new];
            [notification noDataConnectionNotificationView];
            [self.activityIndicator stopAnimating];
            return;
        }
        
        NSString * uploadUrl = [KBASE_URL stringByAppendingString:IMAGE_UPLOAD_URL];
        
        self.groupImageUploadURL = uploadUrl;

        ALHTTPManager * manager = [[ALHTTPManager alloc]init];
        [manager uploadProfileImage:image withFilePath:self.mainFilePath uploadURL:uploadUrl withCompletion:^(NSData * _Nullable data, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(error == nil){

                    NSString *imageLinkFromServer = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    ALSLog(ALLoggerSeverityInfo, @"GROUP_IMAGE_LINK :: %@",imageLinkFromServer);
                    self.groupImageURL = imageLinkFromServer;
                }
                [self.activityIndicator stopAnimating];
            });
        }];
    }];
    
    [alert addAction:cancel];
    [alert addAction:upload];
    [self presentViewController:alert animated:YES completion:nil];
    
}


@end
