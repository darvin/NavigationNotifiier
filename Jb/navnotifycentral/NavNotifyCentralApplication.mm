#import "RootViewController.h"
#import "../Shared/NavNotifyCentralShared.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import <objcipc/objcipc.h>


NS_INLINE CBUUID * ind_CBUUID(NSString *str) {
    return [CBUUID UUIDWithString:str];
}
#define NN_ANCS_SERVICE_UUID ind_CBUUID(@"7905F431-B5CE-4E99-A40F-4B1E122D00D0") // ANCS service
#define NN_ANCS_CHAR_NOTIFICATION_SOURCE_UUID ind_CBUUID(@"9FBF120D-6301-42D9-8C58-25E699A21DBD") // ANCS Notification Source
#define NN_ANCS_CHAR_CONTROL_POINT_UUID ind_CBUUID(@"69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9") // ANCS Control Point
#define NN_ANCS_CHAR_DATA_SOURCE_UUID ind_CBUUID(@"22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB") // ANCS Data Source

#define NN_NN_SERVICE_UUID ind_CBUUID(@"EE193598-6D50-4631-9672-B05BBCEC3591")
#define NN_NN_CHAR_SERVER_NAME_UUID ind_CBUUID(@"E1450996-0DDB-4986-B3E4-A3E49B3CA923")
#define NN_NN_CHAR_PAIRED_CLIENT_NAME_UUID ind_CBUUID(@"98C038A9-A58F-4F3D-A4B2-CEB1250100DE")

@interface NavNotifyCentralApplication: UIApplication <UIApplicationDelegate, CBPeripheralManagerDelegate> {
	UIWindow *_window;
	RootViewController *_viewController;
	NSTimer *_timer;
	CBPeripheralManager *_manager;
    CBMutableService *_service;
    UIBackgroundTaskIdentifier _bgTask;

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
			NSLog(@"NavNotifyCentral hook message received! ");

		[self receivedMessage:message name:NavNotifyMusicNowPlayingMessage];
    	return nil;
	}];
	[OBJCIPC registerIncomingMessageFromAppHandlerForMessageName:NavNotifyNavigationMessage handler:^NSDictionary *(NSDictionary *message) {
					NSLog(@"NavNotifyCentral hook message received! ");

		[self receivedMessage:message name:NavNotifyNavigationMessage];
    	return nil;
	}];


    NSDictionary *options =@{CBPeripheralManagerOptionShowPowerAlertKey : @YES,
                             CBPeripheralManagerOptionRestoreIdentifierKey: @"NavigationNotifierServerPeripheral"} ;
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:options];



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



- (void)applicationDidEnterBackground:(UIApplication *)application {

    // Delay execution of my block for 15 minutes.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * 60 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        NSLog(@"I'm still alive!");
    });

    _bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // should never get here under normal circumstances
        [application endBackgroundTask: _bgTask]; 
        _bgTask = UIBackgroundTaskInvalid;
        NSLog(@"I'm going away now ....");
    }];
}



- (CBMutableService *)createService {
    CBMutableService *service = [[CBMutableService alloc] initWithType:NN_NN_SERVICE_UUID primary:YES];
    
    CBMutableCharacteristic *pairedClientName = [[CBMutableCharacteristic alloc] initWithType:NN_NN_CHAR_PAIRED_CLIENT_NAME_UUID properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
    CBMutableCharacteristic *serverName = [[CBMutableCharacteristic alloc] initWithType:NN_NN_CHAR_SERVER_NAME_UUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];

    service.characteristics = @[pairedClientName, serverName];
    return service;

}





- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {

        if (_service == nil) {
            _service = [self createService];
            [_manager addService:_service];
        }

        NSDictionary *advertisementData = @{CBAdvertisementDataServiceUUIDsKey : @[NN_ANCS_SERVICE_UUID, NN_NN_SERVICE_UUID], CBAdvertisementDataLocalNameKey : UIDevice.currentDevice.name};
        [_manager startAdvertising:advertisementData];
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral
         willRestoreState:(NSDictionary *)dict {

         }

@end

// vim:ft=objc
