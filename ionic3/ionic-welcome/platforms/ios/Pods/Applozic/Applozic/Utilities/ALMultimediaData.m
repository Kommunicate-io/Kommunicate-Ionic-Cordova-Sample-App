//
//  ALMultimediaData.m
//  Applozic
//
//  Created by Shivam Pokhriyal on 10/08/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALMultimediaData.h"

@implementation ALMultimediaData

- (ALMultimediaData *)getMultimediaDataOfType:(ALMultimediaType)type withImage:(UIImage *)image withGif:(NSData *)gif withVideo:(NSString *)video
{
    ALMultimediaData * multimediaData = [ALMultimediaData new];
    multimediaData.attachmentType = type;
    multimediaData.classImage = image;
    multimediaData.dataGIF = gif;
    multimediaData.classVideoPath = video;
    return multimediaData;
}

@end
