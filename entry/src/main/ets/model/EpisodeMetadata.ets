import { image } from '@kit.ImageKit';

export class EpisodeMetadata {
  title: string;
  artist: string;
  durationMs: number;
  artwork: image.PixelMap | null;

  constructor(title: string, artist: string, durationMs: number, artwork: image.PixelMap | null) {
    this.title = title;
    this.artist = artist;
    this.durationMs = durationMs;
    this.artwork = artwork;
  }
}
