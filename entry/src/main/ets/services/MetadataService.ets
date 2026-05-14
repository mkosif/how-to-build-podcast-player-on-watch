import { media } from '@kit.MediaKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Episode, EpisodeSourceType } from '../model/Episode';
import { EpisodeMetadata } from '../model/EpisodeMetadata';

const DOMAIN: number = 0xCE03;
const TAG: string = 'MetadataService';

export class MetadataService {
  private context: common.UIAbilityContext | null = null;

  bind(context: common.UIAbilityContext): void {
    this.context = context;
  }

  async fetchFor(episode: Episode): Promise<EpisodeMetadata> {
    if (episode.sourceType === EpisodeSourceType.Rawfile) {
      return this.fetchFromRawfile(episode);
    }
    return this.staticFallback(episode);
  }

  private async fetchFromRawfile(episode: Episode): Promise<EpisodeMetadata> {
    const ctx: common.UIAbilityContext | null = this.context;
    if (ctx === null) {
      return this.staticFallback(episode);
    }
    let extractor: media.AVMetadataExtractor | null = null;
    try {
      const fd: resourceManager.RawFileDescriptor = await ctx.resourceManager.getRawFd(episode.source);
      extractor = await media.createAVMetadataExtractor();
      extractor.fdSrc = { fd: fd.fd, offset: fd.offset, length: fd.length };
      const meta: media.AVMetadata = await extractor.fetchMetadata();
      const artwork: image.PixelMap | null = await this.tryFetchCover(extractor);
      const title: string = meta.title !== undefined && meta.title.length > 0 ? meta.title : episode.title;
      const artist: string = meta.artist !== undefined ? meta.artist : episode.podcast;
      const durationMs: number = this.parseDurationMs(meta.duration, episode.fallbackDurationSec);
      return new EpisodeMetadata(title, artist, durationMs, artwork);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'fetchFromRawfile failed: %{public}s', JSON.stringify(err));
      return this.staticFallback(episode);
    } finally {
      if (extractor !== null) {
        try {
          await extractor.release();
        } catch (releaseErr) {
          hilog.warn(DOMAIN, TAG, 'release failed: %{public}s', JSON.stringify(releaseErr));
        }
      }
    }
  }

  private async tryFetchCover(extractor: media.AVMetadataExtractor): Promise<image.PixelMap | null> {
    try {
      return await extractor.fetchAlbumCover();
    } catch (err) {
      hilog.info(DOMAIN, TAG, 'no album cover: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  private parseDurationMs(raw: string | undefined, fallbackSec: number): number {
    if (raw === undefined || raw.length === 0) {
      return fallbackSec * 1000;
    }
    const parsed: number = parseInt(raw, 10);
    if (isNaN(parsed) || parsed <= 0) {
      return fallbackSec * 1000;
    }
    return parsed;
  }

  private staticFallback(episode: Episode): EpisodeMetadata {
    return new EpisodeMetadata(episode.title, episode.podcast, episode.fallbackDurationSec * 1000, null);
  }
}

export const metadataService: MetadataService = new MetadataService();
