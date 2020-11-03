//  Converted to Swift 5.3 by Swiftify v5.3.19197 - https://swiftify.com/
//
//
//  NativeAudioAsset.swift
//  NativeAudioAsset
//
//  Created by Sidney Bofah on 2014-06-26.
//

let FADE_STEP: CGFloat = 0.05
let FADE_DELAY: CGFloat = 0.08

class NativeAudioAsset: AVAssetResourceLoaderDelegate {
    private var player: AVPlayer?

    init(path: String?, withVolume volume: NSNumber?, withFadeDelay delay: NSNumber?, withTrackName name: String?) {
        setenv("CFNETWORK_DIAGNOSTICS", "3", 1)
        super.init()
        var pathURL: URL?

        if path?.hasPrefix("http") ?? false {
            pathURL = URL(string: path ?? "")
        } else {
            pathURL = URL(fileURLWithPath: path ?? "")
        }

        var asset: AVURLAsset? = nil
        if let pathURL = pathURL {
            asset = AVURLAsset(url: pathURL, options: nil)
        }
        asset?.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        var playerItem: AVPlayerItem? = nil
        if let asset = asset {
            playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable", "duration"])
        }
        player = AVPlayer(playerItem: playerItem)

        player?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)
        player?.volume = volume?.floatValue ?? 0.0

        if let delay = delay {
            fadeDelay = delay
        } else {
            fadeDelay = NSNumber(value: Float(FADE_DELAY))
        }

        initialVolume = volume

        if let name = name {
            trackName = name
        } else {
            trackName = nil
        }
        self
    }

    func addObservers() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidStall(_:)),
            name: .AVPlayerItemPlaybackStalled,
            object: player?.currentItem)
    }

    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [String : Any]?, context: UnsafeMutableRawPointer?) {

        if (object as? AVPlayer) == player && (keyPath == "status") {
            if player?.status == .failed {
                print("AVPlayer Failed")
            } else if player?.status == .readyToPlay {
                print("AVPlayerStatusReadyToPlay")
                //[player play];
            } else if player?.status == AVPlayerItem.Status.unknown {
                print("AVPlayer Unknown")
            }
        }

        if (object as? AVPlayer) == player && (keyPath == "timeControlStatus") {
            if player?.timeControlStatus == .playing {
                print("AVPlayerTimeControlStatusPlaying")
                if let playPauseCallback = playPauseCallback {
                    playPauseCallback(audioId, true)
                }
            } else if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                print("AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate")
                if let playPauseCallback = playPauseCallback {
                    playPauseCallback(audioId, true)
                }
            } else if player?.timeControlStatus == .paused {
                print("AVPlayerTimeControlStatusPaused")
                if let playPauseCallback = playPauseCallback {
                    playPauseCallback(audioId, false)
                }
            }
        }
    }

    func play() {
        player?.play()
    }

    // The volume is increased repeatedly by the fade step amount until the last step where the audio is stopped.
    // The delay determines how fast the decrease happens
    func playWithFade() {
        //rate=0 -> not playing
        if player?.rate == 0 {
            player?.volume = 0
            player?.play()
            DispatchQueue.main.async(execute: { [self] in
                perform(#selector(playWithFade), with: nil, afterDelay: TimeInterval(fadeDelay.floatValue))
            })
        } else {
            if (player?.volume ?? 0.0) < initialVolume.floatValue {
                player?.volume += Float(FADE_STEP)
                DispatchQueue.main.async(execute: { [self] in
                    perform(#selector(playWithFade), with: nil, afterDelay: TimeInterval(fadeDelay.floatValue))
                })
            }
        }
    }

    func pause() {
        player?.pause()
    }

    // The volume is decreased repeatedly by the fade step amount until the volume reaches the configured level.
    // The delay determines how fast the increase happens
    func pauseWithFade() {
        var shouldContinue = false

        //rate=0 -> not playing
        if player?.rate != 0 && CGFloat(player?.volume ?? 0.0) > FADE_STEP {
            player?.volume -= Float(FADE_STEP)
            shouldContinue = true
        } else {
            // Pause and get the sound ready for playing again
            player?.pause()
            player?.volume = initialVolume.floatValue
        }

        if shouldContinue {
            perform(#selector(pauseWithFade), with: nil, afterDelay: TimeInterval(fadeDelay.floatValue))
        }
    }

    func stop() {
        //There is no stop method in AVPlayer, so we pause and go to position 0

        player?.pause()
        player?.seek(to: CMTimeMake(value: 0, timescale: 1))

    }

    // The volume is decreased repeatedly by the fade step amount until the volume reaches the configured level.
    // The delay determines how fast the increase happens
    func stopWithFade() {
        var shouldContinue = false

        //rate=0 -> not playing
        if player?.rate != 0 && CGFloat(player?.volume ?? 0.0) > FADE_STEP {
            player?.volume -= Float(FADE_STEP)
            shouldContinue = true
        } else {
            // Stop and get the sound ready for playing again
            //There is no stop method in AVPlayer, so we pause and go to position 0
            player?.pause()
            player?.volume = initialVolume.floatValue
            player?.seek(to: CMTimeMake(value: 0, timescale: 1))
        }


        if shouldContinue {
            perform(#selector(stopWithFade), with: nil, afterDelay: TimeInterval(fadeDelay.floatValue))
        }
    }

    func loop() {
        stop()

        player?.seek(to: CMTimeMake(value: 0, timescale: 1))

        player?.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem)

        player?.play()
    }

    @objc func playerItemDidReachEnd(_ notification: Notification?) {
        player?.seek(to: CMTimeMake(value: 0, timescale: 1))
    }

    @objc func playerItemDidStall(_ notification: Notification?) {
        //Do nothing for now
    }

    func unload() {
        stop()

        player = nil
    }

    func setVolume(_ volume: NSNumber?) {

        player?.volume = volume?.floatValue ?? 0.0

    }

    func setCallbackAndId(_ cb: CompleteCallback, audioId aID: String?) {
        audioId = aID
        finished = cb
    }

    func setPlayPauseCallbackAndId(_ cb: PlayPauseCallback, audioId aID: String?) {
        audioId = aID
        playPauseCallback = cb

    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if finished {
            finished(audioId)
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if finished {
            finished(audioId)
        }
    }

    func getDuration() -> TimeInterval {

        //AVPlayerItem is not ready to give us the value, so we return 0
        if player?.status != AVPlayerItem.Status.readyToPlay {
            print("NOT READY TO PLAY")
            return 0
        }
        if CMTIME_IS_INDEFINITE(player?.currentItem?.duration) {
            return 0
        } else {
            if let duration = player?.currentItem?.duration {
                return TimeInterval(CMTimeGetSeconds(duration) * 1000)
            }
            return 0.0
        }
    }

    func getCurrentPosition() -> TimeInterval {
        if let currentTime = player?.currentTime() {
            return TimeInterval(CMTimeGetSeconds(currentTime) * 1000)
        }
        return 0.0
    }

    func seek(to position: NSNumber?) {
        player?.seek(to: CMTimeMake(value: Int64(position?.intValue ?? 0), timescale: 1000))
    }

    func getTrackName() -> String? {
        return trackName
    }

    func skipForward() {
        if let currentTime = player?.currentTime() {
            player?.seek(to: CMTimeAdd(currentTime, CMTimeMakeWithSeconds(Float64(10), preferredTimescale: 1)))
        }
    }

    func skipBackward() {
        if let currentTime = player?.currentTime() {
            player?.seek(to: CMTimeSubtract(currentTime, CMTimeMakeWithSeconds(Float64(10), preferredTimescale: 1)))
        }
    }
}