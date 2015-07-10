//
//  NNANCSManager.m
//  Server
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "NNANCSManager.h"
#import "ANCS.h"

@implementation NNANCSManager
- (void)receivedNotification:(NSData *)notificationData {
    size_t notificationSize = sizeof(ANCSNotification);
    ANCSNotification notification;
    [notificationData getBytes:&notification length:notificationSize];
    
    switch (notification.eventID) {
        case ANCSEventIDNotificationAdded:
            [self notificationAdded:notification];
            break;
        case ANCSEventIDNotificationModified:
            [self notificationModified:notification];
            break;
        case ANCSEventIDNotificationRemoved:
            [self notificationRemoved:notification];
            break;
        default:
            break;
    }
    
}
- (void)receivedDataSource:(NSData *)dsData {
    
}


- (void)notificationAdded:(ANCSNotification) notification {
    uint8_t getNotificationSize;
    uint8_t *getNotification = ANCSGetNotificationAttributesCommand(notification.notificationUID, &getNotificationSize);
    NSData *getNotificationAttributesData = [NSData dataWithBytes:getNotification length:getNotificationSize];
    
    [self.delegate ancsManager:self needsSendDataToControlPoint:getNotificationAttributesData];
}
- (void)notificationRemoved:(ANCSNotification) notification {
    NSLog(@"Not implemented");

}
- (void)notificationModified:(ANCSNotification) notification {
    NSLog(@"Not implemented");
}

@end
