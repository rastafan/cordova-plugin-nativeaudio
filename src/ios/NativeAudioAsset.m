//
//
//  NativeAudioAsset.m
//  NativeAudioAsset
//
//  Created by Sidney Bofah on 2014-06-26.
//

#import "NativeAudioAsset.h"

@interface NativeAudioAsset () <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) AVPlayer *player;

@end

@implementation NativeAudioAsset


static const CGFloat FADE_STEP = 0.05;
static const CGFloat FADE_DELAY = 0.08;

-(id) initWithPath:(NSString*) path withVolume:(NSNumber*) volume withFadeDelay:(NSNumber *)delay withTrackName:(NSString *)name
{
    setenv("CFNETWORK_DIAGNOSTICS","3",1);
    self = [super init];
    if(self) {
        
        NSURL *pathURL;
        
        if([path hasPrefix:@"http"]){
            pathURL = [NSURL URLWithString: path];
        }else{
            pathURL = [NSURL fileURLWithPath: path];
        }

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:pathURL options:nil];
        [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
        AVPlayerItem * playerItem = [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:@[@"playable",@"duration"]];
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];

        [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
        self.player.volume = volume.floatValue;

        if(delay)
        {
            fadeDelay = delay;
        }
        else {
            fadeDelay = [NSNumber numberWithFloat:FADE_DELAY];
        }
        
        initialVolume = volume;

        if(name)
        {
            trackName = name;
        } else {
            trackName = '';
        }
    
        
    }
    return(self);
}

- (void)addObservers
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidStall:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:[self.player currentItem]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
            
        } else if (self.player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            //[player play];
            
        } else if (self.player.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
            
        }
    }
}


- (void) play
{
    [self.player play];
}


// The volume is increased repeatedly by the fade step amount until the last step where the audio is stopped.
// The delay determines how fast the decrease happens
- (void)playWithFade
{
    //rate=0 -> not playing
    if (self.player.rate == 0)
    {
        self.player.volume = 0;
        [self.player play];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(playWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
        });
    }
    else
    {
        if(self.player.volume < initialVolume.floatValue)
        {
            self.player.volume += FADE_STEP;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(playWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
            });
        }
    }
}

- (void) pause
{
    [self.player pause];
}

// The volume is decreased repeatedly by the fade step amount until the volume reaches the configured level.
// The delay determines how fast the increase happens
- (void)pauseWithFade
{
    BOOL shouldContinue = NO;
    
    //rate=0 -> not playing
    if (self.player.rate != 0 && self.player.volume > FADE_STEP) {
        self.player.volume -= FADE_STEP;
        shouldContinue = YES;
    } else {
        // Pause and get the sound ready for playing again
        [self.player pause];
        self.player.volume = initialVolume.floatValue;
    }
    
    if(shouldContinue) {
        [self performSelector:@selector(pauseWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
    }
}

- (void) stop
{
    //There is no stop method in AVPlayer, so we pause and go to position 0
    
    [self.player pause];
    [self.player seekToTime:CMTimeMake(0, 1)];
    
}

// The volume is decreased repeatedly by the fade step amount until the volume reaches the configured level.
// The delay determines how fast the increase happens
- (void)stopWithFade
{
    BOOL shouldContinue = NO;
    
    //rate=0 -> not playing
    if (self.player.rate != 0 && self.player.volume > FADE_STEP) {
        self.player.volume -= FADE_STEP;
        shouldContinue = YES;
    } else {
        // Stop and get the sound ready for playing again
        //There is no stop method in AVPlayer, so we pause and go to position 0
        [self.player pause];
        self.player.volume = initialVolume.floatValue;
        [self.player seekToTime:CMTimeMake(0, 1)];
    }
    
    
    if(shouldContinue) {
        [self performSelector:@selector(stopWithFade) withObject:nil afterDelay:fadeDelay.floatValue];
    }
}

- (void) loop
{
    [self stop];

    [self.player seekToTime:CMTimeMake(0, 1)];
    
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.player currentItem]];
    
    [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:CMTimeMake(0, 1)];
}

- (void)playerItemDidStall:(NSNotification *)notification
{
    //Do nothing for now
}

- (void) unload
{
    [self stop];
    
    self.player = nil;
}

- (void) setVolume:(NSNumber*) volume;
{
    
    [self.player setVolume:volume.floatValue];
    
}

- (void) setCallbackAndId:(CompleteCallback)cb audioId:(NSString*)aID
{
    self->audioId = aID;
    self->finished = cb;
}

- (void) audioPlayerDidFinishPlaying:(AVPlayer *)player successfully:(BOOL)flag
{
    if (self->finished) {
        self->finished(self->audioId);
    }
}

- (void) audioPlayerDecodeErrorDidOccur:(AVPlayer *)player error:(NSError *)error
{
    if (self->finished) {
        self->finished(self->audioId);
    }
}

- (NSTimeInterval) getDuration;
{
    
    //AVPlayerItem is not ready to give us the value, so we return 0
    if(self.player.status != AVPlayerItemStatusReadyToPlay){
        NSLog(@"NOT READY TO PLAY");
        return 0;
    }if(CMTIME_IS_INDEFINITE(self.player.currentItem.duration)){
        return 0;
    }else{
        return CMTimeGetSeconds(self.player.currentItem.duration)*1000;
    }
}

- (NSTimeInterval) getCurrentPosition;
{
    return CMTimeGetSeconds(self.player.currentTime)*1000;
}

- (void) seekTo:(NSNumber*)position;
{
    [self.player seekToTime:CMTimeMake(position.intValue, 1000)];
}

- (NSString) getTrackName;
{
    return self.trackName;
}

@end


