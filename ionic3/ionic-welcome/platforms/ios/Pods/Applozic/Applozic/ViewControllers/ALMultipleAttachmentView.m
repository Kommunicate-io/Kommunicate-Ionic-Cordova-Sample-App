//
//  ALMultipleAttachmentView.m
//  Applozic
//
//  Created by devashish on 29/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Photos/Photos.h>

#import "ALMultipleAttachmentView.h"
#import "AlMultipleAttachmentCell.h"
#import "ALUtilityClass.h"
#import "ALChatViewController.h"
#import "ALImagePickerHandler.h"
#import "ALImagePickerController.h"
#import "UIImage+animatedGIF.h"
#import "ALMultimediaData.h"

#define NAVIGATION_TEXT_SIZE 20

@interface ALMultipleAttachmentView () <UITextFieldDelegate>

@property (nonatomic, retain) ALImagePickerController * mImagePicker;
@property (strong, nonatomic) UIBarButtonItem * sendButton;

@end

@implementation ALMultipleAttachmentView
{
    ALCollectionReusableView * headerView;
}

static NSString * const reuseIdentifier = @"collectionCell";

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mImagePicker = [ALImagePickerController new];
    self.mImagePicker.delegate = self;

    self.imageArray = [NSMutableArray new];
    self.mediaFileArray = [NSMutableArray new];

    UIImage * addButtonImage = [ALUtilityClass getImageFromFramworkBundle:@"Plus_PNG.png"];
    [self.imageArray addObject: addButtonImage];

    //    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

    [self setTitle: NSLocalizedStringWithDefaultValue(@"attachmentViewTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Attachment", @"")];

    self.sendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"sendText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Send" , @"")
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(sendButtonAction)];


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];

    [self.navigationItem setRightBarButtonItem:self.sendButton];
    [self navigationBarColor];
}

-(void)navigationBarColor
{
    if([ALApplozicSettings getColorForNavigation] && [ALApplozicSettings getColorForNavigationItem])
    {
        [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                           NSForegroundColorAttributeName:[ALApplozicSettings getColorForNavigationItem],
                                                                           NSFontAttributeName:[UIFont fontWithName:[ALApplozicSettings getFontFace]
                                                                                                                size:NAVIGATION_TEXT_SIZE]
                                                                           }];

        [self.navigationController.navigationBar addSubview:[ALUtilityClass setStatusBarStyle]];
        [self.navigationController.navigationBar setBarTintColor:[ALApplozicSettings getColorForNavigation]];
        [self.navigationController.navigationBar setTintColor:[ALApplozicSettings getColorForNavigationItem]];
    }
}

-(void)cancelButtonAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

//====================================================================================================================================
#pragma mark UIImagePicker Delegate
//====================================================================================================================================

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [navigationController.navigationBar setTitleTextAttributes: @{
                                                                  NSForegroundColorAttributeName:[ALApplozicSettings getColorForNavigationItem],
                                                                  NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Bold"
                                                                                                       size:18]
                                                                  }];

    [navigationController.navigationBar setBarTintColor: [ALApplozicSettings getColorForNavigation]];
    [navigationController.navigationBar setTintColor:[ALApplozicSettings getColorForNavigationItem]];
    [navigationController.navigationBar addSubview:[ALUtilityClass setStatusBarStyle]];
}

-(void)gifFromURL:(NSURL *)url withCompletion:(void(^)(NSData * imageData))completion{
    PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] lastObject];
    if (asset) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        options.networkAccessAllowed = NO;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            NSNumber * isError = [info objectForKey:PHImageErrorKey];
            NSNumber * isCloud = [info objectForKey:PHImageResultIsInCloudKey];
            if ([isError boolValue] || [isCloud boolValue] || ! imageData) {
                // fail
                ALSLog(ALLoggerSeverityInfo, @"Couldn't find gif data");
                completion(nil);
            } else {
                // success, data is in imageData
                CFStringRef uti = (__bridge CFStringRef)dataUTI;
                if(UTTypeConformsTo(uti, kUTTypeGIF)){
                    completion(imageData);
                }else {
                    completion(nil);
                }
            }
        }];
    }else{
        completion(nil);
    }
}

-(void)chosenImageFrom:(UIImagePickerController *)picker withInfo:(NSDictionary<NSString *,id> *)info
        withCompletion:(void(^)(UIImage * image, ALMultimediaData * multimediaData)) completion {

    NSURL * refUrl = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (refUrl) {
        [self gifFromURL:refUrl withCompletion:^(NSData * imageData) {
            //Check whether chosen media is a GIF and Return as in case of GIF, checking for image will also return true.
            if(imageData) {
                UIImage * image = [UIImage animatedImageWithAnimatedGIFData:imageData];
                ALMultimediaData * object = [[ALMultimediaData new] getMultimediaDataOfType:ALMultimediaTypeGif withImage:image withGif:imageData withVideo:nil];
                completion(image, object);
                return;
            }else{
                // Check whether chosen media is image.
                UIImage * image = [info valueForKey:UIImagePickerControllerOriginalImage];
                if(image)
                {
                    ALMultimediaData * object = [[ALMultimediaData new] getMultimediaDataOfType:ALMultimediaTypeImage withImage:[ALUtilityClass getNormalizedImage:image] withGif:nil withVideo:nil];
                    completion(image, object);
                    return;
                }

                //Check whether chosen media is video.
                NSString *mediaType = info[UIImagePickerControllerMediaType];
                BOOL isMovie = UTTypeConformsTo((__bridge CFStringRef)mediaType, kUTTypeMovie) != 0;
                if(isMovie)
                {
                    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
                    UIImage * image = [ALUtilityClass subProcessThumbnail:videoURL];
                    ALMultimediaData * object = [[ALMultimediaData new] getMultimediaDataOfType:ALMultimediaTypeVideo withImage:nil withGif:nil withVideo:[videoURL path]];
                    completion(image, object);
                    return;
                }
            }
        }];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self chosenImageFrom:picker withInfo:info withCompletion:^(UIImage *image, ALMultimediaData *multimediaData) {
        if(image && multimediaData) {
            [self saveMediaAndReload:picker with:image and:multimediaData];
        }
    }];
}

-(void) saveMediaAndReload:(UIImagePickerController *)picker with:(UIImage *)image and:(ALMultimediaData *) multimediaData {
    [self.imageArray insertObject:image atIndex:0];
    [self.mediaFileArray insertObject:multimediaData atIndex:0];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.collectionView reloadData];
}

//====================================================================================================================================
#pragma mark UICollectionView DataSource
//====================================================================================================================================

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.imageArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlMultipleAttachmentCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self setColorBorder:cell andColor:[UIColor lightGrayColor]];

    [cell.imageView setBackgroundColor: [UIColor clearColor]];

    if(self.mediaFileArray.count >= 1 && indexPath.row < self.imageArray.count - 1){
        ALMultimediaData * multimedia = (ALMultimediaData *)[self.mediaFileArray objectAtIndex:indexPath.row];
        if(multimedia.attachmentType == ALMultimediaTypeGif){
            UIImage * image = [UIImage animatedImageWithAnimatedGIFData:multimedia.dataGIF];
            [cell.imageView setImage:image];
        }else {
            UIImage * image = (UIImage *)[self.imageArray objectAtIndex:indexPath.row];
            [cell.imageView setImage:image];
        }
    }else {
        UIImage * image = (UIImage *)[self.imageArray objectAtIndex:indexPath.row];
        [cell.imageView setImage:image];
    }

    if(indexPath.row == self.imageArray.count - 1)
    {
        if([ALApplozicSettings getBackgroundColorForAttachmentPlusIcon])
        {
            [cell.imageView setBackgroundColor: [ALApplozicSettings getBackgroundColorForAttachmentPlusIcon]];
        }
        else
        {
            [cell.imageView setBackgroundColor: self.navigationController.navigationBar.barTintColor];
        }
    }

    return cell;
}

-(void)gestureAction
{
    int MAX_VALUE = (int)[ALApplozicSettings getMultipleAttachmentMaxLimit];
    int max = MAX_VALUE + 1;
    if(self.imageArray.count >= max)
    {
        [ALUtilityClass showAlertMessage:   NSLocalizedStringWithDefaultValue(@"attachmentLimitReachedText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Maximum attachment limit reached" , @"")  andTitle:   NSLocalizedStringWithDefaultValue(@"oppsText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"OOPS!!!", @"")];
        return;
    }

    [self pickImageFromGallery];

}

-(void)sendButtonAction
{
    if(!self.mediaFileArray.count)
    {
        [ALUtilityClass showAlertMessage: NSLocalizedStringWithDefaultValue(@"selectAtleastAttachment", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Select at least one attachment" , @"")andTitle: NSLocalizedStringWithDefaultValue(@"attachment", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Attachment" , @"")];
        return;
    }
    [self.multipleAttachmentDelegate multipleAttachmentProcess:self.mediaFileArray andText:headerView.msgTextField.text];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)pickImageFromGallery
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized)
        {
            self.mImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.mImagePicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
            [self presentViewController:self.mImagePicker animated:YES completion:nil];
        }
        else
        {
            [ALUtilityClass permissionPopUpWithMessage:NSLocalizedStringWithDefaultValue(@"permissionPopMessageForCamera", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Enable Photos Permission", @"") andViewController:self];
        }
    }];
}

//====================================================================================================================================
#pragma mark UICollectionView Delegate
//====================================================================================================================================

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if(indexPath.row == self.imageArray.count - 1)
    {
        [self gestureAction];
        return;
    }

    AlMultipleAttachmentCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self setColorBorder:cell andColor:[UIColor blueColor]];

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == self.imageArray.count - 1)
    {
        [self gestureAction];
        return;
    }
    AlMultipleAttachmentCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self setColorBorder:cell andColor:[UIColor lightGrayColor]];

}

-(void)setColorBorder:(AlMultipleAttachmentCell *)cell andColor:(UIColor *)color
{
    cell.layer.masksToBounds = YES;
    cell.layer.borderColor = [color CGColor];
    cell.layer.borderWidth = 2.0f;
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
          viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{

    if (kind == UICollectionElementKindSectionHeader)
    {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"collectionHeaderView" forIndexPath:indexPath];

        headerView.msgTextField.delegate = self;
        headerView.msgTextField.layer.masksToBounds = YES;
        headerView.msgTextField.layer.borderColor = [[UIColor brownColor] CGColor];
        headerView.msgTextField.layer.borderWidth = 1.0f;
        headerView.msgTextField.placeholder =  NSLocalizedStringWithDefaultValue(@"writeSomeTextHere", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Write Some Text..." , @"");

        [headerView setBackgroundColor:[UIColor whiteColor]];
    }

    return headerView;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return  YES;
}

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
 }

 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
 return NO;
 }

 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {

 }
 */

@end
