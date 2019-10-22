//
//  ALHTTPManager.m
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALHTTPManager.h"
#import "ALUtilityClass.h"


@implementation ALHTTPManager

static dispatch_semaphore_t semaphore;

- (instancetype)init
{
    self = [super init];
    if (!semaphore) {
        semaphore = dispatch_semaphore_create(2); //2 tasks
    }
    if (self) {
        self.buffer = [[NSMutableData alloc]init];
    }
    return self;
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{

    ALMessageDBService *messageDatabaseService = [[ALMessageDBService alloc]init];

    if(self->_downloadTask != nil){
        [self->_buffer appendData:data];

        if(!self->_downloadTask.isThumbnail){
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.attachmentProgressDelegate onUpdateBytesDownloaded:self->_buffer.length withMessage:[messageDatabaseService getMessageByKey:self->_downloadTask.identifier]];
            });
        }

    }else if(self->_uploadTask != nil){

        DB_Message * dbMessage = (DB_Message*)[messageDatabaseService getMessageByKey:@"key" value:self->_uploadTask.identifier];
        ALMessage * message = [messageDatabaseService createMessageEntity:dbMessage];

        NSError * theJsonError = nil;
        NSDictionary *theJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&theJsonError];

        if(theJsonError == nil){
            if(ALApplozicSettings.isS3StorageServiceEnabled){
                [message.fileMeta populate:theJson];
            }else{
                NSDictionary *fileInfo = [theJson objectForKey:@"fileMeta"];
                [message.fileMeta populate:fileInfo];
            }
            ALMessage * almessage =  [ALMessageService processFileUploadSucess:message];
            [[ALMessageService sharedInstance] sendMessages:almessage withCompletion:^(NSString *message, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    if(error) {
                        ALSLog(ALLoggerSeverityError, @"ERROR IN POSTING Data:: %@", error);
                        if(self.attachmentProgressDelegate){
                            [self.attachmentProgressDelegate onUploadFailed:[[ALMessageService sharedInstance] handleMessageFailedStatus:almessage]];
                        }
                    }else{
                        if(self.attachmentProgressDelegate){
                            [self.attachmentProgressDelegate onUploadCompleted:almessage withOldMessageKey:self->_uploadTask.identifier];
                        }
                        if(self.delegate){
                            [self.delegate onMessageSent:almessage];
                        }
                    }
                });
            }];
        }else{
            ALSLog(ALLoggerSeverityError, @"ERROR In Uploading file:: %@", theJsonError);

            if(self.attachmentProgressDelegate){
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self.attachmentProgressDelegate onUploadFailed:message];
                });
            }
        }
        dispatch_semaphore_signal(semaphore);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{

    ALMessageDBService *messageDatabaseService = [[ALMessageDBService alloc]init];

    if(error == nil && [task.response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse *)task.response statusCode] == 200){
            if( self->_downloadTask != nil){

                if(self->_downloadTask.isThumbnail){
                    ALMessage *almessage =  [messageDatabaseService  writeDataAndUpdateMessageInDb:self.buffer withMessageKey:self->_downloadTask.identifier withFileFlag:NO];

                    if(self.attachmentProgressDelegate){
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [self.attachmentProgressDelegate onDownloadCompleted:almessage];
                        });
                    }
                }else{
                    ALMessage *almessage =  [messageDatabaseService writeDataAndUpdateMessageInDb:self.buffer withMessageKey:self->_downloadTask.identifier withFileFlag:YES];
                    if(self.attachmentProgressDelegate){
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [self.attachmentProgressDelegate onDownloadCompleted:almessage];
                        });
                    }
                }
                self.buffer = nil;
                [[[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue] removeObject:session];
            }
    }else{
        [[[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue] removeObject:session];
        if(error){
            ALSLog(ALLoggerSeverityError, @"Error while downloading  %@", error.localizedDescription);
        }else{
            ALSLog(ALLoggerSeverityError, @"Got some error while downloading");
        }
        self.buffer = nil;
        if(self->_downloadTask != nil && self.attachmentProgressDelegate){
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.attachmentProgressDelegate onDownloadFailed:[messageDatabaseService getMessageByKey:self->_downloadTask.identifier]];
            });
        }
    }
    dispatch_semaphore_signal(semaphore);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    ALMessageDBService *messageDatabaseService = [[ALMessageDBService alloc]init];

    if(self->_uploadTask != nil && self.attachmentProgressDelegate  != nil){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.attachmentProgressDelegate onUpdateBytesUploaded:totalBytesSent withMessage:[messageDatabaseService getMessageByKey:self->_uploadTask.identifier]];
        });
    }
}

-(void) processUploadFileForMessage:(ALMessage *)message uploadURL:(NSString *)uploadURL{

    ALUploadTask * alUploadTask = [[ALUploadTask alloc]init];
    alUploadTask.identifier = message.key;
    self.uploadTask = alUploadTask;

    NSURL * docDirectory =  [ALUtilityClass getApplicationDirectoryWithFilePath:message.imageFilePath];
    NSString * filePath = docDirectory.path;

    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSURL *docURL = [ALUtilityClass getAppsGroupDirectoryWithFilePath:message.imageFilePath];
        if(docURL != nil){
            filePath = docURL.path;
        }
    }

    ALSLog(ALLoggerSeverityInfo, @"FILE_PATH : %@",filePath);
    NSMutableURLRequest * request = [ALRequestHandler createPOSTRequestWithUrlString:uploadURL paramString:nil];

    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //Create boundary, it can be anything
            NSString *boundary = @"------ApplogicBoundary4QuqLuM1cE5lMwCy";
            // set Content-Type in HTTP header
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
            [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
            // post body
            NSMutableData *body = [NSMutableData data];
            //Populate a dictionary with all the regular values you would like to send.
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            // add params (all params are strings)
            for (NSString *param in parameters) {
                [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"%@\r\n", [parameters objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
            }

            NSString* FileParamConstant;
            if(ALApplozicSettings.isS3StorageServiceEnabled){
                FileParamConstant = @"file";
            }else{
                FileParamConstant = @"files[]";
            }
            NSData *imageData = [[NSData alloc]initWithContentsOfFile:filePath];
            ALSLog(ALLoggerSeverityInfo, @"Attachment data length: %f",imageData.length/1024.0);
            //Assuming data is not nil we add this to the multipart form
            if (imageData)
            {
                [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", FileParamConstant,message.fileMeta.name] dataUsingEncoding:NSUTF8StringEncoding]];

                [body appendData:[[NSString stringWithFormat:@"Content-Type:%@\r\n\r\n", message.fileMeta.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:imageData];
                [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            //Close off the request with the boundary
            [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            // setting the body of the post to the request
            [request setHTTPBody:body];
            // set URL
            [request setURL:[NSURL URLWithString:uploadURL]];

            NSMutableArray * nsURLSessionArray = [[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue];

            for(NSURLSession *session in nsURLSessionArray ){
                NSURLSessionConfiguration *config = session.configuration;
                NSArray *array =  [config.identifier componentsSeparatedByString:@","];
                if(array && array.count>1){
                    //Check if message key are same and first argumnent is not THUMBNAIL
                    if(![array[0] isEqual: @"THUMBNAIL"] && [array[1] isEqualToString: message.key]){
                        ALSLog(ALLoggerSeverityInfo, @"Already present in upload file Queue returing for key %@",message.key);
                        return;
                    }
                }
            }

            NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"FILE,%@",message.key]];

            if(ALApplozicSettings.getShareExtentionGroup){
                config.sharedContainerIdentifier = ALApplozicSettings.getShareExtentionGroup;
            }

            NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
            [self startSession: session withRequest: request];
        });
    }else{
        ALSLog(ALLoggerSeverityError, @"<<< ERROR >>> :: FILE DO NOT EXIT AT GIVEN PATH");
        if(self.attachmentProgressDelegate){

            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.attachmentProgressDelegate onUploadFailed:message];
            });
        }
    }

}

-(void) processDownloadForMessage:(ALMessage *) alMessage isAttachmentDownload:(BOOL) attachmentDownloadFlag {

    ALDownloadTask * downloadTask = [[ALDownloadTask alloc]init];
    downloadTask.identifier = alMessage.key;
    downloadTask.isThumbnail = !attachmentDownloadFlag;
    self.downloadTask = downloadTask;

    ALMessageDBService *messageDatabase = [[ALMessageDBService alloc]init];

    NSMutableArray * nsURLSessionArray = [[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue];

    for(NSURLSession *session in nsURLSessionArray){
        NSURLSessionConfiguration *config = session.configuration;
        NSArray *array =  [config.identifier componentsSeparatedByString:@","];
        if(array && array.count>1){
            //Check if the currently  its called for file download or THUMBNAIL with messageKey
            if(attachmentDownloadFlag && [array[0] isEqualToString:@"FILE"] &&
               [array[1] isEqualToString:alMessage.key]){
                ALSLog(ALLoggerSeverityInfo, @"Already present in file Download Queue returing for  key %@",alMessage.key);
                return;
            }else if (!attachmentDownloadFlag &&  [array[0] isEqualToString:@"THUMBNAIL"] && [array[1] isEqualToString:alMessage.key]){
                ALSLog(ALLoggerSeverityInfo, @"Already present in Download Thumbnail download Queue returing for  key %@",alMessage.key);
                return;
            }
        }
    }

    NSString * fileExtension = [ALUtilityClass getFileExtensionWithFileName:alMessage.fileMeta.name];

    NSString* fileName  = [NSString stringWithFormat:attachmentDownloadFlag? @"%@_local.%@": @"%@_thumbnail_local.%@",alMessage.key,fileExtension];

    NSURL * docDirectory =  [ALUtilityClass getApplicationDirectoryWithFilePath:fileName];
    NSString * filePath = docDirectory.path;

    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSURL *docURL = [ALUtilityClass getAppsGroupDirectoryWithFilePath:fileName];
        if(docURL != nil){
            filePath = docURL.path;
        }
    }

    NSData * data =  [[NSData alloc] initWithContentsOfFile:filePath];
    ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
    if(data){
        DB_Message * messageEntity = (DB_Message*)[messageDatabase getMessageByKey:@"key" value:alMessage.key];
        if(attachmentDownloadFlag){
            messageEntity.inProgress = [NSNumber numberWithBool:NO];
            messageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
            messageEntity.filePath = fileName;
        }else{
            messageEntity.fileMetaInfo.thumbnailFilePath = fileName;
        }

        [[ALDBHandler sharedInstance].managedObjectContext save:nil];
        alMessage =  [messageDatabase createMessageEntity:messageEntity];
        if(self.attachmentProgressDelegate){
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.attachmentProgressDelegate onDownloadCompleted:alMessage];
            });
        }
    }else{
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if(attachmentDownloadFlag){
                [messageClientService downloadImageUrl:alMessage.fileMeta.blobKey withCompletion:^(NSString *fileURL, NSError *error) {
                    if(error)
                    {
                        ALSLog(ALLoggerSeverityError, @"ERROR GETTING DOWNLOAD URL : %@", error);
                        if(self.attachmentProgressDelegate){
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [self.attachmentProgressDelegate onDownloadFailed:alMessage];
                            });
                        }
                        return;
                    }
                    ALSLog(ALLoggerSeverityInfo, @"ATTACHMENT DOWNLOAD URL : %@", fileURL);

                    NSMutableURLRequest * theRequest;
                    if(ALApplozicSettings.isS3StorageServiceEnabled || ALApplozicSettings.isGoogleCloudServiceEnabled) {
                        theRequest = [ALRequestHandler createGETRequestWithUrlStringWithoutHeader:fileURL paramString:nil];
                    }else{
                        theRequest = [ALRequestHandler createGETRequestWithUrlString: fileURL paramString:nil];
                    }

                    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"FILE,%@",alMessage.key]];

                    if(ALApplozicSettings.getShareExtentionGroup){
                        config.sharedContainerIdentifier = ALApplozicSettings.getShareExtentionGroup;
                    }
                    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
                    [self startSession: session withRequest:theRequest];
                }];
            } else {
                [messageClientService downloadImageThumbnailUrl:alMessage withCompletion:^(NSString *fileURL, NSError *error) {

                    ALSLog(ALLoggerSeverityInfo, @"Thumbnail DOWNLOAD URL : %@", fileURL);
                    if(error == nil){

                        NSString * theUrlString = [NSString stringWithFormat:@"%@",fileURL];
                        NSMutableURLRequest * urlRequest =  [ALRequestHandler createGETRequestWithUrlStringWithoutHeader:theUrlString paramString:nil];

                        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"THUMBNAIL,%@", alMessage.key]];
                        config.HTTPMaximumConnectionsPerHost = 2;

                        if(ALApplozicSettings.getShareExtentionGroup){
                            config.sharedContainerIdentifier = ALApplozicSettings.getShareExtentionGroup;
                        }

                        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

                        [self startSession: session withRequest:urlRequest];
                    }else{
                        ALSLog(ALLoggerSeverityError, @"ERROR  DOWNLOAD Thumbnail : %@", error.description);
                        if(self.attachmentProgressDelegate){
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [self.attachmentProgressDelegate onDownloadFailed:alMessage];
                            });
                        }
                    }

                }];
            }
        });
    }
}

-(void) startSession: (NSURLSession *) session withRequest: (NSURLRequest *) urlRequest {
    [[[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue] addObject:session];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if ([[[ALConnectionQueueHandler sharedConnectionQueueHandler] getCurrentConnectionQueue] containsObject:session]) {
        NSURLSessionDataTask *nsurlSessionDataTask = [session dataTaskWithRequest: urlRequest];
        [nsurlSessionDataTask resume];
    } else {
        dispatch_semaphore_signal(semaphore);
        return;
    }
}

-(void)uploadProfileImage:(UIImage *)profileImage withFilePath:(NSString *)filePath uploadURL:(NSString *)uploadURL withCompletion:(void(^)(NSData * data,NSError *error)) completion{

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return;
    }
    NSMutableURLRequest * request = [ALRequestHandler createPOSTRequestWithUrlString:uploadURL paramString:nil];

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Create boundary, it can be anything
        NSString *boundary = @"------ApplogicBoundary4QuqLuM1cE5lMwCy";
        // set Content-Type in HTTP header
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
        // post body
        NSMutableData *body = [NSMutableData data];
        NSString *FileParamConstant = @"file";
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:filePath];
        ALSLog(ALLoggerSeverityInfo, @"IMAGE_DATA :: %f",imageData.length/1024.0);

        //Assuming data is not nil we add this to the multipart form
        if (imageData)
        {

            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", FileParamConstant, @"imge_123_profile"] dataUsingEncoding:NSUTF8StringEncoding]];

            [body appendData:[[NSString stringWithFormat:@"Content-Type:%@\r\n\r\n", @"image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:imageData];
            [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        //Close off the request with the boundary
        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // setting the body of the post to the request
        [request setHTTPBody:body];
        // set URL
        [request setURL:[NSURL URLWithString:uploadURL]];

        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];


        NSURLSessionDataTask *nsurlSessionDataTask  = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completion(data,error);
            });
        }];
        [nsurlSessionDataTask resume];
    });
}

@end
