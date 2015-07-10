#import "NNConnectionManager.h"

@implementation NNConnectionManager

- (NSString *)pairedRemoteName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *pairedRemoteName = [defaults stringForKey:@"pairedRemoteName"];
    
    return pairedRemoteName;
    
}
- (void)setPairedRemoteName:(NSString *)pairedRemoteName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:pairedRemoteName forKey:@"pairedRemoteName"];
}

- (BOOL)isPaired {
    return [self pairedRemoteName]!=nil;
}


- (void) unpair {
    NSLog(@"Implement in subclass");
}
- (void) connect {
    NSLog(@"Implement in subclass");

}

- (void) wasUnpaired {
    [self setPairedRemoteName:nil];
    if ([self.delegate respondsToSelector:@selector(connectionManagerUnpaired:)]) {
        [self.delegate connectionManagerUnpaired:self];
    }

}
- (void) wasConnectedToRemote:(NSString *)remoteName {
    if ([remoteName isEqualToString:[self pairedRemoteName]]) {
        //paired already, reconnection
        
    } else {
        //new pairing, refresh pairing
        [self setPairedRemoteName:remoteName];
        if ([self.delegate respondsToSelector:@selector(connectionManager:pairedWith:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate connectionManager:self pairedWith:remoteName];
            });
            
        }
        
    }
    
    if ([self.delegate respondsToSelector:@selector(connectionManager:connectedWith:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate connectionManager:self connectedWith:remoteName];
        });
        
    }

}
- (void) wasPairedWithRemote:(NSString *)remoteName {
    
}
- (void) wasDisconnected {
    
}

@end