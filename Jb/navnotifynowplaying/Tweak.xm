
%hook MPNowPlayingInfoCenter
-(void)setNowPlayingInfo:(NSDictionary *)info {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.
	%orig; // Call through to the original function with its original arguments.
	if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge
                                                                                                              categories:nil]];
    }

    UILocalNotification *notification = [[UILocalNotification alloc] init];
   	notification.alertBody = @"Test Notification";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [notification release];
}

%end
