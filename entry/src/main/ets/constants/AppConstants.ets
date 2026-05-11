export class AppConstants {
  static readonly BUNDLE_NAME: string =
    'com.hmosdemos.wearable.how_to_build_podcast_player_on_watch';

  // Single app-level event the codelab publishes through commonEventManager,
  // exercising CommonEventPublishData. Companion surfaces (notifications,
  // widgets) could subscribe to it.
  static readonly EVENT_EPISODE_COMPLETED: string =
    'com.hmosdemos.wearable.podcast.EPISODE_COMPLETED';

  // SoundPool rawfile asset names — drop matching ogg/wav files into rawfile/.
  static readonly SFX_TAP: string = 'sfx_tap.ogg';
  static readonly SFX_SKIP: string = 'sfx_skip.ogg';
  static readonly SFX_CHIME: string = 'sfx_chime.ogg';
  static readonly SFX_MAX_STREAMS: number = 3;

  // Adaptive streaming buffer hints used by AudioPlayerService when building
  // a URL MediaSource. ConnectivityService picks the right one based on the
  // active bearer (Wi-Fi vs cellular).
  static readonly URL_STREAM_BUFFER_WIFI_SEC: number = 5;
  static readonly URL_STREAM_BUFFER_CELLULAR_SEC: number = 15;
}
