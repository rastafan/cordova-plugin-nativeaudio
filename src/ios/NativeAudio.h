//
//
//  NativeAudio.h
//  NativeAudio
//
//  Created by Sidney Bofah on 2014-06-26.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <AVFoundation/AVPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MPRemoteCommand.h>
#import "NativeAudioAsset.h"

@interface NativeAudio : CDVPlugin
{
    NSMutableDictionary *audioMapping;
    NSMutableDictionary *controlCBMapping;
    NSMutableDictionary *completeCallbacks;
    NSMutableDictionary *playPauseCallbacks;
    NSString *currentAudioInControl;
}

#define OPT_FADE_MUSIC @"fadeMusic"

@property(assign) BOOL fadeMusic;
- (void)setOptions:(CDVInvokedUrlCommand *)command;
- (void)preloadSimple:(CDVInvokedUrlCommand *)command;
- (void)preloadComplex:(CDVInvokedUrlCommand *)command;
- (void)play:(CDVInvokedUrlCommand *)command;
- (void)stop:(CDVInvokedUrlCommand *)command;
- (void)pause:(CDVInvokedUrlCommand *)command;
- (void)loop:(CDVInvokedUrlCommand *)command;
- (void)skipForward:(NativeAudioAsset *) _asset;
- (void)skipBackward:(NativeAudioAsset *) _asset;
- (void)unload:(CDVInvokedUrlCommand *)command;
- (void)setVolumeForComplexAsset:(CDVInvokedUrlCommand *)command;
- (void)addCompleteListener:(CDVInvokedUrlCommand *)command;
- (void)addPlayPauseCallbackListener:(CDVInvokedUrlCommand *)command;
- (void)getDuration:(CDVInvokedUrlCommand *)command;
- (void)getCurrentPosition:(CDVInvokedUrlCommand *)command;
- (void)seekTo:(CDVInvokedUrlCommand *)command;
- (void)parseOptions:(NSDictionary *)options;
@end
