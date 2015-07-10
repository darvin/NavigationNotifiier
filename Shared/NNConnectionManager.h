#import <Foundation/Foundation.h>

@class NNConnectionManager;

@protocol NNConnectionManagerDelegate <NSObject>
- (void)connectionManager:(NNConnectionManager *)manager pairedWith:(NSString *)remoteName;
- (void)connectionManager:(NNConnectionManager *)manager connectedWith:(NSString *)remoteName;

- (void)connectionManagerDisconnected:(NNConnectionManager *)manager;
- (void)connectionManagerUnpaired:(NNConnectionManager *)manager;


@end

@interface NNConnectionManager : NSObject
@property (weak) id<NNConnectionManagerDelegate> delegate;
@property (readonly) BOOL isPaired;
@property (readwrite, copy) NSString *pairedRemoteName;
- (void) unpair;
- (void) connect;

- (void) wasUnpaired;
- (void) wasConnectedToRemote:(NSString *)remoteName;
- (void) wasPairedWithRemote:(NSString *)remoteName;
- (void) wasDisconnected;
@end

