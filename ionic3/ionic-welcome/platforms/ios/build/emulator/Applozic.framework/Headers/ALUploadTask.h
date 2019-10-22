//
//  ALUploadTask.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALUploadTask : NSObject

@property (nonatomic, copy) NSString * filePath;

@property (nonatomic, copy) NSString * fileName;

@property (nonatomic, copy) NSString * identifier;

@end
