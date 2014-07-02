//
//  MainWebViewController.h
//
//  Created by DPich
//

#import "CLBeacon+SN.h"

@implementation CLBeacon (SN)

- (NSDictionary *)dictionary {
    if(self.major) {
        if(self.minor) {
            return @{ SNBeaconUUIDKey:self.proximityUUID.UUIDString,
                      SNBeaconMajorKey:self.major,
                      SNBeaconMinorKey:self.minor};
        }
        return @{ SNBeaconUUIDKey:self.proximityUUID.UUIDString,
                  SNBeaconMajorKey:self.major};
    }
    return @{ SNBeaconUUIDKey:self.proximityUUID.UUIDString};
}

@end

NSString *SNBeaconUUIDKey = @"uuid";
NSString *SNBeaconMajorKey = @"major";
NSString *SNBeaconMinorKey = @"minor";