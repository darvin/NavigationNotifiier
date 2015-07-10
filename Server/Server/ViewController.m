//
//  ViewController.m
//  Server
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "ViewController.h"
#import "NNPeripheralManager.h"
@interface ViewController () <NNConnectionManagerDelegate>

@end

@implementation ViewController {
    NNPeripheralManager *_connManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _connManager = [[NNPeripheralManager alloc] init];
    _connManager.delegate = self;
    [_connManager connect];

    [self updateStatus];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)unpairButtonTouched:(id)sender {
    [_connManager unpair];
}


- (void)updateStatus {
    self.unpairButton.hidden = !_connManager.isPaired;
    self.pairedStatusLabel.text = _connManager.isPaired? [NSString stringWithFormat:@"Paired with %@", _connManager.pairedRemoteName] : @"Not paired";
}

- (void)connectionManager:(NNConnectionManager *)manager pairedWith:(NSString *)remoteName {
    [self updateStatus];
}
- (void)connectionManager:(NNConnectionManager *)manager connectedWith:(NSString *)remoteName {
    self.connectionStatusLabel.text = [NSString stringWithFormat:@"Conected to %@", remoteName];
}

- (void)connectionManagerDisconnected:(NNConnectionManager *)manager {
    self.connectionStatusLabel.text = @"Not connected";
}
- (void)connectionManagerUnpaired:(NNConnectionManager *)manager {
    [self updateStatus];

}

@end
