export class PlaybackEvent {
  id: string;
  name: string;
  detail: string;
  timestampMs: number;

  constructor(id: string, name: string, detail: string, timestampMs: number) {
    this.id = id;
    this.name = name;
    this.detail = detail;
    this.timestampMs = timestampMs;
  }

  shortName(): string {
    const dot: number = this.name.lastIndexOf('.');
    return dot >= 0 ? this.name.substring(dot + 1) : this.name;
  }
}
