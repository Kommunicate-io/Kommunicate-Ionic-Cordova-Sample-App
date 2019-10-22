//
//  ALAppLocalNotifications.m
//  Applozic
//
//  Created by devashish on 07/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALAppLocalNotifications.h"
#import "ALChatViewController.h"
#import "ALNotificationView.h"
#import "ALUtilityClass.h"
#import "ALPushAssist.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALUserDefaultsHandler.h"
#import "ALMessageService.h"
#import "ALMessagesViewController.h"
#import "ALUserService.h"
#import "ALMQTTConversationService.h"
#import "ALGroupDetailViewController.h"
#import "ALConversationService.h"
#import "ALApplozicSettings.h"

@implementation ALAppLocalNotifications


+(ALAppLocalNotifications *)appLocalNotificationHandler
{
    static ALAppLocalNotifications * localNotificationHandler = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        localNotificationHandler = [[self alloc] init];
    });
    
    return localNotificationHandler;
}

-(void)dataConnectionNotificationHandler{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thirdPartyNotificationHandler:)
                                                 name:@"showNotificationAndLaunchChat" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transferVOIPMessage:)
                                                 name:@"newMessageNotification"
                                               object:nil];

    [self dataConnectionHandler];
}

-(void)dataConnectionHandler
{
    [ALApplozicSettings setupSuiteAndMigrate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:)
                                                 name:AL_kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundBase:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackground:)
                                                  name:UIApplicationDidEnterBackgroundNotification
                                                object:nil];
    
   
    
    if([ALUserDefaultsHandler isLoggedIn]){
        
        [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withCompletion:^(NSMutableArray *messageArray, NSError *error) {
            if (error) {
                ALSLog(ALLoggerSeverityError, @"ERROR");
            }
            else{
            }
        }];
    }
    
    // create a Reachability object for www.google.com
    
    self.googleReach = [ALReachability reachabilityWithHostname:@"www.google.com"];
    
    self.googleReach.reachableBlock = ^(ALReachability * reachability)
    {
//        NSString * temp = [NSString stringWithFormat:@"GOOGLE Block Says Reachable(%@)", reachability.currentReachabilityString];
        // NSLog(@"%@", temp);
        
        // to update UI components from a block callback
        // you need to dipatch this to the main thread
        // this uses NSOperationQueue mainQueue
        
    };
    
    self.googleReach.unreachableBlock = ^(ALReachability * reachability)
    {
//        NSString * temp = [NSString stringWithFormat:@"GOOGLE Block Says Unreachable(%@)", reachability.currentReachabilityString];
        //  NSLog(@"%@", temp);
        
        // to update UI components from a block callback
        // you need to dipatch this to the main thread
        // this one uses dispatch_async they do the same thing (as above)
        
    };
    
    [self.googleReach startNotifier];
    
    // create a reachability for the local WiFi
    
    self.localWiFiReach = [ALReachability reachabilityForLocalWiFi];
    
    // we ONLY want to be reachable on WIFI - cellular is NOT an acceptable connectivity
    self.localWiFiReach.reachableOnWWAN = NO;
    
    self.localWiFiReach.reachableBlock = ^(ALReachability * reachability)
    {
//        NSString * temp = [NSString stringWithFormat:@"LocalWIFI Block Says Reachable(%@)", reachability.currentReachabilityString];
        // NSLog(@"%@", temp);
        
        
    };
    
    self.localWiFiReach.unreachableBlock = ^(ALReachability * reachability)
    {
//        NSString * temp = [NSString stringWithFormat:@"LocalWIFI Block Says Unreachable(%@)", reachability.currentReachabilityString];
        
        // NSLog(@"%@", temp);
        
    };
    
    [self.localWiFiReach startNotifier];
    
    // create a Reachability object for the internet
    
    self.internetConnectionReach = [ALReachability reachabilityForInternetConnection];
    
    self.internetConnectionReach.reachableBlock = ^(ALReachability * reachability)
    {
//        NSString * temp = [NSString stringWithFormat:@" InternetConnection Says Reachable(%@)", reachability.currentReachabilityString];
        // NSLog(@"%@", temp);
    };
    
    self.internetConnectionReach.unreachableBlock = ^(ALReachability * reachability)
    {
//        NSString * temp = [NSString stringWithFormat:@"InternetConnection Block Says Unreachable(%@)", reachability.currentReachabilityString];
        //  NSLog(@"%@", temp);
    };
    
    [self.internetConnectionReach startNotifier];
    
}

-(void)reachabilityChanged:(NSNotification*)note
{
    ALReachability * reach = [note object];
    
    if(reach == self.googleReach)
    {
        if([reach isReachable])
        {
            ALSLog(ALLoggerSeverityInfo, @"========== IF googleReach ============");
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"========== ELSE googleReach ============");
        }
    }
    else if (reach == self.localWiFiReach)
    {
        if([reach isReachable])
        {
            ALSLog(ALLoggerSeverityInfo, @"========== IF localWiFiReach ============");
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"========== ELSE localWiFiReach ============");
        }
    }
    else if (reach == self.internetConnectionReach)
    {
        if([reach isReachable])
        {
            ALSLog(ALLoggerSeverityInfo, @"========== IF internetConnectionReach ============");
            [self proactivelyConnectMQTT];
            [ALMessageService syncMessages];

            ALMessageService *messageService = [[ALMessageService alloc]init];
            [messageService processPendingMessages];

            ALUserService *userService = [ALUserService new]; 
            [userService blockUserSync: [ALUserDefaultsHandler getUserBlockLastTimeStamp]];

        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"========== ELSE internetConnectionReach ============");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NETWORK_DISCONNECTED" object:nil];
        }
    }
    
}

-(void)proactivelyConnectMQTT
{
        ALMQTTConversationService *alMqttConversationService = [ALMQTTConversationService sharedInstance];
        [alMqttConversationService  subscribeToConversation];
}

-(void)proactivelyDisconnectMQTT
{
        ALMQTTConversationService *alMqttConversationService = [ALMQTTConversationService sharedInstance];
        [alMqttConversationService  unsubscribeToConversation];
}

-(void)appWillEnterBackground:(NSNotification *)notification
{
    [self proactivelyDisconnectMQTT];
    [ALLogger saveLogArray];
}

//receiver
- (void)appWillEnterForegroundBase:(NSNotification *)notification
{
    [self proactivelyConnectMQTT];
    [ALMessageService syncMessages];
}

// To DISPLAY THE NOTIFICATION ONLY ...from 3rd Party View.
-(void)thirdPartyNotificationHandler:(NSNotification *)notification
{
    if([ALApplozicSettings isSwiftFramework]) {
        return;
    }

    NSNumber *groupId = nil;
    NSNumber *conversationId = nil;
    NSArray *notificationComponents = [notification.object componentsSeparatedByString:@":"];

    if(notificationComponents.count>2)
    {
        NSString *groupIdString = notificationComponents[1];
        groupId = [NSNumber numberWithInt:groupIdString.intValue];
        self.contactId = notificationComponents[2];
    } else if(notificationComponents.count == 2) {
        NSString *conversationIdString = notificationComponents[1];
        conversationId = [NSNumber numberWithInt:conversationIdString.intValue];
        self.contactId = notificationComponents[0];
    }else {
        self.contactId = notification.object;
    }
    self.dict = notification.userInfo;
    NSNumber * updateUI = [self.dict valueForKey:@"updateUI"];
    NSString * alertValue = [self.dict valueForKey:@"alertValue"];
    
    if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_INACTIVE]])
    {
        ALSLog(ALLoggerSeverityInfo, @"App launched from Background....Directly opening view from %@",self.dict);

        if(conversationId != nil){
            ALConversationService * conversationService = [[ALConversationService alloc]init];
            [conversationService fetchTopicDetails:conversationId withCompletion:^(NSError *error, ALConversationProxy *proxy) {
                if(error == nil){
                    [self thirdPartyNotificationTap1:self.contactId withGroupId:groupId withConversationId: conversationId]; //
                }else{
                    ALSLog(ALLoggerSeverityInfo, @"Error in fetching conversation :: %@",error);
                }
            }];
        }else{
            [self thirdPartyNotificationTap1:self.contactId withGroupId:groupId withConversationId: conversationId]; // Directly launching Chat
        }
        return;
    }
    
    if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_ACTIVE]])
    {
        if( alertValue || alertValue.length >0)
        {
            ALSLog(ALLoggerSeverityInfo, @"posting to notification....%@",notification.userInfo);
            if (groupId && [ALChannelService isChannelMuted:groupId])
            {
                return;
            }
            if(groupId){
                
                [[ALChannelService new] getChannelInformation:groupId orClientChannelKey:nil withCompletion:^(ALChannel *alChannel3) {
                    
                    [ALUtilityClass thirdDisplayNotificationTS:alertValue andForContactId:self.contactId withGroupId:groupId withConversationId:conversationId delegate:self];

                }];
            }else{
                if(conversationId != nil){
                    ALConversationService * conversationService = [[ALConversationService alloc]init];
                    [conversationService fetchTopicDetails:conversationId withCompletion:^(NSError *error, ALConversationProxy *proxy) {
                        if(error == nil){
                            [ALUtilityClass thirdDisplayNotificationTS:alertValue andForContactId:self.contactId withGroupId:groupId withConversationId:conversationId delegate:self];

                        }else{
                            ALSLog(ALLoggerSeverityInfo, @"Error in fetching conversation :: %@",error);
                        }
                    }];

                }else{
                    [ALUtilityClass thirdDisplayNotificationTS:alertValue andForContactId:self.contactId withGroupId:groupId withConversationId:conversationId delegate:self];
                }
            }
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"Nil Alert Value");
        }
    }
    if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_BACKGROUND]])
    {
        if(alertValue || alertValue.length >0)
        {
            ALPushAssist* assitant = [[ALPushAssist alloc] init];
            ALSLog(ALLoggerSeverityInfo, @"APP_STATE_BACKGROUND :: %@",notification.userInfo);
            if(!assitant.isOurViewOnTop)
            {
           //     [ALUtilityClass thirdDisplayNotificationTS:alertValue andForContactId:self.contactId withGroupId:groupId delegate:self];
            }
        }
    }
}

-(void)thirdPartyNotificationTap1:(NSString *)contactId withGroupId:(NSNumber *)groupID withConversationId:(NSNumber *)conversationId
{
    ALPushAssist* pushAssistant = [[ALPushAssist alloc] init];
    ALSLog(ALLoggerSeverityInfo, @"Chat Launch Contact ID: %@",self.contactId);
    
    if(!pushAssistant.isOurViewOnTop)
    {
        self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:APPLICATION_KEY];
        [self.chatLauncher launchIndividualChat:contactId withGroupId:groupID withConversationId:conversationId andViewControllerObject:pushAssistant.topViewController andWithText:nil];
    }
}

-(void)transferVOIPMessage:(NSNotification *)notification
{
    NSMutableArray * array = notification.object;
    ALVOIPNotificationHandler * voipHandler = [ALVOIPNotificationHandler sharedManager];
    ALPushAssist * assist = [[ALPushAssist alloc] init];
    for (ALMessage *msg in array)
    {
        [voipHandler handleAVMsg:msg andViewController:assist.topViewController];
    }
}

-(void)dealloc
{
    ALSLog(ALLoggerSeverityInfo, @"DEALLOC METHOD CALLED");
}


@end
