//
//  ALDocumentPickerHandler.h
//  Applozic
//
//  Created by apple on 08/01/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ALPushAssist.h"
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface ALDocumentPickerHandler : NSObject

-(void)showDocumentPickerViewController:(id<UIDocumentPickerDelegate>) pickerDelegate;

+(NSString *)saveFile:(NSURL *)fileUrl;

@end

NS_ASSUME_NONNULL_END
