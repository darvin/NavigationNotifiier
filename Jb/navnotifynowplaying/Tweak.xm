#import <objcipc/objcipc.h>
#import "../Shared/NavNotifyCentralShared.h"

%hook MPNowPlayingInfoCenter
-(void)setNowPlayingInfo:(NSDictionary *)info {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.
	%orig; // Call through to the original function with its original arguments.
  NSLog(@"Message sent");
  [OBJCIPC sendMessageToAppWithIdentifier:NavNotifyCentralAppBundleId 
                              messageName:NavNotifyMusicNowPlayingMessage 
                                dictionary:@{ @"nowPlayingInfo":info } replyHandler:^(NSDictionary *response) {
  }];


}

%end
