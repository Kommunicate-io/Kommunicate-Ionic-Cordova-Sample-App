//
//  ALDBHandler.m
//  ChatApp
//
//  Created by Gaurav Nigam on 09/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALDBHandler.h"
#import "DB_CONTACT.h"
#import "ALContact.h"
#import "ALUtilityClass.h"
#import "ALApplozicSettings.h"

@implementation ALDBHandler

+(ALDBHandler *) sharedInstance
{
    static ALDBHandler *sharedMyManager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedMyManager = [[self alloc] init];
        
    });
    
    return sharedMyManager;
}

- (id)init {
    
    if (self = [super init]) {


    }

    if (@available(iOS 10.0, *)) {
        NSPersistentContainer * container = [[NSPersistentContainer alloc] initWithName:@"AppLozic" managedObjectModel:self.managedObjectModel];

        [container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription* store, NSError * error) {
            ALSLog(ALLoggerSeverityInfo, @"pers url: %@",container.persistentStoreCoordinator.persistentStores.firstObject.URL);
            if(error != nil) {
                ALSLog(ALLoggerSeverityError, @"%@", error);
            }
        }];
        self.persistentContainer = container;
    }
    return self;
}


@synthesize managedObjectContext = _managedObjectContext;

@synthesize managedObjectModel = _managedObjectModel;

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSManagedObjectModel *)managedObjectModel {
    
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    
    if (_managedObjectModel != nil) {
        
        return _managedObjectModel;
        
    }
    
    NSURL *modelURL = [[NSBundle bundleForClass:[self class]]URLForResource:@"AppLozic" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    @synchronized (self) {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.

        if (_persistentStoreCoordinator != nil) {

            return _persistentStoreCoordinator;

        }

        // Create the coordinator and store
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

        NSURL *storeURL =  [ALUtilityClass getApplicationDirectoryWithFilePath:AL_SQLITE_FILE_NAME];

        NSURL *groupURL = [ALUtilityClass getAppsGroupDirectoryWithFilePath:AL_SQLITE_FILE_NAME];

        NSError *error = nil;
        NSPersistentStore  *sourceStore  = nil;
        NSPersistentStore  *destinationStore  = nil;
        NSDictionary *options =   @{NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES]};

        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]){
            ALSLog(ALLoggerSeverityError, @"Failed to setup the persistentStoreCoordinator %@, %@", error, [error userInfo]);
        } else {
            sourceStore = [_persistentStoreCoordinator persistentStoreForURL:storeURL];
            if (sourceStore != nil && groupURL){
                // Perform the migration

                destinationStore = [_persistentStoreCoordinator migratePersistentStore:sourceStore toURL:groupURL options:options withType:NSSQLiteStoreType error:&error];
                if (destinationStore == nil){
                    ALSLog(ALLoggerSeverityError, @"Failed to migratePersistentStore");
                } else {

                    NSFileCoordinator *coord = [[NSFileCoordinator alloc]initWithFilePresenter:nil];
                    [coord coordinateWritingItemAtURL:storeURL options:0 error:nil byAccessor:^(NSURL *url)
                     {
                         NSError *error;
                         [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
                         if(error){
                             ALSLog(ALLoggerSeverityError, @"Failed to Delete the data base file %@, %@", error, [error userInfo]);
                         }

                     }];

                }
            }
        }

    }

    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    
    if (_managedObjectContext != nil) {
        
        return _managedObjectContext;
        
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (!coordinator) {
        
        return nil;
        
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    
    if (managedObjectContext != nil) {
        
        NSError *error = nil;
        
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            
            ALSLog(ALLoggerSeverityError, @"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

#pragma mark - Delete Contacts API -

- (BOOL)purgeListOfContacts:(NSArray *)contacts {
    BOOL result = NO;
    
    for (ALContact *contact in contacts) {
        
        result = [self purgeContact:contact];
        
        if (!result) {
            
            ALSLog(ALLoggerSeverityError, @"Failure to delete the contacts");
            break;
        }
    }
    
    return result;
}

- (BOOL)purgeContact:(ALContact *)contact {
    
    BOOL success = NO;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CONTACT" inManagedObjectContext:self.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId = %@",contact.userId];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    for (DB_CONTACT *userContact in result) {
        
        [self.managedObjectContext deleteObject:userContact];
    }
    
    NSError *deleteError = nil;
    
    success = [self.managedObjectContext save:&deleteError];
    
    if (!success) {
        
        ALSLog(ALLoggerSeverityError, @"Unable to save managed object context.");
        ALSLog(ALLoggerSeverityError, @"%@, %@", deleteError, deleteError.localizedDescription);
    }
    
    return success;
}

- (BOOL)purgeAllContact {
    BOOL success = NO;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CONTACT" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    
    NSError *fetchError = nil;
    
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    for (DB_CONTACT *userContact in result) {
        
        [self.managedObjectContext deleteObject:userContact];
    }
    
    NSError *deleteError = nil;
    
    success = [self.managedObjectContext save:&deleteError];
    
    if (!success) {
        
        ALSLog(ALLoggerSeverityError, @"Unable to save managed object context.");
        ALSLog(ALLoggerSeverityError, @"%@, %@", deleteError, deleteError.localizedDescription);
    }
    
    return success;
}

#pragma mark - Update Contacts API -

- (BOOL)updateListOfContacts:(NSArray *)contacts {
    
    BOOL result = NO;
    
    for (ALContact *contact in contacts) {
        
        result = [self updateContact:contact];
        
        if (!result) {
            
            ALSLog(ALLoggerSeverityError, @"Failure to update the contacts");
            break;
        }
    }
    
    return result;
}

- (BOOL)updateContact:(ALContact *)contact {
    
    BOOL success = NO;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CONTACT" inManagedObjectContext:self.managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId = %@",contact.userId];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    for (DB_CONTACT *userContact in result) {
        
        userContact.userId = contact.userId;
        userContact.email = contact.email;
        userContact.fullName = contact.fullName;
        userContact.contactNumber = contact.contactNumber;
        userContact.contactImageUrl = contact.contactImageUrl;
        userContact.displayName = contact.displayName;
        userContact.localImageResourceName = contact.localImageResourceName;
        if(contact.contactType){
            userContact.contactType = contact.contactType;
        }
        userContact.roleType = contact.roleType;
        userContact.metadata =contact.metadata.description;
    }
    
    NSError *error = nil;
    
    success = [self.managedObjectContext save:&error];
    
    if (!success) {
        
        ALSLog(ALLoggerSeverityError, @"DB ERROR :%@",error);
    }
    
    return success;
}

#pragma mark - Add Contacts API -

- (BOOL)addListOfContacts:(NSArray *)contacts {
    
    BOOL result = NO;
    
    for (ALContact *contact in contacts) {
        
        result = [self addContact:contact];
        
        if (!result) {
            break;
        }
    }
    
    return result;
}

- (ALContact *) loadContactByKey:(NSString *) key value:(NSString*) value {

    if(!value){
        return nil;
    }

    DB_CONTACT *dbContact = [self getContactByKey:key value:value];
    ALContact *contact = [[ALContact alloc]init];

    if (!dbContact) {
         contact.userId = value;
         contact.displayName = value;
         return contact;
    }
     contact.userId = dbContact.userId;
     contact.fullName = dbContact.fullName;
     contact.contactNumber = dbContact.contactNumber;
     contact.displayName = dbContact.displayName;
     contact.contactImageUrl = dbContact.contactImageUrl;
     contact.email = dbContact.email;
     contact.localImageResourceName = dbContact.localImageResourceName;
     contact.connected = dbContact.connected;
     contact.lastSeenAt = dbContact.lastSeenAt;
     contact.contactType = dbContact.contactType;
     contact.roleType = dbContact.roleType;
     contact.metadata = [contact getMetaDataDictionary:dbContact.metadata];

     return contact;
}


- (DB_CONTACT *)getContactByKey:(NSString *) key value:(NSString*) value {
    ALDBHandler * dbHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DB_CONTACT" inManagedObjectContext:dbHandler.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K=%@",key,value];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    NSError *fetchError = nil;
    NSArray *result = [dbHandler.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    
    if (result.count > 0) {
        DB_CONTACT* dbContact = [result objectAtIndex:0];
       /* ALContact *contact = [[ALContact alloc]init];
        contact.userId = dbContact.userId;
        contact.fullName = dbContact.fullName;
        contact.contactNumber = dbContact.contactNumber];
        contact.displayName = dbContact.displayName;
        contact.contactImageUrl = dbContact.contactImageUrl;
        contact.email = dbContact.email;
        contact.localImageResourceName = dbContact.localImageResourceName;
        return contact;*/
        
        return dbContact;
    } else {
        return nil;
    }
}

-(BOOL)addContact:(ALContact *)userContact {
    
    DB_CONTACT* existingContact = [self getContactByKey:@"userId" value:[userContact userId]];
    if (existingContact) {
        return false;
    }
    
    BOOL result = NO;
    
    DB_CONTACT * contact = [NSEntityDescription insertNewObjectForEntityForName:@"DB_CONTACT" inManagedObjectContext:self.managedObjectContext];
    
    contact.userId = userContact.userId;
    
    contact.fullName = userContact.fullName;
    
    contact.contactNumber = userContact.contactNumber;
    
    contact.displayName = userContact.displayName;
    
    contact.email = userContact.email;
    
    contact.contactImageUrl = userContact.contactImageUrl;
    
    contact.localImageResourceName = userContact.localImageResourceName;
    contact.contactType = userContact.contactType;
    contact.roleType = userContact.roleType;
    contact.metadata = userContact.metadata.description;
    
    NSError *error = nil;
    
    result = [self.managedObjectContext save:&error];
    
    if (!result) {
        ALSLog(ALLoggerSeverityError, @"DB ERROR :%@",error);
    }
    
    return result;
}

- (void)savePrivateAndMainContext:(NSManagedObjectContext *)context {
    NSError *error;
    [context save:&error];
    if (!error) {
        [self saveMainContext];
    }else{
        ALSLog(ALLoggerSeverityError, @"DB ERROR in savePrivateAndMainContext :%@",error);
    }
}

- (void)saveMainContext {
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        [self.managedObjectContext save:&error];
        if(error){
            ALSLog(ALLoggerSeverityError, @"DB ERROR in saveMainContext :%@",error);
        }
    }];
}

- (NSManagedObjectContext *)privateContext {

    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [managedObjectContext setParentContext:self.managedObjectContext];

    return managedObjectContext;
}

@end
