//
//  ImageViewController.m
//  Applozic
//
//  Created by apple on 17/10/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALImagePreviewController.h"
#import "ALApplozicSettings.h"
@interface ALImagePreviewController ()

@end

@implementation ALImagePreviewController

- (void)viewWillAppear:(BOOL)animated{

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"imageViewControllerTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Image", @"");


    UIBarButtonItem * rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"send", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Send", @"") style:UIBarButtonItemStylePlain target:self action:@selector(sendAttachment)];

    self.navigationItem.rightBarButtonItem = rightButton;

    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0,screenSize.width, screenSize.height);
    imageView.image = self.image;
    [self.view addSubview:imageView];

}


-(void)sendAttachment{
    
    if(self.imageSelectDelegate){
        [self.imageSelectDelegate onSendButtonClick:self.imageFilePath withReplyMessageKey:self.messageKey];
        [self.navigationController popViewControllerAnimated:YES];
    }

}

@end
