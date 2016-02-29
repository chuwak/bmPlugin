

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDV.h>

#import "AppDelegate.h"


typedef CDVPluginResult* (^CDVPluginCommandHandler)(CDVInvokedUrlCommand*);



@interface BeaconsManagerPlugin : CDVPlugin<CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate>{
}

@property (retain, nonatomic) NSMutableArray *queueArr;

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CBCentralManager* centralManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
//@property CLProximity lastProximity;

@property(nonatomic) Boolean deviceReady;


@property (strong, nonatomic) NSString *monitoringCallbackId;
@property (strong, nonatomic) NSString *rangingCallbackId;

@property(retain, nonatomic) NSArray *extBeaconsArray;

//=======================   add functional like android   ===================

-(void)startService:(CDVInvokedUrlCommand*)command;
-(void)stopService:(CDVInvokedUrlCommand*)command;

-(void)startMonitoring:(CDVInvokedUrlCommand*)command;
-(void)stopMonitoring:(CDVInvokedUrlCommand*)command;

-(void)startRanging:(CDVInvokedUrlCommand*)command;
-(void)stopRanging:(CDVInvokedUrlCommand*)command;

-(void)onDeviceReady:(CDVInvokedUrlCommand*)command;
-(void)setMonitoringFunction:(CDVInvokedUrlCommand*)command;

-(void)applyParameters:(CDVInvokedUrlCommand*)command;


-(void)isBluetoothEnabled: (CDVInvokedUrlCommand*)command;
-(void)enableBluetooth:(CDVInvokedUrlCommand*)command;


@end

