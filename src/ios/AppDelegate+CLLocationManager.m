//
//  AppDelegate+CDVLocationManager.m
//  iBeaconTemplate
//
//  Created by 1 on 01.10.15.
//  Copyright © 2015 iBeaconModules.us. All rights reserved.
//

#import <Foundation/Foundation.h>



#import "AppDelegate+CLLocationManager.h"
#import <objc/runtime.h>



@implementation AppDelegate (CLLocationManager)

//+ (CLLocationManager*)lma {
//    return staticLMPlus;
//}
//
//+ (void)setLMa:(CLLocationManager*)newLM {
//    staticLMPlus = newLM;
//}


//+ (NSObject*)bma{
//    return bMan;
//}
//
//+ (void)setBMa:(NSObject*)newBMa{
//    bMan = newBMa;
//}

//- (NSObject*)bManager
//{
//    return bMan;
//}
//
//- (void)setBManager:(NSObject*)obj
//{
//    bMan = obj;
//    //[self.accessibilityElements ];
//}



+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(xxx_application:didFinishLaunchingWithOptions:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    });
}


- (BOOL) xxx_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    BOOL launchedWithoutOptions = launchOptions == nil;
//    
//    if (!launchedWithoutOptions) {
//        //[self requestMoreBackgroundExecutionTime];
//    }
    
    NSLog(@"===============  xxx_application App Delegate didFinishLaunchingWithOptions===============");
    NSLog(@" -- %@", launchOptions);
    
    return [self xxx_application:application didFinishLaunchingWithOptions:launchOptions];
    
}



- (void) didReceiveLocalNotification:(NSNotification*)localNotification
{
    UILocalNotification* notification = [localNotification object];
    
    NSDictionary* userInfo = notification.userInfo;
    NSString* id = [userInfo objectForKey:@"id"];
    NSString* json = [userInfo objectForKey:@"json"];
    BOOL autoCancel = [[userInfo objectForKey:@"autoCancel"] boolValue];
    
    NSDate* now = [NSDate date];
    NSDate* fireDate = notification.fireDate;
    NSTimeInterval fireDateDistance = [now timeIntervalSinceDate:fireDate];
    NSString* event = (fireDateDistance < 1) ? @"trigger" : @"click";
    
//    if (autoCancel && [event isEqualToString:@"click"]) {
//        [self cancelNotification:notification fireEvent:YES];
//    }
//    
//    [self fireEvent:event id:id json:json];
}



@end
