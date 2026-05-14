import { image } from '@kit.ImageKit';
import { Episode, SAMPLE_EPISODES } from '../model/Episode';
import { EpisodeMetadata } from '../model/EpisodeMetadata';
import {
  audioPlayerService, StateListener, TimeUpdateListener, EndedListener, ErrorListener
} from '../services/AudioPlayerService';
import { metadataService } from '../services/MetadataService';
import { soundEffectService } from '../services/SoundEffectService';
import { TimeFormatter } from '../utils/TimeFormatter';
import { EpisodeHeader } from './EpisodeHeader';
import { PlayerControls } from './PlayerControls';

@Component
export struct MainPlayerView {
  @State episodeIdx: number = 0;
  @State elapsedMs: number = 0;
  @State durationMs: number = 0;
  @State isPlaying: boolean = false;
  @State isReady: boolean = false;
  @State artwork: image.PixelMap | null = null;
  @State displayTitle: string = '';
  private isLoading: boolean = false;
  private metadataToken: number = 0;
  private pendingPlay: boolean = false;

  private stateListener: StateListener = (state: string) => {
    if (state === 'playing') {
      this.isPlaying = true;
      this.isReady = true;
    } else if (state === 'paused') {
      this.isPlaying = false;
      this.isReady = true;
    } else if (state === 'prepared') {
      this.isReady = true;
      this.isLoading = false;
      this.durationMs = audioPlayerService.durationMs();
      this.refreshMetadata();
      if (this.pendingPlay) {
        this.pendingPlay = false;
        audioPlayerService.play();
      }
    } else if (state === 'completed') {
      this.isReady = true;
    } else if (state === 'error' || state === 'idle' || state === 'released') {
      this.isReady = false;
      this.isLoading = false;
      this.isPlaying = false;
    }
  };

  private timeListener: TimeUpdateListener = (positionMs: number, durationMs: number) => {
    this.elapsedMs = positionMs;
    if (durationMs > 0) {
      this.durationMs = durationMs;
    }
  };

  private endedListener: EndedListener = () => {
    this.isPlaying = false;
    this.elapsedMs = 0;
    soundEffectService.play('chime');
  };

  // Raw AVPlayer error strings are not user-friendly; the original message is
  // already in hilog for debugging. Surface a single, generic toast instead.
  private errorListener: ErrorListener = (_message: string) => {
    this.isPlaying = false;
    this.isReady = false;
    this.isLoading = false;
    this.showToast('Audio unavailable');
  };

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: 2500,
        bottom: '12vp'
      });
    } catch (_err) {
      // Toast surface is not available — silently drop; AVPlayer error is
      // already logged through hilog in AudioPlayerService.
    }
  }

  aboutToAppear(): void {
    audioPlayerService.onStateChange(this.stateListener);
    audioPlayerService.onTimeUpdate(this.timeListener);
    audioPlayerService.onEnded(this.endedListener);
    audioPlayerService.onError(this.errorListener);
    this.loadCurrentEpisode();
  }

  aboutToDisappear(): void {
    audioPlayerService.offStateChange(this.stateListener);
    audioPlayerService.offTimeUpdate(this.timeListener);
    audioPlayerService.offEnded(this.endedListener);
    audioPlayerService.offError(this.errorListener);
  }

  build() {
    Column({ space: 4 }) {
      this.episodeIndicator();
      this.artworkBlock();
      EpisodeHeader({
        exampleLabel: this.currentEpisode().exampleLabel,
        title: this.displayTitle.length > 0 ? this.displayTitle : this.currentEpisode().title,
        apiLabel: this.currentEpisode().apiLabel,
        eventLabel: 'CommonEvent: subscribe + publish'
      });
      this.progressBlock();
      PlayerControls({
        isPlaying: this.isPlaying,
        isReady: this.isReady,
        onTogglePlay: () => this.handleTogglePlay(),
        onSkipBack: () => this.handleSkipBack(),
        onSkipForward: () => this.handleSkipForward()
      });
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22, top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  episodeIndicator() {
    Row({ space: 4 }) {
      ForEach(SAMPLE_EPISODES, (ep: Episode) => {
        Circle({ width: 5, height: 5 })
          .fill(ep.id === this.currentEpisode().id ? this.currentEpisode().accentColor : '#D1D5DB');
      }, (ep: Episode) => ep.id);
    }
    .justifyContent(FlexAlign.Center)
    .width('100%');
  }

  @Builder
  artworkBlock() {
    Stack() {
      if (this.artwork !== null) {
        Image(this.artwork)
          .width(44)
          .height(44)
          .borderRadius(22)
          .objectFit(ImageFit.Cover);
      } else {
        Circle({ width: 44, height: 44 })
          .fill(this.currentEpisode().accentColor)
          .opacity(0.18);
        Text(this.currentEpisode().artworkLabel)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentEpisode().accentColor);
      }
    }
    .width(44)
    .height(44);
  }

  @Builder
  progressBlock() {
    Column({ space: 2 }) {
      Progress({
        value: Math.floor(this.elapsedMs / 1000),
        total: Math.floor(this.durationMs / 1000),
        type: ProgressType.Linear
      })
        .color('#1F6FEB')
        .backgroundColor('#E6EEFC')
        .width('100%')
        .height(4);

      Row() {
        Text(TimeFormatter.formatMs(this.elapsedMs))
          .fontSize(10)
          .fontColor('#7A8595');
        Blank();
        Text(TimeFormatter.formatMs(this.durationMs))
          .fontSize(10)
          .fontColor('#7A8595');
      }
      .width('100%');
    }
    .width('100%');
  }

  private currentEpisode(): Episode {
    return SAMPLE_EPISODES[this.episodeIdx];
  }

  private loadCurrentEpisode(): void {
    const ep: Episode = this.currentEpisode();
    this.isPlaying = false;
    this.isReady = false;
    this.isLoading = true;
    this.pendingPlay = false;
    this.elapsedMs = 0;
    this.durationMs = ep.fallbackDurationSec * 1000;
    this.artwork = null;
    this.displayTitle = ep.title;
    audioPlayerService.load(ep).catch(() => {
      this.isLoading = false;
      this.showToast('Audio unavailable');
    });
  }

  private handleTogglePlay(): void {
    soundEffectService.play('tap');
    if (!this.isReady) {
      if (this.isLoading) {
        this.pendingPlay = true;
      } else {
        this.showToast('Audio unavailable');
      }
      return;
    }
    if (this.isPlaying) {
      audioPlayerService.pause();
    } else {
      audioPlayerService.play();
    }
  }

  private handleSkipBack(): void {
    soundEffectService.play('skip');
    this.episodeIdx = (this.episodeIdx - 1 + SAMPLE_EPISODES.length) % SAMPLE_EPISODES.length;
    this.loadCurrentEpisode();
  }

  private handleSkipForward(): void {
    soundEffectService.play('skip');
    this.episodeIdx = (this.episodeIdx + 1) % SAMPLE_EPISODES.length;
    this.loadCurrentEpisode();
  }

  private refreshMetadata(): void {
    const ep: Episode = this.currentEpisode();
    const token: number = this.nextMetadataToken();
    metadataService.fetchFor(ep).then((meta: EpisodeMetadata) => {
      if (token !== this.metadataToken || this.currentEpisode().id !== ep.id) {
        return;
      }
      if (meta.title.length > 0) {
        this.displayTitle = meta.title;
      }
      if (meta.durationMs > 0) {
        this.durationMs = meta.durationMs;
      }
      this.artwork = meta.artwork;
    });
  }

  private nextMetadataToken(): number {
    this.metadataToken = this.metadataToken + 1;
    return this.metadataToken;
  }
}
