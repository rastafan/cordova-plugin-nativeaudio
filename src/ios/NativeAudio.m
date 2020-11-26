#import "NativeAudio.h"
#import <AVFoundation/AVAudioSession.h>
#import <MediaPlayer/MPRemoteCommandCenter.h>
#import <MediaPlayer/MPRemoteCommand.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPNowPlayingSession.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>


@implementation NativeAudio


NSString* ERROR_ASSETPATH_INCORRECT = @"(NATIVE AUDIO) Asset not found.";
NSString* ERROR_REFERENCE_EXISTS = @"(NATIVE AUDIO) Asset reference already exists.";
NSString* ERROR_REFERENCE_MISSING = @"(NATIVE AUDIO) Asset reference does not exist.";
NSString* ERROR_TYPE_RESTRICTED = @"(NATIVE AUDIO) Action restricted to assets loaded using preloadComplex().";
NSString* ERROR_VOLUME_NIL = @"(NATIVE AUDIO) Volume cannot be empty.";
NSString* ERROR_VOLUME_FORMAT = @"(NATIVE AUDIO) Volume is declared as float between 0.0 - 1.0";

NSString* INFO_ASSET_LOADED = @"(NATIVE AUDIO) Asset loaded.";
NSString* INFO_ASSET_UNLOADED = @"(NATIVE AUDIO) Asset unloaded.";
NSString* INFO_PLAYBACK_PLAY = @"(NATIVE AUDIO) Play";
NSString* INFO_PLAYBACK_STOP = @"(NATIVE AUDIO) Stop";
NSString* INFO_PLAYBACK_LOOP = @"(NATIVE AUDIO) Loop.";
NSString* INFO_VOLUME_CHANGED = @"(NATIVE AUDIO) Volume changed.";
NSString* INFO_SEEK_DONE = @"(NATIVE AUDIO) Seek done.";

NSString* INFO_DURATION_RETURNED = @"(NATIVE AUDIO) Duration returned.";

id idPlayListener = nil;
id idPauseListener = nil;
id idSkipForwardListener = nil;
id idSkipBackwardListener = nil;

- (void)pluginInitialize

{
    self.fadeMusic = NO;
    
    
    if(controlCBMapping == nil) {
        controlCBMapping = [NSMutableDictionary dictionary];
    }
    
    //AudioSessionInitialize(NULL, NULL, nil , nil); //DEPRECATED
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    // we activate the audio session after the options to mix with others is set
    [session setActive: NO error: nil];
    // NSError *setCategoryError = nil;
    
    // Allows the application to mix its audio with audio from other apps.
    if (![session setCategory:AVAudioSessionCategoryPlayback error:nil]) {
        /*if (![session setCategory:AVAudioSessionCategoryAmbient
         withOptions:AVAudioSessionCategoryOptionMixWithOthers
         error:&setCategoryError]) {*/
        
        NSLog (@"Error setting audio session category.");
        return;
    }
    
    [session setActive: YES error: nil];
    
}

- (void) parseOptions:(NSDictionary*) options
{
    if ((NSNull *)options == [NSNull null]) return;
    
    NSString* str = nil;
    
    str = [options objectForKey:OPT_FADE_MUSIC];
    if(str) self.fadeMusic = [str boolValue];
}

- (void) setOptions:(CDVInvokedUrlCommand *)command {
    if([command.arguments count] > 0) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self parseOptions:options];
    }
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) preloadSimple:(CDVInvokedUrlCommand *)command
{
    
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSString *assetPath = [arguments objectAtIndex:1];
    
    if(audioMapping == nil) {
        audioMapping = [NSMutableDictionary dictionary];
    }
    
    NSNumber* existingReference = audioMapping[audioID];
    
    [self.commandDelegate runInBackground:^{
        if (existingReference == nil) {
            
            NSString* basePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
            NSString* path = [NSString stringWithFormat:@"%@", assetPath];
            NSString* pathFromWWW = [NSString stringWithFormat:@"%@/%@", basePath, assetPath];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath : path]) {
                
                
                NSURL *pathURL = [NSURL fileURLWithPath : path];
                CFURLRef soundFileURLRef = (CFURLRef) CFBridgingRetain(pathURL);
                SystemSoundID soundID;
                AudioServicesCreateSystemSoundID(soundFileURLRef, & soundID);
                self->audioMapping[audioID] = [NSNumber numberWithInt:soundID];
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_ASSET_LOADED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else if ([[NSFileManager defaultManager] fileExistsAtPath : pathFromWWW]) {
                NSURL *pathURL = [NSURL fileURLWithPath : pathFromWWW];
                CFURLRef        soundFileURLRef = (CFURLRef) CFBridgingRetain(pathURL);
                SystemSoundID soundID;
                AudioServicesCreateSystemSoundID(soundFileURLRef, & soundID);
                self->audioMapping[audioID] = [NSNumber numberWithInt:soundID];
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_ASSET_LOADED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else {
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_ASSETPATH_INCORRECT, assetPath];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_EXISTS, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    }];
    
    
}

- (void) preloadComplex:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSString *assetPath = [arguments objectAtIndex:1];
    
    NSNumber *volume = nil;
    if ( [arguments count] > 2 ) {
        volume = [arguments objectAtIndex:2];
        if([volume isEqual:nil]) {
            volume = [NSNumber numberWithFloat:1.0f];
        }
    } else {
        volume = [NSNumber numberWithFloat:1.0f];
    }
    
    NSNumber *delay = nil;
    if ( [arguments count] > 3 && [arguments objectAtIndex:3] != [NSNull null])
    {
        // The delay is determines how fast the asset is
        // faded in and out
        delay = [arguments objectAtIndex:3];
    }
    
    NSDictionary *controlsOptions = nil;
    if ( [arguments count] > 4 && [arguments objectAtIndex:4] != [NSNull null])
    {
        // The trackName is the name shown in the RemoteCommandCenter
        controlsOptions = [arguments objectAtIndex:4];
    }
    
    if(audioMapping == nil) {
        audioMapping = [NSMutableDictionary dictionary];
    }
    
    
    NSNumber* existingReference = audioMapping[audioID];
    
    [self.commandDelegate runInBackground:^{
        if (existingReference == nil) {
            
            //If path starts with "http" we do not check for file existence on FS, since it is a stream loaded from the network.
            if ([assetPath hasPrefix:@"http"] || [[NSFileManager defaultManager] fileExistsAtPath : assetPath]) {
                NativeAudioAsset* asset = [[NativeAudioAsset alloc] initWithPath:assetPath
                                                                      withVolume:volume
                                                                   withFadeDelay:delay
                                                                withControlsInfo:controlsOptions];
                
                self->audioMapping[audioID] = asset;
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_ASSET_LOADED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else {
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_ASSETPATH_INCORRECT, assetPath];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_EXISTS, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    }];
}

- (void) play:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    BOOL setControls = [arguments objectAtIndex:1];
    
    [self.commandDelegate runInBackground:^{
        if (self->audioMapping) {
            
            NSObject* asset = self->audioMapping[audioID];
            
            if (asset != nil){
                if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                    NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                    
                    if(self.fadeMusic) {
                        // Music assets are faded in
                        [_asset playWithFade];
                    } else {
                        [_asset play];
                    }
                    
                    if(setControls){
                        
                        [[_asset getControlsInfo] setIsPlaying:true];
                        [self setControlsInfo:audioID];
                        
                        NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
                        
                        [playInfo setObject:[NSNumber numberWithDouble:[_asset getCurrentPosition]/1000] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                        [playInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                        
                        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
                        
                    }
                    
                    
                    NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_PLAYBACK_PLAY, audioID];
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                    
                } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                    NSNumber *_asset = (NSNumber*) asset;
                    AudioServicesPlaySystemSound([_asset intValue]);
                    
                    NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_PLAYBACK_PLAY, audioID];
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                    
                }
            } else {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
    }];
    
}

- (void) stop:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if ( audioMapping ) {
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                if(self.fadeMusic) {
                    // Music assets are faded out
                    [_asset stopWithFade];
                } else {
                    [_asset stop];
                }
                
                if([currentAudioInControl isEqualToString:audioID]){
                    [[_asset getControlsInfo] setIsPlaying:false];
                    
                    
                    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
                    
                    [playInfo setObject:[NSNumber numberWithInt:0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                    
                    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
                    
                }
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_PLAYBACK_STOP, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
                
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
    } else {
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];    }
}

- (void) pause:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if ( audioMapping ) {
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                if(self.fadeMusic) {
                    // Music assets are faded out
                    [_asset pauseWithFade];
                } else {
                    [_asset pause];
                }
                
                if([currentAudioInControl isEqualToString:audioID]){
                    
                    [[_asset getControlsInfo] setIsPlaying:true];
                    
                    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
                    
                    [playInfo setObject:[NSNumber numberWithDouble:[_asset getCurrentPosition]/1000] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                    [playInfo setObject:[NSNumber numberWithInt:0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                    
                    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
                    
                }
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_PLAYBACK_STOP, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
                
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    } else {
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        
    }
}



- (void) loop:(CDVInvokedUrlCommand *)command
{
    
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    BOOL setControls = [arguments objectAtIndex:1];
    
    
    if ( audioMapping ) {
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                [_asset loop];
                
                if(setControls){
                    [[_asset getControlsInfo] setIsPlaying:true];
                    [self setControlsInfo:audioID];
                    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
                    
                    [playInfo setObject:[NSNumber numberWithDouble:[_asset getCurrentPosition]/1000] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                    [playInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                    
                    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
                    
                }
                
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_PLAYBACK_LOOP, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
            else {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            
        };
    }
}

-(void) skipForward:(NativeAudioAsset *) _asset
{
    [_asset skipForward];
    
    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
    
    [playInfo setObject:[NSNumber numberWithDouble:[_asset getCurrentPosition]/1000] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
    
}

-(void) skipBackward:(NativeAudioAsset *) _asset
{
    [_asset skipBackward];
    
    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
    
    [playInfo setObject:[NSNumber numberWithDouble:[_asset getCurrentPosition]/1000] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
    
}

- (void) unload:(CDVInvokedUrlCommand *)command
{
    
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if ( audioMapping ) {
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                [_asset unload];
            } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                NSNumber *_asset = (NSNumber*) asset;
                AudioServicesDisposeSystemSoundID([_asset intValue]);
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
        [audioMapping removeObjectForKey: audioID];
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_ASSET_UNLOADED, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
    } else {
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
    
}

- (void) setVolumeForComplexAsset:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSNumber *volume = nil;
    
    if ( [arguments count] > 1 ) {
        
        volume = [arguments objectAtIndex:1];
        
        if([volume isEqual:nil]) {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_VOLUME_NIL, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
    } else if (([volume floatValue] < 0.0f) || ([volume floatValue] > 1.0f)) {
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_VOLUME_FORMAT, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
    
    if ( audioMapping ) {
        NSObject* asset = [audioMapping objectForKey: audioID];
        
        if (asset != nil){
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                [_asset setVolume:volume];
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_VOLUME_CHANGED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
                
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
    } else {
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];    }
}

- (void) sendCompleteCallback:(NSString*)forId {
    NSString* callbackId = self->completeCallbacks[forId];
    if (callbackId) {
        NSDictionary* RESULT = [NSDictionary dictionaryWithObject:forId forKey:@"id"];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:RESULT] callbackId:callbackId];
        [self->completeCallbacks removeObjectForKey:forId];
    }
}

- (void) sendPlayPauseCallback:(NSString*)forId withValue:(BOOL) playing {
    NSString* callbackId = self->playPauseCallbacks[forId];
    if (callbackId) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:playing];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

static void (mySystemSoundCompletionProc)(SystemSoundID ssID,void* clientData)
{
    NativeAudio* nativeAudio = (__bridge NativeAudio*)(clientData);
    NSNumber *idAsNum = [NSNumber numberWithInt:ssID];
    NSArray *temp = [nativeAudio->audioMapping allKeysForObject:idAsNum];
    NSString *audioID = [temp lastObject];
    
    [nativeAudio sendCompleteCallback:audioID];
    
    // Cleanup, these cb are one-shots
    AudioServicesRemoveSystemSoundCompletion(ssID);
}

- (void) addCompleteListener:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    [self.commandDelegate runInBackground:^{
        if (self->audioMapping) {
            
            NSObject* asset = self->audioMapping[audioID];
            
            if (asset != nil){
                
                if(self->completeCallbacks == nil) {
                    self->completeCallbacks = [NSMutableDictionary dictionary];
                }
                self->completeCallbacks[audioID] = command.callbackId;
                
                if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                    NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                    [_asset setCallbackAndId:^(NSString* audioID) {
                        [self sendCompleteCallback:audioID];
                    } audioId:audioID];
                    
                } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                    NSNumber *_asset = (NSNumber*) asset;
                    AudioServicesAddSystemSoundCompletion([_asset intValue],
                                                          NULL,
                                                          NULL,
                                                          mySystemSoundCompletionProc,
                                                          (__bridge void *)(self));
                }
            } else {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
    }];
}

- (void) addPlayPauseCallbackListener:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    [self.commandDelegate runInBackground:^{
        if (self->audioMapping) {
            
            NSObject* asset = self->audioMapping[audioID];
            
            if (asset != nil){
                
                if(self->playPauseCallbacks == nil) {
                    self->playPauseCallbacks = [NSMutableDictionary dictionary];
                }
                self->playPauseCallbacks[audioID] = command.callbackId;
                
                if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                    NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                    [_asset setPlayPauseCallbackAndId:^(NSString* audioID, BOOL playing) {
                        [self sendPlayPauseCallback:audioID withValue:playing];
                    } audioId:audioID];
                    
                } else if ( [asset isKindOfClass:[NSNumber class]] ) {
                    NSString *RESULT = [NSString stringWithFormat:@"Method only available for tracks loaded with PreloadComplex (%@)", audioID];
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
                }
            } else {
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
    }];
}

- (void) getDuration:(CDVInvokedUrlCommand *)command
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if (audioMapping) {
        
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                NSTimeInterval duration = [_asset getDuration];
                
                if([currentAudioInControl isEqualToString:audioID]){
                    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
                    
                    [playInfo setObject:[NSNumber numberWithDouble:duration/1000]  forKey:MPMediaItemPropertyPlaybackDuration];
                    
                    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
                }
                
                CDVPluginResult * pluginResult =[CDVPluginResult resultWithStatus : CDVCommandStatus_OK messageAsDouble: duration];
                [self.commandDelegate sendPluginResult : pluginResult callbackId : callbackId];
                
            }else{
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    } else {
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
    
}

- (void) getCurrentPosition:(CDVInvokedUrlCommand *)command;
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if (audioMapping) {
        
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                NSTimeInterval position = [_asset getCurrentPosition];
                
                CDVPluginResult * pluginResult =[CDVPluginResult resultWithStatus : CDVCommandStatus_OK messageAsDouble: position];
                [self.commandDelegate sendPluginResult : pluginResult callbackId : callbackId];
                
            }else{
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    } else {
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
    
}

- (void) seekTo:(CDVInvokedUrlCommand *)command;
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSNumber *position = [arguments objectAtIndex:1];
    
    if(position == nil){
        position = 0;
    }
    
    if (audioMapping) {
        
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            if ([asset isKindOfClass:[NativeAudioAsset class]]) {
                NativeAudioAsset *_asset = (NativeAudioAsset*) asset;
                [_asset seekTo:position];
                
                if([currentAudioInControl isEqualToString:audioID]){
                    NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
                    
                    [playInfo setObject:@([position intValue] / 1000) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                    
                    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
                }
                
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", INFO_SEEK_DONE, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: RESULT] callbackId:callbackId];
                
            }else{
                NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_TYPE_RESTRICTED, audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
            }
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    } else {
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
}

- (void) addControlsCallback:(CDVInvokedUrlCommand *)command;
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if (audioMapping) {
        
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            self->controlCBMapping[audioID] = callbackId;
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    } else {
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
}

- (void) setControls:(CDVInvokedUrlCommand *)command;
{
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    
    if (audioMapping) {
        
        NSObject* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            [self setControlsInfo:audioID];
            
        } else {
            
            NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
        }
        
    } else {
        
        NSString *RESULT = [NSString stringWithFormat:@"%@ (%@)", ERROR_REFERENCE_MISSING, audioID];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: RESULT] callbackId:callbackId];
    }
}

- (void) setControlsInfo:(NSString *) audioID
{
    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    [[remoteCommandCenter togglePlayPauseCommand] setEnabled:true];
    
    //[[remoteCommandCenter skipForwardCommand] addTarget:self action:@selector(skipForwar)];
    if(idPlayListener != nil) {
        [[remoteCommandCenter playCommand] removeTarget:idPlayListener];
        idPlayListener = nil;
    }
    idPlayListener = [[remoteCommandCenter playCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        return [self executeControlsCallback:@"music-controls-play" withAudioId:audioID];
    }];
    
    if(idPauseListener != nil) {
        [[remoteCommandCenter pauseCommand] removeTarget:idPauseListener];
        idPauseListener = nil;
    }
    idPauseListener = [[remoteCommandCenter pauseCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        return [self executeControlsCallback:@"music-controls-pause" withAudioId:audioID];
    }];
    
    if (audioMapping) {
        
        NativeAudioAsset* asset = audioMapping[audioID];
        
        if (asset != nil){
            
            MusicControlsInfo* controlsInfo = [asset getControlsInfo];
            
            
            [[remoteCommandCenter seekForwardCommand] setEnabled:[controlsInfo hasNext]];
            [[remoteCommandCenter seekBackwardCommand] setEnabled:[controlsInfo hasPrev]];
            
            [[remoteCommandCenter skipForwardCommand] setEnabled:[controlsInfo hasSkipForward]];
            [[remoteCommandCenter skipBackwardCommand] setEnabled:[controlsInfo hasSkipBackward]];
            
            if(idSkipForwardListener != nil) {
                [[remoteCommandCenter skipForwardCommand] removeTarget:idSkipForwardListener];
                idSkipForwardListener = nil;
            }
            if([controlsInfo hasSkipForward]){
                //[[remoteCommandCenter skipForwardCommand] removeTarget:<#(nullable id)#>]
                idSkipBackwardListener = [[remoteCommandCenter skipForwardCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                    return [self executeControlsCallback:@"music-controls-skip-forward" withAudioId:audioID];
                }];
            }
            
            if(idSkipBackwardListener != nil) {
                [[remoteCommandCenter skipBackwardCommand] removeTarget:idSkipBackwardListener];
                idSkipBackwardListener = nil;
            }
            if([controlsInfo hasSkipBackward]){
                idSkipBackwardListener = [[remoteCommandCenter skipBackwardCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                    return [self executeControlsCallback:@"music-controls-skip-backward" withAudioId:audioID];
                }];
            }
            
            
            NSMutableDictionary *playInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo] ;
            
            [playInfo setObject:[NSString stringWithFormat:@"%@", [asset getTrackName] ] forKey:MPMediaItemPropertyTitle];
            //[playInfo setObject:[NSNumber numberWithInt:0] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            //[playInfo setObject:[NSNumber numberWithInt:0] forKey:MPMediaItemPropertyPlaybackDuration];
            [playInfo setObject:[NSString stringWithFormat:@"%@", [controlsInfo track]] forKey:MPMediaItemPropertyTitle];
            [playInfo setObject:[NSString stringWithFormat:@"%@", [controlsInfo artist]] forKey:MPMediaItemPropertyArtist];
            [playInfo setObject:[NSString stringWithFormat:@"%@", [controlsInfo album]] forKey:MPMediaItemPropertyAlbumTitle];
            
            MPMediaItemArtwork * mediaItemArtwork = [self createCoverArtwork:[controlsInfo cover]];
            if (mediaItemArtwork != nil) {
                [playInfo setObject:mediaItemArtwork forKey:MPMediaItemPropertyArtwork];
            }
            
            
            [playInfo setObject:[NSNumber numberWithBool:[controlsInfo isPlaying]] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            
            [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playInfo;
            
            currentAudioInControl = audioID;
            
        } else {
            NSLog(@"setControlsInfo - NO ASSET FOUND");
        }
        
    } else {
        NSLog(@"setControlsInfo - NO AUDIO MAPPING FOUND");
    }
}

- (MPRemoteCommandHandlerStatus) executeControlsCallback:(NSString *) action withAudioId:(NSString *) audioID {
    NSString *callbackId = self->controlCBMapping[audioID];
    
    if(callbackId) {
        NSString * jsonAction = [NSString stringWithFormat:@"{\"message\":\"%@\"}", action];
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonAction];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        return MPRemoteCommandHandlerStatusSuccess;
    } else {
        return MPRemoteCommandHandlerStatusCommandFailed;
    }
}

- (MPMediaItemArtwork *) createCoverArtwork: (NSString *) coverUri {
    UIImage * coverImage = nil;
    
    if (coverUri == nil) {
        return nil;
    }
    
    if ([coverUri hasPrefix:@"http://"] || [coverUri hasPrefix:@"https://"]) {
        NSURL * coverImageUrl = [NSURL URLWithString:coverUri];
        NSData * coverImageData = [NSData dataWithContentsOfURL: coverImageUrl];
        
        coverImage = [UIImage imageWithData: coverImageData];
    }
    else if ([coverUri hasPrefix:@"file://"]) {
        NSString * fullCoverImagePath = [coverUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath: fullCoverImagePath]) {
            coverImage = [[UIImage alloc] initWithContentsOfFile: fullCoverImagePath];
        }
    }
    else if (![coverUri isEqual:@""]) {
        NSString * baseCoverImagePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString * fullCoverImagePath = [NSString stringWithFormat:@"%@%@", baseCoverImagePath, coverUri];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullCoverImagePath]) {
            coverImage = [UIImage imageNamed:fullCoverImagePath];
        }
    }
    else {
        coverImage = [UIImage imageNamed:@"none"];
    }
    
    return [self isCoverImageValid:coverImage] ? [[MPMediaItemArtwork alloc] initWithBoundsSize:coverImage.size requestHandler:^UIImage * _Nonnull(CGSize size) {
        return coverImage;
    }] : nil;
    //return [self isCoverImageValid:coverImage] ? [[MPMediaItemArtwork alloc] initWithImage:coverImage] : nil;
}

- (bool) isCoverImageValid: (UIImage *) coverImage {
    return coverImage != nil && ([coverImage CIImage] != nil || [coverImage CGImage] != nil);
}
@end
