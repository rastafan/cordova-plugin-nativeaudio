//
//
//  NativeAudio.java
//
//  Created by Sidney Bofah on 2014-06-26.
//

package com.rastafan.cordova.plugin.nativeaudio;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.Callable;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;

import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.net.Uri;
import android.os.IBinder;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;
import android.view.KeyEvent;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONObject;


public class NativeAudio extends CordovaPlugin implements AudioManager.OnAudioFocusChangeListener {

	interface CallbackInterface {
		void success(String message);
	}


	/* options */
	public static final String OPT_FADE_MUSIC = "fadeMusic";

	public static final String ERROR_NO_AUDIOID="A reference does not exist for the specified audio id.";
	public static final String ERROR_AUDIOID_EXISTS="A reference already exists for the specified audio id.";

	public static final String SET_OPTIONS="setOptions";
	public static final String PRELOAD_SIMPLE="preloadSimple";
	public static final String PRELOAD_COMPLEX="preloadComplex";
	public static final String PLAY="play";
	public static final String STOP="stop";
	public static final String LOOP="loop";
	public static final String UNLOAD="unload";
	public static final String ADD_COMPLETE_LISTENER="addCompleteListener";
	public static final String SET_VOLUME_FOR_COMPLEX_ASSET="setVolumeForComplexAsset";
	public static final String ADD_CONTROLS_CALLBACK="addControlsCallback";

	private final int notificationID=7824;
	private boolean mediaButtonAccess=true;

	public static final String GET_CURRENT_POSITION="getCurrentPosition";
	public static final String PAUSE="pause";
	public static final String GET_DURATION="getDuration";
	public static final String SEEK_TO="seekTo";
	public static final String SET_CONTROLS="setControls";

	private static final String LOGTAG = "NativeAudio";

	private static HashMap<String, NativeAudioAsset> assetMap;
	private static HashMap<String, CallbackContext> controlsCallbackMap; // Mappa dei callback dei controlli
	private static ArrayList<NativeAudioAsset> resumeList;
	private static HashMap<String, CallbackContext> completeCallbacks;
	private boolean fadeMusic = false;

	private MediaSessionCallback mMediaSessionCallback = new MediaSessionCallback();
	private MusicControlsNotification notification;

	private PendingIntent mediaButtonPendingIntent;
	private AudioManager mAudioManager;

	private MediaSessionCompat mediaSessionCompat;

	private MusicControlsBroadcastReceiver mMessageReceiver;

	private String currentAudioInControl = null; // Conterrà l'audioID della traccia legata ai controlli

	public void setOptions(JSONObject options) {
		if(options != null) {
			if(options.has(OPT_FADE_MUSIC)) this.fadeMusic = options.optBoolean(OPT_FADE_MUSIC);
		}
	}

	//INIZIALIZZAZIONE COMPLETA CON NOTIFICA PER CONTROLLI AUDIO

	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);

		this.mediaSessionCompat = new MediaSessionCompat(cordova.getContext(), "cordova-music-controls-media-session", null, this.mediaButtonPendingIntent);
		this.mediaSessionCompat.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS | MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS);

		this.mediaSessionCompat.setActive(true);

		this.notification = new MusicControlsNotification(cordova.getActivity(),this.notificationID);

		this.mMessageReceiver = new MusicControlsBroadcastReceiver(this);
		this.registerBroadcaster(mMessageReceiver);


		this.mediaSessionCompat = new MediaSessionCompat(cordova.getContext(), "cordova-music-controls-media-session", null, this.mediaButtonPendingIntent);
		this.mediaSessionCompat.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS | MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS);

		this.mMediaSessionCallback.setCallback(generalControlsCallback());
		this.mMessageReceiver.setCallback(generalControlsCallback());

		setMediaPlaybackState(PlaybackStateCompat.STATE_PAUSED);
		this.mediaSessionCompat.setActive(true);

		this.mediaSessionCompat.setCallback(this.mMediaSessionCallback);

		// Register media (headset) button event receiver
		try {
			this.mAudioManager = (AudioManager)cordova.getContext().getSystemService(Context.AUDIO_SERVICE);
			Intent headsetIntent = new Intent("music-controls-media-button");
			this.mediaButtonPendingIntent = PendingIntent.getBroadcast(cordova.getContext(), 0, headsetIntent, PendingIntent.FLAG_UPDATE_CURRENT);
			this.registerMediaButtonEvent();
		} catch (Exception e) {
			this.mediaButtonAccess=false;
			Log.e(LOGTAG, "ERRORE executeSetVolumeForComplexAsset", e);
		}

		// Notification Killer
		ServiceConnection mConnection = new ServiceConnection() {
			public void onServiceConnected(ComponentName className, IBinder binder) {
				Log.d(LOGTAG, "SERVICE CONNECTED");
				((KillBinder) binder).service.startService(new Intent(cordova.getActivity(), MusicControlsNotificationKiller.class));
			}
			public void onServiceDisconnected(ComponentName className) {
				Log.d(LOGTAG, "SERVICE DISCONNECTED");
			}
		};
		Intent startServiceIntent = new Intent(cordova.getActivity(),MusicControlsNotificationKiller.class);
		startServiceIntent.putExtra("notificationID",this.notificationID);
		boolean esito = cordova.getActivity().bindService(startServiceIntent, mConnection, Context.BIND_AUTO_CREATE);
		Log.d("NativeAudio", "ESITO SERVICE BIND : " + esito);
	}

	@Override
	public void onDestroy() {
		this.notification.destroy();
		this.mMessageReceiver.stopListening();
		this.unregisterMediaButtonEvent();
		super.onDestroy();
	}

	@Override
	public void onReset() {
		onDestroy();
		super.onReset();
	}

	private CallbackInterface generalControlsCallback() {
		return new CallbackInterface() {
			@Override
			public void success(String message) {
				MusicControlsInfos infos = notification.getInfos();
				if(controlsCallbackMap.containsKey(infos.audioId)) {
					CallbackContext cb = (CallbackContext)controlsCallbackMap.get(infos.audioId);
					PluginResult result = new PluginResult(Status.OK, message);
					result.setKeepCallback(true);
					cb.sendPluginResult(result);
				}
			}
		};
	}

	private void registerBroadcaster(MusicControlsBroadcastReceiver mMessageReceiver){
		final Context context = this.cordova.getActivity().getApplicationContext();
		context.registerReceiver(mMessageReceiver, new IntentFilter("music-controls-previous"));
		context.registerReceiver(mMessageReceiver, new IntentFilter("music-controls-pause"));
		context.registerReceiver(mMessageReceiver, new IntentFilter("music-controls-play"));
		context.registerReceiver(mMessageReceiver, new IntentFilter("music-controls-next"));
		context.registerReceiver(mMessageReceiver, new IntentFilter("music-controls-media-button"));
		context.registerReceiver(mMessageReceiver, new IntentFilter("music-controls-destroy"));

		// Listen for headset plug/unplug
		context.registerReceiver(mMessageReceiver, new IntentFilter(Intent.ACTION_HEADSET_PLUG));
	}

	// Register pendingIntent for broacast
	public void registerMediaButtonEvent(){
		this.mediaSessionCompat.setMediaButtonReceiver(this.mediaButtonPendingIntent);
	}

	public void unregisterMediaButtonEvent(){
		this.mediaSessionCompat.setMediaButtonReceiver(null);
	}

	public void destroyPlayerNotification(){
		this.notification.destroy();
	}

	private void setMediaPlaybackState(int state) {
		PlaybackStateCompat.Builder playbackstateBuilder = new PlaybackStateCompat.Builder();
		if( state == NativeAudioAssetComplex.PLAYING || state == NativeAudioAssetComplex.LOOPING ) {
			playbackstateBuilder.setActions(PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PAUSE | PlaybackStateCompat.ACTION_SKIP_TO_NEXT | PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS |
					PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID |
					PlaybackStateCompat.ACTION_PLAY_FROM_SEARCH);
			playbackstateBuilder.setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 1.0f);
		} else {
			playbackstateBuilder.setActions(PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PLAY | PlaybackStateCompat.ACTION_SKIP_TO_NEXT | PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS |
					PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID |
					PlaybackStateCompat.ACTION_PLAY_FROM_SEARCH);
			playbackstateBuilder.setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 0);
		}
		this.mediaSessionCompat.setPlaybackState(playbackstateBuilder.build());
	}

	// Get image from url
	private Bitmap getBitmapCover(String coverURL){
		try{
			if(coverURL.matches("^(https?|ftp)://.*$"))
				// Remote image
				return getBitmapFromURL(coverURL);
			else {
				// Local image
				return getBitmapFromLocal(coverURL);
			}
		} catch (Exception ex) {
			ex.printStackTrace();
			return null;
		}
	}

	// get Local image
	private Bitmap getBitmapFromLocal(String localURL){
		try {
			Uri uri = Uri.parse(localURL);
			File file = new File(uri.getPath());
			FileInputStream fileStream = new FileInputStream(file);
			BufferedInputStream buf = new BufferedInputStream(fileStream);
			Bitmap myBitmap = BitmapFactory.decodeStream(buf);
			buf.close();
			return myBitmap;
		} catch (Exception ex) {
			try {
				InputStream fileStream = cordova.getActivity().getAssets().open("www/" + localURL);
				BufferedInputStream buf = new BufferedInputStream(fileStream);
				Bitmap myBitmap = BitmapFactory.decodeStream(buf);
				buf.close();
				return myBitmap;
			} catch (Exception ex2) {
				ex.printStackTrace();
				ex2.printStackTrace();
				return null;
			}
		}
	}

	// get Remote image
	private Bitmap getBitmapFromURL(String strURL) {
		try {
			URL url = new URL(strURL);
			HttpURLConnection connection = (HttpURLConnection) url.openConnection();
			connection.setDoInput(true);
			connection.connect();
			InputStream input = connection.getInputStream();
			Bitmap myBitmap = BitmapFactory.decodeStream(input);
			return myBitmap;
		} catch (Exception ex) {
			ex.printStackTrace();
			return null;
		}
	}


	//// FINE INTIALIZE

	private void setupMediaControls (final String audioId, final JSONArray args) throws JSONException {
		final MusicControlsInfos infos = new MusicControlsInfos(audioId, args);
		final MediaMetadataCompat.Builder metadataBuilder = new MediaMetadataCompat.Builder();


		this.cordova.getThreadPool().execute(new Runnable() {
			public void run() {
				notification.updateNotification(infos);

				// track title
				Log.d(LOGTAG, " IMPOSTO TRACK : " + infos.track);
				metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_TITLE, infos.track);
				// artists
				Log.d(LOGTAG, " IMPOSTO ARTIST : " + infos.artist);
				metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, infos.artist);
				//album
				Log.d(LOGTAG, " IMPOSTO ALBUM : " + infos.album);
				metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, infos.album);

				Bitmap art = getBitmapCover(infos.cover);
				if(art != null){
					metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, art);
					metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ART, art);

				}

				mediaSessionCompat.setMetadata(metadataBuilder.build());

				setMediaPlaybackState(infos.isPlaying ? PlaybackStateCompat.STATE_PLAYING : PlaybackStateCompat.STATE_PAUSED);

			}
		});
	}

	private PluginResult executePreload(JSONArray data) {
		String audioID;
		try {
			audioID = data.getString(0);
			if (!assetMap.containsKey(audioID)) {
				String assetPath = data.getString(1);
				Log.d(LOGTAG, "preloadComplex - " + audioID + ": " + assetPath);

				double volume;
				if (data.length() <= 2) {
					volume = 1.0;
				} else {
					volume = data.getDouble(2);
				}

				JSONObject controlsInfos = null;

				// L'indice 4 è il fade

				//Parametri per la configurazione dei controlli esterni
				if(data.length() >= 5) {
					controlsInfos = data.optJSONObject(4);
				}

				NativeAudioAsset asset;

				if(assetPath.indexOf("http") == 0){
					asset = new NativeAudioAsset(assetPath, (float)volume);
				}else {
					File f = new File(assetPath);
					FileInputStream fis = new FileInputStream(f);

					FileDescriptor fd = fis.getFD();

					asset = new NativeAudioAsset(
							fd, (float) volume);

				}

				asset.setControlsInfos(controlsInfos);

				assetMap.put(audioID, asset);

				return new PluginResult(Status.OK);
			} else {
				Log.w(LOGTAG, "WARNING executePreload - AUDIO GIA' ESISTENTE");
				return new PluginResult(Status.ERROR, ERROR_AUDIOID_EXISTS);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executePreload - JSONException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (IOException e) {
			Log.e(LOGTAG, "ERRORE executePreload - IOException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Exception e) {
			Log.e(LOGTAG, "ERRORE executePreload - Exception", e);
			return new PluginResult(Status.ERROR, e.toString());
		}
	}

	private PluginResult executePlayOrLoop(String action, JSONArray data) {
		final String audioID;
		final boolean setControls;
		try {
			audioID = data.getString(0);
			setControls = data.optBoolean(1, false);
			Log.d( LOGTAG, "playOrLoop - " + action + " - " + audioID );

			for(String key : assetMap.keySet()) {
				Log.d(LOGTAG, "ESISTE LA CHIAVE " + key);
			}

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);

				if (LOOP.equals(action)) {
					asset.loop();
				} else {
					asset.play(new Callable<Void>() {
						public Void call() throws Exception {

							if (completeCallbacks != null) {
								CallbackContext callbackContext = completeCallbacks.get(audioID);
								if (callbackContext != null) {
									JSONObject done = new JSONObject();
									done.put("id", audioID);
									callbackContext.sendPluginResult(new PluginResult(Status.OK, done));
								}
							}
							return null;
						}
					});
				}

				if(asset.getControlsInfos() != null) {
					asset.getControlsInfos().put("isPlaying", true);
					if(setControls) {
						executeSetControls(data);
						setMediaPlaybackState(NativeAudioAssetComplex.PLAYING);
					} else {
						Log.d(LOGTAG, "NON SETTO CONTROLLI : setControls = false");
					}
				} else {
					Log.d(LOGTAG, "NON HO INFO!!");
				}


			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executePlayOrLoop - JSONException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (IOException e) {
			Log.e(LOGTAG, "ERRORE executePlayOrLoop - IOException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Error e) {
			Log.e(LOGTAG, "ERRORE executePlayOrLoop - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}

		return new PluginResult(Status.OK);
	}

	private PluginResult executeStop(JSONArray data) {
		String audioID;
		try {
			audioID = data.getString(0);
			//Log.d( LOGTAG, "stop - " + audioID );

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);
				asset.stop();
				if(asset.getControlsInfos() != null && audioID.equals(currentAudioInControl)) {
					asset.getControlsInfos().put("isPlaying", false);
					executeSetControls(data);
					setMediaPlaybackState(NativeAudioAssetComplex.INVALID);
				}
			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executeStop - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}

		return new PluginResult(Status.OK);
	}

	private PluginResult executePause(JSONArray data) {
		String audioID;
		try {
			audioID = data.getString(0);

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);
				asset.pause();

				if(asset.getControlsInfos() != null && audioID.equals(currentAudioInControl)) {
					asset.getControlsInfos().put("isPlaying", false);
					executeSetControls(data);
					setMediaPlaybackState(NativeAudioAssetComplex.PAUSED);
				}
			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executePause - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Error e) {
			Log.e(LOGTAG, "ERRORE executePause - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}

		return new PluginResult(Status.OK);
	}

	private PluginResult executeUnload(JSONArray data) {
		String audioID;
		try {
			audioID = data.getString(0);
			Log.d( LOGTAG, "unload - " + audioID );

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);
				asset.unload();
				assetMap.remove(audioID);

				//this.onDestroy();
			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executeUnload - JSONException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (IOException e) {
			Log.e(LOGTAG, "ERRORE executeUnload - IOException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Error e) {
			Log.e(LOGTAG, "ERRORE executeUnload - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}

		return new PluginResult(Status.OK);
	}

	private PluginResult executeSetVolumeForComplexAsset(JSONArray data) {
		String audioID;
		float volume;
		try {
			audioID = data.getString(0);
			volume = (float) data.getDouble(1);
			Log.d( LOGTAG, "setVolume - " + audioID );

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);
				asset.setVolume(volume);
			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		}  catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executeSetVolumeForComplexAsset - JSONException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Error e) {
			Log.e(LOGTAG, "ERRORE executeSetVolumeForComplexAsset - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}
		return new PluginResult(Status.OK);
	}

	private PluginResult executeSeekTo(JSONArray data) {
		String audioID;
		int position;

		try {
			audioID = data.getString(0);
			position = data.getInt(1);
			Log.d( LOGTAG, "seekTo - " + position );

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);
				asset.seekTo(position);
			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executeSeekTo - JSONException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Error e) {
			Log.e(LOGTAG, "ERRORE executeSeekTo - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}
		return new PluginResult(Status.OK);
	}

	private PluginResult executeSetControls(JSONArray data) {
		String audioID;
		int position;

		try {
			audioID = data.getString(0);
			Log.d( LOGTAG, "setControls - " + audioID );

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);

				if(asset.getControlsInfos() != null) {
					JSONArray ctrlArray = new JSONArray();
					ctrlArray.put(asset.getControlsInfos());
					this.setupMediaControls(audioID, ctrlArray);
					currentAudioInControl = audioID;
				}

			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			Log.e(LOGTAG, "ERRORE executeSetControls - JSONException", e);
			return new PluginResult(Status.ERROR, e.toString());
		} catch (Error e) {
			Log.e(LOGTAG, "ERRORE executeSetControls - Error", e);
			return new PluginResult(Status.ERROR, e.toString());
		}
		return new PluginResult(Status.OK);
	}

	private PluginResult getDuration(JSONArray data) {
		String audioID;
		try {
			audioID = data.getString(0);

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);
				return new PluginResult(Status.OK, asset.getDuration());
			} else {
				return new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
			}
		} catch (JSONException e) {
			return new PluginResult(Status.ERROR, e.toString());
		}

	}

	private void executeAddControlsCallback(JSONArray data, CallbackContext callback) {
		String audioID;
		try {
			audioID = data.getString(0);

			if (assetMap.containsKey(audioID)) {
				NativeAudioAsset asset = assetMap.get(audioID);

				//Mano NO_RESULT per settare il keepCallback a true
				PluginResult result = new PluginResult(Status.NO_RESULT);
				result.setKeepCallback(true);
				callback.sendPluginResult(result);

				controlsCallbackMap.put(audioID,callback);
			} else {
				callback.sendPluginResult(new PluginResult(Status.ERROR, ERROR_NO_AUDIOID));
			}
		} catch (JSONException e) {
			callback.sendPluginResult(new PluginResult(Status.ERROR, e.toString()));
		}
	}

	@Override
	protected void pluginInitialize() {
		AudioManager am = (AudioManager)cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);

		int result = am.requestAudioFocus(this,
				// Use the music stream.
				AudioManager.STREAM_MUSIC,
				// Request permanent focus.
				AudioManager.AUDIOFOCUS_GAIN);

		// Allow android to receive the volume events
		this.webView.setButtonPlumbedToJs(KeyEvent.KEYCODE_VOLUME_DOWN, false);
		this.webView.setButtonPlumbedToJs(KeyEvent.KEYCODE_VOLUME_UP, false);
	}

	@Override
	public boolean execute(final String action, final JSONArray data, final CallbackContext callbackContext) {
		Log.d(LOGTAG, "Plugin Called: " + action);

		PluginResult result = null;
		initSoundPool();

		try {
			if (SET_OPTIONS.equals(action)) {
				JSONObject options = data.optJSONObject(0);
				this.setOptions(options);
				callbackContext.sendPluginResult( new PluginResult(Status.OK) );

			} else if (PRELOAD_SIMPLE.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executePreload(data) );
					}
				});

			} else if (PRELOAD_COMPLEX.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executePreload(data) );
					}
				});

			} else if (PLAY.equals(action) || LOOP.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executePlayOrLoop(action, data) );
					}
				});

			} else if (STOP.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executeStop(data) );
					}
				});

			} else if (UNLOAD.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						executeStop(data);
						callbackContext.sendPluginResult( executeUnload(data) );
					}
				});
			} else if (ADD_COMPLETE_LISTENER.equals(action)) {
				if (completeCallbacks == null) {
					completeCallbacks = new HashMap<String, CallbackContext>();
				}
				try {
					String audioID = data.getString(0);
					completeCallbacks.put(audioID, callbackContext);
				} catch (JSONException e) {
					callbackContext.sendPluginResult(new PluginResult(Status.ERROR, e.toString()));
				}
			} else if (SET_VOLUME_FOR_COMPLEX_ASSET.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executeSetVolumeForComplexAsset(data) );
					}
				});
			} else if (GET_CURRENT_POSITION.equals(action)){

				String audioID = data.getString(0);

				cordova.getThreadPool().execute(new Runnable() {
					public void run() {

						if (assetMap.containsKey(audioID)) {
							NativeAudioAsset asset = assetMap.get(audioID);
							callbackContext.sendPluginResult(new PluginResult(Status.OK, asset.getCurrentPosition()));
						}else{
							callbackContext.sendPluginResult(new PluginResult(Status.ERROR, ERROR_NO_AUDIOID));
						}

					}
				});

			} else if (PAUSE.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executePause(data) );
					}
				});

			} else if (GET_DURATION.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( getDuration(data) );
					}
				});

			} else if(SEEK_TO.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executeSeekTo(data) );
					}
				});
			} else if(SET_CONTROLS.equals(action)) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						callbackContext.sendPluginResult( executeSetControls(data) );
					}
				});
			} else if(ADD_CONTROLS_CALLBACK.equals(action)){
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						executeAddControlsCallback(data, callbackContext);
					}
				});
			}else {
				result = new PluginResult(Status.OK);
			}
		} catch (Exception ex) {
			result = new PluginResult(Status.ERROR, ex.toString());
		}

		if(result != null) callbackContext.sendPluginResult( result );
		return true;
	}

	private void initSoundPool() {

		if (assetMap == null) {
			assetMap = new HashMap<String, NativeAudioAsset>();
		}

		if( controlsCallbackMap == null) {
			controlsCallbackMap = new HashMap<String, CallbackContext>();
		}

		if (resumeList == null) {
			resumeList = new ArrayList<NativeAudioAsset>();
		}
	}

	public void onAudioFocusChange(int focusChange) {
		if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
			// Pause playback
		} else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
			// Resume playback
		} else if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
			// Stop playback
		}
	}
/*
	@Override
	public void onPause(boolean multitasking) {
		super.onPause(multitasking);
		Log.d(LOGTAG, "LANCIO onPause");

		for (HashMap.Entry<String, NativeAudioAsset> entry : assetMap.entrySet()) {
			NativeAudioAsset asset = entry.getValue();
			boolean wasPlaying = asset.pause();
			if (wasPlaying) {
				resumeList.add(asset);
			}
		}
	}

	@Override
	public void onResume(boolean multitasking) {
		super.onResume(multitasking);
		Log.d(LOGTAG, "LANCIO onResume");

		while (!resumeList.isEmpty()) {
			NativeAudioAsset asset = resumeList.remove(0);
			asset.resume();
		}
	}
	
 */
}
