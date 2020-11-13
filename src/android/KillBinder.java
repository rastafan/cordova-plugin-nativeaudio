//
//
//  KillBinder.java
//
//  Original code from https://github.com/ghenry22/cordova-plugin-music-controls2
//

package com.rastafan.cordova.plugin.nativeaudio;

import android.app.Service;
import android.os.Binder;

public class KillBinder extends Binder {
	public final Service service;

	public KillBinder(Service service) {
		this.service = service;
	}
}
