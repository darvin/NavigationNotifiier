//
//  ViewController.m
//  testmusicnotifications
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "ViewController.h"
@import MediaPlayer;

@interface ViewController ()

@end

@implementation ViewController {
    NSTimer *_timer;
    NSDictionary *_currentAlbum;
    NSUInteger _currentSongIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self
                                            selector:@selector(fireNotification)
                                            userInfo:nil repeats:NO];
    [self fireNotification];
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
    
    ic.nowPlayingInfo = @{
                          MPMediaItemPropertyAlbumTitle:currentAlbumName,
                          MPMediaItemPropertyAlbumTrackCount:@([[_currentAlbum objectForKey:@"tracks"] count]),
                          MPMediaItemPropertyAlbumTrackNumber:@(_currentSongIndex),
                          MPMediaItemPropertyArtist:_currentAlbum[@"artist"],
//                          MPMediaItemPropertyArtwork
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
