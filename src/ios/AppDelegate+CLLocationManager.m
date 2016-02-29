//
//  AppDelegate+CDVLocationManager.m
//  iBeaconTemplate
//


#import <Foundation/Foundation.h>



#import "AppDelegate+CLLocationManager.h"
#import <objc/runtime.h>



@implementation AppDelegate (CLLocationManager)


@dynamic beaconsManagerPluginInstanceAO;

-(void)setBeaconsManagerPluginInstanceAO: (BeaconsManagerPlugin*) bMan{
    objc_setAssociatedObject(self, @selector(beaconsManagerPluginInstanceAO), bMan, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(BeaconsManagerPlugin*)beaconsManagerPluginInstanceAO{
    return objc_getAssociatedObject(self, @selector(beaconsManagerPluginInstanceAO));
}






@end
