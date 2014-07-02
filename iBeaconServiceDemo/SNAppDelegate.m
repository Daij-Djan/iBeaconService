//
//  SNAppDelegate.m
//  iBeaconServiceDemo
//
//  Created by Dominik Pich on 01/07/14.
//  Copyright (c) 2014 Sapient. All rights reserved.
//

#import "SNAppDelegate.h"
#import "SNBeaconService.h"

@interface SNAppDelegate () <SNBeaconServiceDelegate>
@end

@implementation SNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef __IPHONE_8_0
    if(NSClassFromString(@"UIUserNotificationSettings")) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }
#endif
    
//    [[SNBeaconService sharedService] monitorIfNeeded];
    //our delegate doesnt do anything but for demo purposes I add it here
    [[SNBeaconService sharedService] monitorIfNeeded:self];

    UILocalNotification *theNotification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
    if(theNotification) {
        //handle it however you like.
        //remember that it WAS ALREADY displayed
        [self handleLocalNotification:theNotification];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    //handle it however you like.
    //remember that it was MAYBE NOT displayed already based on state
    
    if(application.applicationState != UIApplicationStateActive) {
        //show alert view and THEN handle it!
    }
    else {
        [self handleLocalNotification:notification];
    }
}

- (void)handleLocalNotification:(UILocalNotification*)theNotification {
    if(theNotification.userInfo[SNBeaconServiceLocalNotificationKey]) {
        //TODO!
        NSLog(@"%@", theNotification.userInfo[SNBeaconServiceLocalNotificationKey]);
    }
}

#pragma mark beacon service delegate demo

- (BOOL)beaconService:(SNBeaconService *)service shouldNotifyForBeacon:(NSDictionary *)beaconProperties {
    //filter
    if([beaconProperties[SNBeaconMinorKey] intValue] > 5) {
        return NO;
    }
    return YES;
}

- (void)beaconService:(SNBeaconService *)service willPostNotification:(UILocalNotification *)note forBeacon:(NSDictionary *)beaconProperties {
    //modify note
    note.alertBody = [NSString stringWithFormat:@"Found! %@", beaconProperties];
}
@end
