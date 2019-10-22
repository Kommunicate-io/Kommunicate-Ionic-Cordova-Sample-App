//
//  ImageViewController.h
//  Applozic
//
//  Created by apple on 17/10/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ALImageSendDelegate <NSObject>

-(void)onSendButtonClick:(NSString*_Nullable) filePath withReplyMessageKey:(NSString*_Nullable)
messageKey;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ALImagePreviewController : UIViewController

@property (weak, nonatomic) id <ALImageSendDelegate> imageSelectDelegate;
@property (nonatomic, strong) NSString * imageFilePath;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, strong) NSString * messageKey;

@end

NS_ASSUME_NONNULL_END
