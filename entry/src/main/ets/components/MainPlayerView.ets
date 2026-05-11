import { image } from '@kit.ImageKit';
import { promptAction } from '@kit.ArkUI';
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
  @State displayArtist: string = '';

  private stateListener: StateListener = (state: string) => {
    if (state === 'playing') {
      this.isPlaying = true;
      this.isReady = true;
    } else if (state === 'paused') {
      this.isPlaying = false;
      this.isReady = true;
    } else if (state === 'prepared') {
      this.isReady = true;
      this.durationMs = audioPlayerService.durationMs();
      this.refreshMetadata();
    } else if (state === 'completed') {
      this.isReady = true;
    } else if (state === 'error' || state === 'idle' || state === 'released') {
      this.isReady = false;
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
    this.showToast('Audio unavailable');
  };

  private showToast(message: string): void {
    try {
      promptAction.showToast({ message: message, duration: 2500, bottom: '12vp' });
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
      this.artworkBlock();
      EpisodeHeader({
        podcast: this.displayArtist.length > 0 ? this.displayArtist : this.currentEpisode().podcast,
        title: this.displayTitle.length > 0 ? this.displayTitle : this.currentEpisode().title
      });
      this.progressBlock();
      PlayerControls({
        isPlaying: this.isPlaying,
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
          .fill('#1F6FEB')
          .opacity(0.18);
        Text(this.currentEpisode().artworkLabel)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F6FEB');
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
    this.elapsedMs = 0;
    this.durationMs = ep.fallbackDurationSec * 1000;
    this.artwork = null;
    this.displayTitle = ep.title;
    this.displayArtist = ep.podcast;
    audioPlayerService.load(ep).catch(() => {
      this.showToast('Audio unavailable');
    });
  }

  private handleTogglePlay(): void {
    soundEffectService.play('tap');
    if (!this.isReady) {
      this.showToast('Audio unavailable');
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
    metadataService.fetchFor(ep).then((meta: EpisodeMetadata) => {
      if (meta.title.length > 0) {
        this.displayTitle = meta.title;
      }
      if (meta.artist.length > 0) {
        this.displayArtist = meta.artist;
      }
      if (meta.durationMs > 0) {
        this.durationMs = meta.durationMs;
      }
      this.artwork = meta.artwork;
    });
  }
}
