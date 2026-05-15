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

const STREAM_SCHEME: string = 'https';
const TIME_MACHINE_HOST: string = 'ia902804.us.archive.org';
const TIME_MACHINE_PATH: string = '13/items/timemachine_sjm_librivox/timemachine_01_wells_64kb.mp3';
const TIME_MACHINE_STREAM: string = `${STREAM_SCHEME}://${TIME_MACHINE_HOST}/${TIME_MACHINE_PATH}`;

// Three examples: rawfile playback, URL streaming, then a second rawfile that
// proves skip/reload switches to a distinct bundled asset.
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
    TIME_MACHINE_STREAM,
    1280,
    'TM', '#8B5CF6',
    'URL streaming',
    'MediaSource'
  ),
  new Episode(
    'ep-03', 'Adventure Classics', 'Everything through Electricity',
    EpisodeSourceType.Rawfile, 'episode_electricity.mp3', 24,
    'EL', '#10B981',
    'Second offline asset',
    'AVMetadataExtractor'
  )
];
