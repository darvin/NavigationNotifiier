//
//  NNANCSManager.h
//  Server
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNANCSMessage : NSObject
@property (readwrite, copy) NSString *title;
@property (readwrite, copy) NSString *appTitle;
@property (readwrite, copy) NSDate *date;
@end

@class NNANCSManager;

@protocol NNANCSManagerDelegate <NSObject>
@required
-(void)ancsManager:(NNANCSManager *)manager needsSendDataToControlPoint:(NSData*)data;
@optional
-(void)ancsManager:(NNANCSManager *)manager messageAdded:(NNANCSMessage*)message;

@end


@interface NNANCSManager : NSObject
@property (weak) id<NNANCSManagerDelegate> delegate;
- (void)receivedNotification:(NSData *)notificationData;
- (void)receivedDataSource:(NSData *)dsData;

@end
