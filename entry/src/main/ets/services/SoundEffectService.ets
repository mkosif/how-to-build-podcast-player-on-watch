import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../constants/AppConstants';

const DOMAIN: number = 0xCE04;
const TAG: string = 'SoundEffectService';

export type SoundEffectKey = 'tap' | 'skip' | 'chime';

// Wraps media.SoundPool for low-latency UI feedback. load() / play() use
// PlayParameters with priority 0 and full volume. Missing rawfile assets are
// tolerated so the codelab compiles and runs even without bundled sfx.
export class SoundEffectService {
  private pool: media.SoundPool | null = null;
  private context: common.UIAbilityContext | null = null;
  private ids: Map<string, number> = new Map<string, number>();

  bind(context: common.UIAbilityContext): void {
    this.context = context;
  }

  async init(): Promise<void> {
    if (this.pool !== null) {
      return;
    }
    if (this.context === null) {
      return;
    }
    const info: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_NOTIFICATION,
      rendererFlags: 0
    };
    try {
      this.pool = await media.createSoundPool(AppConstants.SFX_MAX_STREAMS, info);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'createSoundPool failed: %{public}s', JSON.stringify(err));
      return;
    }
    await this.tryLoad('tap', AppConstants.SFX_TAP);
    await this.tryLoad('skip', AppConstants.SFX_SKIP);
    await this.tryLoad('chime', AppConstants.SFX_CHIME);
  }

  async play(key: SoundEffectKey): Promise<void> {
    const pool: media.SoundPool | null = this.pool;
    const id: number | undefined = this.ids.get(key);
    if (pool === null || id === undefined) {
      return;
    }
    const params: media.PlayParameters = {
      loop: 0,
      rate: 1,
      leftVolume: 1,
      rightVolume: 1,
      priority: 0
    };
    try {
      await pool.play(id, params);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'play %{public}s failed: %{public}s', key, JSON.stringify(err));
    }
  }

  async release(): Promise<void> {
    const pool: media.SoundPool | null = this.pool;
    if (pool === null) {
      this.ids.clear();
      return;
    }
    try {
      const values: IterableIterator<number> = this.ids.values();
      let next: IteratorResult<number> = values.next();
      while (!next.done) {
        await pool.unload(next.value);
        next = values.next();
      }
      await pool.release();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'release failed: %{public}s', JSON.stringify(err));
    }
    this.ids.clear();
    this.pool = null;
  }

  private async tryLoad(key: SoundEffectKey, rawName: string): Promise<void> {
    const ctx: common.UIAbilityContext | null = this.context;
    const pool: media.SoundPool | null = this.pool;
    if (ctx === null || pool === null) {
      return;
    }
    try {
      const fd: resourceManager.RawFileDescriptor = await ctx.resourceManager.getRawFd(rawName);
      const id: number = await pool.load(fd.fd, fd.offset, fd.length);
      this.ids.set(key, id);
    } catch (err) {
      hilog.info(DOMAIN, TAG, 'sfx %{public}s missing: %{public}s', rawName, JSON.stringify(err));
    }
  }
}

export const soundEffectService: SoundEffectService = new SoundEffectService();
