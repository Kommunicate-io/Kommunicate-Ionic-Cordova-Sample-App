//
//  ALChannelDBService.m
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALChannelDBService.h"
#import "ALConstant.h"
#import "ALContactDBService.h"
#import "ALContact.h"
#import "ALContactDBService.h"
#import "ALContact.h"
#import "ALChannelUser.h"
#import "SearchResultCache.h"

@interface ALChannelDBService ()

@end

@implementation ALChannelDBService


dispatch_queue_t syncSerialBackgroundQueue;


-(void)createChannel:(ALChannel *)channel
{
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    [self createChannelEntity:channel];
    [theDBHandler.managedObjectContext save:nil];


    if(channel.membersName == nil){
        channel.membersName = channel.membersId;
    }

    [self deleteMembers:channel.key];

    [self saveDataInBackgroundWithContext:theDBHandler.privateContext withChannel:channel];
    [self addedMembersArray:channel.membersName andChannelKey:channel.key];
    [self removedMembersArray:channel.removeMembers andChannelKey:channel.key];

}

- (void)saveDataInBackgroundWithContext:(NSManagedObjectContext *) nsContext withChannel:(ALChannel *)channel
{

    if (syncSerialBackgroundQueue == NULL) {
        syncSerialBackgroundQueue = dispatch_queue_create("ApplozicSyncSerialBackgroundQueue", 0);
    }
    // As saveGroupUsersOfChannel:channel withContext:nsContext is running in a background thread it's important to check if the user is loggedIn otherwise it will continue the operation even after logout
    if(!ALUserDefaultsHandler.isLoggedIn){
        return;
    }

    dispatch_async(syncSerialBackgroundQueue, ^{
        [self saveGroupUsersOfChannel:channel withContext:nsContext];
    });

}


-(void)saveGroupUsersOfChannel:(ALChannel *)channel withContext:(NSManagedObjectContext *)context {
    [context performBlock:^{

        int count = 0;
        for(ALChannelUser * channelUser  in  channel.groupUsers)
        {
            ALChannelUserX *newChannelUserX = [[ALChannelUserX alloc] init];
            newChannelUserX.key = channel.key;
            if(channelUser.userId != nil){
                newChannelUserX.userKey = channelUser.userId;
            }
            if(channelUser.parentGroupKey != nil){
                newChannelUserX.parentKey = channelUser.parentGroupKey;
            }
            if(channelUser.role != nil){
                newChannelUserX.role = channelUser.role;
            }
            if(ALUserDefaultsHandler.isLoggedIn){
                [self createChannelUserXEntity:newChannelUserX  withContext:context];
            }
            count++;
            if(count % 300 == 0){
                [[ALDBHandler sharedInstance] savePrivateAndMainContext:context];
            }
        }
        [[ALDBHandler sharedInstance] savePrivateAndMainContext:context];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Updated_Group_Members" object:channel];

    }];
}


-(void)addMemberToChannel:(NSString *)userId andChannelKey:(NSNumber *)channelKey
{
    ALChannelUserX *newUserX = [[ALChannelUserX alloc] init];
    newUserX.key = channelKey;
    newUserX.userKey = userId;
    
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
//    DB_CHANNEL_USER_X *dbChannelUserX = [self createChannelUserXEntity: newUserX];
    [self createChannelUserXEntity: newUserX];
    
    [theDBHandler.managedObjectContext save:nil];
    //channelUserX.channelDBObjectId = dbChannelUserX.objectID;
    
}

-(void)insertChannel:(NSMutableArray *)channelList
{
    NSMutableArray *channelArray = [[NSMutableArray alloc] init];
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    
    for(ALChannel *channel in channelList)
    {
//        DB_CHANNEL *dbChannel = [self createChannelEntity:channel];
         [self createChannelEntity:channel];
        // IT MIGHT BE USED IN FUTURE
        [theDBHandler.managedObjectContext save:nil];
        //channel.channelDBObjectId = dbChannel.objectID;
        [channelArray addObject:channel];
    }
    
    NSError *error = nil;
    [theDBHandler.managedObjectContext save:&error];
    if(error)
    {
        ALSLog(ALLoggerSeverityError, @"ERROR IN insertChannel METHOD %@",error);
    }
}

-(DB_CHANNEL *)createChannelEntity:(ALChannel *)channel
{
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    DB_CHANNEL * theChannelEntity = [self getChannelByKey:channel.key];
    
    if(!theChannelEntity)
    {
        theChannelEntity = [NSEntityDescription insertNewObjectForEntityForName:@"DB_CHANNEL" inManagedObjectContext:theDBHandler.managedObjectContext];
    }
    theChannelEntity.channelDisplayName = channel.name;
    theChannelEntity.channelKey = channel.key;
    theChannelEntity.clientChannelKey = channel.clientChannelKey;
    if(channel.userCount)
    {
        theChannelEntity.userCount = channel.userCount;
    }
    theChannelEntity.notificationAfterTime = channel.notificationAfterTime;
    theChannelEntity.deletedAtTime = channel.deletedAtTime;
    theChannelEntity.parentGroupKey = channel.parentKey;
    theChannelEntity.parentClientGroupKey = channel.parentClientKey;
    theChannelEntity.channelImageURL = channel.channelImageURL;
    theChannelEntity.type = channel.type;
    theChannelEntity.adminId = channel.adminKey;
    if(channel.unreadCount != nil && [channel.unreadCount  compare:[NSNumber numberWithInt:0]] != NSOrderedSame){
        theChannelEntity.unreadCount = channel.unreadCount;
    }
    theChannelEntity.metadata = channel.metadata.description;
    theChannelEntity.category = channel.category;
    return theChannelEntity;
}

-(void)deleteMembers:(NSNumber *)key
{
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X" inManagedObjectContext:theDBHandler.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@", key];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [theDBHandler.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(array.count)
    {
        for(NSManagedObject *manageOBJ in array)
        {
            [theDBHandler.managedObjectContext deleteObject:manageOBJ];
        }
    }
    [theDBHandler.managedObjectContext save:nil];
}

-(void)insertChannelUserX:(NSMutableArray *)channelUserXList
{
    NSMutableArray *channelUserXArray = [[NSMutableArray alloc] init];
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    
    if(channelUserXList.count)
    {
        ALChannelUserX *channelUserTemp = [channelUserXList objectAtIndex:0];
        [self deleteMembers:channelUserTemp.key];
    }
    
    for(ALChannelUserX *channelUserX in channelUserXList)
    {
//        DB_CHANNEL_USER_X *dbChannelUserX = [self createChannelUserXEntity:channelUserX];
         [self createChannelUserXEntity:channelUserX];
        // IT MIGHT BE USED IN FUTURE
        [theDBHandler.managedObjectContext save:nil];
        //channelUserX.channelDBObjectId = dbChannelUserX.objectID;
        [channelUserXArray addObject:channelUserX];
    }

    NSError *error = nil;
    [theDBHandler.managedObjectContext save:&error];
    if(error)
    {
        ALSLog(ALLoggerSeverityError, @"ERROR IN insertChannelUserX METHOD %@",error);
    }
    
}

-(DB_CHANNEL_USER_X *)createChannelUserXEntity:(ALChannelUserX *)channelUserX  withContext:(NSManagedObjectContext *) context{

    DB_CHANNEL_USER_X * theChannelUserXEntity = [NSEntityDescription insertNewObjectForEntityForName:@"DB_CHANNEL_USER_X" inManagedObjectContext:context];

    if(channelUserX)
    {
        theChannelUserXEntity.channelKey = channelUserX.key;
        theChannelUserXEntity.userId = channelUserX.userKey;
        if(channelUserX.parentKey != nil){
            theChannelUserXEntity.parentGroupKey = channelUserX.parentKey;
        }

        if(channelUserX.role != nil){
            theChannelUserXEntity.role = channelUserX.role;
        }
    }

    return theChannelUserXEntity;
}

-(DB_CHANNEL_USER_X *)createChannelUserXEntity:(ALChannelUserX *)channelUserX
{
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    DB_CHANNEL_USER_X * theChannelUserXEntity = [NSEntityDescription insertNewObjectForEntityForName:@"DB_CHANNEL_USER_X" inManagedObjectContext:theDBHandler.managedObjectContext];
    
    if(channelUserX)
    {
        theChannelUserXEntity.channelKey = channelUserX.key;
        theChannelUserXEntity.userId = channelUserX.userKey;
        theChannelUserXEntity.parentGroupKey = channelUserX.parentKey;
        //        theChannelUserXEntity.status = channelUserX.status;
    }
    
    return theChannelUserXEntity;
}

-(NSMutableArray *)getChannelMembersList:(NSNumber *)channelKey
{
    NSMutableArray *memberList = [[NSMutableArray alloc] init];
    ALDBHandler * theDBHandler = [ALDBHandler sharedInstance];
    NSManagedObjectContext * managedObjectContext = theDBHandler.managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:@"userId"]];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@", channelKey];
    [fetchRequest setPredicate:predicate];

    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error)
    {
        ALSLog(ALLoggerSeverityError, @"ERROR IN FETCH MEMBER LIST");
    }
    else
    {

        NSMutableArray* users = [NSMutableArray arrayWithArray:fetchedObjects];

        for (NSDictionary * theDictionary in users)
        {
            [memberList addObject:[theDictionary valueForKey:@"userId"]];
        }
    }

    return memberList;
}

-(ALChannel *)loadChannelByKey:(NSNumber *)key
{
    ALChannel *cachedChannel = [[SearchResultCache shared] getChannelWithId: key];
    if (cachedChannel != nil) {
        return cachedChannel;
    }
    DB_CHANNEL *dbChannel = [self getChannelByKey:key];
    ALChannel *alChannel = [[ALChannel alloc] init];

    if (!dbChannel)
    {
        return nil;
    }

    alChannel.parentKey = dbChannel.parentGroupKey;
    alChannel.parentClientKey = dbChannel.parentClientGroupKey;
    alChannel.key = dbChannel.channelKey;
    alChannel.clientChannelKey = dbChannel.clientChannelKey;
    alChannel.name = dbChannel.channelDisplayName;
    alChannel.channelImageURL = dbChannel.channelImageURL;
    alChannel.unreadCount = dbChannel.unreadCount;
    alChannel.adminKey = dbChannel.adminId;
    alChannel.type = dbChannel.type;
    if(alChannel.type == GROUP_OF_TWO){
        alChannel.membersName = [self getChannelMembersList:key];
        alChannel.membersId = [self getChannelMembersList:key];
    }
    alChannel.notificationAfterTime = dbChannel.notificationAfterTime;
    alChannel.deletedAtTime = dbChannel.deletedAtTime;
    alChannel.metadata = [alChannel getMetaDataDictionary:dbChannel.metadata];
    alChannel.userCount = dbChannel.userCount;
    alChannel.category = dbChannel.category;
    return alChannel;
}

-(DB_CHANNEL *)getChannelByKey:(NSNumber *)key
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",key];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL *dbChannel = [result objectAtIndex:0];
        return dbChannel;
    }
    else
    {
        return nil;
    }
}


//------------------------------------------
#pragma mark CONTACTS GROUP TYPE and NAME GET CHANNEL
//------------------------------------------


-(DB_CHANNEL *)getContactsGroupChannelByName:(NSString *)channelName
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"channelDisplayName = %@",channelName];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"type = %i", CONTACT_GROUP];
    NSPredicate* combinePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate: combinePredicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL *dbChannel = [result objectAtIndex:0];
        return dbChannel;
    }
    else
    {
        return nil;
    }
}




-(ALChannelUserX *)loadChannelUserX:(NSNumber *)channelKey{
    
    DB_CHANNEL_USER_X *dbChannelUserX = [self getChannelUserX:channelKey];
    ALChannelUserX *alChannelUserX = [[ALChannelUserX alloc] init];
    
    if (!dbChannelUserX)
    {
        return nil;
    }
    
    alChannelUserX.key =dbChannelUserX.channelKey;
    alChannelUserX.parentKey =dbChannelUserX.parentGroupKey;
    alChannelUserX.userKey =dbChannelUserX.userId;
    alChannelUserX.status = dbChannelUserX.status;
    alChannelUserX.unreadCount =dbChannelUserX.unreadCount;
    alChannelUserX.role = dbChannelUserX.role;
    return alChannelUserX;
}




-(DB_CHANNEL_USER_X *)getChannelUserXByUserId:(NSNumber *)channelKey andUserId:(NSString *) userId
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey == %@ AND userId == %@", channelKey, userId];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL_USER_X *dbChannelUserX = [result objectAtIndex:0];
        return dbChannelUserX;
    }
    else
    {
        return nil;
    }
}


-(DB_CHANNEL_USER_X *)getChannelUserX:channelKey{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",channelKey];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL_USER_X *dbChannelUserX = [result objectAtIndex:0];
        return dbChannelUserX;
    }
    else
    {
        return nil;
    }
}



-(ALChannelUserX *)loadChannelUserXByUserId:(NSNumber *)channelKey andUserId:(NSString *)userId{
    
    DB_CHANNEL_USER_X *dbChannelUserX = [self getChannelUserXByUserId:channelKey andUserId:userId];
    ALChannelUserX *alChannelUserX = [[ALChannelUserX alloc] init];
    
    if (!dbChannelUserX)
    {
        return nil;
    }
    
    alChannelUserX.key = dbChannelUserX.channelKey;
    alChannelUserX.parentKey =dbChannelUserX.parentGroupKey;
    alChannelUserX.userKey = dbChannelUserX.userId;
    alChannelUserX.status = dbChannelUserX.status;
    alChannelUserX.unreadCount = dbChannelUserX.unreadCount;
    alChannelUserX.role = dbChannelUserX.role;
    
    return alChannelUserX;
}








-(void)updateParentKeyInChannelUserX:(NSNumber *)channelKey andWithParentKey:(NSNumber *)parentKey addUserId :(NSString *) userId
{
    
    DB_CHANNEL_USER_X *channelUserX =  [self getChannelUserXByUserId:channelKey andUserId:userId];
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    
    channelUserX.parentGroupKey = parentKey;
    [dbHandler.managedObjectContext save:nil];
    
}

-(void)updateRoleInChannelUserX:(NSNumber *)channelKey andUserId:(NSString *)userId withRoleType:(NSNumber*)role
{
    
    DB_CHANNEL_USER_X *channelUserX = [self getChannelUserXByUserId:channelKey andUserId:userId];
    
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    
    channelUserX.role = role;
    
    [dbHandler.managedObjectContext save:nil];
    
}

-(NSMutableArray *)getListOfAllUsersInChannel:(NSNumber *)key
{
    NSMutableArray *memberList = [[NSMutableArray alloc] init];
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X"
                                              inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",key];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *resultArray = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (resultArray.count)
    {
        for(DB_CHANNEL_USER_X *dbChannelUserX in resultArray)
        {
            [memberList addObject:dbChannelUserX.userId];
        }
        
        return memberList;
    }
    else
    {
        return nil;
    }
    
}


//------------------------------------------
#pragma mark GET ALL USERS OF CONTACT GROUP BY CHANNEL NAME
//------------------------------------------


-(NSMutableArray *)getListOfAllUsersInChannelByNameForContactsGroup:(NSString *)channelName
{
    
    if(channelName == nil){
        return nil;
    }
    
    DB_CHANNEL *dbChannel = [self getContactsGroupChannelByName:channelName];
    
    if(dbChannel != nil){
        return [self getListOfAllUsersInChannel:dbChannel.channelKey];
        
    }
    return nil;
    
}

-(NSString *)stringFromChannelUserList:(NSNumber *)key
{
    NSString *listString = @"";
    NSString *str = @"";

    NSMutableArray * tempArray = [NSMutableArray arrayWithArray:[self getListOfAllUsersInChannel:key]];

    if(!tempArray ||  tempArray.count == 0)
    {
        return @"";
    }
    NSMutableArray * listArray = [NSMutableArray new];
    ALContactDBService *contactDB = [ALContactDBService new];
    for(NSString *userID in tempArray)
    {
        ALContact *contact = [contactDB loadContactByKey:@"userId" value:userID];
        [listArray addObject: [contact getDisplayName]];
    }
    if(listArray.count == 1)
    {
        listString = listArray[0];
    }
    else if(listArray.count == 2)
    {
        listString = [NSString stringWithFormat:@"%@, %@", listArray[0], listArray[1]];
    }
    else if(listArray.count > 2)
    {
        int counter = (int)listArray.count - 2;
        str = [NSString stringWithFormat:@"+%d %@",counter, NSLocalizedStringWithDefaultValue(@"moreMember", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"more", @"")];
        listString = [NSString stringWithFormat:@"%@, %@, %@", listArray[0], listArray[1], str];
    }

    return listString;
}


-(ALChannel *)checkChannelEntity:(NSNumber *)channelKey
{
    DB_CHANNEL *dbChannel = [self getChannelByKey:channelKey];
    ALChannel *channel  = [[ALChannel alloc] init];
    
    if(dbChannel)
    {
        channel.parentKey = dbChannel.parentGroupKey;
        channel.parentClientKey = dbChannel.parentClientGroupKey;
        channel.key = dbChannel.channelKey;
        channel.clientChannelKey = dbChannel.clientChannelKey;
        channel.name = dbChannel.channelDisplayName;
        channel.adminKey = dbChannel.adminId;
        channel.type = dbChannel.type;
        channel.unreadCount = dbChannel.unreadCount;
        channel.channelImageURL = dbChannel.channelImageURL;
        channel.deletedAtTime = dbChannel.deletedAtTime;
        channel.metadata = [channel getMetaDataDictionary:dbChannel.metadata];
        channel.userCount = dbChannel.userCount;
        channel.category = dbChannel.category;
        return channel;
    }
    else
    {
        return nil;
    }
}

-(void)removeMemberFromChannel:(NSString *)userId andChannelKey:(NSNumber *)channelKey
{
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X"
                                              inManagedObjectContext:theDBHandler.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"channelKey = %@", channelKey];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"userId = %@", userId];
    NSPredicate* combinePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
    [fetchRequest setPredicate: combinePredicate];
    
    NSError *error = nil;
    NSArray *array = [theDBHandler.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(array.count)
    {
        NSManagedObject *manageOBJ = [array objectAtIndex:0];
        [theDBHandler.managedObjectContext deleteObject:manageOBJ];
        [theDBHandler.managedObjectContext save:nil];
    }
    else
    {
        ALSLog(ALLoggerSeverityWarn, @"NO MEMBER FOUND");
    }
}

-(void)deleteChannel:(NSNumber *)channelKey
{
    //Delete channel
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL"
                                              inManagedObjectContext:theDBHandler.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@", channelKey];
    [fetchRequest setPredicate: predicate];
    
    NSError *error = nil;
    NSArray *array = [theDBHandler.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    //    NSLog(@"CHANEL KEY = %@", channelKey);
    //    NSLog(@"ARRAY COUNT = %lu", (unsigned long)array.count);
    if(array.count)
    {
        NSManagedObject *manageOBJ = [array objectAtIndex:0];
        [theDBHandler.managedObjectContext deleteObject:manageOBJ];
        [theDBHandler.managedObjectContext save:nil];
        
        // Delete all members
        [self deleteMembers:channelKey];
        
    }
    else
    {
        ALSLog(ALLoggerSeverityWarn, @"NO ENTRY FOUND");
    }
}

#pragma mark- Fetch All Channels
//==============================

-(NSMutableArray*)getAllChannelKeyAndName
{
    ALDBHandler *theDBHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL"
                                              inManagedObjectContext:theDBHandler.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type != %i",CONTACT_GROUP];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [theDBHandler.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSMutableArray * alChannels = [[NSMutableArray alloc] init];
    if(array.count)
    {
        for(DB_CHANNEL * dbChannel in array)
        {
            ALChannel* channel = [[ALChannel alloc] init];
            channel.parentKey = dbChannel.parentGroupKey;
            channel.parentClientKey = dbChannel.parentClientGroupKey;
            channel.key = dbChannel.channelKey;
            channel.clientChannelKey = dbChannel.clientChannelKey;
            channel.name = dbChannel.channelDisplayName;            
            channel.adminKey = dbChannel.adminId;
            channel.type = dbChannel.type;
            channel.unreadCount = dbChannel.unreadCount;
            channel.channelImageURL = dbChannel.channelImageURL;
            channel.deletedAtTime = dbChannel.deletedAtTime;
            channel.metadata = [channel getMetaDataDictionary:dbChannel.metadata];
            channel.userCount = dbChannel.userCount;
            channel.category = dbChannel.category;
            [alChannels addObject:channel];
        }
    }
    else
    {
        ALSLog(ALLoggerSeverityWarn, @"NO ENTRY FOUND");
    }
    return alChannels;
}

-(NSNumber *)getOverallUnreadCountForChannelFromDB
{
    NSNumber * unreadCount;
    int count = 0;
    NSMutableArray * channelArray = [NSMutableArray arrayWithArray:[self getAllChannelKeyAndName]];
    for(ALChannel *alChannel in channelArray)
    {
        count = count + [alChannel.unreadCount intValue];
    }
    unreadCount = [NSNumber numberWithInt:count];
    return unreadCount;
}


-(void)updateChannel:(NSNumber *)channelKey andNewName:(NSString *)newName orImageURL:(NSString *)imageURL orChildKeys:(NSMutableArray *)childKeysList isUpdatingMetaData:(BOOL)flag  orChannelUsers:(NSMutableArray *)channelUsers{
    
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",channelKey];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL *dbChannel = [result objectAtIndex:0];
        if(newName.length) {
            dbChannel.channelDisplayName = newName;
        }
        
        if (!flag){
            dbChannel.channelImageURL = imageURL;
        }
        
        if(childKeysList.count) {
            for(NSNumber * childKey in childKeysList) {
                [self updateChannelParentKey:childKey andWithParentKey:channelKey isAdding:YES];
            }
        }
        for(NSDictionary * chUserDict in channelUsers)
        {
            ALChannelUser * channelUser = [[ALChannelUser alloc] initWithDictonary:chUserDict];
            if(channelUser.parentGroupKey)
            {
                [self updateParentKeyInChannelUserX:channelKey andWithParentKey:channelUser.parentGroupKey addUserId:channelUser.userId];
            }
            
            if(channelUser.role)
            {
                [self updateRoleInChannelUserX:channelKey andUserId:channelUser.userId withRoleType:channelUser.role];
            }
            
        }
        
        [dbHandler.managedObjectContext save:nil];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"UPDATE_CHANNEL_DB : NO CHANNEL FOUND");
    }
}

-(void)updateChannelMetaData:(NSNumber *)channelKey metaData:(NSMutableDictionary *)newMetaData{
    
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",channelKey];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL *dbChannel = [result objectAtIndex:0];
        if(newMetaData!=nil) {
            dbChannel.metadata = newMetaData.description;
            
            // Update conversation status from metadata
            dbChannel.category = [ALChannel getConversationCategory:newMetaData];
        }
        
        [dbHandler.managedObjectContext save:nil];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"UPDATE_CHANNEL_DB : NO CHANNEL FOUND");
    }
}

-(void) updateChannelParentKey:(NSNumber *)channelKey andWithParentKey:(NSNumber *)channelParentKey isAdding:(BOOL)flag
{
    DB_CHANNEL *parentChannel = [self getChannelByKey:channelParentKey];
    DB_CHANNEL *childChannel = [self getChannelByKey:channelKey];
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    
    if(flag)
    {
        childChannel.parentGroupKey = parentChannel.channelKey;
        childChannel.parentClientGroupKey = parentChannel.clientChannelKey;
    }
    else
    {
        childChannel.parentGroupKey = nil;
        childChannel.parentClientGroupKey = nil;
    }
    
    [dbHandler.managedObjectContext save:nil];
}

-(void)updateClientChannelParentKey:(NSString *)clientChildKey andWithClientParentKey:(NSString *)clientParentKey isAdding:(BOOL)flag
{
    DB_CHANNEL *parentChannel = [self getChannelByClientChannelKey:clientParentKey];
    DB_CHANNEL *childChannel = [self getChannelByClientChannelKey:clientChildKey];
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    
    if(flag)
    {
        childChannel.parentGroupKey = parentChannel.channelKey;
        childChannel.parentClientGroupKey = parentChannel.clientChannelKey;
    }
    else
    {
        childChannel.parentGroupKey = nil;
        childChannel.parentClientGroupKey = nil;
    }
    
    [dbHandler.managedObjectContext save:nil];
}

-(void)updateUnreadCountChannel:(NSNumber *)channelKey unreadCount:(NSNumber *)unreadCount
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",channelKey];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count && unreadCount!=nil)
    {
        DB_CHANNEL *dbChannel = [result objectAtIndex:0];
        dbChannel.unreadCount = unreadCount;
        [dbHandler.managedObjectContext save:nil];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"NO CHANNEL FOUND");
    }
}

-(void)setLeaveFlag:(BOOL)flag forChannel:(NSNumber *)groupId
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    DB_CHANNEL *dbChannel = [self getChannelByKey:groupId];
    
    if(dbChannel)
    {
        dbChannel.isLeft = flag;
        [dbHandler.managedObjectContext save:nil];
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"NO CHANNEL : %@ FOUND",groupId);
    }
}

-(BOOL)isChannelLeft:(NSNumber *)groupId
{
    DB_CHANNEL *dbChannel = [self getChannelByKey:groupId];
    return dbChannel.isLeft;
}

-(BOOL)isChannelDeleted:(NSNumber *)groupId
{
    DB_CHANNEL *dbChannel = [self getChannelByKey:groupId];
    return (dbChannel.deletedAtTime != nil);
}

-(BOOL)isConversaionClosed:(NSNumber *)groupId
{
    DB_CHANNEL *dbChannel = [self getChannelByKey:groupId];
    ALChannel *channel = [ALChannel new];
    NSMutableDictionary *metadata =   [channel getMetaDataDictionary:dbChannel.metadata];
    
    if( metadata && [metadata  valueForKey:CHANNEL_CONVERSATION_STATUS] ){
        return ([[metadata  valueForKey:CHANNEL_CONVERSATION_STATUS] isEqualToString:@"CLOSE"]);
    }
    return NO;
}

-(BOOL)isAdminBroadcastChannel:(NSNumber *)groupId
{
    DB_CHANNEL *dbChannel = [self getChannelByKey:groupId];
    ALChannel *channel = [ALChannel new];
    NSMutableDictionary *metadata = [channel getMetaDataDictionary:dbChannel.metadata];
    
    return (metadata && [[metadata valueForKey:@"AL_ADMIN_BROADCAST"] isEqualToString:@"true"]);
}


-(void)createChannelsAndUpdateInfo:(NSMutableArray *)channelArray withDelegate:(id<ApplozicUpdatesDelegate>)delegate{
   
    for(ALChannel *channelObject in channelArray)
    {
        [self createChannel:channelObject];
        if(delegate){
            [delegate onChannelUpdated:channelObject];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_channel_Info" object:channelObject];
    }

}


//------------------------------------------
#pragma mark AFTER LEAVE LOGOUT and LOGIN
//------------------------------------------

-(void)removedMembersArray:(NSMutableArray *)memberArray andChannelKey:(NSNumber *)channelKey
{
    if([memberArray containsObject:[ALUserDefaultsHandler getUserId]])
    {
        [self setLeaveFlag:YES forChannel:channelKey];
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:channelKey forKey:@"CHANNEL_KEY"];
        [dict setObject:[NSNumber numberWithInt:1] forKey:@"FLAG_VALUE"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_USER_FREEZE_CHANNEL_ADD_REMOVING" object:nil userInfo:dict];
    }
}

-(void)addedMembersArray:(NSMutableArray *)memberArray andChannelKey:(NSNumber *)channelKey
{
    if([memberArray containsObject:[ALUserDefaultsHandler getUserId]])
    {
        [self setLeaveFlag:NO forChannel:channelKey];
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:channelKey forKey:@"CHANNEL_KEY"];
        [dict setObject:[NSNumber numberWithInt:0] forKey:@"FLAG_VALUE"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_USER_FREEZE_CHANNEL_ADD_REMOVING" object:nil userInfo:dict];
    }
}


//-----------------------------
#pragma mark Marking Group Read
//-----------------------------

-(NSUInteger)markConversationAsRead:(NSNumber*)channelKey
{
    NSArray *messages;
    
    if(channelKey){
        messages =  [self getUnreadMessagesForGroup:channelKey];
    }
    else{
        ALSLog(ALLoggerSeverityError, @"channelKey null for marking unread");
    }
    
    if(messages.count > 0)
    {
        NSBatchUpdateRequest *req= [[NSBatchUpdateRequest alloc] initWithEntityName:@"DB_Message"];
        req.predicate = [NSPredicate predicateWithFormat:@"groupId=%d",[channelKey intValue]];
        req.propertiesToUpdate = @{
                                   @"status" : @(DELIVERED_AND_READ)
                                   };
        req.resultType = NSUpdatedObjectsCountResultType;
        ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
        NSBatchUpdateResult *res = (NSBatchUpdateResult *)[dbHandler.managedObjectContext executeRequest:req error:nil];
        ALSLog(ALLoggerSeverityInfo, @"%@ objects updated", res.result);
    }
    return messages.count;
}

- (NSArray *)getUnreadMessagesForGroup:(NSNumber*)groupId {
    
    //Runs at Opening AND Leaving ChatVC AND Opening MessageList..
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_Message" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate;
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"status != %i AND type==%@ ",DELIVERED_AND_READ,@"4"];
    
    if (groupId) {
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"%K=%d",@"groupId",groupId.intValue];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
    }
    else {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate2]];
    }
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    return result;
}

-(DB_CHANNEL *)getChannelByClientChannelKey:(NSString *)clientChannelKey
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"clientChannelKey = %@",clientChannelKey];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count)
    {
        DB_CHANNEL *dbChannel = [result objectAtIndex:0];
        return dbChannel;
    }
    else
    {
        ALSLog(ALLoggerSeverityError, @"CHANNEL_NOT_FOUND :: %@",clientChannelKey);
        return nil;
    }
}

-(ALChannel *)loadChannelByClientChannelKey:(NSString *)clientChannelKey
{
    DB_CHANNEL * dbChannel = [self getChannelByClientChannelKey:clientChannelKey];
    ALChannel *alChannel = [[ALChannel alloc] init];
    
    if (!dbChannel)
    {
        return nil;
    }
    
    alChannel.parentKey = dbChannel.parentGroupKey;
    alChannel.parentClientKey = dbChannel.parentClientGroupKey;
    alChannel.key = dbChannel.channelKey;
    alChannel.clientChannelKey = dbChannel.clientChannelKey;
    alChannel.name = dbChannel.channelDisplayName;
    alChannel.unreadCount = dbChannel.unreadCount;
    alChannel.adminKey = dbChannel.adminId;
    alChannel.type = dbChannel.type;
    alChannel.channelImageURL = dbChannel.channelImageURL;
    alChannel.deletedAtTime = dbChannel.deletedAtTime;
    alChannel.metadata = [alChannel getMetaDataDictionary:dbChannel.metadata];
    alChannel.userCount = dbChannel.userCount;
    alChannel.category = dbChannel.category;
    return alChannel;
}


-(NSMutableArray *)fetchChildChannels:(NSNumber *)parentGroupKey
{
    NSMutableArray *childArray = [[NSMutableArray alloc] init];
    
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL" inManagedObjectContext:dbHandler.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroupKey = %@",parentGroupKey];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    ALSLog(ALLoggerSeverityInfo, @"CHILD CHANNEL FOUND : %lu WITH PARENT KEY : %@",(unsigned long)result.count, parentGroupKey);
    ALSLog(ALLoggerSeverityError, @"ERROR (IF-ANY) : %@",fetchError.description);
    
    for(DB_CHANNEL *dbChannel in result)
    {
        ALChannel *alChannel = [[ALChannel alloc] init];
        
        alChannel.parentKey = dbChannel.parentGroupKey;
        alChannel.parentClientKey = dbChannel.parentClientGroupKey;
        alChannel.key = dbChannel.channelKey;
        alChannel.clientChannelKey = dbChannel.clientChannelKey;
        alChannel.name = dbChannel.channelDisplayName;
        alChannel.unreadCount = dbChannel.unreadCount;
        alChannel.adminKey = dbChannel.adminId;
        alChannel.type = dbChannel.type;
        alChannel.channelImageURL = dbChannel.channelImageURL;
        alChannel.deletedAtTime = dbChannel.deletedAtTime;
        alChannel.metadata = [alChannel getMetaDataDictionary:dbChannel.metadata];
        alChannel.userCount = dbChannel.userCount;
        alChannel.category = dbChannel.category;
        [childArray addObject:alChannel];
    }
    
    return childArray;
}

-(void)updateMuteAfterTime:(NSNumber*)notificationAfterTime andChnnelKey:(NSNumber*)channelKey
{
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    
    DB_CHANNEL *dbChannel = [self getChannelByKey:channelKey];
    dbChannel.notificationAfterTime = notificationAfterTime;
    [dbHandler.managedObjectContext save:nil];
}

-(NSMutableArray *) getGroupUsersInChannel:(NSNumber *)key {
    NSMutableArray *memberList = [[NSMutableArray alloc] init];
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CHANNEL_USER_X"
                                              inManagedObjectContext:dbHandler.managedObjectContext];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",key];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];

    NSError *fetchError = nil;
    NSArray *resultArray = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];

    if (resultArray.count)
    {
        for(DB_CHANNEL_USER_X *dbChannelUserX in resultArray)
        {
            [memberList addObject:dbChannelUserX];
        }

        return memberList;
    }
    else
    {
        return nil;
    }
}


-(void)fetchChannelMembersAsyncWithChannelKey:(NSNumber*)channelKey witCompletion:(void(^)(NSMutableArray *membersArray))completion{

    NSMutableArray *memberList = [[NSMutableArray alloc] init];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DB_CHANNEL_USER_X"];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@",channelKey];

    [fetchRequest setPredicate:predicate];

    NSAsynchronousFetchRequest *asynchronousFetchRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:fetchRequest completionBlock:^(NSAsynchronousFetchResult *result) {

        NSArray *resultArray =   result.finalResult;

        if (resultArray && resultArray.count)
        {
            for(DB_CHANNEL_USER_X *dbChannelUserX in resultArray)
            {
                [memberList addObject:dbChannelUserX.userId];
            }
        }else{
            ALSLog(ALLoggerSeverityWarn, @"NO MEMBER FOUND");
        }
        completion(memberList);
    }];

    NSManagedObjectContext *managedObjectContext =  [[ALDBHandler sharedInstance] managedObjectContext];
    [managedObjectContext performBlock:^{
        [managedObjectContext executeRequest:asynchronousFetchRequest error:nil];
    }];
}

-(void) getUserInSupportGroup:(NSNumber *) channelKey withCompletion:(void(^)(NSString *userId)) completion {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DB_CHANNEL_USER_X"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelKey = %@ AND role = %@", channelKey, @3];
    [fetchRequest setPredicate:predicate];

    NSAsynchronousFetchRequest *asynchronousFetchRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:fetchRequest completionBlock:^(NSAsynchronousFetchResult *result) {
        NSArray *resultArray =   result.finalResult;
        if (resultArray && resultArray.count) {
            DB_CHANNEL_USER_X *user = resultArray[0];
            completion(user.userId);
        } else {
            ALSLog(ALLoggerSeverityWarn, @"NO MEMBER FOUND");
            completion(nil);
        }
    }];

    NSManagedObjectContext *managedObjectContext = [[ALDBHandler sharedInstance] managedObjectContext];
    [managedObjectContext performBlock:^{
        [managedObjectContext executeRequest:asynchronousFetchRequest error:nil];
    }];
}

@end
