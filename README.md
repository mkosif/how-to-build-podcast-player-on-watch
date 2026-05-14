> **Note:** To access all shared projects, get information about environment setup, and view other guides, please visit [Explore-In-HMOS-Wearable Index](https://github.com/Explore-In-HMOS-Wearable/hmos-index).

# Mini Podcast Player

**Mini Podcast Player** is a HarmonyOS wearable codelab that demonstrates how to build a compact podcast player for watches with `media.AVPlayer`, `media.AVMetadataExtractor`, `media.SoundPool`, and BasicServicesKit `commonEventManager`.

The app plays bundled rawfile episodes and URL-streamed episodes, extracts runtime metadata and album artwork, gives low-latency sound feedback for player actions, and reacts to battery and connectivity events through a focused pub/sub backbone.

# Use Cases

- **Rawfile playback**: Play bundled podcast episodes with `resourceManager.getRawFd` and `AVFileDescriptor`.
- **URL streaming**: Stream remote audio with `createMediaSourceWithUrl` and `setMediaSource`.
- **Runtime metadata**: Read title, artist, duration, and album cover with `media.AVMetadataExtractor`.
- **Sound feedback**: Trigger tap, skip, and completion sounds with `media.SoundPool`.
- **System event subscription**: Subscribe to battery and connectivity events with `commonEventManager`.
- **App event publishing**: Publish an `EPISODE_COMPLETED` event with `CommonEventPublishData` when playback ends.
- **Background playback**: Keep audio running when the watch screen sleeps with `backgroundModes: ["audioPlayback"]`.
- **Adaptive buffering**: Adjust the preferred buffer duration for Wi-Fi and cellular connections with NetworkKit.

# Tech Stack

- **Languages**: ArkTS / ArkUI
- **Frameworks**: HarmonyOS SDK 6.0.0(20)
- **Tools**: DevEco Studio 5.1.0.260+
- **Libraries**:
  - `@kit.MediaKit`
  - `@kit.AudioKit`
  - `@kit.BasicServicesKit`
  - `@kit.NetworkKit`
  - `@kit.ImageKit`

## Required Permissions

| Permission | Reason |
|---|---|
| `ohos.permission.INTERNET` | Streams URL-based podcast episodes. |
| `ohos.permission.GET_NETWORK_INFO` | Reads the active bearer and network capabilities. |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | Keeps audio playback alive while the app is backgrounded. |

# Directory Structure

```
entry/src/main/ets/
|--- components/
|    |--- EpisodeHeader.ets
|    |--- MainPlayerView.ets
|    |--- PlayerControls.ets
|--- constants/
|    |--- AppConstants.ets
|--- entryability/
|    |--- EntryAbility.ets
|--- entrybackupability/
|    |--- EntryBackupAbility.ets
|--- model/
|    |--- Episode.ets
|    |--- EpisodeMetadata.ets
|--- pages/
|    |--- Index.ets
|--- services/
|    |--- AudioPlayerService.ets
|    |--- CommonEventService.ets
|    |--- ConnectivityService.ets
|    |--- MetadataService.ets
|    |--- SoundEffectService.ets
|--- utils/
|    |--- TimeFormatter.ets
```

Bundled audio assets live in `entry/src/main/resources/rawfile/`.

# Constraints and Restrictions

## Supported Devices

- Huawei Watch 5
- DevEco Studio wearable simulator

## Project Constraints

- Single `EntryAbility`
- Empty Ability template
- Wearable device family only

# LICENSE

**Mini Podcast Player** is distributed under the terms of the MIT License.
See the [LICENSE](/LICENSE) for more information.
