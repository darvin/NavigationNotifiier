//
//  ViewController.h
//  ClientMac
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (assign) IBOutlet NSTextField *connectionLabel;
@property (assign) IBOutlet NSTextField *pairedLabel;
@property (assign) IBOutlet NSButton *unpairButton;
@property (assign) IBOutlet NSButton *disconnectButton;
@property (assign) IBOutlet NSButton *discoverConnectButton;

-(IBAction)unpairButtonTouched:(id)sender;
-(IBAction)disconnectButtonTouched:(id)sender;
-(IBAction)discoverConnectButtonTouched:(id)sender;


@end

