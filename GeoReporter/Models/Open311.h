//
//  Open311.h
//  GeoReporter
//
//  Created by Cliff Ingham on 1/30/13.
//  Copyright (c) 2013 City of Bloomington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Report.h"
#import "CoreLocation/CoreLocation.h"

extern NSString * const kNotification_ServiceListReady;
extern NSString * const kNotification_ServiceDefinitionReady;
extern NSString * const kNotification_RefreshServiceRequestReady;
extern NSString * const kNotification_AccountListReady;
extern NSString * const kNotification_ServiceListReadyForAccount;
extern NSString * const kNotification_PostSucceeded;
extern NSString * const kNotification_PostFailed;

@interface Open311 : NSObject <CLLocationManagerDelegate>
@property (readonly) NSDictionary *endpointParameters;
@property (readonly) NSMutableArray *groups;
@property (readonly) NSMutableArray *accounts;
@property (readonly) NSMutableArray *services;
@property (readonly) NSMutableDictionary *accountsDefinitions;
@property (readonly) NSMutableDictionary *serviceDefinitions;
@property (readonly) NSString  *gpsCity;
@property (readonly) NSString  *gpsAdministrativeArea;
@property (readonly) NSString  *selectedCity;
@property (nonatomic,strong) NSMutableDictionary *currentAccount;

+ (id)sharedInstance;

- (void)loadAllMetadataForServer:(NSDictionary *)server;
- (void)loadFailedWithError:(NSError *)error;

- (void)loadServiceList;
- (void)loadServiceListForAccount;
- (void)loadServiceDefinitions;
- (void)loadServiceDefinitions2:(NSDictionary *)service;
- (void)loadAccountList;
- (void) clearGpsCity;  
- (void)loadAccountDefinitions;
- (NSArray *)getServicesForGroup:(NSString *)group;
- (void) getServicesForAccount:(NSDictionary *)account;

- (void)startPostingServiceRequest:(Report *)report;
- (NSMutableURLRequest *)preparePostForReport:(Report *)report withMedia:(UIImage *)media;
- (void)postReport:(Report *)report withPost:(NSMutableURLRequest *)post;
- (void)postFailedWithError:(NSError *)error forOperation:(AFHTTPRequestOperation *)operation;
- (void)refreshLocation;

@end
