import { AppConstants } from '../constants/AppConstants';
import { Episode, SAMPLE_EPISODES } from '../model/Episode';
import { PlaybackEvent } from '../model/PlaybackEvent';
import { commonEventService, EventListener } from '../services/CommonEventService';
import { TimeFormatter } from '../utils/TimeFormatter';
import { EpisodeHeader } from '../components/EpisodeHeader';
import { PlayerControls } from '../components/PlayerControls';
import { StatusPill } from '../components/StatusPill';
import { EventMonitorPage } from './EventMonitorPage';

@Entry
@Component
struct Index {
  @State navStack: NavPathStack = new NavPathStack();

  @Builder
  pageMap(name: string) {
    if (name === AppConstants.NAV_EVENT_MONITOR) {
      EventMonitorPage();
    }
  }

  build() {
    Navigation(this.navStack) {
      MainPlayerView({
        onOpenMonitor: () => {
          this.navStack.pushPath({ name: AppConstants.NAV_EVENT_MONITOR });
        }
      });
    }
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

@Component
struct MainPlayerView {
  onOpenMonitor: () => void = () => {};

  @State episodeIdx: number = 0;
  @State elapsedSec: number = 0;
  @State isPlaying: boolean = false;
  @State cacheReady: boolean = false;
  @State batterySaver: boolean = false;
  @State statusLine: string = 'Ready';

  private tickHandle: number = -1;

  private listener: EventListener = (event: PlaybackEvent) => {
    this.applyEvent(event);
  };

  aboutToAppear(): void {
    commonEventService.addListener(this.listener);
  }

  aboutToDisappear(): void {
    this.stopTick();
    commonEventService.removeListener(this.listener);
  }

  build() {
    Column() {
      Column({ space: 8 }) {
        EpisodeHeader({
          podcast: this.currentEpisode().podcast,
          title: this.currentEpisode().title,
          artworkLabel: this.currentEpisode().artworkLabel
        });

        this.progressBlock();

        PlayerControls({
          isPlaying: this.isPlaying,
          onTogglePlay: () => this.handleTogglePlay(),
          onSkipBack: () => this.handleSkipBack(),
          onSkipForward: () => this.handleSkipForward()
        });

        this.statusRow();

        this.demoActions();
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 6 })
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF');
  }

  @Builder
  progressBlock() {
    Column({ space: 4 }) {
      Progress({
        value: this.elapsedSec,
        total: this.currentEpisode().durationSec,
        type: ProgressType.Linear
      })
        .color('#1F6FEB')
        .backgroundColor('#E6EEFC')
        .width('100%')
        .height(4);

      Row() {
        Text(TimeFormatter.formatSeconds(this.elapsedSec))
          .fontSize(10)
          .fontColor('#7A8595');
        Blank();
        Text(TimeFormatter.formatSeconds(this.currentEpisode().durationSec))
          .fontSize(10)
          .fontColor('#7A8595');
      }
      .width('100%');
    }
    .width('100%');
  }

  @Builder
  statusRow() {
    Row({ space: 6 }) {
      StatusPill({
        label: this.batterySaver ? 'Battery low' : 'Battery OK',
        tone: this.batterySaver ? 'warn' : 'good'
      });
      StatusPill({
        label: this.cacheReady ? 'Cached' : 'Streaming',
        tone: this.cacheReady ? 'good' : 'info'
      });
    }
    .justifyContent(FlexAlign.Center)
    .width('100%');

    Text(this.statusLine)
      .fontSize(10)
      .fontColor('#5A6472')
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .margin({ top: 4 })
      .width('100%');
  }

  @Builder
  demoActions() {
    Row({ space: 6 }) {
      Button('Cache')
        .fontSize(10)
        .fontColor('#1F4FB1')
        .backgroundColor('#E6EEFC')
        .height(28)
        .layoutWeight(1)
        .onClick(() => {
          commonEventService.publish(AppConstants.EVENT_CACHE_READY, 'Episode cached for offline');
        });
      Button('Low Bat')
        .fontSize(10)
        .fontColor('#7A4A00')
        .backgroundColor('#FFE9C7')
        .height(28)
        .layoutWeight(1)
        .onClick(() => {
          commonEventService.publish(AppConstants.EVENT_LOW_BATTERY, 'Simulated low battery');
        });
      Button('Events')
        .fontSize(10)
        .fontColor('#FFFFFF')
        .backgroundColor('#1F6FEB')
        .height(28)
        .layoutWeight(1)
        .onClick(() => this.onOpenMonitor());
    }
    .width('100%')
    .margin({ top: 6 });
  }

  private currentEpisode(): Episode {
    return SAMPLE_EPISODES[this.episodeIdx];
  }

  private handleTogglePlay(): void {
    if (this.batterySaver && !this.isPlaying) {
      this.statusLine = 'Streaming paused on low battery';
      return;
    }
    const next: string = this.isPlaying
      ? AppConstants.EVENT_PLAYBACK_PAUSED
      : AppConstants.EVENT_PLAYBACK_STARTED;
    commonEventService.publish(next, this.currentEpisode().title);
  }

  private handleSkipBack(): void {
    const prevIdx: number = (this.episodeIdx - 1 + SAMPLE_EPISODES.length) % SAMPLE_EPISODES.length;
    commonEventService.publish(AppConstants.EVENT_EPISODE_SKIPPED, `back:${prevIdx}`);
  }

  private handleSkipForward(): void {
    const nextIdx: number = (this.episodeIdx + 1) % SAMPLE_EPISODES.length;
    commonEventService.publish(AppConstants.EVENT_EPISODE_SKIPPED, `forward:${nextIdx}`);
  }

  private applyEvent(event: PlaybackEvent): void {
    const name: string = event.name;
    if (name === AppConstants.EVENT_PLAYBACK_STARTED) {
      this.isPlaying = true;
      this.statusLine = `Playing: ${this.currentEpisode().title}`;
      this.startTick();
    } else if (name === AppConstants.EVENT_PLAYBACK_PAUSED) {
      this.isPlaying = false;
      this.statusLine = 'Paused';
      this.stopTick();
    } else if (name === AppConstants.EVENT_EPISODE_SKIPPED) {
      this.applySkip(event.detail);
    } else if (name === AppConstants.EVENT_EPISODE_COMPLETED) {
      this.isPlaying = false;
      this.elapsedSec = 0;
      this.statusLine = 'Episode complete';
      this.stopTick();
    } else if (name === AppConstants.EVENT_CACHE_READY) {
      this.cacheReady = true;
      this.statusLine = 'Cache ready for offline play';
    } else if (this.isLowBatteryName(name)) {
      this.batterySaver = true;
      this.statusLine = 'Streaming paused on low battery';
      if (this.isPlaying) {
        commonEventService.publish(AppConstants.EVENT_PLAYBACK_PAUSED, 'auto-pause');
      }
    } else if (this.isCellularReadyName(name)) {
      this.batterySaver = false;
      this.statusLine = 'Cellular streaming ready';
    }
  }

  private applySkip(detail: string): void {
    let target: number = this.episodeIdx;
    const parts: string[] = detail.split(':');
    if (parts.length === 2) {
      const parsed: number = parseInt(parts[1], 10);
      if (!isNaN(parsed) && parsed >= 0 && parsed < SAMPLE_EPISODES.length) {
        target = parsed;
      }
    }
    this.episodeIdx = target;
    this.elapsedSec = 0;
    this.cacheReady = false;
    this.statusLine = `Switched to ${this.currentEpisode().title}`;
  }

  private isLowBatteryName(name: string): boolean {
    return name === AppConstants.EVENT_LOW_BATTERY
      || name === 'usual.event.BATTERY_LOW';
  }

  private isCellularReadyName(name: string): boolean {
    return name === AppConstants.EVENT_CELLULAR_READY
      || name === 'usual.event.POWER_CONNECTED';
  }

  private startTick(): void {
    if (this.tickHandle !== -1) {
      return;
    }
    this.tickHandle = setInterval(() => {
      const total: number = this.currentEpisode().durationSec;
      if (this.elapsedSec + 1 >= total) {
        this.elapsedSec = total;
        this.stopTick();
        commonEventService.publish(AppConstants.EVENT_EPISODE_COMPLETED, this.currentEpisode().title);
        return;
      }
      this.elapsedSec = this.elapsedSec + 1;
    }, AppConstants.TICK_INTERVAL_MS);
  }

  private stopTick(): void {
    if (this.tickHandle !== -1) {
      clearInterval(this.tickHandle);
      this.tickHandle = -1;
    }
  }
}
