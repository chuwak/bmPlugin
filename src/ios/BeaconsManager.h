//
//  BeaconsManager.h
//  iBeaconTemplate
//
//  Created by 1 on 11.09.15.
//  Copyright © 2015 iBeaconModules.us. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDV.h>


#import "AppDelegate.h"
//#import "AppDelegate+CLLocationManager.h"



typedef CDVPluginResult* (^CDVPluginCommandHandler)(CDVInvokedUrlCommand*);

//const double CDV_LOCATION_MANAGER_DOM_DELEGATE_TIMEOUT = 30.0;
//const int CDV_LOCATION_MANAGER_INPUT_PARSE_ERROR = 100;

//static CLLocationManager *staticLocationManager;
static CLLocationManager *staticLM = nil;

extern NSArray *staticEBA ;

@interface BeaconsManager : CDVPlugin<CLLocationManagerDelegate>{
    //BeaconsManager *bManager;
}

@property (strong, nonatomic) CLLocationManager *locationManager;
@property CLProximity lastProximity;

@property(strong, nonatomic) NSArray *extBeaconsArray;


//@property(strong, nonatomic) NSArray *extBeaconsArray;


+ (CLLocationManager*)lm;
+ (void)setLM:(CLLocationManager*)newLM;


+ (NSArray*)extBeaconsArray;
+ (void)setExtBeaconsArray:(NSArray*)newEBA;



-(void)startScan:(CDVInvokedUrlCommand*)command;

-(void)stopScan:(CDVInvokedUrlCommand*)command;


-(void)startScanInner: (NSArray*)beaconsArr;

-(void)stopScanInner;



- (void)onDomDelegateReady:(CDVInvokedUrlCommand*)command;


@end
