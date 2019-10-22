//
//  ALVCardClass.m
//  Applozic
//
//  Created by Abhishek Thapliyal on 9/21/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALVCardClass.h"
#import "ALUtilityClass.h"
#import "ALPushAssist.h"

@implementation ALVCardClass

-(NSString *)saveContactToDocDirectory:(CNContact *)contact
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * vcfCARDPath = [documentsDirectory stringByAppendingString:
                              [NSString stringWithFormat:@"/CONTACT_%f_CARD.vcf",[[NSDate date] timeIntervalSince1970] * 1000]];
    
    NSError *errorVCFCARD;

    NSData* vCardData = [CNContactVCardSerialization dataWithContacts:@[contact] error:&errorVCFCARD];
    if(contact.imageData)
    {
        NSString* vcString = [[NSString alloc] initWithData:vCardData encoding:NSUTF8StringEncoding];
        NSString* base64Image = [contact.imageData base64EncodedStringWithOptions:0];
        NSString* vcardImageString = [[@"PHOTO;TYPE=JPEG;ENCODING=BASE64:" stringByAppendingString:base64Image] stringByAppendingString:@"\n"];
        vcString = [vcString stringByReplacingOccurrencesOfString:@"END:VCARD" withString:[vcardImageString stringByAppendingString:@"END:VCARD"]];
        vCardData = [vcString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    [vCardData writeToFile:vcfCARDPath atomically:YES];
    ALSLog(ALLoggerSeverityError, @"ERROR_IF_ANY WHILE SAVING VCF FILE :: %@",errorVCFCARD.description);
    return vcfCARDPath;
}

-(void)vCardParser:(NSString *)filePath
{
    NSData *dataString = [NSData dataWithContentsOfFile:filePath];
    NSError *errorVCF;
    NSArray *contactList = [NSArray arrayWithArray:[CNContactVCardSerialization contactsWithData:dataString error:&errorVCF]];
    
    ALSLog(ALLoggerSeverityError, @"ERROR_IF_ANY :: %@", errorVCF);
    
    if(contactList.count == 0)
    {
        return;
    }
    
    CNContact *contactObject = [contactList objectAtIndex:0];
    
    self.alCNContact = contactObject;
//    self.fullName = [contactObject.givenName stringByAppendingString:contactObject.familyName];
    self.fullName = [NSString stringWithFormat:@"%@ %@", contactObject.givenName, contactObject.familyName];
    
    if(contactObject.imageData)
    {
        self.contactImage = [[UIImage alloc] initWithData:contactObject.imageData];
    }
    
    NSString * phone = @"";
    for(CNLabeledValue *phonelabel in contactObject.phoneNumbers)
    {
        CNPhoneNumber *phoneNo = phonelabel.value;
        phone = [phoneNo stringValue];
        if (phone)
        {
            self.userPHONE_NO = phone;
        }
    }
    
    NSString * email = @"";
    for(CNLabeledValue *emaillabel in contactObject.emailAddresses)
    {
        email = emaillabel.value;
        if (email)
        {
            self.userEMAIL_ID = email;
        }
    }
}

-(void)addContact:(ALVCardClass *)alVcard
{
    CNContactStore *store = [[CNContactStore alloc] init];
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    CNMutableContact *mutableContact = [[CNMutableContact alloc] init];
    
    mutableContact.givenName = alVcard.fullName;
    mutableContact.imageData = UIImagePNGRepresentation(alVcard.contactImage);
    mutableContact.phoneNumbers = [NSArray arrayWithArray:alVcard.alCNContact.phoneNumbers];
    mutableContact.emailAddresses = [NSArray arrayWithArray:alVcard.alCNContact.emailAddresses];
    
    [saveRequest addContact:mutableContact toContainerWithIdentifier:nil];
    
    NSError * error;
    [store executeSaveRequest:saveRequest error:&error];
    
    ALSLog(ALLoggerSeverityError, @"ERROR SAVING_CONTACT (IF ANY) : %@", error.description);


    if(error)
    {   NSString * alertTitle = NSLocalizedStringWithDefaultValue(@"applicationSettings", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Application Settings", @"");
        NSString * alertMessage = NSLocalizedStringWithDefaultValue(@"permissionPopMessageForContacts", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Enable Contacts Permission", @"");
        NSString * cancelTitle = NSLocalizedStringWithDefaultValue(@"cancel", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Cancel", @"");
        NSString * settingTitle = NSLocalizedStringWithDefaultValue(@"settings", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Settings", @"");


        UIAlertController * uiAlertController = [UIAlertController
                                                 alertControllerWithTitle:alertTitle
                                                 message:alertMessage
                                                 preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* settingButton = [UIAlertAction
                                        actionWithTitle:settingTitle
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [ALUtilityClass openApplicationSettings];

                                        }];

        UIAlertAction* cancelButton = [UIAlertAction
                                       actionWithTitle:cancelTitle
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {

                                       }];
        [uiAlertController addAction:settingButton];
        [uiAlertController addAction:cancelButton];

        ALPushAssist* assistant = [[ALPushAssist alloc] init];

        [assistant.topViewController presentViewController:uiAlertController animated:YES completion:nil];
        return;
    }


    NSString * saveContactMessage = NSLocalizedStringWithDefaultValue(@"ContactSaveMessage", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Contact Saved Successfully", @"");
    NSString * contactTitle = NSLocalizedStringWithDefaultValue(@"contactsTitle", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Contact", @"");

    [ALUtilityClass showAlertMessage:saveContactMessage andTitle:contactTitle];
    
}

@end
