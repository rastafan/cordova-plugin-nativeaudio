//
//
//  MusicControlsInfos.java
//
//  Integrated from https://github.com/ghenry22/cordova-plugin-music-controls2
//

package com.rastafan.cordova.plugin.nativeaudio;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class MusicControlsInfos{
	public String audioId;
	public String artist;
  	public String album;
	public String track;
	public String ticker;
	public String cover;
	public boolean isPlaying;
	public boolean hasPrev;
	public boolean hasNext;
	public boolean hasClose;
	public boolean dismissable;
	public String playIcon;
	public String pauseIcon;
	public String prevIcon;
	public String nextIcon;
	public String closeIcon;
	public String notificationIcon;

	public MusicControlsInfos(String audioId, JSONArray args) throws JSONException {
		final JSONObject params = args.getJSONObject(0);

		this.audioId = audioId;

		this.track = params.optString("track");
		this.artist = params.optString("artist");
		this.album = params.optString("album");
		this.ticker = params.optString("ticker");
		this.cover = params.optString("cover");
		this.isPlaying = params.optBoolean("isPlaying", false);
		this.hasPrev = params.optBoolean("hasPrev", false);
		this.hasNext = params.optBoolean("hasNext", false);
		this.hasClose = params.optBoolean("hasClose", false);
		this.dismissable = params.optBoolean("dismissable");
		this.playIcon = params.optString("playIcon");
		this.pauseIcon = params.optString("pauseIcon");
		this.prevIcon = params.optString("prevIcon");
		this.nextIcon = params.optString("nextIcon");
		this.closeIcon = params.optString("closeIcon");
		this.notificationIcon = params.optString("notificationIcon");
	}

}
