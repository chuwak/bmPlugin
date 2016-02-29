//
//  AppDelegate+CDVLocationManager.h
//  iBeaconTemplate
//


#import "AppDelegate.h"
#import "BeaconsManagerPlugin.h"


@interface AppDelegate (CLLocationManager)

@property(nonatomic, strong) BeaconsManagerPlugin* beaconsManagerPluginInstanceAO;

//- (BOOL) xxx_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;  // todo uncomment

@end