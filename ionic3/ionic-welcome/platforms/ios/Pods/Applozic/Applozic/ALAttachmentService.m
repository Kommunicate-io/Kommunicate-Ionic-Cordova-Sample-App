//
//  ALAttachmentService.m
//  Applozic
//
//  Created by Sunil on 25/09/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALAttachmentService.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ALMessageClientService.h"
#import "ApplozicClient.h"
#import "ALMessageService.h"

@implementation ALAttachmentService


+(ALAttachmentService *)sharedInstance
{
    static ALAttachmentService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALAttachmentService alloc] init];
    });
    return sharedInstance;
}


-(void)sendMessageWithAttachment:(ALMessage*) attachmentMessage withDelegate:(id<ApplozicUpdatesDelegate>) delegate withAttachmentDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate{

    if(!attachmentMessage || !attachmentMessage.imageFilePath){
        return;
    }
    self.delegate = delegate;
    self.attachmentProgressDelegate = attachmentProgressDelegate;

    CFStringRef pathExtension = (__bridge_retained CFStringRef)[attachmentMessage.imageFilePath pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);

    attachmentMessage.fileMeta.contentType = mimeType;
    if( attachmentMessage.contentType == ALMESSAGE_CONTENT_VCARD){
        attachmentMessage.fileMeta.contentType = @"text/x-vcard";
    }
    NSData *imageSize = [NSData dataWithContentsOfFile:attachmentMessage.imageFilePath];
    attachmentMessage.fileMeta.size = [NSString stringWithFormat:@"%lu",(unsigned long)imageSize.length];

    //DB Addition

    ALMessageDBService *alMessageDbService = [[ALMessageDBService alloc]init];

    DB_Message *dbMessage =   [alMessageDbService addAttachmentMessage:attachmentMessage];

    NSDictionary * userInfo = [attachmentMessage dictionary];

    ALMessageClientService * clientService  = [[ALMessageClientService alloc]init];
    [clientService sendPhotoForUserInfo:userInfo withCompletion:^(NSString *responseUrl, NSError *error) {

        if (error)
        {

            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.attachmentProgressDelegate onUploadFailed:[[ALMessageService sharedInstance] handleMessageFailedStatus:attachmentMessage]];
            });
            return;
        }

        ALHTTPManager *httpManager = [[ALHTTPManager alloc]init];
        httpManager.attachmentProgressDelegate = self.attachmentProgressDelegate;
        httpManager.delegate = self.delegate;
        [httpManager processUploadFileForMessage:[alMessageDbService createMessageEntity:dbMessage] uploadURL:responseUrl];
    }];

}

-(void) downloadMessageAttachment:(ALMessage*)alMessage withDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate{

    self.attachmentProgressDelegate = attachmentProgressDelegate;
    ALHTTPManager * manager =  [[ALHTTPManager alloc] init];
    manager.attachmentProgressDelegate = self.attachmentProgressDelegate;
    [manager processDownloadForMessage:alMessage isAttachmentDownload:YES];
}

-(void) downloadImageThumbnail:(ALMessage*)alMessage withDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate{

    self.attachmentProgressDelegate = attachmentProgressDelegate;
    ALHTTPManager * manager =  [[ALHTTPManager alloc] init];
    manager.attachmentProgressDelegate = self.attachmentProgressDelegate;
    [manager processDownloadForMessage:alMessage isAttachmentDownload:NO];
}


@end
