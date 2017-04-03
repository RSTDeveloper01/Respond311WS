/**
 * @copyright 2013 Rock Solid Technologies,Inc. All Rights Reserved
 * @author Cliff Ingham <inghamn@bloomington.in.gov>
 * @editor Samuel Rivera <srivera@rocksolid.com>
 * @license http://www.gnu.org/licenses/gpl.txt GNU/GPLv3, see LICENSE.txt
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

#import "LocationController.h"
#import "ReportController.h"
#import "Strings.h"
#import "Open311.h"

@interface LocationController ()

@end

static NSInteger const kMapTypeStandardIndex  = 0;
static NSInteger const kMapTypeSatelliteIndex = 1;
static CLLocationDegrees const kLatitudeDelta = 0.0080;
static CLLocationDegrees const kLongitudeDelta = 0.0080;

@implementation LocationController {
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    UIActivityIndicatorView *busyIcon;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Open311 *open311= [Open311 sharedInstance];
    ReportController *rc= (ReportController *) self.delegate;
    NSString *lat= [rc.report.postData objectForKey:kOpen311_Latitude];
    NSString *longitude= [rc.report.postData objectForKey:kOpen311_Longitude];
    
    locationManager = [[CLLocationManager alloc] init];
//    locationManager.delegate = self;
//    locationManager.distanceFilter = kCLDistanceFilterNone;
//    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
//        [locationManager requestWhenInUseAuthorization];
//    
//    [locationManager startUpdatingLocation];

    if(!(lat==nil || [lat isEqualToString:@""]) && !(longitude==nil || [longitude isEqualToString:@""]))
    {
        MKCoordinateRegion region;
        region.center.latitude  = [lat doubleValue];
        region.center.longitude = [longitude doubleValue];
        MKCoordinateSpan span;
        span.latitudeDelta  = kLatitudeDelta;
        span.longitudeDelta = kLongitudeDelta;
        region.span = span;
        [self.map setRegion:region animated:YES];
        
    }
    else{
        locationManager.delegate = self;
        locationManager.distanceFilter = 50;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
            [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];
    }
   /* else if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined || [CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorized)
    {
        //locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter = 50;
        
        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
            [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];
        
    }
    else if([open311.gpsCity isEqualToString:open311.selectedCity]){
        [self startBusyIcon];
        //locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter = 50;
        [locationManager startUpdatingLocation];
    }
    else{
        [self startBusyIcon];
        [self goToSelectedCity];
    }
    */
    
    /*if([[[UIDevice currentDevice]systemVersion]isEqualToString:@"7.0"])
    {
            UIAlertView *alertView= [[UIAlertView alloc]initWithTitle:@"RUNNING IOS 7" message:@"OH NO, WHERE IS THE BAR" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:nil];
        
            [alertView show];
    }*/
    
    MKUserTrackingBarButtonItem *button = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.map];
    [self.navigationController.toolbar setItems:@[button]];
    
    [self.segmentedControl setTitle:NSLocalizedString(kUI_Standard,  nil) forSegmentAtIndex:kMapTypeStandardIndex];
    [self.segmentedControl setTitle:NSLocalizedString(kUI_Satellite, nil) forSegmentAtIndex:kMapTypeSatelliteIndex];
}


- (void)startBusyIcon
{
    /*busyIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
     busyIcon.center = self.view.center;
     [busyIcon setFrame:self.view.frame];
     [busyIcon setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
     [busyIcon startAnimating];
     [self.view addSubview:busyIcon];*/
    
    busyIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    busyIcon.center = self.tabBarController.view.center;
    [busyIcon setFrame:self.tabBarController.view.frame];
    [busyIcon setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [busyIcon startAnimating];
    [self.tabBarController.view addSubview:busyIcon];
}


- (void)zoomToLocation:(CLLocation *)location
{
    [busyIcon stopAnimating];
    [busyIcon removeFromSuperview];
    MKCoordinateRegion region;
    region.center.latitude  = location.coordinate.latitude;
    region.center.longitude = location.coordinate.longitude;
    MKCoordinateSpan span;
    span.latitudeDelta  = kLatitudeDelta;
    span.longitudeDelta = kLongitudeDelta;
    region.span = span;
    [self.map setRegion:region animated:YES];
}
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"User still thinking..");
        } break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"User denied authorization");
        } break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            [locationManager startUpdatingLocation]; //Will update location immediately
        } break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [locationManager stopUpdatingLocation];
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *location = newLocation;
    [self zoomToLocation:location];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
    [locationManager stopUpdatingLocation];
    CLLocation* location = [locations lastObject];
    NSLog(@"lat%f - lon%f", location.coordinate.latitude, location.coordinate.longitude);
    [self zoomToLocation:location];

}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
     NSLog(@"didFailWithError: %@", error);
    [self goToSelectedCity];
}

- (void)goToSelectedCity{
    geocoder = [[CLGeocoder alloc] init];
    
    Open311 *open311= [Open311 sharedInstance];
    [geocoder geocodeAddressString:[NSString
                                    stringWithFormat:@"%@, Puerto Rico",open311.selectedCity]
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     CLPlacemark *placemark = [placemarks objectAtIndex:0];
                     //          MKPlacemark *mapPlacemark= [[MKPlacemark alloc] initWithPlacemark:placemark];
                     MKCoordinateRegion region;
                     region.center.latitude= placemark.region.center.latitude;
                     region.center.longitude= placemark.region.center.longitude;
                     MKCoordinateSpan span;
                     span.latitudeDelta  = kLatitudeDelta;
                     span.longitudeDelta = kLatitudeDelta;
                     region.span = span;
                     [busyIcon stopAnimating];
                     [busyIcon removeFromSuperview];
                     //            [self.map addAnnotation:mapPlacemark];
                     [self.map setRegion:region animated:YES];
                 }];
}

- (IBAction)done:(id)sender
{
    [self.delegate didChooseLocation:[self.map centerCoordinate]];
}

- (IBAction)centerOnLocation:(id)sender
{
    
    if ([CLLocationManager locationServicesEnabled]){
        
        NSLog(@"Location Services Enabled");
        
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied){
            
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(kUI_EnableLocationServicesTitle, nil)
                                                            message: NSLocalizedString(kUI_EnableLocationServices, nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    
    
    
    
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];

    
    if(locationManager.location !=nil){
        [self zoomToLocation:locationManager.location];
    }
    //else{
     //   [self goToSelectedCity];
    //}
//    if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined || [CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorized){
//        [self startBusyIcon];
//        locationManager = [[CLLocationManager alloc] init];
//        locationManager.delegate = self;
//        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
//        locationManager.distanceFilter = 50;
//        [locationManager startUpdatingLocation];
//        return;
//    }
//    
//    ReportController *rc= (ReportController *) self.delegate;
//    NSString *lat= [rc.report.postData objectForKey:kOpen311_Latitude];
//    NSString *longitude= [rc.report.postData objectForKey:kOpen311_Longitude];
//    
//    if (!(lat==nil || [lat isEqualToString:@""]) && !(longitude==nil || [longitude isEqualToString:@""]))
//    {
//        MKCoordinateRegion region;
//        region.center.latitude  = [lat doubleValue];
//        region.center.longitude = [longitude doubleValue];
//        MKCoordinateSpan span;
//        span.latitudeDelta  = kLatitudeDelta;
//        span.longitudeDelta = kLongitudeDelta;
//        region.span = span;
//        [self.map setRegion:region animated:YES];
//    }
//    
//    else{
//        [self startBusyIcon];
//        [self goToSelectedCity];
//    }
}

- (IBAction)mapTypeChanged:(id)sender
{
    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
        case kMapTypeStandardIndex:
            [self.map setMapType:MKMapTypeStandard];
            break;
            
        case kMapTypeSatelliteIndex:
            [self.map setMapType:MKMapTypeSatellite];
            break;
    }
}
- (void)viewDidUnload {
    [self setSegmentedControl:nil];
    [super viewDidUnload];
}
@end
