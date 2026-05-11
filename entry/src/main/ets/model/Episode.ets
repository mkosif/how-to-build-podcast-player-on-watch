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
  accentColor: string;
  exampleLabel: string;
  apiLabel: string;

  constructor(
    id: string,
    podcast: string,
    title: string,
    sourceType: EpisodeSourceType,
    source: string,
    fallbackDurationSec: number,
    artworkLabel: string,
    accentColor: string,
    exampleLabel: string,
    apiLabel: string
  ) {
    this.id = id;
    this.podcast = podcast;
    this.title = title;
    this.sourceType = sourceType;
    this.source = source;
    this.fallbackDurationSec = fallbackDurationSec;
    this.artworkLabel = artworkLabel;
    this.accentColor = accentColor;
    this.exampleLabel = exampleLabel;
    this.apiLabel = apiLabel;
  }
}

// Two episodes covering the two AVPlayer source paths the spec requires.
export const SAMPLE_EPISODES: Episode[] = [
  new Episode(
    'ep-01', 'Public Domain Sci-Fi', 'The Machine Stops',
    EpisodeSourceType.Rawfile, 'episode_machine_stops.mp3', 24,
    'MS', '#1F6FEB',
    'Rawfile playback',
    'AVFileDescriptor'
  ),
  new Episode(
    'ep-02', 'Public Domain Sci-Fi', 'The Time Machine',
    EpisodeSourceType.Url,
    'https://ia902804.us.archive.org/13/items/timemachine_sjm_librivox/timemachine_01_wells_64kb.mp3',
    1280,
    'TM', '#8B5CF6',
    'URL streaming',
    'MediaSource'
  )
];
