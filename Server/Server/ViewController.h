//
//  ViewController.h
//  Server
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (assign) IBOutlet UIButton *unpairButton;
@property (assign) IBOutlet UILabel *pairedStatusLabel;
@property (assign) IBOutlet UILabel *localNameLabel;
@property (assign) IBOutlet UILabel *connectionStatusLabel;
-(IBAction)unpairButtonTouched:(id)sender;

@end

