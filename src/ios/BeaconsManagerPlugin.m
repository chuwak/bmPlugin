

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "BeaconsManagerPlugin.h"
#import "ExtBeacon.h"
#import "AppDelegate+CLLocationManager.h"

@implementation BeaconsManagerPlugin



@synthesize queueArr;

@synthesize deviceReady;
@synthesize isPaused;

@synthesize locationManager;
@synthesize centralManager;
@synthesize peripheralManager;

@synthesize monitoringCallbackId;
@synthesize rangingCallbackId;


@synthesize extBeaconsArray;

NSMutableArray* frameArr;
double framePreviousTime = 0;



- (void)pluginInitialize
{
    NSLog(@"=== BeaconsManager pluginInitialize");
    self.isPaused = false;
    
    [self initLocationManager];
    
    BeaconsManagerPlugin *bManager = [[BeaconsManagerPlugin alloc]init];
    bManager.locationManager = self.locationManager;
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    appDelegate.beaconsManagerPluginInstanceAO = bManager;
    

    
    [self addObserver:NSSelectorFromString(@"didReceiveLocalNotification:")
                 name:CDVLocalNotification
               object:NULL];

    [self initEventQueue];
    
    
    frameArr = [[NSMutableArray alloc]init];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [self.centralManager scanForPeripheralsWithServices:nil options:options];
}


- (void) initLocationManager{
    CLLocationManager *selfLocationManager = [[CLLocationManager alloc] init];
    self.locationManager = selfLocationManager;
    if([selfLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [selfLocationManager requestAlwaysAuthorization];
    }
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge categories:nil]];
    }
    
    selfLocationManager.pausesLocationUpdatesAutomatically = NO;
    selfLocationManager.delegate = self;

}


- (void) initEventQueue
{
    self.queueArr = [[NSMutableArray alloc] init];
    [BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].queueArr = self.queueArr;
}

-(void) tryToSendResult
{
    int size = [self.queueArr count];
    if(size>0  &&  self.deviceReady  && self.monitoringCallbackId!=nil){
        for(int i=0; i<size; i++){
        
            NSDictionary *dict = [self.queueArr objectAtIndex:0];
            [self.queueArr removeObjectAtIndex:0];
            
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
            [pluginResult setKeepCallbackAsBool:YES];
            
            if(self.commandDelegate != nil){
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.monitoringCallbackId];
            }
        }
    }
    
}

-(void)addToQueue: (NSDictionary*) dict
{
    [self.queueArr addObject:dict];
    [self tryToSendResult];
}





- (void) addObserver:(SEL)selector  name:(NSString*)event  object:(id)object
{
    if (![self respondsToSelector:selector]){
        return;
    }
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:selector
                   name:event
                 object:object];
}








//=========================  init callbacks  ========================


-(void)onDeviceReady:(CDVInvokedUrlCommand *)command{
    
    self.deviceReady = true;
    [BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].deviceReady = true;
    
    [self tryToSendResult];
}

-(void)setMonitoringFunction:(CDVInvokedUrlCommand *)command{
    
    //[self _handleCallSafely:^CDVPluginResult *(CDVInvokedUrlCommand* command) {
    
    
    self.monitoringCallbackId = command.callbackId;
    //[BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].monitoringCallbackId = command.callbackId;
    
    
    //[BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].commandDelegate = self.commandDelegate;
    
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    //return result;
    //} :command];
    
    [self tryToSendResult];
}





//==========================================================================
//=======================   Start-stop service  ============================
//==========================================================================


-(void)startService:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[@"Service was started. " stringByAppendingString:[self warningOfBluetooth] ] ];
    @try {
        [self startServiceInner];
    }
    @catch (NSException *exception) {
        NSString *errMsg = [NSString stringWithFormat:@"Error:: %@  by Reason :: %@", exception.name, exception.reason ];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    }
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


-(void)startServiceInner {
    
    //AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    if(self.locationManager == nil){
        [self initLocationManager];
    }
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"Authorized Always");
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            NSLog(@"Authorized when in use");
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"Denied");
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"Not determined");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"Restricted");
            break;
            
        default:
            break;
    }
    
    //[CLLocationManager regionMonitoringAvailable];
    //[CLLocationManager regionMonitoringEnabled];

    [self.locationManager startUpdatingLocation];  // variant local
    
    
    //[locManInstance startUpdatingLocation];
}



-(void) stopService:(CDVInvokedUrlCommand *)command
{
    [self.locationManager stopUpdatingLocation];
    //[[BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].locationManager stopUpdatingLocation];
    self.locationManager = nil;
    [BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].locationManager = nil;
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Service was stopped"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



//==========================================================================
//=======================   Start-stop Monitoring  =========================
//==========================================================================


-(void)startMonitoring:(CDVInvokedUrlCommand *)command{
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[@"Monitoring started" stringByAppendingString:[self warningOfBluetooth] ] ];
    @try {
        NSArray* inputBeaconsArr = [command.arguments objectAtIndex:0];
        [self startMonitoringInner:inputBeaconsArr];
    }
    @catch (NSException *exception) {
        NSString *errMsg = [NSString stringWithFormat:@"Error:: %@  by Reason :: %@", exception.name, exception.reason ];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    }
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


-(void)startMonitoringInner:(NSArray*)beaconsArr{
    if(self.locationManager == nil){
        [self initLocationManager];
    }
    
    NSMutableArray *incomingArr = [NSMutableArray array];
    
    for (int i=0; i<[beaconsArr count]; i++) {
        NSDictionary *beaconDict = [beaconsArr objectAtIndex:i];
        
        ExtBeacon *currBeacon =  [ExtBeacon fillBeaconFromDictionary :beaconDict ];
        NSString *uuid = currBeacon.uuid;
        
        // Override point for customization after application launch.
        NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString: uuid];
        CLBeaconMajorValue major = [currBeacon.major isEqual: [NSNull null]] ? 0 : [currBeacon.major integerValue];
        CLBeaconMajorValue minor = [currBeacon.minor isEqual: [NSNull null]] ? 0 : [currBeacon.minor integerValue];
        
        NSString *idStr = [[NSNumber numberWithInt: currBeacon.id] stringValue];
        NSString *regionIdentifier = [@"region_" stringByAppendingString : idStr ];
        
        CLBeaconRegion *beaconRegion;
        
        if(major!=0  && minor!=0){
            beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID major:major minor:minor identifier:regionIdentifier];
        }else{
            beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID identifier:regionIdentifier];
        }
        
        
        beaconRegion.notifyEntryStateOnDisplay = YES;
        
        currBeacon.region = beaconRegion;
        
        
        [self.locationManager startMonitoringForRegion:beaconRegion];
        //[self.locationManager startRangingBeaconsInRegion:beaconRegion];
        
        
        [incomingArr addObject: currBeacon];
        
        
    }
    
    self.extBeaconsArray = incomingArr;
    [BeaconsManagerPlugin getBeaconsManagerPluginFromAppDelegate].extBeaconsArray = incomingArr;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:incomingArr];
    [[NSUserDefaults standardUserDefaults] setObject : data forKey:@"incomingArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    [self.locationManager startUpdatingLocation];
    

}

-(CLBeaconRegion*) createNativeBeaconRegionFromIncomingRegion: (NSDictionary*)beaconDict
{
    ExtBeacon *currBeacon =  [ExtBeacon fillBeaconFromDictionary :beaconDict ];
    NSString *uuid = currBeacon.uuid;
    
    // Override point for customization after application launch.
    NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString: uuid];
    CLBeaconMajorValue major = [currBeacon.major isEqual: [NSNull null]] ? 0 : [currBeacon.major integerValue];
    CLBeaconMajorValue minor = [currBeacon.minor isEqual: [NSNull null]] ? 0 : [currBeacon.minor integerValue];
    
    NSString *idStr = [[NSNumber numberWithInt: currBeacon.id] stringValue];
    NSString *regionIdentifier = [@"region_" stringByAppendingString : idStr ];
    
    CLBeaconRegion *beaconRegion;
    
    if(major!=0  && minor!=0){
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID major:major minor:minor identifier:regionIdentifier];
    }else{
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID identifier:regionIdentifier];
    }
    
    
    beaconRegion.notifyEntryStateOnDisplay = YES;
    
    currBeacon.region = beaconRegion;

    return beaconRegion;
}


-(void) stopMonitoring:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Monitoring stopped"];
    @try {
        NSSet *monitoredRegionsSet = [self.locationManager monitoredRegions];
        NSArray *monitoredRegionsArr = [monitoredRegionsSet allObjects];
        for (int i=0; i<[monitoredRegionsArr count]; i++) {
            CLBeaconRegion *currRegion = [monitoredRegionsArr objectAtIndex:i];
            [self.locationManager stopMonitoringForRegion: currRegion];
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"incomingArray"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    @catch (NSException *exception) {
        NSString *errMsg = [NSString stringWithFormat:@"Error:: %@  by Reason :: %@", exception.name, exception.reason ];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    }
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}







//==================================================================================
//===================     regions Monitoring Callback    ===========================
//==================================================================================


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"Region monitoring failed with error: %@", [error localizedDescription]);
}



-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    //[self.locationManager startUpdatingLocation];  //======= todo maybe no need
    
    //AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
//    NSArray *globArr = [appDelegate globalArray];
    
    
//    NSLog(@"=== globalArr size is: %d", [globArr count] );
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"incomingArray"];
    NSArray *incomingArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSLog(@"=== incomingArray size is: %d", [incomingArray count] );

    [self process : EnterRegion : (CLBeaconRegion*)region];
    
 }

 
 -(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
     [self process:ExitRegion : (CLBeaconRegion*)region];
     
     //[manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
     //[self.locationManager stopUpdatingLocation];  //====== todo maybe no need this
     
     //NSLog(@"You come out of the region.");
 }




//-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
//{
//    [self.locationManager stopUpdatingLocation];
//    self.locationManager = nil;
//}

//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
//{//Use if you are supporting iOS 5
//    [self.locationManager stopUpdatingLocation];
//    self.locationManager = nil;
//}



-(void)process: (ActionType) actionLocationType : (CLBeaconRegion*)beaconRegion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"incomingArray"];
    NSArray *incomingArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    ExtBeacon *searchedExtBeacon = [BeaconsManagerPlugin findBeaconFromArray: incomingArray : beaconRegion];

    if(searchedExtBeacon == nil){
        NSLog(@"=== Saved beacon not found ===");
        return;
    }
    
    NSString *dataStr = searchedExtBeacon.data;
    
    MsgForType *msgForType = [searchedExtBeacon getMsgForType: actionLocationType];
    
    
    NSMutableDictionary* dict = [NSMutableDictionary new];
    
    [dict setObject: ActionType_toString[actionLocationType]  forKey:@"actionLocationType"];
    [dict setObject: @"didDetermineStateForRegion"  forKey:@"eventType"];
    [dict setObject: dataStr  forKey:@"parametersMap"];
    [dict setObject: [BeaconsManagerPlugin dictionaryFromRegion:beaconRegion]  forKey:@"region"];
    
    
    double currentTime = CFAbsoluteTimeGetCurrent();
    NSNumber *tempTime = [[NSNumber alloc] initWithDouble:currentTime];
    [dict setValue:tempTime forKey:@"fireTimeMillis"];
    
    if(msgForType.show == true && isPaused){
        [BeaconsManagerPlugin sendLocalNotificationWithMessage: msgForType.msg : dataStr : dict ];
    }
    
    [self addToQueue:dict];
}



//==================================================================================
//==============================   start-stop Ranging   ============================
//==================================================================================


-(void)startRanging:(CDVInvokedUrlCommand *)command
{
    if(self.locationManager == nil){
        [self initLocationManager];
    }
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[@"Ranging was started" stringByAppendingString:[self warningOfBluetooth] ]];
    @try {
        NSArray* rangingBeaconsArr = [command.arguments objectAtIndex:0];
        [self startRangingInner:rangingBeaconsArr];
        
        //self.rangingCallbackId = command.callbackId;
    }
    @catch (NSException *exception) {
        NSString *errMsg = [NSString stringWithFormat:@"Error:: %@  by Reason :: %@", exception.name, exception.reason ];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


-(void)setRangingFunction:(CDVInvokedUrlCommand *)command
{
    self.rangingCallbackId = command.callbackId;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}




-(void) startRangingInner:rangingBeaconsArr
{
    for(int i=0; i<[rangingBeaconsArr count]; i++){
        CLBeaconRegion* beaconRegion = [self createNativeBeaconRegionFromIncomingRegion:rangingBeaconsArr[i]];
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    }
}

     
-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    //if([beacons count]>0){
        //NSLog(@"%d rID: %@",[beacons count], region.proximityUUID.UUIDString);
        [self multipeRegions:beacons ];
    //}
//    if([beacons count]>2){
//        NSLog(@">2");
//    }
//    if([beacons count]>3){
//        NSLog(@">3");
//    }
    //double currentTime = CFAbsoluteTimeGetCurrent();
    //[self multipeRegions:beacons : currentTime ];
}






-(void)multipeRegions: (NSArray*) beacons
{
    double currentTime = CFAbsoluteTimeGetCurrent();
    if(framePreviousTime == 0){
        framePreviousTime = currentTime;
    }
    
    double diff = currentTime-framePreviousTime;
    //if(diff < 0.8){
        //NSLog(@"inArr      %d  + %d ;; diff: %f",[frameArr count], [beacons count], diff);
        [frameArr addObjectsFromArray:beacons];
    //}
    if(diff>0.8){
        //NSLog(@"before del %d  ;; diff: %f", [frameArr count], diff);
        [self sendRangingResult:frameArr];
        [frameArr removeAllObjects];
        framePreviousTime = currentTime;
        
        
    }
    
    
}

-(void) sendRangingResult:(NSMutableArray*) beaconsArr
{
    NSMutableArray *beaconsRestruct = [[NSMutableArray alloc] init];
    for(int i=0; i<[beaconsArr count];i++){
        NSDictionary* beaconAsDict =[BeaconsManagerPlugin dictionaryFromBeacon:beaconsArr[i] ];
        [beaconsRestruct addObject : beaconAsDict];
    }
    
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject: @"didRangeBeaconsInRegion"  forKey:@"eventType"];
    //[dict setObject: dataStr  forKey:@"parametersMap"];
    //[dict setObject: [BeaconsManagerPlugin dictionaryFromRegion:beaconRegion]  forKey:@"region"];
    [dict setObject:beaconsRestruct forKey:@"beacons"];

    
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    [pluginResult setKeepCallbackAsBool:YES];
    
    if(self.commandDelegate != nil){
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.rangingCallbackId];
    }
    

    
}


-(void)stopRanging:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ranging was stopped"];
    @try {
        NSSet *rangedRegionsSet = [self.locationManager rangedRegions];
        NSArray *rangedRegionsArr = [rangedRegionsSet allObjects];
        for (int i=0; i<[rangedRegionsArr count]; i++) {
            CLBeaconRegion *currRegion = [rangedRegionsArr objectAtIndex:i];
            [self.locationManager stopRangingBeaconsInRegion: currRegion];
        }
    }
    @catch (NSException *exception) {
        NSString *errMsg = [NSString stringWithFormat:@"Error:: %@  by Reason :: %@", exception.name, exception.reason ];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
    }
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


//================ apply parameters ===================

-(void)applyParameters:(CDVInvokedUrlCommand *)command
{
    NSString* resultStr = @"OK";
    NSDictionary* params = [command.arguments objectAtIndex:0];
    
    for (NSString* key in params) {
        if([key isEqual:@"paused"]){
            NSNumber* value = [params objectForKey:key];
            bool b= [value boolValue];
            if(b == true){
                self.isPaused = true;
            }else{
                self.isPaused = false;
            }
            
        }
        else{
            resultStr = [NSString stringWithFormat: @"key %@ not apply to ios", key];
        }
        
    }
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: resultStr];
   
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    
}



//================   notifications  ===================

+(void)sendLocalNotificationWithMessage:(NSString*)message : (NSString*)actionJson : (NSDictionary*) userInfo
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertAction = @"open application";
    notification.userInfo = userInfo;
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    [self checkAndDeleteNotificationIfExists:notification];
    
    // [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

+(Boolean)checkAndDeleteNotificationIfExists : (UILocalNotification*) _notification
{
    NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for(UILocalNotification *notification in notificationArray){
        if ([notification.alertBody isEqualToString:_notification.alertBody]  /*&& (notification.fireDate == your alert date time)*/) {
            // delete this notification
            [[UIApplication sharedApplication] cancelLocalNotification:notification] ;
            return true;
        }
    }
    return false;
}



- (void) didReceiveLocalNotification:(NSNotification*)nNotification
{
    double currentTime = CFAbsoluteTimeGetCurrent();
    UILocalNotification* localNotification = [nNotification object];
    
    if ([localNotification userInfo] == NULL ){
        return;
    }
    NSDictionary *userInfoDict =[localNotification userInfo];
    
    double fireTimeMillis = [[userInfoDict valueForKey:@"fireTimeMillis"] doubleValue];
    
    double diff = currentTime-fireTimeMillis;
    
    if(diff<0.8){
        return;
    }
    
    [self addToQueue:userInfoDict];
}



//=========================  bluetooth state listener  ===================

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSMutableDictionary *data = [NSMutableDictionary new];
    [dict setObject: @"didChangeBluetoothStatus"  forKey:@"eventType"];
    [dict setObject:data forKey:@"data"];

    if ([central state] == CBCentralManagerStatePoweredOff) {
        //NSLog(@"Bluetooth off");
        [data setObject: @"STATE_OFF"  forKey:@"status"];
        [data setObject: @"STATE_ON"  forKey:@"oldStatus"];
        
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        //NSLog(@"Bluetooth on");
        [data setObject: @"STATE_ON"  forKey:@"status"];
        [data setObject: @"STATE_OFF"  forKey:@"oldStatus"];

    }
    [self addToQueue:dict];
}



-(void) isBluetoothEnabled: (CDVInvokedUrlCommand*)command
{
    BOOL isEnabled = [self _isBluetoothEnabled];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isEnabled];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(BOOL) _isBluetoothEnabled
{
    BOOL isEnabled = peripheralManager.state == CBPeripheralManagerStatePoweredOn;
    return isEnabled;
}

-(NSString*)warningOfBluetooth
{
    if([self _isBluetoothEnabled]){
        return @"";
    }
    return @" WARNING: Bluetooth is disabled.";
}


- (void) enableBluetooth: (CDVInvokedUrlCommand *) command{
    
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=General&path=Bluetooth"]];
    //NSURL* url = [NSURL URLWithString:@"prefs:root=Bluetooth"];
    
    [[UIApplication sharedApplication] openURL: [NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    
}

- (void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
}






//==============

- (void) dealloc
{
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[super dealloc];
}




//============  utils ===========

+(ExtBeacon*)findBeaconFromArray : (NSArray*)arr : (CLBeaconRegion*)region
{
    for (int i=0; i<[arr count]; i++) {
        ExtBeacon *currBeacon = [arr objectAtIndex:i];
        CLBeaconRegion *currRegion= currBeacon.region;
        if([region isEqual: currRegion]){
            return currBeacon;
        }
    }
    return nil;
}


+(BeaconsManagerPlugin*)getBeaconsManagerPluginFromAppDelegate
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    //return appDelegate.beaconsManagerPluginInstance;
    return appDelegate.beaconsManagerPluginInstanceAO;
}


+(NSDictionary*)dictionaryFromRegion: (CLBeaconRegion*)beaconRegion
{
    NSMutableDictionary* dict = [NSMutableDictionary new];
    [dict setObject:beaconRegion.proximityUUID.UUIDString  forKey:@"uuid"];
    [dict setValue:beaconRegion.major  forKey:@"major"];
    [dict setValue:beaconRegion.minor  forKey:@"minor"];
    return dict;
}


+(NSDictionary*)dictionaryFromBeacon: (CLBeacon*)beacon
{
    //NSInteger rssiNSInt = beacon.rssi;
    //int rssiInt = (int)rssiNSInt;
    //NSNumber rssi = [NSNumber numberWithInteger:beacon.rssi];
    
    NSMutableDictionary* dict = [NSMutableDictionary new];
    [dict setObject:beacon.proximityUUID.UUIDString  forKey:@"uuid"];
    
    [dict setObject:[NSNumber numberWithInteger:beacon.rssi] forKey:@"rssi"];
    

    [dict setValue:beacon.major  forKey:@"major"];
    [dict setValue:beacon.minor  forKey:@"minor"];
    [dict setValue:[NSNumber numberWithDouble:beacon.accuracy] forKey:@"accuracy"];
    
    return dict;
}



@end