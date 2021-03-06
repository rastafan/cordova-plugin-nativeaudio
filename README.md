# Cordova Native Audio Plugin

Cordova / PhoneGap 3.5+ extension for Native Audio playback, aimed at HTML5 gaming and audio applications which require minimum latency, polyphony and concurrency.

## Contents

1. [Description](#description)
2. [History](#history)
3. [Roadmap](#next-steps)
5. [Integration](#integration)
7. [Supported Platforms](#supported-platforms)
8. [Installation](#installation)
9. [Usage](#usage)
10. [API](#api)
11. [Demo](#demo)
12. [Example](#example)

## Description

This Cordova / PhoneGap (3.5+) plugin enables concurrency (multi-channel playback) and minimized latency (via caching) in audio-based applications, by leveraging native audio APIs. Designed for the use in HTML5-based cross-platform games and mobile/hybrid audio applications.

## History

This plugin is a fork of [this plugin](https://github.com/floatinghotpot/cordova-plugin-nativeaudio), which in turn is a community-driven, clean fork of the Low Latency Audio Plugin for Cordova / PhoneGap, initially published by [Andrew Trice](http://www.tricedesigns.com/2012/01/25/low-latency-polyphonic-audio-in-phonegap/) and then maintained by [Raymond Xie](http://github.com/floatinghotpot/) and [Sidney Bofah](https://github.com/SidneyS/).

In addition to the clean-up of legacy code and callbacks, this fork uses AVPlayer for iOS, fixes some caveats with the original project, and can reproduce streaming audio from http/https.

Also, Media Controls are integrated to control audio flow from outside the app. Media Controls have been integrated using the code of [this plugin by ghenry22 and homerours](https://github.com/ghenry22/cordova-plugin-music-controls2). Thank you!

## Roadmap

Following the Cordova philosophy, this is a shim for a web audio implementation (on mobile) which is as fast and feature-rich as native mobile APIs. Currently, neither HTML5 Audio or the more recent Web Audio API offer a cross-platform solution which 1) is fast, 2) supports concurrency and 3) maintains a low overhead.

It should be replaced by a standardised W3C solution as soon as such an implementation offers comparable performance across (mobile) devices, which is crucial for HTML5-based games.

## Integration

This plugin is available as an AngularJS service module, facilitating the usage in AngularJS-based Cordova/PhoneGap projects.

It extends the ngCordova project, an effort by the great guys at [Drifty](http://github.com/driftyco), creators of the Ionic Framework.
Download it at the ngCordova [website](http://www.ngcordova.com) or the [repository](http://www.github.com/driftyco/ng-cordova).

## Supported Platforms

* iOS (tested with 10, 11, 13)
* Android (tested in API levels 26 - 27 - 28)

## Installation

Via Cordova CLI:
```bash
cordova plugin add cordova-plugin-nativeaudio
```

##Usage


1. Wait for `deviceReady`.
1. Preload an audio asset and assign an id - either optimized for single-shot style short clips (`preloadSimple()`) or looping, ambient background audio (`preloadComplex()`)
2. `play()` the audio asset via its id.
3. `unload()` the audio asset via its id.

##API

###Preloading

```javascript
preloadSimple: function ( id, assetPath, successCallback, errorCallback)
```
Loads an audio file into memory. Optimized for short clips / single shots (up to five seconds).
Cannot be stopped / looped.

Uses lower-level native APIs with small footprint (iOS: AudioToolbox/AudioServices).
Fully concurrent and multichannel.

* params
 * id - string unique ID for the audio file
 * assetPath - the relative path or absolute URL (inluding http://) to the audio asset.
 * successCallback - success callback function
 * errorCallback - error callback function


```javascript
preloadComplex: function(id, assetPath, volume, delay, options, successCallback, errorCallback) 
```

Loads an audio file into memory. Optimized for background music / ambient sound.
Uses highlevel native APIs with a larger footprint. (iOS: AVAudioPlayer).
Can be stopped / looped. Can be faded in and out using the delay parameter.

The "options" parameter takes a configuration object for mediaControls.
These options are bound to the audioID used to load the file.
If you give controls to another track, the options from that track will apply.
It takes the same parameters as [cordova-plugin-music-controls2 plugin](https://github.com/ghenry22/cordova-plugin-music-controls2):

```javascript
MusicControls.create({
	track       : 'Time is Running Out',		// optional, default : ''
	artist      : 'Muse',						// optional, default : ''
	album       : 'Absolution',     // optional, default: ''
 	cover       : 'albums/absolution.jpg',		// optional, default : nothing
	// cover can be a local path (use fullpath 'file:///storage/emulated/...', or only 'my_image.jpg' if my_image.jpg is in the www folder of your app)
	//			 or a remote url ('http://...', 'https://...', 'ftp://...')
	isPlaying   : true,							// optional, default : true
	dismissable : true,							// optional, default : false

	// hide previous/next/close buttons:
	hasPrev   : false,		// show previous button, optional, default: true
	hasNext   : false,		// show next button, optional, default: true
	hasClose  : true,		// show close button, optional, default: false

	// iOS only, optional
	
	duration : 60, // optional, default: 0
	elapsed : 10, // optional, default: 0
  	hasSkipForward : true, //optional, default: false. true value overrides hasNext.
  	hasSkipBackward : true, //optional, default: false. true value overrides hasPrev.
  	skipForwardInterval : 15, //optional. default: 0.
	skipBackwardInterval : 15, //optional. default: 0.
	hasScrubbing : false, //optional. default to false. Enable scrubbing from control center progress bar 

	// Android only, optional
	// text displayed in the status bar when the notification (and the ticker) are updated
	ticker	  : 'Now playing "Time is Running Out"',
	//All icons default to their built-in android equivalents
	//The supplied drawable name, e.g. 'media_play', is the name of a drawable found under android/res/drawable* folders
	playIcon: 'media_play',
	pauseIcon: 'media_pause',
	prevIcon: 'media_prev',
	nextIcon: 'media_next',
	closeIcon: 'media_close',
	notificationIcon: 'notification'
}, onSuccess, onError);
```

####Volume & Voices

The default **volume** is 1.0, a lower default can be set by using a numerical value from 0.1 to 1.0.

Change the float-based **delay** parameter to increase the fade-in/fade-out timing.

**SUPPORT FOR VOICES HAS BEEN REMOVED IN THIS PLUGIN**

### Playback

* params
 * id - string unique ID for the audio file
 * assetPath - the relative path to the audio asset within the www directory
 * volume - the volume of the preloaded sound (0.1 to 1.0)
 * successCallback - success callback function
 * errorCallback - error callback function


```javascript
addControlsCallback: function(id, successCallback, errorCallback)
```

Sets the callback for the Media Controls. Each time an event is fired, it will go through thid callback.
Again, this piece reflects what is stated in the [cordova-plugin-music-controls2 plugin](https://github.com/ghenry22/cordova-plugin-music-controls2).
Below are shown some of them, check the plugin code to see all of them, or just console.log the returned value if you need one event in particular.

```javascript
function events(action) {

  const message = JSON.parse(action).message;
	switch(message) {
		case 'music-controls-next':
			// Do something
			break;
		case 'music-controls-previous':
			// Do something
			break;
		case 'music-controls-pause':
			// Do something
			break;
		case 'music-controls-play':
			// Do something
			break;
		case 'music-controls-destroy':
			// Do something
			break;

		// External controls (iOS only)
    	case 'music-controls-toggle-play-pause' :
			// Do something
			break;
    	case 'music-controls-seek-to':
			const seekToInSeconds = JSON.parse(action).position;
			MusicControls.updateElapsed({
				elapsed: seekToInSeconds,
				isPlaying: true
			});
			// Do something
			break;

		// Headset events (Android only)
		// All media button events are listed below
		case 'music-controls-media-button' :
			// Do something
			break;
		case 'music-controls-headset-unplugged':
			// Do something
			break;
		case 'music-controls-headset-plugged':
			// Do something
			break;
		default:
			break;
	}
}
```



```javascript
setControls: function(id, successCallback, errorCallback)
```
Sets the controls to the audio file with the specified id. The controls will then manage that track in particular


```javascript
play: function(id, setControls, successCallback, errorCallback, completeCallback)
```
Plays an audio asset.

* params:
 * id - string unique ID for the audio file
 * setControls - boolean, true if the controls should be bound to this track
 * successCallback - success callback function
 * errorCallback - error callback function
 * completeCallback - error callback function


```javascript
loop: function (id, setControls, successCallback, errorCallback)
```
Loops an audio asset infinitely - this only works for assets loaded via preloadComplex.

* params
 * id - string unique ID for the audio file
 * setControls - boolean, true if the controls should be bound to this track
 * successCallback - success callback function
 * errorCallback - error callback function


```javascript
stop: function (id, successCallback, errorCallback)
```

Stops an audio file. Only works for assets loaded via preloadComplex.

* params:
 * ID - string unique ID for the audio file
 * successCallback - success callback function
 * errorCallback - error callback function

```javascript
unload: function (id, successCallback, errorCallback)
```

Unloads an audio file from memory.


* params:
 * ID - string unique ID for the audio file
 * successCallback - success callback function
 * errorCallback - error callback function

```javascript
setVolumeForComplexAsset: function (id, volume, successCallback, errorCallback)
```

Changes the volume for preloaded complex assets.
 
 
* params:
 * ID - string unique ID for the audio file
 * volume - the volume of the audio asset (0.1 to 1.0)
 * successCallback - success callback function
 * errorCallback - error callback function

## Example Code

In this example, the resources reside in a relative path under the Cordova root folder "www/".

```javascript
if( window.plugins && window.plugins.NativeAudio ) {
	
	// Preload audio resources
	window.plugins.NativeAudio.preloadComplex( 'music', 'audio/music.mp3', 1, 1, 0, function(msg){
	}, function(msg){
		console.log( 'error: ' + msg );
	});
	
	window.plugins.NativeAudio.preloadSimple( 'click', 'audio/click.mp3', function(msg){
	}, function(msg){
		console.log( 'error: ' + msg );
	});


	// Play
	window.plugins.NativeAudio.play( 'click' );
	window.plugins.NativeAudio.loop( 'music' );


	// Stop multichannel clip after 60 seconds
	window.setTimeout( function(){

		window.plugins.NativeAudio.stop( 'music' );
			
		window.plugins.NativeAudio.unload( 'music' );
		window.plugins.NativeAudio.unload( 'click' );

	}, 1000 * 60 );
}
```

## Demo

The **Drumpad** in the examples directory is a first starting point.

```bash
[sudo] npm install plugin-verify -g
plugin-verify cordova-plugin-nativeaudio ios
plugin-verify cordova-plugin-nativeaudio android
```

Or, type the commands step by step:

```bash
cordova create drumpad com.example.nativeaudio drumpad
cd drumpad
cordova platform add ios
cordova plugin add cordova-plugin-nativeaudio
rm -r www/*
cp -r plugins/cordova-plugin-nativeaudio/test/* www
cordova build ios
cordova emulate ios
```
