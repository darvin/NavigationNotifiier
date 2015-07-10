//
//  ViewController.h
//  Client
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (assign) IBOutlet UILabel *connectionLabel;
@property (assign) IBOutlet UILabel *pairedLabel;
@property (assign) IBOutlet UIButton *unpairButton;
@property (assign) IBOutlet UIButton *disconnectButton;
@property (assign) IBOutlet UIButton *discoverConnectButton;

-(IBAction)unpairButtonTouched:(id)sender;
-(IBAction)disconnectButtonTouched:(id)sender;
-(IBAction)discoverConnectButtonTouched:(id)sender;

@end

