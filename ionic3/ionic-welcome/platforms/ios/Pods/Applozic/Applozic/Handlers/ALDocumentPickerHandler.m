//
//  ALDocumentPickerHandler.m
//  Applozic
//
//  Created by Sunil on 08/01/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALDocumentPickerHandler.h"


@implementation ALDocumentPickerHandler

-(void)showDocumentPickerViewController:(id<UIDocumentPickerDelegate>) pickerDelegate{

    ALPushAssist * pushAssist = [[ALPushAssist alloc]init];

    NSArray *types = @[(NSString*)kUTTypeSpreadsheet,(NSString*)kUTTypePresentation,(NSString*)kUTTypeCompositeContent,(NSString*)kUTTypeContent];

    UIDocumentPickerViewController *docPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    docPicker.delegate = pickerDelegate;
    [pushAssist.topViewController presentViewController:docPicker animated:YES completion:nil];
}

+(NSString *)saveFile:(NSURL *)fileUrl{

    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * filePath = [docDir stringByAppendingString:[NSString stringWithFormat:@"/%f.%@",[[NSDate date] timeIntervalSince1970] * 1000,fileUrl.pathExtension]];
    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    [fileData writeToFile:filePath atomically:NO];
    return filePath;
}

@end
