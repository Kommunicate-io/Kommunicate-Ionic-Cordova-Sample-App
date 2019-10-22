//
//  ALAttachmentPickerData.h
//  Applozic
//
//  Created by Shivam Pokhriyal on 10/08/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    ALAttachmentTypeGif = 0,
    ALAttachmentTypeImage,
    ALAttachmentTypeVideo
} ALAttachmentType;

@interface ALAttachmentPickerData : NSObject

@property (nonatomic) ALAttachmentType attachmentType;
@property (nonatomic, strong) UIImage * classImage;                          //Stores the image
@property (nonatomic, strong) NSString * classVideoPath;                     //Stores the video path
@property (nonatomic, strong) NSData * dataGIF;                         //Stores the GIF data

@end
