//
//  ViewController.m
//  Client
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "ViewController.h"
#import "../../Shared/NNConnectionManager.h"
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
    _isConnected = NO;
    [self updateStatus];
    [self discoverConnectButtonTouched:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateStatus {
    self.pairedLabel.hidden = self.unpairButton.hidden = !_manager.isPaired;
    if (_manager.isPaired) {
        self.pairedLabel.text = [NSString stringWithFormat:@"Paired with %@", _manager.pairedRemoteName];
        self.discoverConnectButton.titleLabel.text = [NSString stringWithFormat:@"Connect to %@", _manager.pairedRemoteName];
    } else {
        self.discoverConnectButton.titleLabel.text = @"Discover Server app";
    }
    
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
    self.connectionLabel.text = @"Connecting...";

    [_manager connect];
}

- (void)connectionManager:(NNConnectionManager *)manager pairedWith:(NSString *)remoteName {
    [self updateStatus];
}
- (void)connectionManager:(NNConnectionManager *)manager connectedWith:(NSString *)remoteName {
    self.connectionLabel.text = [NSString stringWithFormat:@"Connected to %@", remoteName];
    _isConnected = YES;
    [self updateStatus];
}

- (void)connectionManagerDisconnected:(NNConnectionManager *)manager {
    self.connectionLabel.text = @"Disconnected";
    _isConnected = NO;
    [self updateStatus];

}
- (void)connectionManagerUnpaired:(NNConnectionManager *)manager {
    [self updateStatus];

}

@end
