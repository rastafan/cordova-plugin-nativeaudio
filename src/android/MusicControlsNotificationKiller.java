//
//
//  MusicControlsNotificationKiller.java
//
//  Original code from https://github.com/ghenry22/cordova-plugin-music-controls2
//

package com.rastafan.cordova.plugin.nativeaudio;

import android.app.Service;
import android.os.IBinder;
import android.app.NotificationManager;
import android.content.Intent;
import android.util.Log;

public class MusicControlsNotificationKiller extends Service {

	private static int NOTIFICATION_ID = 7824;
	private NotificationManager mNM;
	private final IBinder mBinder = new KillBinder(this);

	@Override
	public IBinder onBind(Intent intent) {
		//this.NOTIFICATION_ID=intent.getIntExtra("notificationID",1);
		Log.d("NativeAudio", "SERVICE BINDATO - " + NOTIFICATION_ID);
		return mBinder;
	}
	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		Log.d("NativeAudio", "SERVICE STARTATO - " + NOTIFICATION_ID);
		super.onStartCommand(intent, flags, startId);
		return Service.START_STICKY;
	}

	@Override
	public void onCreate() {
		Log.d("NativeAudio", "SERVICE CREATO - " + NOTIFICATION_ID);
		mNM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
		mNM.cancel(NOTIFICATION_ID);
		super.onCreate();
	}

	@Override
	public void onDestroy() {
		Log.d("NativeAudio", "SERVICE DISTRUTTO!! - " + NOTIFICATION_ID);
		mNM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
		mNM.cancel(NOTIFICATION_ID);
		super.onDestroy();
	}

}
