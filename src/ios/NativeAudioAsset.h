//
//
//  NativeAudioAsset.h
//  NativeAudioAsset
//
//  Created by Sidney Bofah on 2014-06-26.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetResourceLoader.h>

typedef void (^CompleteCallback)(NSString*);
typedef void (^PlayPauseCallback)(NSString*, BOOL);

@interface NativeAudioAsset : NSObject {
    NSString* audioId;
    CompleteCallback finished;
    PlayPauseCallback playPauseCallback;
    NSNumber *initialVolume;
    NSNumber *fadeDelay;
    NSString *trackName;
}

- (id) initWithPath:(NSString*) path withVolume:(NSNumber*) volume withFadeDelay:(NSNumber *)delay withTrackName:(NSString *)name;
- (void) play;
- (void) playWithFade;
- (void) pause;
- (void) pauseWithFade;
- (void) stop;
- (void) stopWithFade;
- (void) loop;
- (void) unload;
- (void) setVolume:(NSNumber*) volume;
- (void) setCallbackAndId:(CompleteCallback)cb audioId:(NSString*)audioId;
- (void) setPlayPauseCallbackAndId:(PlayPauseCallback)cb audioId:(NSString*)audioId;
- (void) audioPlayerDidFinishPlaying:(AVPlayer *)player successfully:(BOOL)flag;
- (void) audioPlayerDecodeErrorDidOccur:(AVPlayer *)player error:(NSError *)error;
- (NSTimeInterval) getDuration;
- (NSTimeInterval) getCurrentPosition;
- (void) seekTo:(NSNumber*) position;
- (NSString*) getTrackName;
- (void) skipForward;
- (void) skipBackward;
@end
