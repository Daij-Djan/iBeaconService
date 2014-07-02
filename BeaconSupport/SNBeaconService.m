//
//  MainWebViewController.h
//
//  Created by DPich
//

#import "SNBeaconService.h"

#define SNBeaconSettingsKey @"SNBeaconSettings"
#define SNBeaconUUIDsKey @"SNBeaconUUIDs"
#define SNBeaconServiceOnKey @"SNBeaconServiceOnKey"

#define SNBeaconHistoryKey @"SNBeaconHistoryKey"
#define SNBeaconHistoryMaxSize 10

@interface SNBeaconService ()
@property (nonatomic, strong, readwrite) NSArray *history;

@property (nonatomic, strong, readwrite) CLLocationManager *locationManager;
@property (nonatomic, strong, readwrite) NSMutableDictionary *rangingToken;
@property (nonatomic, strong, readwrite) NSMutableDictionary *rangingRegion;
@property (nonatomic, strong, readwrite) NSMutableArray *enteredRegions;
@end

@implementation SNBeaconService

+ (instancetype) sharedService {
    if(![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        return nil;
    }
    
    static SNBeaconService *sharedService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[[self class] alloc] init];
    });
    
    return sharedService;
}

- (BOOL)monitorIfNeeded {
    if(!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    id regions = [[self.locationManager monitoredRegions] copy];
    
    if(self.detectionStarted) {
        id theIds = self.regionsToMonitor;
        
        for (CLBeaconRegion *r in regions) {
            if(![theIds containsObject:r.identifier]) {
                [self.locationManager stopMonitoringForRegion:r];
                [self.locationManager stopRangingBeaconsInRegion:r];
            }
        }

        self.rangingToken = [[NSMutableDictionary alloc] init];
        self.rangingRegion = [[NSMutableDictionary alloc] init];
        self.enteredRegions = [[NSMutableArray alloc] init];
        
        for (id theId in theIds) {
            //add
            NSLog(@"monitor ID: %@", theId);
            
            CLBeaconRegion *region;
            region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:theId] identifier:theId];
            region.notifyEntryStateOnDisplay = YES;
            [self.locationManager startMonitoringForRegion:region];
            [self.locationManager stopRangingBeaconsInRegion:region];
        }
        
        NSLog(@"started");
        
//#if DEBUG && TARGET_IPHONE_SIMULATOR
//        [self handleStrongestBeaconFound:@{@"uuid": @"83E2C4FD-FE19-4E29-AE78-B91A52E77C5F", @"major": @258, @"minor": @2} inRegion:nil];
//#endif

        return YES;
    }
    else {
        for (CLBeaconRegion *r in regions) {
            [self.locationManager stopMonitoringForRegion:r];
            [self.locationManager stopRangingBeaconsInRegion:r];
        }
        
        NSLog(@"stopped");
        
        return NO;
    }
}

- (BOOL)monitorIfNeeded:(id<SNBeaconServiceDelegate>)delegate {
    self.delegate = delegate;
    return [self monitorIfNeeded];
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    id txt;
    
    if(state == CLRegionStateInside) {
        txt = [NSString stringWithFormat:@"locationManager didDetermineState INSIDE for %@", region.identifier];
        if(![self.enteredRegions containsObject:region.identifier]) {
            if(!self.rangingToken[region.identifier]) {
                UIBackgroundTaskIdentifier token = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    NSLog(@"Ranging for region %@ killed", region.identifier);
                }];
                if(token == UIBackgroundTaskInvalid) {
                    NSLog(@"cant start background task");
                }
                [self.enteredRegions addObject:region.identifier];
                self.rangingToken[region.identifier] = @(token);
                self.rangingRegion[region.identifier] = @(YES);
                [self.locationManager startRangingBeaconsInRegion:(id)region];
            }
            [self.enteredRegions addObject:region.identifier];
        }
    }
    else if(state == CLRegionStateOutside) {
        if([self.enteredRegions containsObject:region.identifier]) {
            [self.enteredRegions removeObject:region.identifier];
            txt = [NSString stringWithFormat:@"locationManager didDetermineState OUTSIDE for %@", region.identifier];
        }
    }
    else {
        if([self.enteredRegions containsObject:region.identifier]) {
            [self.enteredRegions removeObject:region.identifier];
            txt = [NSString stringWithFormat:@"locationManager didDetermineState OTHER for %@", region.identifier];
        }
    }

    if(txt) {
        NSLog(@"%@", txt);
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"didRange %@", beacons);
    if(self.rangingToken[region.identifier] && self.rangingRegion[region.identifier]) {
        NSDictionary *beaconProperties = beacons.count ? [beacons[0] dictionary] : nil;
        BOOL bEnded = [self handleStrongestBeaconFound:beaconProperties inRegion:region];
    
        [self.locationManager stopRangingBeaconsInRegion:region];
        [self.rangingRegion removeObjectForKey:region.identifier];
    
        if(bEnded) {
            UIBackgroundTaskIdentifier token = [self.rangingToken[region.identifier] intValue];
            [self.rangingToken removeObjectForKey:region.identifier];
            [[UIApplication sharedApplication] endBackgroundTask:token];
        }
    }
}

#pragma mark -

- (BOOL)handleStrongestBeaconFound:(NSDictionary*)beaconProperties inRegion:(CLBeaconRegion*)region {
    if (beaconProperties) {
        //check watchlist
        if(![self shouldNotifyForBeacon:beaconProperties]) {
            NSLog(@"filtered out by delegate");
            return YES;
        }
        
        //prepare local notify
        UILocalNotification *theNotification = [[UILocalNotification alloc] init];
        theNotification.alertBody = [NSString stringWithFormat:@"Found beacon %@", beaconProperties];
        theNotification.alertAction = @"View in App";
        theNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
        theNotification.soundName = UILocalNotificationDefaultSoundName;
        theNotification.userInfo = @{SNBeaconServiceLocalNotificationKey: beaconProperties};
        
        //schedule it
        if([self.delegate respondsToSelector:@selector(beaconService:willPostNotification:forBeacon:)]) {
            [self.delegate beaconService:self willPostNotification:theNotification forBeacon:beaconProperties];
        }
        
        NSLog(@"Notify for %@", beaconProperties);
        [[UIApplication sharedApplication] scheduleLocalNotification:theNotification];

        //record new beacon in history
        [self addHistoryEntry:beaconProperties];
    }
    
    return YES;
}

- (BOOL)shouldNotifyForBeacon:(NSDictionary*)beaconProperties {
    //ask delegate
    if(![self.delegate respondsToSelector:@selector(beaconService:shouldNotifyForBeacon:)]) {
        return YES;
    }
    
    return [self.delegate beaconService:self shouldNotifyForBeacon:beaconProperties];
}

#pragma mark user defaults

- (BOOL)detectionStarted {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    if(![standardUserDefaults objectForKey:SNBeaconServiceOnKey]) {
        [standardUserDefaults setBool:YES forKey:SNBeaconServiceOnKey];
    }
    
    return [standardUserDefaults boolForKey:SNBeaconServiceOnKey];
}

- (void)setDetectionStarted:(BOOL)detectionStarted {
    [[NSUserDefaults standardUserDefaults] setBool:detectionStarted forKey:SNBeaconServiceOnKey];
}

- (NSArray *)history {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:SNBeaconHistoryKey];
}

- (void)setHistory:(NSArray*)history {
    [[NSUserDefaults standardUserDefaults] setObject:history forKey:SNBeaconHistoryKey];
}

- (void)addHistoryEntry:(NSDictionary*)beaconProperties {
    NSMutableArray *ma = [self.history mutableCopy];
    if(!ma) {
        ma = [NSMutableArray array];
    }
    [ma addObject:@{SNBeaconServiceHistoryTimestampKey: @([NSDate date].timeIntervalSince1970),
                    SNBeaconServiceHistoryBeaconKey: beaconProperties}];
    
    if(ma.count > SNBeaconHistoryMaxSize) {
        [ma removeObjectsInRange:NSMakeRange(0, ma.count-SNBeaconHistoryMaxSize)];
    }
    self.history = ma;
}

- (NSArray *)regionsToMonitor {
    NSDictionary *dict = [[NSBundle mainBundle] objectForInfoDictionaryKey:SNBeaconSettingsKey];
    if(!dict) {
        NSLog(@"Cant get settings from plist, wont start service");
    }
    if(![dict isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Settings from plist, need to be a dictionary");
    }
    
    id theIds = dict[SNBeaconUUIDsKey];
    if(!theIds) {
        NSLog(@"Cant get UUIDs from plist");
    }
    
    return theIds;
}

@end

NSString *SNBeaconServiceHistoryBeaconKey = @"beacon";
NSString *SNBeaconServiceHistoryTimestampKey = @"timestamp";
NSString *SNBeaconServiceLocalNotificationKey = @"beacon";