//
//  ALAudioSession.h
//  Applozic
//
//  Created by apple on 18/09/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALAudioSession : NSObject

-(AVAudioSession *)getAudioSessionWithPlayback:(BOOL)isPlayback;

@end

NS_ASSUME_NONNULL_END
