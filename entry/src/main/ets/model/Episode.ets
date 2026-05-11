export class Episode {
  id: string;
  podcast: string;
  title: string;
  durationSec: number;
  artworkLabel: string;

  constructor(id: string, podcast: string, title: string, durationSec: number, artworkLabel: string) {
    this.id = id;
    this.podcast = podcast;
    this.title = title;
    this.durationSec = durationSec;
    this.artworkLabel = artworkLabel;
  }
}

export const SAMPLE_EPISODES: Episode[] = [
  new Episode('ep-01', 'HarmonyDev Daily', 'Common Events 101', 312, 'CE'),
  new Episode('ep-02', 'HarmonyDev Daily', 'NavPathStack Patterns', 408, 'NV'),
  new Episode('ep-03', 'Wearable Weekly', 'UI on a Round Display', 276, 'WW')
];
