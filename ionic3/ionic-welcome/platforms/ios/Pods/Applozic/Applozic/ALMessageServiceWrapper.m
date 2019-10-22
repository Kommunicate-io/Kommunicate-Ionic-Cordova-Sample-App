//
//  ALMessageWrapper.m
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 12/14/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALMessageServiceWrapper.h"
#import <Applozic/ALMessageService.h>
#import <Applozic/ALMessageDBService.h>
#import <Applozic/ALConnectionQueueHandler.h>
#import <Applozic/ALMessageClientService.h>
#include <tgmath.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Applozic/ALApplozicSettings.h>
#import "ALHTTPManager.h"
#import "ALDownloadTask.h"

@interface ALMessageServiceWrapper  ()<ApplozicAttachmentDelegate>

@end

@implementation ALMessageServiceWrapper

-(void)sendTextMessage:(NSString*)text andtoContact:(NSString*)toContactId {
    
    ALMessage * almessage = [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_DEFAULT toSendTo:toContactId withText:text];
    
    [[ALMessageService sharedInstance] sendMessages:almessage withCompletion:^(NSString *message, NSError *error) {
        
        if(error)
        {
            ALSLog(ALLoggerSeverityError, @"REACH_SEND_ERROR : %@",error);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:almessage];
    }];
}


-(void)sendTextMessage:(NSString*)messageText andtoContact:(NSString*)contactId orGroupId:(NSNumber*)channelKey{
    
    ALMessage * almessage = [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_DEFAULT toSendTo:contactId withText:messageText];
    
    almessage.groupId=channelKey;
    
    [[ALMessageService sharedInstance] sendMessages:almessage withCompletion:^(NSString *message, NSError *error) {
        
        if(error)
        {
            ALSLog(ALLoggerSeverityError, @"REACH_SEND_ERROR : %@",error);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:almessage];
    }];
}

-(void) sendMessage:(ALMessage *)alMessage
withAttachmentAtLocation:(NSString *)attachmentLocalPath
andWithStatusDelegate:(id)statusDelegate
     andContentType:(short)contentype{
    
    //Message Creation
    ALMessage * theMessage = alMessage;
    theMessage.contentType = contentype;
    theMessage.imageFilePath = attachmentLocalPath.lastPathComponent;
    
    //File Meta Creation
    theMessage.fileMeta = [self getFileMetaInfo];
    theMessage.fileMeta.name = [NSString stringWithFormat:@"AUD-5-%@", attachmentLocalPath.lastPathComponent];
    if(alMessage.contactIds){
        theMessage.fileMeta.name = [NSString stringWithFormat:@"%@-5-%@",alMessage.contactIds, attachmentLocalPath.lastPathComponent];
    }
    
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[attachmentLocalPath pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    
    theMessage.fileMeta.contentType = mimeType;
    if( theMessage.contentType == ALMESSAGE_CONTENT_VCARD){
        theMessage.fileMeta.contentType = @"text/x-vcard";
    }
    NSData *imageSize = [NSData dataWithContentsOfFile:attachmentLocalPath];
    theMessage.fileMeta.size = [NSString stringWithFormat:@"%lu",(unsigned long)imageSize.length];
    
    //DB Addition
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    ALMessageDBService* messageDBService = [[ALMessageDBService alloc] init];
    DB_Message * theMessageEntity = [messageDBService createMessageEntityForDBInsertionWithMessage:theMessage];
    [theDBHandler.managedObjectContext save:nil];
    theMessage.msgDBObjectId = [theMessageEntity objectID];
    theMessageEntity.inProgress = [NSNumber numberWithBool:YES];
    theMessageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
    [[ALDBHandler sharedInstance].managedObjectContext save:nil];
    
    NSDictionary * userInfo = [alMessage dictionary];
    
    ALMessageClientService * clientService  = [[ALMessageClientService alloc]init];
    [clientService sendPhotoForUserInfo:userInfo withCompletion:^(NSString *message, NSError *error) {
        
        if (error)
        {
            [self.messageServiceDelegate uploadDownloadFailed:alMessage];
            return;
        }
        ALHTTPManager *httpManager = [[ALHTTPManager alloc]init];
        httpManager.attachmentProgressDelegate = self;
        [httpManager processUploadFileForMessage:[messageDBService createMessageEntity:theMessageEntity] uploadURL:message];
    }];
    
}


-(ALFileMetaInfo *)getFileMetaInfo
{
    ALFileMetaInfo *info = [ALFileMetaInfo new];
    
    info.blobKey = nil;
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

-(ALMessage *)createMessageEntityOfContentType:(int)contentType
                                      toSendTo:(NSString*)to
                                      withText:(NSString*)text{
    
    ALMessage * theMessage = [ALMessage new];
    
    theMessage.contactIds = to;//1
    theMessage.to = to;//2
    theMessage.message = text;//3
    theMessage.contentType = contentType;//4
    
    theMessage.type = @"5";
    theMessage.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    theMessage.deviceKey = [ALUserDefaultsHandler getDeviceKeyString ];
    theMessage.sendToDevice = NO;
    theMessage.shared = NO;
    theMessage.fileMeta = nil;
    theMessage.storeOnDevice = NO;
    theMessage.key = [[NSUUID UUID] UUIDString];
    theMessage.delivered = NO;
    theMessage.fileMetaKey = nil;
    
    return theMessage;
}


-(void) downloadMessageAttachment:(ALMessage*)alMessage{

    ALHTTPManager * manager =  [[ALHTTPManager alloc] init];
    manager.attachmentProgressDelegate = self;
    [manager processDownloadForMessage:alMessage isAttachmentDownload:YES];

}

- (void)onDownloadCompleted:(ALMessage *)alMessage {
   [self.messageServiceDelegate DownloadCompleted:alMessage];
}

- (void)onDownloadFailed:(ALMessage *)alMessage {
    [self.messageServiceDelegate uploadDownloadFailed:alMessage];
}

- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)alMessage {
    [self.messageServiceDelegate updateBytesDownloaded:(NSUInteger)bytesReceived];
}

- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)alMessage {
    [self.messageServiceDelegate updateBytesUploaded:(NSInteger)bytesSent];
}

- (void)onUploadCompleted:(ALMessage *)alMessage withOldMessageKey:(NSString *)oldMessageKey {
    [self.messageServiceDelegate uploadCompleted:alMessage];
}

- (void)onUploadFailed:(ALMessage *)alMessage {
    [self.messageServiceDelegate uploadDownloadFailed:alMessage];
}

@end
