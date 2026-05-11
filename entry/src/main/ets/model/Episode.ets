export enum EpisodeSourceType {
  Rawfile = 'rawfile',
  Url = 'url'
}

export class Episode {
  id: string;
  podcast: string;
  title: string;
  sourceType: EpisodeSourceType;
  source: string;
  fallbackDurationSec: number;
  artworkLabel: string;

  constructor(
    id: string,
    podcast: string,
    title: string,
    sourceType: EpisodeSourceType,
    source: string,
    fallbackDurationSec: number,
    artworkLabel: string
  ) {
    this.id = id;
    this.podcast = podcast;
    this.title = title;
    this.sourceType = sourceType;
    this.source = source;
    this.fallbackDurationSec = fallbackDurationSec;
    this.artworkLabel = artworkLabel;
  }
}

// First and third entries play from a bundled rawfile so the codelab works
// offline on the simulator. The middle entry exercises the URL MediaSource
// path; swap in a reachable public mp3 to demo real streaming.
export const SAMPLE_EPISODES: Episode[] = [
  new Episode(
    'ep-01', 'HarmonyDev Daily', 'Common Events 101',
    EpisodeSourceType.Rawfile, 'sample_episode.mp3', 312, 'CE'
  ),
  new Episode(
    'ep-02', 'Wearable Weekly', 'Streaming on the Wrist',
    EpisodeSourceType.Url, 'https://example.com/streaming.mp3', 408, 'WW'
  ),
  new Episode(
    'ep-03', 'HarmonyDev Daily', 'AVPlayer Deep Dive',
    EpisodeSourceType.Rawfile, 'sample_episode.mp3', 276, 'AV'
  )
];
