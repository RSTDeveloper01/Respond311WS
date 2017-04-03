//
//  Open311.m
//  GeoReporter
//
//  Created by Cliff Ingham on 1/30/13.
//  Copyright (c) 2013 City of Bloomington. All rights reserved.
//
// Class for handling all Open311 network operations
//
// To make the user experience better, we request all the
// service metadata information at once.  Once everything is
// loaded, the UI should be snappy.
//
// You must call |loadAllMetadataForServer| before doing any other
// Open311 stuff in the app.

#import "Open311.h"
#import "Strings.h"
#import "Preferences.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "Media.h"
#import "CoreLocation/CoreLocation.h"



NSString * const kNotification_ServiceListReady = @"serviceListReady";
NSString * const kNotification_ServiceDefinitionReady = @"serviceDefinitionReady";
NSString * const kNotification_RefreshServiceRequestReady = @"refreshServiceRequestReady";
NSString * const kNotification_ServiceListReadyForAccount = @"serviceListReadyForAccount";

NSString * const kNotification_CurrentLocationUpdated = @"currentLocationUpdated";
NSString * const kNotification_AccountListReady = @"accountListReady";
NSString * const kNotification_PostSucceeded    = @"postSucceeded";
NSString * const kNotification_PostFailed       = @"postFailed";

@implementation Open311 {
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    AFHTTPClient *httpClient;
    NSDictionary *currentServer;
    NSArray *serviceList;
    NSArray *accountList;
    //NSDictionary *accountList;
    CLLocation *newLocation;
    CLLocation *oldLocation;
    bool *locationFirstTime;
}
SHARED_SINGLETON(Open311);

// Make sure to call this method before doing any other work
- (void)loadAllMetadataForServer:(NSDictionary *)server
{
    if (_groups             == nil) { _groups             = [[NSMutableArray      alloc] init]; } else { [_groups             removeAllObjects]; }
    if (_services             == nil) { _services             = [[NSMutableArray      alloc] init]; } else { [_services             removeAllObjects]; }
    if (_serviceDefinitions == nil) { _serviceDefinitions = [[NSMutableDictionary alloc] init]; } else { [_serviceDefinitions removeAllObjects]; }
    if (_accounts             == nil) { _accounts             = [[NSMutableArray      alloc] init]; } else { [_accounts             removeAllObjects]; }
    
    

    
    locationManager = [[CLLocationManager alloc]init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    geocoder = [[CLGeocoder alloc]init];
    
    currentServer = server;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *jurisdictionId = currentServer[kOpen311_Jurisdiction];
    NSString *apiKey         = currentServer[kOpen311_ApiKey];
    if (jurisdictionId != nil) { params[kOpen311_Jurisdiction] = jurisdictionId; }
    if (apiKey         != nil) { params[kOpen311_ApiKey]       = apiKey; }
    _endpointParameters = [NSDictionary dictionaryWithDictionary:params];
    httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[server objectForKey:kOpen311_Url]]];
    
    [self loadAccountList];
}

-(void) refreshLocation{
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        locationFirstTime=true;
    }
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    locationManager.distanceFilter = 50;
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
    
   
    
    
//    if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusNotDetermined || [CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorized)
//    {
//        locationFirstTime=true;
//        locationManager = [[CLLocationManager alloc] init];
//        locationManager.delegate = self;
//        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
//        locationManager.distanceFilter = 50;
//        
//        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
//            [locationManager requestWhenInUseAuthorization];
//        
//        [locationManager startUpdatingLocation];
//        
//    }
//    
//    else{
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
//    }
    
    
    
//    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
//    {
//        locationFirstTime=true;
//        [locationManager startUpdatingLocation];
//    }
//
//    else{
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
//    }

   
}

-(void) clearGpsCity{
    
    _gpsCity=@"";
    _gpsAdministrativeArea=@"";
    return;
}

-(void)refreshEndpointParams{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *jurisdictionId = currentServer[kOpen311_Jurisdiction];
    NSString *apiKey         = currentServer[kOpen311_ApiKey];
    if (jurisdictionId != nil) { params[kOpen311_Jurisdiction] = jurisdictionId; }
    if (apiKey         != nil) { params[kOpen311_ApiKey]       = apiKey; } //00000000-0000-0000-0000-000000000000
    
    _endpointParameters = [NSDictionary dictionaryWithDictionary:params];
}

- (void)loadFailedWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ServiceListReady object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_AccountListReady object:self];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kUI_FailureLoadingServices, nil)
                                                    message:NSLocalizedString(kUI_CommError,nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(kUI_Cancel, nil)
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - GET Service List
- (void)loadServiceList
{
    if (_groups             == nil) { _groups             = [[NSMutableArray      alloc] init]; } else { [_groups             removeAllObjects]; }
    
    if (_services             == nil) { _services             = [[NSMutableArray      alloc] init]; } else { [_services             removeAllObjects]; }
    [httpClient getPath:@"services.json"
             parameters:_endpointParameters
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSError *error;
                    serviceList = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
                    if (!error) {
                        [self loadServiceDefinitions];
                    }
                    else {
                        [self loadFailedWithError:error];
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self loadFailedWithError:error];
                }];
}

#pragma mark - GET Service List
- (void)loadServiceListForAccount
{
    
    if (_groups             == nil) { _groups             = [[NSMutableArray      alloc] init]; } else { [_groups             removeAllObjects]; }
    
    if (_services             == nil) { _services             = [[NSMutableArray      alloc] init]; } else { [_services             removeAllObjects]; }
    
    [httpClient getPath:@"services.json"
             parameters:_endpointParameters
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSError *error;
                    serviceList = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
                    if (!error) {
                        [self loadServiceDefinitions];
                    }
                    else {
                        [self loadFailedWithError:error];
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self loadFailedWithError:error];
                }];
}



#pragma mark - GET Account List
- (void)loadAccountList
{
    if (_accounts             == nil) { _accounts             = [[NSMutableArray      alloc] init]; } else { [_accounts             removeAllObjects]; }
  
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *apiKey         = currentServer[kOpen311_ApiKey];
    params[kOpen311_Jurisdiction] = @"municipiospr";
    
    [httpClient getPath:@"accounts.json"
             parameters:params
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSError *error;
                    accountList = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
                    if (!error) {
                        [self loadAccountDefinitions];
                    }
                    else {
                        [self loadFailedWithError:error];
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self loadFailedWithError:error];
                }];
}



// |serviceList| must already be loaded before calling this method.
//
// Loads unique |groups| from the |serviceList|
//
// Kicks off an HTTP Request for any and all |serviceDefinitions| that are needed.
// We do not wait around for them to finish.  Instead, we leave them in
// the background.  We can send the user on to the Group and Service choosing
// screens right away.  Hopefully, by the time the user has chosen a service
// to report, the HTTP request for that particular service will have finished.
// If not, the user will just not see any attributes that would have been defined
// in the service definition.

- (void)loadServiceDefinitions
{
    int count = [serviceList count];
    for (int i=0; i<count; i++) {
        NSDictionary *service = [serviceList objectAtIndex:i];
        
        // Add the current group if it's not already there
        NSString *group = [service objectForKey:kOpen311_Group];
        if (group == nil) { group = kUI_Uncategorized; }
        if (![_groups containsObject:group]) { [_groups addObject:group]; }
        
       // Fire off a service definition request, if needed
       /*
        __block NSString *serviceCode = [service objectForKey:kOpen311_ServiceCode];
        __block NSString *serviceId = [service objectForKey:krst_ServiceId];
        if ([[service objectForKey:kOpen311_Metadata] boolValue]) {
            [httpClient getPath:[NSString stringWithFormat:@"services/%@.json", serviceId]
                     parameters:_endpointParameters
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            NSError *error;
                            _serviceDefinitions[serviceCode] = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
                            if (error) {
                                [self loadFailedWithError:error];
                            }
                        }
                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            [self loadFailedWithError:error];
                        }
             ];
        }*/
    }
    
    NSSortDescriptor *aToZ= [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [_groups sortUsingDescriptors:[NSArray arrayWithObject:aToZ]];
    [_services addObjectsFromArray:serviceList];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ServiceListReady object:self];
}

- (void) loadServiceDefinitionsFailedWithError:(NSError *)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(kUI_FailureLoadingServices, nil)
                                                    message:NSLocalizedString(kUI_CommError,nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(kUI_Cancel, nil)
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)loadServiceDefinitions2:(NSDictionary *)service
{
    __block NSString *serviceCode = [service objectForKey:kOpen311_ServiceCode];
    __block NSString *serviceId = [service objectForKey:krst_ServiceId];
    if ([[service objectForKey:kOpen311_Metadata] boolValue]) {
        [httpClient getPath:[NSString stringWithFormat:@"services/%@.json", serviceId]
                 parameters:_endpointParameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSError *error;
                        _serviceDefinitions[serviceCode] = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
                        if (error) {
                            [self loadFailedWithError:error];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ServiceDefinitionReady object:self];
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ServiceDefinitionReady object:self];
                        [self loadFailedWithError:error];
                    }
         ];
    }
       
    
}



/*
- (void)loadServiceDefinitions
{
    int count = [serviceList count];
    if(count>0)
    {
        [_services addObjectsFromArray:serviceList];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ServiceListReady object:self];
}
*/

- (void)loadAccountDefinitions
{
    int count = [accountList count];
    if(count > 0)
    {
        [_accounts addObjectsFromArray:accountList];
        //[_accounts addObjectsFromArray:[accountList objectForKey:@"accounts"]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_AccountListReady object:self];
}


/**
 * Returns an array of service dictionaries from |serviceList|
 */
- (NSArray *)getServicesForGroup:(NSString *)group
{
    NSMutableArray *services = [[NSMutableArray alloc] init];
    for (NSDictionary *service in serviceList) {
        NSString *sg = service[kOpen311_Group];
        
        if (![group isEqualToString:kUI_Uncategorized]) {
            if ([sg isEqualToString:group]) {
                [services addObject:service];
            }
        }
        else if (sg==nil || [sg isEqualToString:@""]) {
            [services addObject:service];
        }
    }
    return [NSArray arrayWithArray:services];
}


- (void) getServicesForAccount:(NSDictionary *)account
{
    _selectedCity=[account objectForKey:@"account_name"];
    
    if(![[account objectForKey:kRst_AccountURL] isEqualToString:@""]){
        
        NSArray *parts=[[account objectForKey:kRst_AccountURL]componentsSeparatedByString:@"."];
        NSString *jurisdictionId = [[[parts objectAtIndex:0]componentsSeparatedByString:@"//"]objectAtIndex:1];
        NSDictionary* server= [[NSDictionary alloc]initWithObjectsAndKeys:
                           [NSNumber numberWithBool:TRUE],kOpen311_SupportsMedia,
                           @"json",kOpen311_Format,
                          @"http://respond311api.respondcrm.com/dev/V2.0/Open311API.svc/",kOpen311_Url,
                          //@"http://192.168.3.17/RESPOND-Open311API/Open311API.svc/",kOpen311_Url,
                           @"00000000-0000-0000-0000-000000000000",kOpen311_ApiKey,
                           [account objectForKey:kRst_AccountName],kOpen311_Name,
                           jurisdictionId,kOpen311_Jurisdiction,nil];
        [[Preferences sharedInstance] setCurrentServer:server];
        currentServer=server;
        [self refreshEndpointParams];
        httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[server objectForKey:kOpen311_Url]]];
    }
    
    else{
        NSDictionary* server= [[NSDictionary alloc]initWithObjectsAndKeys:
                               [NSNumber numberWithBool:TRUE],kOpen311_SupportsMedia,
                               @"json",kOpen311_Format,
                               @"http://respond311api.respondcrm.com/dev/V2.0/Open311API.svc/",kOpen311_Url,
                               //@"http://192.168.3.17/RESPOND-Open311API/Open311API.svc/",kOpen311_Url,
                               @"00000000-0000-0000-0000-000000000000",kOpen311_ApiKey,
                               [account objectForKey:kRst_AccountName],kOpen311_Name,
                               @"municipiospr",kOpen311_Jurisdiction,nil];
        [[Preferences sharedInstance] setCurrentServer:server];
        currentServer=server;
        [self refreshEndpointParams];
        httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:[server objectForKey:kOpen311_Url]]];
    }
    
    
    [self loadServiceListForAccount];
    
}


#pragma mark - POST Service Request
/**
 * Displays an alert to the user and sets notification to any observers
 *
 * If the server supports known Open311 error formatting, we can display
 * the error message reported by the Open311 server.  Otherwise, we can
 * only display a generic message.
 */
- (void)postFailedWithError:(NSError *)error forOperation:(AFHTTPRequestOperation *)operation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_PostFailed object:self];
    NSString *title = NSLocalizedString(kUI_FailurePostingService, nil);
    NSString *message = [error localizedDescription];

    if (operation) {
        NSError *e;
        NSArray *serviceRequests = [NSJSONSerialization JSONObjectWithData:[operation responseData] options:nil error:&e];
        NSInteger statusCode = [[operation response] statusCode];
        if (!e) {
            NSDictionary *sr = serviceRequests[0];
            if (sr[kOpen311_Description]) {
                message = sr[kOpen311_Description];
            }
        }
        
        if (statusCode == 403) {
            title = NSLocalizedString(kUI_Error403, nil);
        }
        if (statusCode == 463) {
            message = NSLocalizedString(kUI_Error463, nil);
        }
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(kUI_Cancel, nil)
                                          otherButtonTitles:nil];
    [alert show];
}

/**
 * Creates a POST request
 *
 * The POST will be either a regular POST or multipart/form-data,
 * depending on whether the service request has media or not.
 */
- (NSMutableURLRequest *)preparePostForReport:(Report *)report withMedia:(UIImage *)media
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:_endpointParameters];
    [report.postData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (!parameters[key]) {
            parameters[key] = obj;
        }
    }];
    
    NSMutableURLRequest *post;
    if (media) {
        [parameters removeObjectForKey:kOpen311_Media];
        post = [httpClient multipartFormRequestWithMethod:@"POST"
                                                     path:@"requests.json"
                                               parameters:parameters
                                constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                    [formData appendPartWithFileData:UIImagePNGRepresentation(media)
                                                                name:kOpen311_Media
                                                            fileName:@"media.png"
                                                            mimeType:@"image/png"];
                                }];
    }
    else {
        post = [httpClient requestWithMethod:@"POST" path:@"requests.json" parameters:parameters];
    }
    return post;
}

/**
 * Kicks off the report posting process
 *
 * Loading media from the asset library is an async call.
 * So we have to set a callback for when the image data is loaded.
 * This starts the process and sets the image-loaded callback
 * to [self postServiceRequest]
 *
 * If there's no media involved, we just call that method right away
 */
- (void)startPostingServiceRequest:(Report *)report
{
    NSURL *mediaUrl = report.postData[kOpen311_Media];
    if (mediaUrl) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:mediaUrl
                 resultBlock:^(ALAsset *asset) {
                     ALAssetRepresentation *rep = [asset defaultRepresentation];
                     UIImage *original = [UIImage imageWithCGImage:[rep fullScreenImage]];
                     UIImage *media = [Media resizeImage:original toBoundingBox:800];
                     
                     NSMutableURLRequest *post = [self preparePostForReport:report withMedia:media];
                     [self postReport:report withPost:post];
                 }
                failureBlock:^(NSError *error) {
                    [self postFailedWithError:error forOperation:nil];
                }];
    }
    else {
        NSMutableURLRequest *post = [self preparePostForReport:report withMedia:nil];
        [self postReport:report withPost:post];
    }
}

/**
 * Sends the report to the Open311 server
 *
 * This is an Async network call.
 * The Open311 object will send out notifications when the call is finished.
 * PostSucceeded or PostFailed
 */
- (void)postReport:(Report *)report withPost:(NSMutableURLRequest *)post
{
    AFHTTPRequestOperation *operation = [httpClient HTTPRequestOperationWithRequest:post
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSNotificationCenter *notifications = [NSNotificationCenter defaultCenter];
            
            NSError *error;
            NSArray *serviceRequests = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:&error];
            if (!error) {
                NSMutableDictionary *sr = [NSMutableDictionary dictionaryWithDictionary:serviceRequests[0]];
                if (sr[kOpen311_ServiceRequestId] || sr[kOpen311_Token]) {
                    report.requestedDate  = [NSDate date];
                    report.server         = currentServer;
                    report.serviceRequest = sr;
                    [[Preferences sharedInstance] saveReport:report forIndex:-1];
                    [notifications postNotificationName:kNotification_PostSucceeded object:self];
                }
                else {
                    // We got a 200 response back in the correct format
                    // However, it did not include a token or a service_request_id
                    [notifications postNotificationName:kNotification_PostFailed object:self];
                }
            }
            else {
                // We got a 200 response, but it was not valid JSON
                [notifications postNotificationName:kNotification_PostFailed object:self];
            }
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self postFailedWithError:error forOperation:operation];
        }];
    [operation start];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [locationManager stopUpdatingLocation];
    
    
    if(![CLLocationManager locationServicesEnabled] ||
       [CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied ||
       [CLLocationManager authorizationStatus]==kCLAuthorizationStatusRestricted)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc]
         initWithTitle:NSLocalizedString(kUI_EnableLocationServicesTitle,nil) message:NSLocalizedString(kUI_EnableLocationServices,nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    
    if(locationFirstTime==true){
        locationFirstTime=false;
        return;
    }

    
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString *szMessage= @"";
        
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            
            if(placemark.locality!= NULL)
            {
                NSLog(@"Locality:%@",placemark.locality);
                _gpsCity = placemark.locality;
                szMessage = [szMessage stringByAppendingString:[NSString stringWithFormat:@"%@", placemark.locality]];
            }
            
            if(placemark.administrativeArea != NULL){
                NSLog(@"Administrative Area:%@",placemark.administrativeArea);
                _gpsAdministrativeArea=placemark.administrativeArea;
                szMessage = [szMessage stringByAppendingString:[NSString stringWithFormat:@", %@ ", placemark.administrativeArea]];
            }
            
        } else {
            NSLog(@"%@", error.debugDescription);
        }
        [locationManager stopUpdatingLocation];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
    } ];
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

- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations{
    
   /* if(newLocation!=nil){
        
        NSDate *eventDate = newLocation.timestamp;
        NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
        if(abs(howRecent) < 10.0)
        {
         //  [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
            return;
        }
    }
    */
    if(locationFirstTime==true){
        locationFirstTime=false;
        return;
    }
    
    newLocation = [locations lastObject];
    
    //newLocation = [locations lastObject];
    //*oldLocation;
   
    if(locations.count>1){
        oldLocation = [locations objectAtIndex:locations.count-2];
    }else{
        oldLocation = nil;
    }
    NSLog(@"didUpdateLocation %@ from %@",newLocation,oldLocation);
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString *szMessage= @"";
        
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
           
            if(placemark.locality!= NULL)
            {
                NSLog(@"Locality:%@",placemark.locality);
                _gpsCity = placemark.locality;
                szMessage = [szMessage stringByAppendingString:[NSString stringWithFormat:@"%@", placemark.locality]];
            }
            if(placemark.administrativeArea != NULL){
                NSLog(@"Administrative Area:%@",placemark.administrativeArea);
                _gpsAdministrativeArea=placemark.administrativeArea;
                szMessage = [szMessage stringByAppendingString:[NSString stringWithFormat:@", %@ ", placemark.administrativeArea]];
            }
            
        } else {
            NSLog(@"%@", error.debugDescription);
        }

        [locationManager stopUpdatingLocation];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CurrentLocationUpdated object:self];
    } ];
}
@end
