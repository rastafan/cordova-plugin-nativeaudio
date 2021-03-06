//
//
//  NativeAudioAsset.java
//
//  Created by Sidney Bofah on 2014-06-26.
//  Edited and re-adapted by a bunch other people (see Readme for details)
//

package com.rastafan.cordova.plugin.nativeaudio;

import java.io.FileDescriptor;
import java.io.IOException;
import java.util.ArrayList;
import java.util.concurrent.Callable;

import android.content.res.AssetFileDescriptor;

import org.json.JSONObject;

public class NativeAudioAsset
{
	NativeAudioAssetComplex track;
	private int playIndex = 0;

	public NativeAudioAsset(String url, float volume) throws IOException
	{
		track = new NativeAudioAssetComplex(url, volume);
	}

	public NativeAudioAsset(FileDescriptor fd, float volume) throws IOException
	{
		track = new NativeAudioAssetComplex(fd, volume);
	}

	public void play(Callable<Void> completeCb) throws IOException
	{
		track.play(completeCb);
	}

	public Integer getCurrentPosition(){
		return track.getCurrentPosition();
	}

	public boolean pause()
	{
		boolean wasPlaying = false;
		wasPlaying |= track.pause();
		return wasPlaying;
	}

	public void resume()
	{
		track.resume();
	}

    public void stop()
	{
		track.stop();
	}
	
	public void loop() throws IOException
	{
		track.loop();
	}
	
	public void unload() throws IOException
	{
		this.stop();
		track.unload();
		track = null;
	}
	
	public void setVolume(float volume)
	{
		track.setVolume(volume);
	}

	public void seekTo(int position){
		track.seekTo(position);
	}

	public Integer getDuration(){
        return track.getDuration();
    }

    public void setControlsInfos(JSONObject infos){ track.setControlsInfos(infos); }

    public JSONObject getControlsInfos() {return track.getControlsInfos();}

}