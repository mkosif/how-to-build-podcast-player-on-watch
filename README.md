# Mini Podcast Player

A wearable-first HarmonyOS codelab that demonstrates how to use **BasicServicesKit common events** as the pub/sub backbone of a real app. The sample is dressed up as a tiny watch podcast player, but the focus is the event flow: publishing playback intents, subscribing to app and system events, and reacting to them on a circular display without polling.

## Preview

<div>

The app boots into a compact watch face that shows the current episode, a progress bar, and a single primary play / pause control. Tapping the small "Events" button on the player opens a second screen — a live, scrollable feed of every `CommonEventData` record the app has received, including events the app itself published and any system events the device delivered.

</div>

## Use Cases

- Drive playback state on a watch through `commonEventManager.publish` instead of direct method calls, so unrelated UI pieces can stay in sync.
- Receive system signals such as battery low or power connected and translate them into wearable-friendly hints ("Streaming paused on low battery", "Cellular streaming ready").
- Inspect the live stream of received `CommonEventData` records on a dedicated, scrollable monitor screen — useful when teaching pub/sub or debugging event wiring.
- Use the project as a starting skeleton for any HarmonyOS wearable feature that needs decoupled, event-driven state propagation.

## Technology

- **ArkTS / ArkUI** with `Navigation` and `NavPathStack` for screen flow (no `@ohos.router`).
- **BasicServicesKit** common events:
  - `commonEventManager.createSubscriber` with `CommonEventSubscribeInfo`
  - `commonEventManager.subscribe` receiving `CommonEventData`
  - `commonEventManager.publish` with `CommonEventPublishData`
  - `commonEventManager.unsubscribe` for clean teardown
- **HarmonyOS SDK**: `targetSdkVersion 6.0.2(22)` / `compatibleSdkVersion 6.0.0(20)`.
- **Device target**: Wearable (Huawei Watch 5, DevEco Studio Simulator).
- **Module**: `entry`, single ability `EntryAbility`, template "Empty Ability".

## Directory Structure

```
entry/src/main/ets/
├── components/
│   ├── EpisodeHeader.ets       // compact title block for the watch face
│   ├── PlayerControls.ets      // skip-back / play-pause / skip-forward row
│   ├── StatusPill.ets          // battery / network / cache chip
│   └── EventLogList.ets        // scrollable list used by the monitor screen
├── constants/
│   └── AppConstants.ets        // event names, bundle name, tunables
├── entryability/
│   └── EntryAbility.ets        // boots the CommonEventService
├── entrybackupability/
│   └── EntryBackupAbility.ets
├── model/
│   ├── Episode.ets             // simulated podcast data
│   └── PlaybackEvent.ets       // record stored in the event log
├── pages/
│   ├── Index.ets               // Navigation host + main player view
│   └── EventMonitorPage.ets    // NavDestination for the event log
├── services/
│   └── CommonEventService.ets  // publish/subscribe/unsubscribe wrapper
└── utils/
    └── TimeFormatter.ets       // mm:ss formatter
```

## Constraints and Restrictions

- HarmonyOS SDK: `targetSdkVersion 6.0.2(22)` and `compatibleSdkVersion 6.0.0(20)` — both as declared in `build-profile.json5`.
- Wearable device type only; the layout is tuned for a circular display.
- Navigation is implemented with `Navigation` + `NavPathStack`. The legacy `@ohos.router` API is intentionally not used.
- All BasicServicesKit common-event work is wrapped in `services/CommonEventService.ets`. Subscriptions are released on ability destroy and on page disappear so the watch never leaks subscribers.
- No network or sensitive runtime permissions are required. Real audio streaming is intentionally not implemented — the focus is the common-event pub/sub flow with simulated playback time.
- No use of `Math.random()`; all IDs and demo values are deterministic.

## License

Released under the [MIT License](LICENSE).
