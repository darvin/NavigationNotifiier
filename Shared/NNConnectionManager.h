#ifndef CONNECTIONMANAGER_h
#define CONNECTIONMANAGER_h
#import <Foundation/Foundation.h>


@protocol NNConnectionManager;

@protocol NNConnectionManagerDelegate <NSObject>
- (void)connectionManager:(id<NNConnectionManager>)manager pairedWith:(NSString *)remoteName;
- (void)connectionManager:(id<NNConnectionManager>)manager connectedWith:(NSString *)remoteName;

- (void)connectionManagerDisconnected:(id<NNConnectionManager>)manager;
- (void)connectionManagerUnpaired:(id<NNConnectionManager>)manager;


@end

@protocol NNConnectionManager <NSObject>
@property (weak) id<NNConnectionManagerDelegate> delegate;
@property (readonly) BOOL isPaired;
@property (readonly) NSString *pairedRemoteName;
- (void) unpair;
- (void) connect;
@end

#endif
