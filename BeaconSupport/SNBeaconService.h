//
//  MainWebViewController.h
//
//  Created by DPich
//

#import <CoreLocation/CoreLocation.h>
#import "CLBeacon+SN.h"

@protocol SNBeaconServiceDelegate;

//class
@interface SNBeaconService : NSObject <CLLocationManagerDelegate>

//shared instance
//returns nil if the device cant do beacon monitoring
+ (instancetype) sharedService;

//call this to start/stop monitoring depending on the setting of detectionStarted
// monitoring with this service means:
// 1.region monitoring
// 2. upon entering a region the region is ranged once to find the strongest beacon
// 3. ranging is stopped after one pass per region and the strongest beacon is handled
- (BOOL)monitorIfNeeded;
//for convenience this takes the delegate as a parameter
- (BOOL)monitorIfNeeded:(id<SNBeaconServiceDelegate>)delegate;

//optional delegate
@property (weak) id<SNBeaconServiceDelegate> delegate;

//this reflects the enabled yes/no state of beacon detection. it is stored in the userDefaults and defaults to YES
@property (nonatomic, assign) BOOL detectionStarted;

//array of dictionaries with beacons and dates when they were previously seen
@property (nonatomic, strong, readonly) NSArray *history;

//array of dictionaries with beacon region UUIDs to monitor - this is read from the userDefaults and defaults to the plist key SNBeaconSettings>SNBeaconUUIDs
//TODO this key should be mutably and set the user defaults but I havent done that
@property (nonatomic, strong, readonly) NSArray *regionsToMonitor;

//'low-level' detection details
@property (nonatomic, strong, readonly) CLLocationManager *locationManager;
@property (nonatomic, strong, readonly) NSMutableDictionary *rangingToken;
@property (nonatomic, strong, readonly) NSMutableDictionary *rangingRegion;
@property (nonatomic, strong, readonly) NSMutableArray *enteredRegions;

@end

//delegate
@protocol SNBeaconServiceDelegate <NSObject>

@optional

//return YES if you want a UILocalNotification
- (BOOL)beaconService:(SNBeaconService*)service shouldNotifyForBeacon:(NSDictionary*)beaconProperties;

//your chance to modify the notification
- (void)beaconService:(SNBeaconService*)service willPostNotification:(UILocalNotification*)note forBeacon:(NSDictionary*)beaconProperties;

@end

//keys
extern NSString *SNBeaconServiceHistoryBeaconKey;
extern NSString *SNBeaconServiceHistoryTimestampKey;
extern NSString *SNBeaconServiceLocalNotificationKey;