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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
