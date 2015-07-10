//
//  ViewController.m
//  ClientMac
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "ViewController.h"

#import "NNConnectionManager.h"
#import "NNCentralManager.h"

@interface ViewController () <NNConnectionManagerDelegate>

@end

@implementation ViewController {
    NNCentralManager *_manager;
    BOOL _isConnected;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _manager = [[NNCentralManager alloc] init];
    _manager.delegate = self;
    self.localName.stringValue = [_manager localName];
    _isConnected = NO;
    [self updateStatus];
    [self discoverConnectButtonTouched:self];
}


- (void) updateStatus {
    self.pairedLabel.hidden = self.unpairButton.hidden = !_manager.isPaired;
    NSString *discoverButtonText = @"Discover Server app";
    if (_manager.isPaired) {
        self.pairedLabel.stringValue = [NSString stringWithFormat:@"Paired with %@", _manager.pairedRemoteName];
        discoverButtonText = [NSString stringWithFormat:@"Connect to %@", _manager.pairedRemoteName];
        
    }
    [self.discoverConnectButton setTitle:discoverButtonText];
    
    self.connectionLabel.hidden = !_isConnected;
    self.disconnectButton.hidden = !_isConnected;
    self.discoverConnectButton.hidden = _isConnected;
}
-(IBAction)unpairButtonTouched:(id)sender {
    [_manager unpair];
}
-(IBAction)disconnectButtonTouched:(id)sender {
    [_manager disconnect];
}
-(IBAction)discoverConnectButtonTouched:(id)sender {
    self.connectionLabel.stringValue = @"Connecting...";
    
    [_manager connect];
}

- (void)connectionManager:(NNConnectionManager *)manager pairedWith:(NSString *)remoteName {
    [self updateStatus];
}
- (void)connectionManager:(NNConnectionManager *)manager connectedWith:(NSString *)remoteName {
    self.connectionLabel.stringValue = [NSString stringWithFormat:@"Connected to %@", remoteName];
    _isConnected = YES;
    [self updateStatus];
}

- (void)connectionManagerDisconnected:(NNConnectionManager *)manager {
    self.connectionLabel.stringValue = @"Disconnected";
    _isConnected = NO;
    [self updateStatus];
    
}
- (void)connectionManagerUnpaired:(NNConnectionManager *)manager {
    [self updateStatus];
    
}



@end
