//
//  ALLocationManager.m
//  ChatApp
//
//  Created by Adarsh on 03/10/15.
//  Copyright © 2015 Applozic. All rights reserved.
//

#import "ALLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@implementation ALLocationManager


-(instancetype) initWithDistanceFilter:(int) distance{

    _locationManager = [[CLLocationManager alloc]init];
    _locationManager.delegate =self ;
    _locationManager.distanceFilter = 20.0;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    return self;
}


-(void)getAddress {
    
    [self setup];
    ALSLog(ALLoggerSeverityInfo, @"get Address...");

}

-(void) setup
{
    [_locationManager requestWhenInUseAuthorization];
    [_locationManager startUpdatingLocation];
    //[_locationManager requestLocation];
    ALSLog(ALLoggerSeverityInfo, @"get Address...####");


}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    ALSLog(ALLoggerSeverityError, @"didFailWithError: %@", error);
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
    ALSLog(ALLoggerSeverityInfo, @"didUpdateLocations called:");
    CLLocation *newLocation = locations[[locations count] -1];
    CLLocation *currentLocation = newLocation;
    [ self handleLocationUpdate: currentLocation];
    
    
}

-(void) handleLocationUpdate:(CLLocation * )currentLocation {
    
    if (currentLocation != nil) {
        [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        
        _googleURL=[NSString stringWithFormat:@"https://www.google.com/maps?q=%f,%f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude ];
        
    }
    
    // Reverse Geocoding
    ALSLog(ALLoggerSeverityInfo, @"Resolving the Address");
    _geocoder = [[CLGeocoder alloc]init];
    
    [self.geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSMutableDictionary * dict =  [[NSMutableDictionary alloc]init];
        if(error){
            ALSLog(ALLoggerSeverityError, @"%@", [error localizedDescription]);
            [dict setObject:error.debugDescription forKey:@"error"];
            
        }
        
        CLPlacemark *placemark = [placemarks lastObject];
        
      self->_addressString = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                              placemark.subThoroughfare, placemark.thoroughfare,
                              placemark.postalCode, placemark.locality,
                              placemark.administrativeArea,
                              placemark.country];
        
        [dict setObject:self->_addressString forKey:@"address"];
        [dict setObject:self->_googleURL forKey:@"googleurl"];

        [self.locationDelegate  handleAddress:dict ];
        
    }];
    
}



@end
