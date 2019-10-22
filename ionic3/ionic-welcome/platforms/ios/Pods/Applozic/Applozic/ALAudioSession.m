//
//  ALAudioSession.m
//  Applozic
//
//  Created by apple on 18/09/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALAudioSession.h"

@implementation ALAudioSession

-(AVAudioSession *)getAudioSessionWithPlayback:(BOOL)isPlayback{
    
    AVAudioSession *audioSession =   [AVAudioSession sharedInstance];
    NSError * error;
    
    if (@available(iOS 11.0, *)) {
        
        if(isPlayback){
            [audioSession setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault routeSharingPolicy:AVAudioSessionRouteSharingPolicyDefault options:0 error:&error];
        }else{
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault routeSharingPolicy:AVAudioSessionRouteSharingPolicyDefault options:0 error:&error];
        }
        
    }else if(@available(iOS 10.0, *)){
        if(isPlayback){
            [audioSession setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0  error:&error];
        }else{
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:0  error:&error];
        }
        
    }else{
        if(isPlayback){
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
        }else{
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        }
    }
    
    return audioSession;
}

@end
