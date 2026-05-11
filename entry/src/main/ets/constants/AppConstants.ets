export class AppConstants {
  static readonly BUNDLE_NAME: string =
    'com.hmosdemos.wearable.how_to_build_podcast_player_on_watch';

  static readonly EVENT_PLAYBACK_STARTED: string =
    'com.hmosdemos.wearable.podcast.PLAYBACK_STARTED';
  static readonly EVENT_PLAYBACK_PAUSED: string =
    'com.hmosdemos.wearable.podcast.PLAYBACK_PAUSED';
  static readonly EVENT_EPISODE_SKIPPED: string =
    'com.hmosdemos.wearable.podcast.EPISODE_SKIPPED';
  static readonly EVENT_EPISODE_COMPLETED: string =
    'com.hmosdemos.wearable.podcast.EPISODE_COMPLETED';
  static readonly EVENT_CACHE_READY: string =
    'com.hmosdemos.wearable.podcast.CACHE_READY';
  static readonly EVENT_LOW_BATTERY: string =
    'com.hmosdemos.wearable.podcast.LOW_BATTERY';
  static readonly EVENT_CELLULAR_READY: string =
    'com.hmosdemos.wearable.podcast.CELLULAR_READY';

  static readonly NAV_EVENT_MONITOR: string = 'event-monitor';
  static readonly TICK_INTERVAL_MS: number = 1000;
  static readonly MAX_LOG_SIZE: number = 32;
}
