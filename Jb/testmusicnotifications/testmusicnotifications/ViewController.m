//
//  ViewController.m
//  testmusicnotifications
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "ViewController.h"
@import MediaPlayer;
@import AVFoundation;

@interface ViewController ()

@end

@implementation ViewController {
    NSTimer *_timer;
    NSDictionary *_currentAlbum;
    NSUInteger _currentSongIndex;
    UIImage *_currentArtwork;
    AVPlayer *_player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set ourselves as the first responder
    
    [self becomeFirstResponder];
    
    // Set the audio session
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    
    // Play an mp3 with AVAudioPlayer
    
    NSString *audioFileName = @"%@/5min.mp3";
    NSURL *audioURL = [NSURL fileURLWithPath:[NSString stringWithFormat:audioFileName, [[NSBundle mainBundle] resourcePath]]];
    _player = [[AVPlayer alloc] initWithURL:audioURL];
    
    [_player play];

    
    
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self
                                            selector:@selector(fireNotification)
                                            userInfo:nil repeats:NO];
    [self fireNotification];
}


- (void)viewWillDisappear:(BOOL)animated {
    
    // Turn off remote control event delivery & Resign as first responder
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    // Don't forget to call super
    
    [super viewWillDisappear:animated];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"prev");
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"next");
                [self fireNotification];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [_player play];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [_player pause];
                break;
                
            default:
                break;
        }
    }
}

- (void)fireNotification {
    MPNowPlayingInfoCenter *ic = [MPNowPlayingInfoCenter defaultCenter];
    
    
    if (_currentAlbum==nil||[[_currentAlbum objectForKey:@"tracks"] count] <=_currentSongIndex) {
        [self fetchAlbum];
        _currentSongIndex = 0;
    }
    
    NSString *currentSongName = [[_currentAlbum objectForKey:@"tracks"] objectAtIndex:_currentSongIndex];
    NSString *currentSongID = [[[_currentAlbum objectForKey:@"secrets"] objectForKey:@"tracks"] objectAtIndex:_currentSongIndex];
    NSTimeInterval currentSongDuration = arc4random()%60*3 + 60 *3;
    NSString *currentAlbumName = _currentAlbum[@"album"];
    
    self.songLabel.text = currentSongName;
    self.albumLabel.text = currentAlbumName;
    self.artistLabel.text = _currentAlbum[@"artist"];
    self.durationLabel.text =  [[NSString alloc] initWithFormat:@"%02ld:%02ld", (long)currentSongDuration / 60, (long)currentSongDuration % 60];
    self.artworkImage.image = _currentArtwork;
    
    ic.nowPlayingInfo = @{
                          MPMediaItemPropertyAlbumTitle:currentAlbumName,
                          MPMediaItemPropertyAlbumTrackCount:@([[_currentAlbum objectForKey:@"tracks"] count]),
                          MPMediaItemPropertyAlbumTrackNumber:@(_currentSongIndex),
                          MPMediaItemPropertyArtist:_currentAlbum[@"artist"],
                          MPMediaItemPropertyArtwork:[[MPMediaItemArtwork alloc] initWithImage:_currentArtwork],
//                          MPMediaItemPropertyComposer
//                          MPMediaItemPropertyDiscCount
//                          MPMediaItemPropertyDiscNumber
                          
                          MPMediaItemPropertyGenre:@"Metal",
                          MPMediaItemPropertyPersistentID: currentSongID,
                          MPMediaItemPropertyPlaybackDuration: @(currentSongDuration),
                          MPMediaItemPropertyTitle: currentSongName
                          
      
                          };
    _currentSongIndex++;

}

- (void) fetchAlbum {
    NSData *albumData = [self getDataFrom:@"http://metallizer.dk/api/json/0"];
    NSString *albumString = [[NSString alloc] initWithData:albumData encoding:NSUTF8StringEncoding];
    albumString = [[albumString stringByReplacingOccurrencesOfString:@"jsonMetallizerAlbum(" withString:@""] stringByReplacingOccurrencesOfString:@");" withString:@""];
    NSError *err;
    _currentAlbum = [NSJSONSerialization JSONObjectWithData:[albumString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
    
    
    NSData *artworkData = [self getDataFrom:@"http://thecatapi.com/api/images/get?format=src&type=png"];
    _currentArtwork = [UIImage imageWithData:artworkData scale:1.0];
    
}
- (NSData *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return nil;
    }
    
    return oResponseData;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)nextSongTouched:(id)sender {
    [self fireNotification];
}

@end
