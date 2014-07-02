//
//  MainWebViewController.h
//
//  Created by DPich
//

#import <CoreLocation/CoreLocation.h>

@interface CLBeacon (SN)

//beacon details :: uuid, major, minor keys
@property(readonly) NSDictionary *dictionary;

@end

//keys
extern NSString *SNBeaconUUIDKey;
extern NSString *SNBeaconMajorKey;
extern NSString *SNBeaconMinorKey;