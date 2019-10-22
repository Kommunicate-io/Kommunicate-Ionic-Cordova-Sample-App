//
//  ALHTTPManager.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUploadTask.h"
#import "ALDownloadTask.h"
#import "Applozic.h"
#import "ALRealTimeUpdate.h"

@interface ALHTTPManager : NSObject <NSURLSessionDataDelegate,NSURLSessionDelegate>

@property (nonatomic, weak) id<ApplozicAttachmentDelegate>attachmentProgressDelegate;

@property (nonatomic, weak) id<ApplozicUpdatesDelegate> delegate;

@property (nonatomic, strong) NSMutableData * buffer;

@property (nonatomic) NSUInteger *length;

@property (nonatomic) ALUploadTask * uploadTask;

@property (nonatomic) ALDownloadTask * downloadTask;

-(void) processDownloadForMessage:(ALMessage *) alMessage isAttachmentDownload:(BOOL) attachmentDownloadFlag ;

-(void) processUploadFileForMessage:(ALMessage *)message uploadURL:(NSString *)uploadURL;

-(void)uploadProfileImage:(UIImage *)profileImage withFilePath:(NSString *)filePath uploadURL:(NSString *)uploadURL withCompletion:(void(^)(NSData * data,NSError *error)) completion;

@end
