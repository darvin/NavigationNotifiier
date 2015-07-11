#import "RootViewController.h"
#import "../Shared/NavNotifyCentralShared.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import <objcipc/objcipc.h>

@interface NavNotifyCentralApplication: UIApplication <UIApplicationDelegate> {
	UIWindow *_window;
	RootViewController *_viewController;
	NSTimer *_timer;
	CBPeripheralManager *_manager;

}
@property (nonatomic, retain) UIWindow *window;
@end

@implementation NavNotifyCentralApplication
@synthesize window = _window;
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	_viewController = [[RootViewController alloc] init];
	[_window addSubview:_viewController.view];
	[_window makeKeyAndVisible];

	NSLog(@"NavNotifyCentral hooks registered ");

	[OBJCIPC registerIncomingMessageFromAppHandlerForMessageName:NavNotifyMusicNowPlayingMessage handler:^NSDictionary *(NSDictionary *message) {
		[self receivedMessage:message name:NavNotifyMusicNowPlayingMessage];
    	return nil;
	}];
	[OBJCIPC registerIncomingMessageFromAppHandlerForMessageName:NavNotifyNavigationMessage handler:^NSDictionary *(NSDictionary *message) {
		[self receivedMessage:message name:NavNotifyNavigationMessage];
    	return nil;
	}];


    NSDictionary *options =@{CBPeripheralManagerOptionShowPowerAlertKey : @YES,
                             CBPeripheralManagerOptionRestoreIdentifierKey: @"NavigationNotifierServerPeripheral"} ;
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_delegateQueue options:options];



    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                            selector:@selector(loggingTimer)
                                            userInfo:nil repeats:YES];

}

- (void)loggingTimer {
	NSLog(@"NavNotifyCentral is up and running...");
}

- (void)receivedMessage:(NSDictionary *)message name:(NSString*)name {
	NSLog(@"NavNotifyCentral MESSAGE RECEIVED %@", message);
	if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge
                                                                                                              categories:nil]];
    }

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertTitle = name;
    notification.alertBody = [NSString stringWithFormat:@"Info: %@", message];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

}

- (void)dealloc {
	[_viewController release];
	[_window release];
	[super dealloc];
}
@end

// vim:ft=objc
