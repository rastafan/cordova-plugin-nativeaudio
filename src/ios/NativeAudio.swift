//  Converted to Swift 5.3 by Swiftify v5.3.19197 - https://swiftify.com/
import AVFoundation
import MediaPlayer

// Cleanup, these cb are one-shots
AudioServicesRemoveSystemSoundCompletion(ssID)
var callbackId = command.callbackId
var arguments = command.arguments
var audioID = arguments[0] as? String
var asset = audioMapping[audioID ?? ""] as? NSObject
var _asset = asset as? NativeAudioAsset
var _asset = asset as? NSNumber
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var callbackId = command.callbackId
var arguments = command.arguments
var audioID = arguments[0] as? String
var asset = audioMapping[audioID ?? ""] as? NSObject
var _asset = asset as? NativeAudioAsset
var audioID: String?
var aBOOL: String = ""
var RESULT = "Method only available for tracks loaded with PreloadComplex (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var callbackId = command.callbackId
var arguments = command.arguments
var audioID = arguments[0] as? String
var asset = audioMapping[audioID ?? ""]
var _asset = asset as? NativeAudioAsset
var duration = _asset?.getDuration() ?? 0.0
var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDouble: duration)
var RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var callbackId = command.callbackId
var arguments = command.arguments
var audioID = arguments[0] as? String
var asset = audioMapping[audioID ?? ""]
var _asset = asset as? NativeAudioAsset
var position = _asset?.getCurrentPosition() ?? 0.0
var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDouble: position)
var RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var callbackId = command.callbackId
var arguments = command.arguments
var audioID = arguments[0] as? String
var position = arguments[1] as? NSNumber
var asset = audioMapping[audioID ?? ""]
var _asset = asset as? NativeAudioAsset
var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
var RESULT = "\(INFO_SEEK_DONE) (\(audioID ?? ""))"
var RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
var RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"

var ERROR_ASSETPATH_INCORRECT = "(NATIVE AUDIO) Asset not found."
var ERROR_REFERENCE_EXISTS = "(NATIVE AUDIO) Asset reference already exists."
var ERROR_REFERENCE_MISSING = "(NATIVE AUDIO) Asset reference does not exist."
var ERROR_TYPE_RESTRICTED = "(NATIVE AUDIO) Action restricted to assets loaded using preloadComplex()."
var ERROR_VOLUME_NIL = "(NATIVE AUDIO) Volume cannot be empty."
var ERROR_VOLUME_FORMAT = "(NATIVE AUDIO) Volume is declared as float between 0.0 - 1.0"
var INFO_ASSET_LOADED = "(NATIVE AUDIO) Asset loaded."
var INFO_ASSET_UNLOADED = "(NATIVE AUDIO) Asset unloaded."
var INFO_PLAYBACK_PLAY = "(NATIVE AUDIO) Play"
var INFO_PLAYBACK_STOP = "(NATIVE AUDIO) Stop"
var INFO_PLAYBACK_LOOP = "(NATIVE AUDIO) Loop."
var INFO_VOLUME_CHANGED = "(NATIVE AUDIO) Volume changed."
var INFO_SEEK_DONE = "(NATIVE AUDIO) Seek done."
var INFO_DURATION_RETURNED = "(NATIVE AUDIO) Duration returned."
var: Void?
var ssID: SystemSoundID = 0
    var clientData: SystemSoundID?
var nativeAudio = clientData as? NativeAudio
var idAsNum = NSNumber(value: Int32(ssID))
var temp = nativeAudio?.audioMapping.allKeys(for: idAsNum)
var audioID = temp?.last as? String

class NativeAudio {
    func pluginInitialize() {
        fadeMusic = false

        //AudioSessionInitialize(NULL, NULL, nil , nil); //DEPRECATED
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }

        let session = AVAudioSession.sharedInstance()
        // we activate the audio session after the options to mix with others is set
        do {
            try session.setActive(false)
        } catch {
        }
        // NSError *setCategoryError = nil;

        // Allows the application to mix its audio with audio from other apps.
        do {
            try session.setCategory(.playback)
        } catch {
            /*if (![session setCategory:AVAudioSessionCategoryAmbient
                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                     error:&setCategoryError]) {*/

            print("Error setting audio session category.")
            return
        }

        do {
            try session.setActive(true)
        } catch {
        }

    }

    func parseOptions(_ options: [AnyHashable : Any]?) {
        if options as? NSNull == NSNull() {
            return
        }

        var str: String? = nil

        str = options?[OPT_FADE_MUSIC] as? String
        if let str = str {
            fadeMusic = (str as NSString).boolValue
        }
    }

    func setOptions(_ command: CDVInvokedUrlCommand?) {
        if (command?.arguments.count() ?? 0) > 0 {
            let options = command?.argument(atIndex: 0, withDefault: NSNull())
            parseOptions(options)
        }

        commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command?.callbackId)
    }

    func preloadSimple(_ command: CDVInvokedUrlCommand?) {

        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String
        let assetPath = arguments?[1] as? String

        if audioMapping == nil {
            audioMapping = [AnyHashable : Any]()
        }

        let existingReference = audioMapping[audioID ?? ""]

        commandDelegate.run(inBackground: { [self] in
            if existingReference == nil {

                let basePath = URL(fileURLWithPath: Bundle.main.resourcePath ?? "").appendingPathComponent("www").path
                let path = "\(assetPath ?? "")"
                let pathFromWWW = "\(basePath)/\(assetPath ?? "")"

                if FileManager.default.fileExists(atPath: path) {


                    let pathURL = URL(fileURLWithPath: path)
                    let soundFileURLRef = CFBridgingRetain(pathURL) as? CFURL?
                    var soundID: SystemSoundID
                    if let soundFileURLRef = soundFileURLRef {
                        AudioServicesCreateSystemSoundID(soundFileURLRef, UnsafeMutablePointer<SystemSoundID>(mutating: &soundID))
                    }
                    audioMapping[audioID ?? ""] = NSNumber(value: Int32(soundID))

                    let RESULT = "\(INFO_ASSET_LOADED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else if FileManager.default.fileExists(atPath: pathFromWWW) {
                    let pathURL = URL(fileURLWithPath: pathFromWWW)
                    let soundFileURLRef = CFBridgingRetain(pathURL) as? CFURL?
                    var soundID: SystemSoundID
                    if let soundFileURLRef = soundFileURLRef {
                        AudioServicesCreateSystemSoundID(soundFileURLRef, UnsafeMutablePointer<SystemSoundID>(mutating: &soundID))
                    }
                    audioMapping[audioID ?? ""] = NSNumber(value: Int32(soundID))

                    let RESULT = "\(INFO_ASSET_LOADED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else {
                    let RESULT = "\(ERROR_ASSETPATH_INCORRECT) (\(assetPath ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_EXISTS) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }

        })


    }

    func preloadComplex(_ command: CDVInvokedUrlCommand?) {
        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String
        let assetPath = arguments?[1] as? String

        var volume: NSNumber? = nil
        if (arguments?.count ?? 0) > 2 {
            volume = arguments?[2] as? NSNumber
            if volume == nil {
                volume = NSNumber(value: 1.0)
            }
        } else {
            volume = NSNumber(value: 1.0)
        }

        var delay: NSNumber? = nil
        if (arguments?.count ?? 0) > 3 && arguments?[3] != NSNull() {
            // The delay is determines how fast the asset is
            // faded in and out
            delay = arguments?[3] as? NSNumber
        }

        var trackName: String? = nil
        if (arguments?.count ?? 0) > 4 && arguments?[4] != NSNull() {
            // The trackName is the name shown in the RemoteCommandCenter
            trackName = arguments?[4] as? String
        }

        if audioMapping == nil {
            audioMapping = [AnyHashable : Any]()
        }

        let existingReference = audioMapping[audioID ?? ""]

        commandDelegate.run(inBackground: { [self] in
            if existingReference == nil {

                //If path starts with "http" we do not check for file existence on FS, since it is a stream loaded from the network.
                if assetPath?.hasPrefix("http") ?? false || FileManager.default.fileExists(atPath: assetPath ?? "") {
                    let asset = NativeAudioAsset(
                        path: assetPath,
                        withVolume: volume,
                        withFadeDelay: delay,
                        withTrackName: trackName)

                    audioMapping[audioID ?? ""] = asset

                    let RESULT = "\(INFO_ASSET_LOADED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else {
                    let RESULT = "\(ERROR_ASSETPATH_INCORRECT) (\(assetPath ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_EXISTS) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }

        })
    }

    func play(_ command: CDVInvokedUrlCommand?) -> MPRemoteCommandHandlerStatus {
        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String

        commandDelegate.run(inBackground: { [self] in
            if audioMapping {

                let asset = audioMapping[audioID ?? ""] as? NSObject

                if let asset = asset {
                    if asset is NativeAudioAsset {
                        let _asset = asset as? NativeAudioAsset

                        if fadeMusic {
                            // Music assets are faded in
                            _asset?.playWithFade()
                        } else {
                            _asset?.play()
                        }

                        let remoteCommandCenter = MPRemoteCommandCenter.shared()
                        //[[remoteCommandCenter skipForwardCommand] addTarget:self action:@selector(skipForwar)];
                        remoteCommandCenter.playCommand.addTarget(handler: { [self] event in
                            return play(command)
                        })
                        remoteCommandCenter.pauseCommand.addTarget(handler: { [self] event in
                            return pause(command)
                        })

                        let trackName = _asset?.getTrackName()
                        if trackName != nil {

                            remoteCommandCenter.seekForwardCommand.isEnabled = false
                            remoteCommandCenter.seekBackwardCommand.isEnabled = false

                            remoteCommandCenter.skipForwardCommand.isEnabled = true
                            remoteCommandCenter.skipBackwardCommand.isEnabled = true

                            remoteCommandCenter.skipForwardCommand.addTarget(handler: { [self] event in
                                return skipForward(_asset)
                            })

                            remoteCommandCenter.skipBackwardCommand.addTarget(handler: { [self] event in
                                return skipBackward(_asset)
                            })


                            var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo

                            if let get = _asset?.getTrackName() {
                                playInfo[MPMediaItemPropertyTitle] = "\(get)"
                            }
                            playInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: (_asset?.getCurrentPosition() ?? 0) / 1000)
                            playInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: (_asset?.getDuration() ?? 0) / 1000)
                            playInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1)

                            MPNowPlayingInfoCenter.default().nowPlayingInfo = playInfo as? [String : Any]
                        }


                        let RESULT = "\(INFO_PLAYBACK_PLAY) (\(audioID ?? ""))"
                        commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                    } else if asset is NSNumber {
                        let _asset = asset as? NSNumber
                        AudioServicesPlaySystemSound(SystemSoundID(_asset?.intValue ?? 0))

                        let RESULT = "\(INFO_PLAYBACK_PLAY) (\(audioID ?? ""))"
                        commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                    }
                } else {

                    let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }
        })

        return .success
    }

    func stop(_ command: CDVInvokedUrlCommand?) {
        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String

        if audioMapping {
            let asset = audioMapping[audioID ?? ""]

            if let asset = asset {

                if asset is NativeAudioAsset {
                    let _asset = asset as? NativeAudioAsset
                    if fadeMusic {
                        // Music assets are faded out
                        _asset?.stopWithFade()
                    } else {
                        _asset?.stop()
                    }

                    if _asset?.getTrackName() != nil {
                        var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo

                        playInfo[MPMediaItemPropertyTitle] = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")

                        playInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: 0)
                        playInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: 0)
                        playInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 0)

                        MPNowPlayingInfoCenter.default().nowPlayingInfo = playInfo as? [String : Any]
                    }

                    let RESULT = "\(INFO_PLAYBACK_STOP) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else if asset is NSNumber {

                    let RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }
        } else {
            let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
        }
    }

    func pause(_ command: CDVInvokedUrlCommand?) -> MPRemoteCommandHandlerStatus {
        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String

        if audioMapping {
            let asset = audioMapping[audioID ?? ""]

            if let asset = asset {

                if asset is NativeAudioAsset {
                    let _asset = asset as? NativeAudioAsset
                    if fadeMusic {
                        // Music assets are faded out
                        _asset?.pauseWithFade()
                    } else {
                        _asset?.pause()
                    }

                    if _asset?.getTrackName() != nil {
                        var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo

                        playInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: (_asset?.getCurrentPosition() ?? 0) / 1000)
                        playInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 0)

                        MPNowPlayingInfoCenter.default().nowPlayingInfo = playInfo as? [String : Any]
                    }

                    let RESULT = "\(INFO_PLAYBACK_STOP) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else if asset is NSNumber {

                    let RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }

            return .success
        } else {
            let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)

            return .commandFailed
        }
    }

    func loop(_ command: CDVInvokedUrlCommand?) -> MPRemoteCommandHandlerStatus {

        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String


        if audioMapping {
            let asset = audioMapping[audioID ?? ""]

            if let asset = asset {


                if asset is NativeAudioAsset {
                    let _asset = asset as? NativeAudioAsset
                    _asset?.loop()

                    let remoteCommandCenter = MPRemoteCommandCenter.shared()
                    //[[remoteCommandCenter skipForwardCommand] addTarget:self action:@selector(skipForwar)];
                    remoteCommandCenter.playCommand.addTarget(handler: { [self] event in
                        return loop(command)
                    })
                    remoteCommandCenter.pauseCommand.addTarget(handler: { [self] event in
                        return pause(command)
                    })

                    let trackName = _asset?.getTrackName()
                    if trackName != nil {
                        remoteCommandCenter.seekForwardCommand.isEnabled = false
                        remoteCommandCenter.seekBackwardCommand.isEnabled = false

                        remoteCommandCenter.skipForwardCommand.isEnabled = true
                        remoteCommandCenter.skipBackwardCommand.isEnabled = true

                        remoteCommandCenter.skipForwardCommand.addTarget(handler: { [self] event in
                            return skipForward(_asset)
                        })

                        remoteCommandCenter.skipBackwardCommand.addTarget(handler: { [self] event in
                            return skipBackward(_asset)
                        })


                        var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo

                        if let get = _asset?.getTrackName() {
                            playInfo[MPMediaItemPropertyTitle] = "\(get)"
                        }
                        playInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: (_asset?.getCurrentPosition() ?? 0) / 1000)
                        playInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: (_asset?.getDuration() ?? 0) / 1000)
                        playInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1)

                        MPNowPlayingInfoCenter.default().nowPlayingInfo = playInfo as? [String : Any]
                    }

                    let RESULT = "\(INFO_PLAYBACK_LOOP) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else if asset is NSNumber {
                    let RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                } else {

                    let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }

                return .success
            } else {
                let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)

                return .commandFailed
            }
        } else {
            return .commandFailed
        }
    }

    func skipForward(_ _asset: NativeAudioAsset?) -> MPRemoteCommandHandlerStatus {
        _asset?.skipForward()

        var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo

        playInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: (_asset?.getCurrentPosition() ?? 0) / 1000)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = playInfo as? [String : Any]

        return .success
    }

    func skipBackward(_ _asset: NativeAudioAsset?) -> MPRemoteCommandHandlerStatus {
        _asset?.skipBackward()

        var playInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo

        playInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: (_asset?.getCurrentPosition() ?? 0) / 1000)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = playInfo as? [String : Any]

        return .success
    }

    func unload(_ command: CDVInvokedUrlCommand?) {

        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String

        if audioMapping {
            let asset = audioMapping[audioID ?? ""]

            if let asset = asset {


                if asset is NativeAudioAsset {
                    let _asset = asset as? NativeAudioAsset
                    _asset?.unload()
                } else if asset is NSNumber {
                    let _asset = asset as? NSNumber
                    AudioServicesDisposeSystemSoundID(SystemSoundID(_asset?.intValue ?? 0))
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }

            audioMapping.removeObject(forKey: audioID ?? "")

            let RESULT = "\(INFO_ASSET_UNLOADED) (\(audioID ?? ""))"
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
        } else {
            let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
        }

    }

    func setVolumeForComplexAsset(_ command: CDVInvokedUrlCommand?) {
        let callbackId = command?.callbackId
        let arguments = command?.arguments
        let audioID = arguments?[0] as? String
        var volume: NSNumber? = nil

        if (arguments?.count ?? 0) > 1 {

            volume = arguments?[1] as? NSNumber

            if volume == nil {

                let RESULT = "\(ERROR_VOLUME_NIL) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }
        } else if (volume?.floatValue ?? 0.0 < 0.0) || (volume?.floatValue ?? 0.0 > 1.0) {

            let RESULT = "\(ERROR_VOLUME_FORMAT) (\(audioID ?? ""))"
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
        }

        if audioMapping {
            let asset = audioMapping[audioID ?? ""] as? NSObject

            if let asset = asset {

                if asset is NativeAudioAsset {
                    let _asset = asset as? NativeAudioAsset
                    _asset?.volume = volume

                    let RESULT = "\(INFO_VOLUME_CHANGED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: RESULT), callbackId: callbackId)
                } else if asset is NSNumber {

                    let RESULT = "\(ERROR_TYPE_RESTRICTED) (\(audioID ?? ""))"
                    commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
                }
            } else {

                let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
                commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
            }
        } else {
            let RESULT = "\(ERROR_REFERENCE_MISSING) (\(audioID ?? ""))"
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: RESULT), callbackId: callbackId)
        }
    }

    func sendCompleteCallback(_ forId: String?) {
        let callbackId = completeCallbacks[forId ?? ""] as? String
        if let callbackId = callbackId {
            let RESULT = ["id" : forId ?? ""]
            commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: RESULT), callbackId: callbackId)
            completeCallbacks.removeObject(forKey: forId ?? "")
        }
    }

    func sendPlayPauseCallback(_ forId: String?, withValue playing: Bool) {
        let callbackId = playPauseCallbacks[forId ?? ""] as? String
        if let callbackId = callbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: playing)
            result.keepCallbackAsBool = true
            commandDelegate.send(result, callbackId: callbackId)
        }
    }
}