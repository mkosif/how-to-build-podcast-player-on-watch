# Mini Podcast Player

A wearable HarmonyOS codelab that builds a watch podcast player from `media.AVPlayer`, `media.AVMetadataExtractor`, `media.SoundPool` and BasicServicesKit's `commonEventManager`. AVPlayer plays bundled rawfile episodes and URL-streamed episodes; AVMetadataExtractor pulls the title, duration and album cover; SoundPool gives every tap, skip and completion an instant audible response; and `commonEventManager` is the pub/sub bus that lets the watch react to system battery and connectivity events without polling.

## Scenario

- **AVPlayer** drives playback. Rawfile episodes are loaded with `AVFileDescriptor`; URL episodes are loaded with `createMediaSourceWithUrl` and `setMediaSource`.
- **AVMetadataExtractor** fills in episode metadata at runtime: `fetchMetadata` resolves the title / artist / duration, `fetchAlbumCover` returns a `PixelMap` for the artwork.
- **SoundPool** is loaded once with three short clips (tap, skip, chime) and triggered via `play()` + `PlayParameters` for low-latency UI feedback.
- **commonEventManager** is wired through `CommonEventService`:
  - `createSubscriber` + `CommonEventSubscribeInfo` for `COMMON_EVENT_BATTERY_LOW`, `COMMON_EVENT_POWER_CONNECTED`, `COMMON_EVENT_CONNECTIVITY_CHANGE`.
  - Subscribed `CommonEventData` is fanned out to in-process listeners.
  - `commonEventManager.publish` with `CommonEventPublishData` broadcasts a single app-level `EPISODE_COMPLETED` event when an episode ends, so notifications, complications or future companion surfaces can subscribe.
- **Offline caching**: rawfile episodes are bundled with the app and read via `resourceManager.getRawFd`, so playback works with no network.
- **Background playback resumption**: the ability declares `backgroundModes: ["audioPlayback"]` and the `KEEP_BACKGROUND_RUNNING` permission, so AVPlayer keeps running when the watch screen sleeps.
- **Adaptive streaming for cellular**: `ConnectivityService` reads the active bearer through `connection.getDefaultNetSync` / `getNetCapabilitiesSync` and adjusts `AudioPlayerService`'s `preferredBufferDuration` (5 s on Wi-Fi, 15 s on cellular). It re-runs on every `COMMON_EVENT_CONNECTIVITY_CHANGE`.

## How the pub/sub backbone is used

The codelab keeps the bus narrow on purpose. AVPlayer state, time updates, end-of-stream and error are delivered to the UI through direct listeners on `AudioPlayerService`. `commonEventManager` is used only where the spec needs it:

- **Subscribe** to system events the watch should react to (battery, connectivity).
- **Publish** the app-level `EPISODE_COMPLETED` event with `CommonEventPublishData`.

This keeps high-frequency callbacks off the event bus while still exercising every target module (`commonEventManager`, `commonEventSubscriber`, `CommonEventSubscribeInfo`, `CommonEventData`, `CommonEventPublishData`).

## Project layout

```
entry/src/main/ets/
├── components/
│   ├── EpisodeHeader.ets         // podcast + title
│   ├── MainPlayerView.ets        // artwork, progress, transport controls
│   └── PlayerControls.ets        // skip / play-pause / skip
├── constants/AppConstants.ets    // bundle name, event name, sfx assets, buffer hints
├── entryability/EntryAbility.ets // boots and tears down every service
├── entrybackupability/EntryBackupAbility.ets
├── model/
│   ├── Episode.ets               // rawfile + URL source descriptors
│   └── EpisodeMetadata.ets       // title / artist / durationMs / artwork
├── pages/Index.ets               // @Entry, renders MainPlayerView
├── services/
│   ├── CommonEventService.ets    // commonEventManager subscribe + publish wrapper
│   ├── AudioPlayerService.ets    // media.AVPlayer wrapper, listens to battery
│   ├── MetadataService.ets       // media.AVMetadataExtractor wrapper
│   ├── SoundEffectService.ets    // media.SoundPool wrapper
│   └── ConnectivityService.ets   // NetworkKit → buffer strategy
└── utils/TimeFormatter.ets       // mm:ss formatter
```

Bundled audio assets live in `entry/src/main/resources/rawfile/`. See that folder's README for the expected filenames.

## Required permissions

| Permission | Reason |
|---|---|
| `ohos.permission.INTERNET` | `media.AVPlayer` uses it when streaming a URL `MediaSource`. |
| `ohos.permission.GET_NETWORK_INFO` | `ConnectivityService` reads the active bearer with `connection.getNetCapabilitiesSync`. |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | Pairs with `backgroundModes: ["audioPlayback"]` so audio survives screen-off. |

## Build target

- `targetSdkVersion 6.0.0(20)` / `compatibleSdkVersion 6.0.0(20)` as declared in `build-profile.json5`.
- Wearable device type only (Huawei Watch 5, DevEco Studio Simulator).
- Single ability `EntryAbility`, Empty Ability template.

## License

Released under the [MIT License](LICENSE).
