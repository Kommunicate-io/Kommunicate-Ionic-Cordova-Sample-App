//
//  ALMultimediaData.h
//  Applozic
//
//  Created by Shivam Pokhriyal on 10/08/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    ALMultimediaTypeGif = 0,
    ALMultimediaTypeImage,
    ALMultimediaTypeVideo
} ALMultimediaType;

@interface ALMultimediaData : NSObject

@property (nonatomic) ALMultimediaType attachmentType;
@property (nonatomic, strong) UIImage * classImage;                          //Stores the image
@property (nonatomic, strong) NSString * classVideoPath;                     //Stores the video path
@property (nonatomic, strong) NSData * dataGIF;                         //Stores the GIF data

-(ALMultimediaData *) getMultimediaDataOfType:(ALMultimediaType)type withImage:(UIImage *) image withGif:(NSData *) gif withVideo:(NSString *) video;

@end
 
