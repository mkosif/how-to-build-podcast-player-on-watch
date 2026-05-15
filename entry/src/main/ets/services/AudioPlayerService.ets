import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { commonEventManager, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { AppConstants } from '../constants/AppConstants';
import { Episode, EpisodeSourceType } from '../model/Episode';
import { commonEventService, SystemEventListener } from './CommonEventService';

const DOMAIN: number = 0xCE02;
const TAG: string = 'AudioPlayerService';

export type StateListener = (state: string) => void;
export type TimeUpdateListener = (positionMs: number, durationMs: number) => void;
export type EndedListener = () => void;
export type ErrorListener = (message: string) => void;

// AVPlayer wrapper. Drives the UI through direct callbacks (state, time,
// ended, error). The pub/sub bus is reserved for the spec's stated purpose —
// reacting to system events (battery low pauses playback) and broadcasting a
// single app-level EPISODE_COMPLETED so other surfaces can subscribe.
export class AudioPlayerService {
  private avPlayer: media.AVPlayer | null = null;
  private currentEpisode: Episode | null = null;
  private context: common.UIAbilityContext | null = null;

  private stateListeners: StateListener[] = [];
  private timeListeners: TimeUpdateListener[] = [];
  private endedListeners: EndedListener[] = [];
  private errorListeners: ErrorListener[] = [];

  private lastDurationMs: number = 0;
  private bufferDurationSec: number = AppConstants.URL_STREAM_BUFFER_WIFI_SEC;
  private loadToken: number = 0;

  private systemListener: SystemEventListener = (event: string, _data: commonEventManager.CommonEventData) => {
    if (event === commonEventManager.Support.COMMON_EVENT_BATTERY_LOW) {
      this.pause().catch((err: Object) => {
        hilog.warn(DOMAIN, TAG, 'auto-pause failed: %{public}s', JSON.stringify(err));
      });
    }
  };

  bind(context: common.UIAbilityContext): void {
    this.context = context;
  }

  attachSystemListener(): void {
    commonEventService.addSystemListener(this.systemListener);
  }

  setBufferDuration(seconds: number): void {
    this.bufferDurationSec = seconds;
  }

  durationMs(): number {
    return this.lastDurationMs;
  }

  currentEpisodeRef(): Episode | null {
    return this.currentEpisode;
  }

  async load(episode: Episode): Promise<void> {
    const token: number = this.nextLoadToken();
    await this.disposePlayer();
    if (!this.isActiveToken(token)) {
      return;
    }
    this.currentEpisode = episode;
    this.lastDurationMs = episode.fallbackDurationSec * 1000;
    try {
      const player: media.AVPlayer = await media.createAVPlayer();
      if (!this.isActiveToken(token)) {
        await this.releaseStalePlayer(player);
        return;
      }
      this.avPlayer = player;
      this.attachAvListeners(player, token);
      if (episode.sourceType === EpisodeSourceType.Rawfile) {
        await this.applyRawfileSource(player, episode.source);
      } else {
        this.applyUrlSource(player, episode.source);
      }
    } catch (err) {
      if (this.isActiveToken(token)) {
        this.reportError('load', err);
      }
    }
  }

  async play(): Promise<void> {
    const player: media.AVPlayer | null = this.avPlayer;
    if (player === null) {
      return;
    }
    try {
      await player.play();
    } catch (err) {
      this.reportError('play', err);
    }
  }

  async pause(): Promise<void> {
    const player: media.AVPlayer | null = this.avPlayer;
    if (player === null) {
      return;
    }
    try {
      await player.pause();
    } catch (err) {
      this.reportError('pause', err);
    }
  }

  seek(positionMs: number): void {
    const player: media.AVPlayer | null = this.avPlayer;
    if (player === null) {
      return;
    }
    try {
      player.seek(positionMs, media.SeekMode.SEEK_PREV_SYNC);
    } catch (err) {
      this.reportError('seek', err);
    }
  }

  onStateChange(listener: StateListener): void {
    this.register(this.stateListeners, listener);
  }
  offStateChange(listener: StateListener): void {
    this.unregister(this.stateListeners, listener);
  }
  onTimeUpdate(listener: TimeUpdateListener): void {
    this.register(this.timeListeners, listener);
  }
  offTimeUpdate(listener: TimeUpdateListener): void {
    this.unregister(this.timeListeners, listener);
  }
  onEnded(listener: EndedListener): void {
    this.register(this.endedListeners, listener);
  }
  offEnded(listener: EndedListener): void {
    this.unregister(this.endedListeners, listener);
  }
  onError(listener: ErrorListener): void {
    this.register(this.errorListeners, listener);
  }
  offError(listener: ErrorListener): void {
    this.unregister(this.errorListeners, listener);
  }

  async release(): Promise<void> {
    this.nextLoadToken();
    commonEventService.removeSystemListener(this.systemListener);
    await this.disposePlayer();
    this.stateListeners = [];
    this.timeListeners = [];
    this.endedListeners = [];
    this.errorListeners = [];
    this.currentEpisode = null;
  }

  private attachAvListeners(player: media.AVPlayer, token: number): void {
    player.on('stateChange', (state: string, _reason: media.StateChangeReason) => {
      this.handleStateChange(player, token, state);
    });
    player.on('error', (err: BusinessError) => {
      if (!this.isActivePlayer(player, token)) {
        return;
      }
      hilog.error(DOMAIN, TAG, 'AVPlayer error: %{public}s', JSON.stringify(err));
      this.fireError(err.message);
    });
    player.on('timeUpdate', (timeMs: number) => {
      if (!this.isActivePlayer(player, token)) {
        return;
      }
      for (let i = 0; i < this.timeListeners.length; i++) {
        this.timeListeners[i](timeMs, this.lastDurationMs);
      }
    });
    player.on('endOfStream', () => {
      if (!this.isActivePlayer(player, token)) {
        return;
      }
      this.handleEnded();
    });
    player.on('audioInterrupt', (event: audio.InterruptEvent) => {
      if (!this.isActivePlayer(player, token)) {
        return;
      }
      this.handleAudioInterrupt(event);
    });
    player.on('audioOutputDeviceChangeWithInfo', (info: audio.AudioStreamDeviceChangeInfo) => {
      if (!this.isActivePlayer(player, token)) {
        return;
      }
      this.handleOutputDeviceChange(info);
    });
  }

  private async handleStateChange(player: media.AVPlayer, token: number, state: string): Promise<void> {
    if (!this.isActivePlayer(player, token)) {
      return;
    }
    if (state === 'initialized') {
      try {
        await player.prepare();
      } catch (err) {
        this.reportError('prepare', err);
      }
    } else if (state === 'prepared') {
      if (player.duration > 0) {
        this.lastDurationMs = player.duration;
      }
    }
    if (!this.isActivePlayer(player, token)) {
      return;
    }
    for (let i = 0; i < this.stateListeners.length; i++) {
      this.stateListeners[i](state);
    }
  }

  private handleEnded(): void {
    const title: string = this.currentEpisode === null ? '' : this.currentEpisode.title;
    commonEventService.publish(AppConstants.EVENT_EPISODE_COMPLETED, title);
    for (let i = 0; i < this.endedListeners.length; i++) {
      this.endedListeners[i]();
    }
  }

  private handleAudioInterrupt(event: audio.InterruptEvent): void {
    const isInterruptBegin: boolean = event.eventType === audio.InterruptType.INTERRUPT_TYPE_BEGIN;
    const isPauseHint: boolean = event.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE;
    const isStopHint: boolean = event.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP;
    const isMuteHint: boolean = event.hintType === audio.InterruptHint.INTERRUPT_HINT_MUTE;
    const shouldPause: boolean = isInterruptBegin || isPauseHint || isStopHint || isMuteHint;
    if (shouldPause) {
      this.pause().catch((err: Object) => {
        hilog.warn(DOMAIN, TAG, 'interrupt pause failed: %{public}s', JSON.stringify(err));
      });
    }
  }

  private handleOutputDeviceChange(info: audio.AudioStreamDeviceChangeInfo): void {
    const isOldDeviceUnavailable: boolean =
      info.changeReason === audio.AudioStreamDeviceChangeReason.REASON_OLD_DEVICE_UNAVAILABLE;
    const isOverrode: boolean = info.changeReason === audio.AudioStreamDeviceChangeReason.REASON_OVERRODE;
    const shouldPause: boolean = isOldDeviceUnavailable || isOverrode;
    if (shouldPause) {
      this.pause().catch((err: Object) => {
        hilog.warn(DOMAIN, TAG, 'device-change pause failed: %{public}s', JSON.stringify(err));
      });
    }
  }

  private async applyRawfileSource(player: media.AVPlayer, name: string): Promise<void> {
    const ctx: common.UIAbilityContext | null = this.context;
    if (ctx === null) {
      throw new Error('AudioPlayerService: UIAbilityContext not bound');
    }
    let fd: resourceManager.RawFileDescriptor;
    try {
      fd = await ctx.resourceManager.getRawFd(name);
    } catch (err) {
      const message: string = (err as BusinessError).message;
      throw new Error(`getRawFd failed: ${message !== undefined ? message : 'unknown'}`);
    }
    const avFd: media.AVFileDescriptor = { fd: fd.fd, offset: fd.offset, length: fd.length };
    player.fdSrc = avFd;
  }

  private applyUrlSource(player: media.AVPlayer, url: string): void {
    try {
      const source: media.MediaSource = media.createMediaSourceWithUrl(url, {});
      const strategy: media.PlaybackStrategy = {
        preferredBufferDuration: this.bufferDurationSec
      };
      player.setMediaSource(source, strategy);
    } catch (err) {
      const message: string = (err as BusinessError).message;
      throw new Error(`url source failed: ${message !== undefined ? message : 'unknown'}`);
    }
  }

  private async disposePlayer(): Promise<void> {
    const player: media.AVPlayer | null = this.avPlayer;
    if (player === null) {
      return;
    }
    try {
      await player.release();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'release failed: %{public}s', JSON.stringify(err));
    }
    this.avPlayer = null;
    this.lastDurationMs = 0;
  }

  private nextLoadToken(): number {
    this.loadToken = this.loadToken + 1;
    return this.loadToken;
  }

  private isActiveToken(token: number): boolean {
    return token === this.loadToken;
  }

  private isActivePlayer(player: media.AVPlayer, token: number): boolean {
    return this.isActiveToken(token) && this.avPlayer === player;
  }

  private async releaseStalePlayer(player: media.AVPlayer): Promise<void> {
    try {
      await player.release();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'stale release failed: %{public}s', JSON.stringify(err));
    }
  }

  private reportError(stage: string, err: Object): void {
    const message: string = this.extractMessage(err);
    hilog.error(DOMAIN, TAG, '%{public}s failed: %{public}s', stage, message);
    this.fireError(`${stage}: ${message}`);
  }

  // BusinessError is not an Error subclass in ArkTS strict mode, so prefer its
  // message field before falling back to Error.message or a JSON dump.
  private extractMessage(err: Object): string {
    const candidate: BusinessError = err as BusinessError;
    if (candidate.message !== undefined && candidate.message.length > 0) {
      return candidate.message;
    }
    if (err instanceof Error) {
      return err.message;
    }
    return JSON.stringify(err);
  }

  private fireError(message: string): void {
    for (let i = 0; i < this.errorListeners.length; i++) {
      this.errorListeners[i](message);
    }
  }

  private register<T>(list: T[], listener: T): void {
    if (list.indexOf(listener) < 0) {
      list.push(listener);
    }
  }

  private unregister<T>(list: T[], listener: T): void {
    const idx: number = list.indexOf(listener);
    if (idx >= 0) {
      list.splice(idx, 1);
    }
  }
}

export const audioPlayerService: AudioPlayerService = new AudioPlayerService();
