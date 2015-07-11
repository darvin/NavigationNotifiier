//
//  ViewController.h
//  testmusicnotifications
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (assign) IBOutlet UILabel *songLabel;
@property (assign) IBOutlet UILabel *artistLabel;
@property (assign) IBOutlet UILabel *albumLabel;
@property (assign) IBOutlet UILabel *durationLabel;
@property (assign) IBOutlet UIImageView *artworkImage;
- (IBAction)nextSongTouched:(id)sender;
@end

