//
//
//  NativeAudioAssetComplex.java
//
//  Created by Sidney Bofah on 2014-06-26.
//

package com.rastafan.cordova.plugin.nativeaudio;

import java.io.FileDescriptor;
import java.io.IOException;
import java.util.concurrent.Callable;

import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.media.MediaPlayer.OnSeekCompleteListener;

import android.util.Log;

import org.json.JSONObject;

public class NativeAudioAssetComplex implements OnPreparedListener, OnCompletionListener, OnSeekCompleteListener {

	public static final int INVALID = 0;
	public static final int PREPARED = 1;
	public static final int PENDING_PLAY = 2;
	public static final int PLAYING = 3;
	public static final int PENDING_LOOP = 4;
	public static final int LOOPING = 5;
	public static final int PAUSED = 6;
	
	private MediaPlayer mp;
	private int state;

	private int duration = 0;

    Callable<Void> completeCallback;

	private JSONObject controlsInfos;


	public NativeAudioAssetComplex(String url, float volume)  throws IOException
	{
		this.prepareMediaPlayer(volume);
		mp.setDataSource(url);
		mp.prepareAsync();
	}

	public NativeAudioAssetComplex(FileDescriptor fd, float volume)  throws IOException
	{
		this.prepareMediaPlayer(volume);
		mp.setDataSource(fd);
		mp.prepare();
	}

	private void prepareMediaPlayer(float volume) {
		state = INVALID;
		mp = new MediaPlayer();
		mp.setOnCompletionListener(this);
		mp.setOnPreparedListener(this);
		mp.setAudioAttributes(
				new AudioAttributes.Builder()
						.setUsage(AudioAttributes.USAGE_MEDIA)
						.setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
						.build()
		);
		//mp.setAudioStreamType(AudioManager.STREAM_MUSIC);
		mp.setVolume(volume, volume);
	}

	public void play(Callable<Void> completeCb) throws IOException
	{
        completeCallback = completeCb;
		invokePlay( false );
	}

	public Integer getCurrentPosition(){
		return mp.getCurrentPosition();
	}

	/**
	 *	Returns a duration value saved in the class (default value is 0).
	 * 	This is used because, while prepareAsync is in the "Preparing" state (but not still Prepared),
	 * 	calling getDuration will return a garbage value.
	 * 	This way, one can ask for duration until it becomes a value != 0
	 * 	knowing it is the correct value.
	 */
	public Integer getDuration(){
		return duration;
	}
	
	private void invokePlay( Boolean loop )
	{
		Boolean playing = mp.isPlaying();
		if(state == PAUSED) {
			mp.start();
			state = PLAYING;
		} else if ( playing ) {
			mp.pause();
			mp.setLooping(loop);
			mp.seekTo(0);
			mp.start();
		}
		if ( !playing && state == PREPARED )
		{
			state = (loop ? PENDING_LOOP : PENDING_PLAY);
			onPrepared( mp );
		}

		else if ( !playing )
		{
			state = (loop ? PENDING_LOOP : PENDING_PLAY);
			mp.setLooping(loop);
			//mp.start();
		}

	}

	public boolean pause()
	{
		try
		{
    		if ( mp.isPlaying() )
				{
					mp.pause();
					state = PAUSED;
					return true;
				}
        	}
		catch (IllegalStateException e)
		{
		// I don't know why this gets thrown; catch here to save app
		}

		return false;
	}

	public void resume()
	{
		mp.start();
	}

    public void stop()
	{
		try
		{
			if ( mp.isPlaying() )
			{
				state = PAUSED;
				mp.pause();
				mp.seekTo(0);
	           	}
		}
	        catch (IllegalStateException e)
	        {
            // I don't know why this gets thrown; catch here to save app
	        }

	}

	public void setVolume(float volume) 
	{
	        try
	        {
			mp.setVolume(volume,volume);
            	}
            	catch (IllegalStateException e) 
		{
                // I don't know why this gets thrown; catch here to save app
		}
	}
	
	public void loop() throws IOException
	{
		invokePlay( true );
	}
	
	public void unload() throws IOException
	{
		this.stop();
		mp.release();
	}
	
	public void onPrepared(MediaPlayer mPlayer) 
	{
		duration = mp.getDuration();

		Log.i("PLAYER","PREPARED CALLBACK");
		if (state == PENDING_PLAY) 
		{
			mp.setLooping(false);
			mp.seekTo(0);
			mp.start();
			state = PLAYING;
		}
		else if ( state == PENDING_LOOP )
		{
			mp.setLooping(true);
			mp.seekTo(0);
			mp.start();
			state = LOOPING;
		}
		else
		{
			state = PREPARED;
			mp.seekTo(0);
		}
	}
	
	public void onCompletion(MediaPlayer mPlayer)
	{
		if (state != LOOPING)
		{
			this.state = PAUSED;
			try {
				this.stop();
				if (completeCallback != null)
                completeCallback.call();
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}
	}

	public void onSeekComplete(MediaPlayer mPlayer){
		Log.d("LOOP", "SEEK COMPLETATO");
	}

	public void seekTo(int position){

		mp.seekTo(position);

	}

	public void setControlsInfos(JSONObject infos){
		this.controlsInfos = infos;
	}

	public JSONObject getControlsInfos() {
		return this.controlsInfos;
	}

}