//
//  ALMapViewController.m
//  ChatApp
//
//  Created by Devashish on 13/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALMapViewController.h"
#import "ALUserDefaultsHandler.h"
#import "ALApplozicSettings.h"
#import "ALDataNetworkConnection.h"
#import "TSMessage.h"
#import "UIImageView+WebCache.h"
#import "ALMessage.h"
#import "ALUtilityClass.h"

@interface ALMapViewController ()


- (IBAction)sendLocation:(id)sender;

@property (nonatomic, strong) CLGeocoder * geocoder;
@property (nonatomic, strong) CLPlacemark * placemark;
@property (nonatomic, strong) NSString * addressLabel;
@property (nonatomic, strong) NSString * longX;
@property (nonatomic, strong) NSString * lattY;
@end

@implementation ALMapViewController

@synthesize locationManager, region;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    
    //[self.locationManager requestAlwaysAuthorization];
    [self.locationManager requestWhenInUseAuthorization];
    
    if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    
    [self.mapKitView setShowsUserLocation:YES];
    [self.mapKitView setDelegate:self];
    self.geocoder = [[CLGeocoder alloc] init];
    
    [self setTitle:NSLocalizedStringWithDefaultValue(@"sendLocationViewTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Send Location", @"")] ;
    
    [_sendLocationButton setTitle:NSLocalizedStringWithDefaultValue(@"sendLocationButtonText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Send Location", @"") forState:UIControlStateNormal]; // To set the title
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.tabBarController.tabBar setHidden: YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.tabBarController.tabBar setHidden: YES];
    [self.navigationController.navigationBar setBarTintColor: [ALApplozicSettings getColorForNavigation]];
    [self.navigationController.navigationBar setTintColor:[ALApplozicSettings getColorForNavigationItem]];
    [self.navigationController.navigationBar setBackgroundColor: [ALApplozicSettings getColorForNavigation]];
    
    if (![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [TSMessage showNotificationInViewController:self title:@"" subtitle:        NSLocalizedStringWithDefaultValue(@"noInternetMessage", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"No Internet", @"")
                                               type:TSMessageNotificationTypeError duration:1.0 canBeDismissedByUser:NO];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- Send Location Button Action
//======================================
- (IBAction)sendLocation:(id)sender {
    
    _sendLocationButton.enabled=YES;
    region = self.mapKitView.region;
    
    NSString * lat = [NSString stringWithFormat:@"%.8f",region.center.latitude];
    NSString * lon = [NSString stringWithFormat:@"%.8f",region.center.longitude];
    NSDictionary * latLongDic = [[NSDictionary alloc] initWithObjectsAndKeys:lat,@"lat",lon,@"lon", nil];
    
    NSString *jsonString = [self createJson:latLongDic];
    
    [self.sendLocationButton setEnabled:NO];
    
    if([ALDataNetworkConnection checkDataNetworkAvailable]){
        [self.controllerDelegate sendGoogleMap:jsonString withCompletion:^(NSString *message, NSError *error) {
            
            if(!error)
            {
                [self.navigationController popViewControllerAnimated:YES];
                [self.sendLocationButton setEnabled:YES];
            }
        }];
    }
    else
    {
        [self.controllerDelegate sendGoogleMapOffline:jsonString];
        [self.navigationController popViewControllerAnimated:YES];
        [self.sendLocationButton setEnabled:YES];
    }
    
}

-(NSString *)createJson:(NSDictionary *)latLongDic{
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:latLongDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (! jsonData) {
        ALSLog(ALLoggerSeverityError, @"Got an error: %@", error);
        return nil;
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
}

- (void)requestAlwaysAuthorization
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied)
    {
        NSString *title;
        title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
        NSString *message = @"To use background location you must turn on 'Always' in the Location Services Settings";

        UIAlertController * uiAlertController = [UIAlertController
                                                 alertControllerWithTitle:title
                                                 message:message
                                                 preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* settingButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedStringWithDefaultValue(@"settings", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Settings", @"")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                       [[UIApplication sharedApplication] openURL:settingsURL];
                                   }];

        UIAlertAction* cancelButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedStringWithDefaultValue(@"cancelOptionText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Cancel", @"")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {

                                   }];
        [uiAlertController addAction:settingButton];
        [uiAlertController addAction:cancelButton];

        [self.presentedViewController.navigationController presentViewController:uiAlertController animated:YES completion:nil];
    }
    else if (status == kCLAuthorizationStatusNotDetermined) {
        // The user has not enabled any location services. Request background authorization.
        [locationManager requestAlwaysAuthorization];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *newLocation = [locations lastObject];
    
    self.lattY = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    self.longX = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
    
    [self.geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (error == nil && [placemarks count] > 0)
        {
            self.placemark = [placemarks lastObject];
            self.addressLabel = [NSString stringWithFormat:@"Address: %@\n%@ %@, %@, %@\n",
                                 self.placemark.thoroughfare,
                                 self.placemark.postalCode, self.placemark.locality,
                                 self.placemark.administrativeArea,
                                 self.placemark.country];
            
        }
        else
        {
            ALSLog(ALLoggerSeverityInfo, @"inside GEOCODER");
        }
        
    }];
    
}

#pragma mark - MKMapViewDelegate Methods

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    [self.mapKitView setRegion:MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.002f, 0.002f)) animated:YES];
    
}

//~ Currently inactive ~//
-(void)formMapURL{
    
    //static map location
    NSString * staticMapLocationURL=[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/staticmap?center=%.8f,%.8f&zoom=17&size=290x179&maptype=roadmap&format=png&visual_refresh=true&markers=%.8f,%.8f&key=%@",region.center.latitude, region.center.longitude,region.center.latitude, region.center.longitude,[ALUserDefaultsHandler getGoogleMapAPIKey]];
    
    if([ALDataNetworkConnection checkDataNetworkAvailable])
    {
        NSURL* staticImageURL=[NSURL URLWithString:staticMapLocationURL];
        [self.mapView sd_setImageWithURL:staticImageURL];
    }
    else{
        UIImage * offlineMapImage = [ALUtilityClass getImageFromFramworkBundle:@"ic_map_no_data.png"];
        [self.mapView setImage:offlineMapImage];
        
    }
}

@end
