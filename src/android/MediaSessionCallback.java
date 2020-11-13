package com.rastafan.cordova.plugin.nativeaudio;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.media.session.MediaSessionCompat;
import android.view.KeyEvent;

import org.apache.cordova.CallbackContext;

public class MediaSessionCallback extends MediaSessionCompat.Callback {

  private NativeAudio.CallbackInterface cb;

  public void setCallback(NativeAudio.CallbackInterface cb){
    this.cb = cb;
  }

  @Override
  public void onPlay() {
    super.onPlay();
    if(this.cb != null) {
      this.cb.success("{\"message\": \"music-controls-media-button-play\"}");

    }
  }

  @Override
  public void onPause() {
    super.onPause();
    if(this.cb != null) {
      this.cb.success("{\"message\": \"music-controls-media-button-pause\"}");

    }
  }

  @Override
  public void onSkipToNext() {
    super.onSkipToNext();
    if(this.cb != null) {
      this.cb.success("{\"message\": \"music-controls-media-button-next\"}");

    }
  }

  @Override
  public void onSkipToPrevious() {
    super.onSkipToPrevious();
    if(this.cb != null) {
      this.cb.success("{\"message\": \"music-controls-media-button-previous\"}");

    }
  }

  @Override
  public void onPlayFromMediaId(String mediaId, Bundle extras) {
    super.onPlayFromMediaId(mediaId, extras);
  }

  @Override
  public boolean onMediaButtonEvent(Intent mediaButtonIntent) {
    final KeyEvent event = (KeyEvent) mediaButtonIntent.getExtras().get(Intent.EXTRA_KEY_EVENT);

    if (event == null) {
      return super.onMediaButtonEvent(mediaButtonIntent);
    }

    if (event.getAction() == KeyEvent.ACTION_DOWN) {
      final int keyCode = event.getKeyCode();
      switch (keyCode) {
        case KeyEvent.KEYCODE_MEDIA_PAUSE:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-pause\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_PLAY:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-play\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_PREVIOUS:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-previous\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_NEXT:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-next\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-play-pause\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_STOP:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-stop\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_FAST_FORWARD:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-forward\"}");

          }
          break;
        case KeyEvent.KEYCODE_MEDIA_REWIND:

          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-rewind\"}");

          }
          break;
        default:
          if(this.cb != null) {
            this.cb.success("{\"message\": \"music-controls-media-button-unknown-" + keyCode + "\"}");

          }
          return super.onMediaButtonEvent(mediaButtonIntent);
      }
    }

    return true;
  }
}

